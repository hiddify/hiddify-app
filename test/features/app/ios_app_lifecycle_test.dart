import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('coalesced inactive and resumed events restart the stopped iOS measurement', (tester) async {
    final fixture = await _mount(tester);
    final initialRequests = fixture.repository.requests;
    expect(initialRequests, greaterThan(0));
    fixture.app.events.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    final measurement = fixture.container.read(iosActiveProxyMeasurementProvider);
    expect(fixture.app.events, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(fixture.repository.requests, initialRequests + 1);
    expect(measurement.state.phase, IosProxyMeasurementPhase.checking);
    expect(measurement.canRefresh, true);

    await fixture.dispose(tester);
  });

  testWidgets('direct observer forwards normal inactive paused and resumed events exactly once', (tester) async {
    final fixture = await _mount(tester);
    expect(fixture.app.events, [AppLifecycleState.resumed]);
    fixture.app.events.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(fixture.app.events, [AppLifecycleState.inactive, AppLifecycleState.paused, AppLifecycleState.resumed]);
    await fixture.dispose(tester);
  });

  testWidgets('disposed direct observer receives no later lifecycle callbacks', (tester) async {
    final fixture = await _mount(tester);
    fixture.app.events.clear();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(fixture.app.events, isEmpty);
    await fixture.disposeContainer();
  });

  testWidgets('legacy hook path keeps its existing frame-coalesced behavior', (tester) async {
    final fixture = await _mount(tester, direct: false);
    expect(fixture.app.events, [AppLifecycleState.resumed]);
    fixture.app.events.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(fixture.app.events, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    fixture.app.events.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(fixture.app.events, isEmpty);

    await fixture.dispose(tester);
  });
}

Future<_Fixture> _mount(WidgetTester tester, {bool direct = true}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  final repository = _Repository();
  final app = _SpyApp(direct: direct);
  final container = ProviderContainer(
    overrides: [
      iosActiveProxyMeasurementEnabledProvider.overrideWithValue(true),
      serviceRunningProvider.overrideWith((ref) => true),
      proxyRepositoryProvider.overrideWithValue(repository),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: _LifecycleHarness(app: app)),
    ),
  );
  await tester.pump();
  return _Fixture(app, container, repository);
}

class _Fixture {
  _Fixture(this.app, this.container, this.repository);

  final _SpyApp app;
  final ProviderContainer container;
  final _Repository repository;

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await disposeContainer();
  }

  Future<void> disposeContainer() async {
    container.dispose();
    await repository.events.close();
  }
}

class _LifecycleHarness extends HookConsumerWidget {
  const _LifecycleHarness({required this.app});

  final App app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(iosActiveProxyMeasurementStateProvider);
    app.setupStateListener(ref);
    return const SizedBox.shrink();
  }
}

class _SpyApp extends App {
  _SpyApp({required this.direct});

  final bool direct;
  final events = <AppLifecycleState>[];

  @override
  bool get useDirectAppLifecycleObserver => direct;

  @override
  void onInactive(WidgetRef ref) {
    events.add(AppLifecycleState.inactive);
  }

  @override
  void onPause(WidgetRef ref) {
    events.add(AppLifecycleState.paused);
  }

  @override
  void onResume(WidgetRef ref) {
    events.add(AppLifecycleState.resumed);
    scheduleMicrotask(() => ref.read(coreRestartSignalProvider.notifier).restart());
  }
}

class _Repository implements ProxyRepository {
  final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
  int requests = 0;

  @override
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies() => events.stream;

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) => TaskEither(() async {
    requests++;
    return right(unit);
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
