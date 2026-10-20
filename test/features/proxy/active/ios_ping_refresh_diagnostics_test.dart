import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('failed foreground recovery is observable without issuing a measurement', (tester) async {
    final fixture = await _Fixture.mount(tester);
    await fixture.completeInitialMeasurement(tester);
    expect(fixture.measurement.state.phase, IosProxyMeasurementPhase.available);
    expect(fixture.repository.requests, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(fixture.measurement.state.phase, IosProxyMeasurementPhase.idle);
    expect(fixture.measurement.canRefresh, false);

    await expectLater(
      fixture.container.read(activeProxyNotifierProvider.notifier).urlTest(''),
      throwsA(isA<HiddifyCoreInitializationException>()),
    );

    final operation = fixture.operationEvents;
    expect(operation.map((entry) => entry.event), [
      IosPingEvent.refreshTapped,
      IosPingEvent.refreshCoreNotReady,
      IosPingEvent.refreshFailed,
    ]);
    expect(operation.map((entry) => entry.operationId).toSet(), hasLength(1));
    expect(operation.first.operationId, greaterThan(0));
    expect(fixture.repository.requests, 1);

    await fixture.dispose();
  });

  testWidgets('accepted refresh correlates notifier and coordinator boundaries', (tester) async {
    final fixture = await _Fixture.mount(tester);
    await fixture.completeInitialMeasurement(tester);
    fixture.repository.gate = Completer<void>();

    final refresh = fixture.container.read(activeProxyNotifierProvider.notifier).urlTest('');
    await tester.pump();
    expect(fixture.repository.requests, 2);

    fixture.repository.events.add(
      right([
        OutboundGroup(items: [fixture.repository.freshProxy()]),
      ]),
    );
    await tester.pump();
    fixture.repository.gate!.complete();
    fixture.repository.gate = null;
    await refresh;
    await tester.pump();

    final operation = fixture.operationEvents;
    expect(operation.map((entry) => entry.event), [
      IosPingEvent.refreshTapped,
      IosPingEvent.hapticRequested,
      IosPingEvent.hapticCompleted,
      IosPingEvent.refreshIssued,
      IosPingEvent.measurementChecking,
      IosPingEvent.probeRequestIssued,
      IosPingEvent.probeStreamUsable,
      IosPingEvent.probeSnapshotFresh,
      IosPingEvent.probeRequestCompleted,
      IosPingEvent.measurementAvailable,
      IosPingEvent.refreshCompleted,
    ]);
    expect(operation.map((entry) => entry.operationId).toSet(), hasLength(1));
    expect(operation.first.operationId, greaterThan(0));
    expect(fixture.measurement.state.phase, IosProxyMeasurementPhase.available);

    await fixture.dispose();
  });

  test('late request completion keeps the operation id of the cancelled attempt', () async {
    final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
    final requestGates = <Completer<void>>[];
    final observed = <(IosPingEvent, int)>[];
    final measurement = IosActiveProxyMeasurement(
      watch: () => events.stream,
      request: () async {
        final gate = Completer<void>();
        requestGates.add(gate);
        await gate.future;
      },
      observer: (event, operationId) => observed.add((event, operationId)),
    );
    addTearDown(() async {
      for (final gate in requestGates) {
        if (!gate.isCompleted) gate.complete();
      }
      measurement.dispose();
      await events.close();
    });

    final first = measurement.refresh(operationId: 11);
    final firstOutcome = first.then<Object?>((_) => null, onError: (Object error, StackTrace _) => error);
    await Future<void>.delayed(Duration.zero);
    expect(requestGates, hasLength(1));
    measurement.stop();
    expect(await firstOutcome, isA<IosProxyMeasurementException>());

    final second = measurement.refresh(operationId: 22);
    final secondOutcome = second.then<Object?>((_) => null, onError: (Object error, StackTrace _) => error);
    await Future<void>.delayed(Duration.zero);
    expect(requestGates, hasLength(2));

    requestGates.first.complete();
    await Future<void>.delayed(Duration.zero);
    expect(observed.where((entry) => entry.$1 == IosPingEvent.probeRequestCompleted && entry.$2 == 22), isEmpty);

    events.add(
      right([
        OutboundGroup(
          items: [
            OutboundInfo(
              tag: 'synthetic-active',
              urlTestDelay: 84,
              urlTestTime: Timestamp.fromDateTime(DateTime.now().add(const Duration(seconds: 1))),
            ),
          ],
        ),
      ]),
    );
    requestGates.last.complete();
    expect(await secondOutcome, isNull);
    expect(observed.where((entry) => entry.$1 == IosPingEvent.probeRequestCompleted && entry.$2 == 22), hasLength(1));
  });

  test('repeated usable stream events retain one boundary entry per attempt', () async {
    final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
    final requestGate = Completer<void>();
    final trace = IosPingTrace();
    final measurement = IosActiveProxyMeasurement(
      watch: () => events.stream,
      request: () => requestGate.future,
      observer: (event, operationId) => trace.record(event, operationId: operationId),
    );
    final refresh = measurement.refresh(operationId: 33);
    final outcome = refresh.then<Object?>((_) => null, onError: (Object error, StackTrace _) => error);
    addTearDown(() async {
      if (!requestGate.isCompleted) requestGate.complete();
      measurement.dispose();
      trace.dispose();
      await events.close();
    });
    await Future<void>.delayed(Duration.zero);

    final stale = right<ProxyFailure, List<OutboundGroup>>([
      OutboundGroup(
        items: [
          OutboundInfo(
            tag: 'synthetic-active',
            urlTestDelay: 84,
            urlTestTime: Timestamp.fromDateTime(DateTime.utc(2000)),
          ),
        ],
      ),
    ]);
    for (var index = 0; index < 150; index++) {
      events.add(stale);
    }
    await Future<void>.delayed(Duration.zero);

    expect(trace.snapshot.events.where((entry) => entry.event == IosPingEvent.probeStreamUsable), hasLength(1));
    expect(trace.snapshot.events.map((entry) => entry.event), contains(IosPingEvent.measurementChecking));

    measurement.stop();
    expect(await outcome, isA<IosProxyMeasurementException>());
  });

  testWidgets('automatic provider rebuild keeps late request completion on the old operation', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final repository = _RebuildRepository();
    final trace = IosPingTrace(elapsedMilliseconds: () => 0);
    final container = ProviderContainer(
      overrides: [
        iosActiveProxyMeasurementEnabledProvider.overrideWithValue(true),
        serviceRunningProvider.overrideWith((ref) => true),
        proxyRepositoryProvider.overrideWithValue(repository),
        iosPingTraceProvider.overrideWithValue(trace),
      ],
    );
    await tester.pumpWidget(_ContainerOwner(container: container));
    final subscription = container.listen(iosActiveProxyMeasurementStateProvider, (_, _) {});
    var disposed = false;
    Future<void> dispose() async {
      if (disposed) return;
      disposed = true;
      subscription.close();
      for (final gate in repository.requestGates) {
        if (!gate.isCompleted) gate.complete();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      trace.dispose();
      await repository.events.close();
    }

    addTearDown(dispose);

    await tester.pump();
    await tester.pump();
    expect(repository.requestGates, hasLength(1));
    final oldMeasurement = container.read(iosActiveProxyMeasurementProvider);
    final oldOperationId = trace.snapshot.events
        .firstWhere((entry) => entry.event == IosPingEvent.measurementCreated)
        .operationId;

    container.read(coreRestartSignalProvider.notifier).restart();
    await tester.pump();
    await tester.pump();
    final newMeasurement = container.read(iosActiveProxyMeasurementProvider);
    await tester.pump();
    expect(repository.requestGates, hasLength(2));
    final creationEvents = trace.snapshot.events
        .where((entry) => entry.event == IosPingEvent.measurementCreated)
        .toList(growable: false);
    final newOperationId = creationEvents.last.operationId;

    expect(newMeasurement, isNot(same(oldMeasurement)));
    expect(oldOperationId, greaterThan(0));
    expect(newOperationId, greaterThan(0));
    expect(newOperationId, isNot(oldOperationId));

    repository.requestGates.first.complete();
    await tester.pump();

    expect(
      trace.snapshot.events.where(
        (entry) => entry.event == IosPingEvent.probeRequestCompleted && entry.operationId == oldOperationId,
      ),
      hasLength(1),
    );
    expect(
      trace.snapshot.events.where(
        (entry) => entry.event == IosPingEvent.probeRequestCompleted && entry.operationId == newOperationId,
      ),
      isEmpty,
    );
    await dispose();
  });
}

final class _Fixture {
  _Fixture(this.container, this.repository, this.trace, this._measurementSubscription, this._proxySubscription);

  final ProviderContainer container;
  final _Repository repository;
  final IosPingTrace trace;
  final ProviderSubscription<AsyncValue<IosProxyMeasurementState>> _measurementSubscription;
  final ProviderSubscription<AsyncValue<OutboundInfo>> _proxySubscription;

  static Future<_Fixture> mount(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final repository = _Repository();
    final trace = IosPingTrace(elapsedMilliseconds: () => 0);
    final container = ProviderContainer(
      overrides: [
        iosActiveProxyMeasurementEnabledProvider.overrideWithValue(true),
        serviceRunningProvider.overrideWith((ref) => true),
        proxyRepositoryProvider.overrideWithValue(repository),
        hapticServiceProvider.overrideWith(_NoopHaptic.new),
        hiddifyCoreServiceProvider.overrideWith((ref) {
          final service = _UnavailableForeground(ref);
          ref.onDispose(() {
            unawaited(service.statusController.close());
            unawaited(service.logController.close());
          });
          return service;
        }),
        iosPingTraceProvider.overrideWithValue(trace),
      ],
    );
    final measurementSubscription = container.listen(iosActiveProxyMeasurementStateProvider, (_, _) {});
    final proxySubscription = container.listen(activeProxyNotifierProvider, (_, _) {});
    await tester.pump();
    await tester.pump();
    return _Fixture(container, repository, trace, measurementSubscription, proxySubscription);
  }

  IosActiveProxyMeasurement get measurement => container.read(iosActiveProxyMeasurementProvider);

  List<IosPingTraceEntry> get operationEvents {
    final operationId = trace.snapshot.events
        .lastWhere((entry) => entry.event == IosPingEvent.refreshTapped)
        .operationId;
    return trace.snapshot.events.where((entry) => entry.operationId == operationId).toList(growable: false);
  }

  Future<void> completeInitialMeasurement(WidgetTester tester) async {
    expect(repository.requests, 1);
    repository.events.add(
      right([
        OutboundGroup(items: [repository.freshProxy()]),
      ]),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> dispose() async {
    if (repository.gate?.isCompleted == false) repository.gate!.complete();
    _proxySubscription.close();
    _measurementSubscription.close();
    container.dispose();
    trace.dispose();
    await repository.events.close();
  }
}

final class _UnavailableForeground extends HiddifyCoreService {
  _UnavailableForeground(super.ref);

  @override
  Future<bool> ensureForegroundReady() async => false;
}

final class _NoopHaptic extends HapticService {
  @override
  bool build() => false;
}

final class _Repository implements ProxyRepository {
  final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
  Completer<void>? gate;
  int requests = 0;
  int _freshness = 1;

  OutboundInfo freshProxy() => OutboundInfo(
    tag: 'synthetic-active',
    tagDisplay: 'Synthetic active',
    type: 'vless',
    urlTestDelay: 84,
    urlTestTime: Timestamp.fromDateTime(DateTime.now().add(Duration(seconds: _freshness++))),
  );

  @override
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies() => events.stream;

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) => TaskEither(() async {
    requests++;
    await gate?.future;
    return right(unit);
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RebuildRepository implements ProxyRepository {
  final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
  final requestGates = <Completer<void>>[];

  @override
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies() => events.stream;

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) => TaskEither(() async {
    final gate = Completer<void>();
    requestGates.add(gate);
    await gate.future;
    return right(unit);
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ContainerOwner extends StatefulWidget {
  const _ContainerOwner({required this.container});

  final ProviderContainer container;

  @override
  State<_ContainerOwner> createState() => _ContainerOwnerState();
}

final class _ContainerOwnerState extends State<_ContainerOwner> {
  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: widget.container, child: const SizedBox.shrink());

  @override
  void dispose() {
    widget.container.dispose();
    super.dispose();
  }
}
