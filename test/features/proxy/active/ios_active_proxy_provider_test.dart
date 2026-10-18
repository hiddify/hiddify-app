import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, _Repository)> mount(
    WidgetTester tester, {
    bool ios = true,
    bool running = true,
    HapticService? haptic,
  }) async {
    SharedPreferences.setMockInitialValues({'haptic_feedback': false});
    final prefs = await SharedPreferences.getInstance();
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => prefs),
        iosActiveProxyMeasurementEnabledProvider.overrideWithValue(ios),
        serviceRunningProvider.overrideWith((ref) => running),
        proxyRepositoryProvider.overrideWithValue(repository),
        if (haptic != null) hapticServiceProvider.overrideWith(() => haptic),
      ],
    );
    await container.read(sharedPreferencesProvider.future);
    await tester.pumpWidget(_ContainerOwner(container: container));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      if (repository.gate?.isCompleted == false) repository.gate!.complete();
      await repository.events.close();
    });
    return (container, repository);
  }

  testWidgets('connected iOS starts one awaited request and publishes latency and IP from its fresh event', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final (container, repository) = await mount(tester);
    repository.gate = Completer<void>();
    final subscription = container.listen(iosActiveProxyMeasurementStateProvider, (_, _) {});
    addTearDown(subscription.close);
    final outboundSubscription = container.listen(activeProxyNotifierProvider, (_, _) {});
    addTearDown(outboundSubscription.close);
    await tester.pump();
    await tester.pump();
    expect(repository.requests, 1);
    expect(repository.tags, ['']);
    repository.events.add(right(<OutboundGroup>[]));
    await tester.pump();
    expect(container.read(iosActiveProxyMeasurementProvider).state.proxy, isNull);
    expect(container.read(activeProxyNotifierProvider).valueOrNull, isNull);

    var returned = false;
    final manual = container.read(activeProxyNotifierProvider.notifier).urlTest('').then((_) => returned = true);
    await tester.pump();
    expect(returned, false);
    expect(repository.requests, 1);
    repository.events.add(
      right([
        OutboundGroup(items: [freshProxy()]),
      ]),
    );
    await tester.pump();
    expect(returned, false);
    repository.gate!.complete();
    repository.gate = null;
    await tester.pump();
    await tester.pump();
    await manual;
    expect(container.read(iosActiveProxyMeasurementProvider).state.phase, IosProxyMeasurementPhase.available);
    final outbound = container.read(activeProxyNotifierProvider).requireValue;
    expect(outbound.urlTestDelay, 84);
    expect(outbound.ipinfo.ip, '192.0.2.1');
  });

  testWidgets('core restart replaces the iOS attempt and clears prior metadata', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final (container, repository) = await mount(tester);
    final subscription = container.listen(iosActiveProxyMeasurementStateProvider, (_, _) {});
    addTearDown(subscription.close);
    await tester.pump();
    await tester.pump();
    repository.events.add(
      right([
        OutboundGroup(items: [freshProxy()]),
      ]),
    );
    await tester.pump();
    final old = container.read(iosActiveProxyMeasurementProvider);
    expect(old.state.phase, IosProxyMeasurementPhase.available);
    container.read(coreRestartSignalProvider.notifier).restart();
    await tester.pump();
    await tester.pump();
    final current = container.read(iosActiveProxyMeasurementProvider);
    expect(current, isNot(same(old)));
    expect(current.state.proxy, isNull);
    expect(repository.requests, 2);
  });

  testWidgets('background stops the attempt and only core-ready restart begins the next one', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final (container, repository) = await mount(tester);
    final subscription = container.listen(iosActiveProxyMeasurementStateProvider, (_, _) {});
    addTearDown(subscription.close);
    await tester.pump();
    await tester.pump();
    expect(repository.requests, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(container.read(iosActiveProxyMeasurementProvider).state.phase, IosProxyMeasurementPhase.idle);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.requests, 1);
    container.read(coreRestartSignalProvider.notifier).restart();
    await tester.pump();
    await tester.pump();
    expect(repository.requests, 2);
  });

  for (final entry in [(ios: false, running: true), (ios: true, running: false)]) {
    testWidgets('no automatic measurement for ios=${entry.ios} running=${entry.running}', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final (container, repository) = await mount(tester, ios: entry.ios, running: entry.running);
      final subscription = container.listen(iosActiveProxyMeasurementStateProvider, (_, _) {});
      addTearDown(subscription.close);
      await tester.pump();
      await tester.pump();
      expect(repository.requests, 0);
    });
  }

  testWidgets('new manual tap after resume waits for core-ready restart', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final (container, repository) = await mount(tester);
    final keep = container.listen(activeProxyNotifierProvider, (_, _) {});
    addTearDown(keep.close);
    await tester.pump();
    await tester.pump();
    repository.events.add(
      right([
        OutboundGroup(items: [freshProxy()]),
      ]),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    unawaited(container.read(activeProxyNotifierProvider.notifier).urlTest('').catchError((Object _) {}));
    await tester.pump();
    expect(repository.requests, 1);
    expect(container.read(iosActiveProxyMeasurementProvider).state.phase, IosProxyMeasurementPhase.idle);
    container.read(coreRestartSignalProvider.notifier).restart();
    await tester.pump();
    await tester.pump();
    expect(repository.requests, 2);
  });

  for (final boundary in ['background', 'resume before core ready', 'core restart']) {
    final background = boundary != 'core restart';
    testWidgets('manual haptic cannot cross a $boundary boundary', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final haptic = _GateHaptic();
      final (container, repository) = await mount(tester, haptic: haptic);
      final keep = container.listen(activeProxyNotifierProvider, (_, _) {});
      addTearDown(keep.close);
      await tester.pump();
      await tester.pump();
      repository.events.add(
        right([
          OutboundGroup(items: [freshProxy()]),
        ]),
      );
      await tester.pump();
      expect(container.read(activeProxyNotifierProvider).requireValue.tag, 'synthetic-active');

      var returned = false;
      final manual = container
          .read(activeProxyNotifierProvider.notifier)
          .urlTest('')
          .then((_) => returned = true, onError: (Object _) => returned = true);
      await tester.pump();
      expect(haptic.entered.isCompleted, true);
      if (background) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        if (boundary == 'resume before core ready') {
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        }
      } else {
        container.read(coreRestartSignalProvider.notifier).restart();
      }
      await tester.pump();
      haptic.release.complete();
      await tester.pump();
      await tester.pump();
      expect(repository.requests, background ? 1 : 2);
      expect(returned, true);
      await manual;
    });
  }
}

OutboundInfo freshProxy() => OutboundInfo(
  tag: 'synthetic-active',
  tagDisplay: 'Synthetic active',
  type: 'vless',
  urlTestDelay: 84,
  urlTestTime: Timestamp.fromDateTime(DateTime.now().add(const Duration(seconds: 1))),
  ipinfo: IpInfo(ip: '192.0.2.1'),
);

class _Repository implements ProxyRepository {
  final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
  Completer<void>? gate;
  int requests = 0;
  final tags = <String>[];

  @override
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies() => events.stream;
  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) {
    tags.add(groupTag);
    return TaskEither(() async {
      requests++;
      await gate?.future;
      return right(unit);
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GateHaptic extends HapticService {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  bool build() => false;
  @override
  Future<void> lightImpact() async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
  }
}

// The widget-test binding unmounts the tree before checking pending timers.
// Own the external container in that tree so provider disposal runs in time.
class _ContainerOwner extends StatefulWidget {
  const _ContainerOwner({required this.container});

  final ProviderContainer container;

  @override
  State<_ContainerOwner> createState() => _ContainerOwnerState();
}

class _ContainerOwnerState extends State<_ContainerOwner> {
  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: widget.container, child: const SizedBox.shrink());

  @override
  void dispose() {
    widget.container.dispose();
    super.dispose();
  }
}
