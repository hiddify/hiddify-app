import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final t = AppLocale.en.buildSync();

  tearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

  testWidgets('keeps the verified ping while inactive then shows updating until the resumed check finishes', (
    tester,
  ) async {
    final fixture = await _mount(tester, t, initial: _available(84, second: 1));
    addTearDown(fixture.dispose);

    expect(find.text('84 ms'), findsOneWidget);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.idle));
    await tester.pump();

    expect(find.text('84 ms'), findsOneWidget);
    expect(_isEnabled(tester, t.pages.proxies.delay.result(delay: 84)), isFalse);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(_isEnabled(tester, t.pages.proxies.delay.updating), isFalse);

    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.checking));
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);
    expect(find.byType(ShimmerSkeleton), findsNothing);

    fixture.emit(_available(91, second: 2));
    await tester.pump();
    expect(find.text('91 ms'), findsOneWidget);
    expect(find.text(t.pages.proxies.delay.updating), findsNothing);
  });

  testWidgets('a stale available replay cannot end resume updating but a changed available snapshot can', (
    tester,
  ) async {
    final stale = _available(84, second: 1);
    final fixture = await _mount(tester, t, initial: stale);
    addTearDown(fixture.dispose);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.idle));
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    fixture.emit(stale);
    await tester.pump();

    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);
    expect(find.text('84 ms'), findsNothing);

    fixture.emit(_available(95, second: 2));
    await tester.pump();
    expect(find.text('95 ms'), findsOneWidget);
  });

  testWidgets('resume failure clears retained ping and restores retry', (tester) async {
    final fixture = await _mount(tester, t, initial: _available(84, second: 1));
    addTearDown(fixture.dispose);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.idle));
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.failed));
    await tester.pump();

    expect(find.text(t.common.unknown), findsOneWidget);
    expect(find.text('84 ms'), findsNothing);
    expect(_isEnabled(tester, t.common.unknown), isTrue);
  });

  testWidgets('measurement stream error clears a checking snapshot and restores retry', (tester) async {
    final fixture = await _mount(tester, t, initial: _available(84, second: 1));
    addTearDown(fixture.dispose);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.checking));
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);

    fixture.emitError(StateError('closed stream'));
    await tester.pump();
    expect(find.text(t.common.unknown), findsOneWidget);
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(_isEnabled(tester, t.common.unknown), isTrue);
  });

  testWidgets('disconnect clears retained ping and reconnect requires a fresh result', (tester) async {
    final fixture = await _mount(tester, t, initial: _available(84, second: 1));
    addTearDown(fixture.dispose);

    fixture.runningState = const AsyncData(false);
    await tester.pump();
    expect(find.text('84 ms'), findsNothing);

    fixture.runningState = const AsyncData(true);
    fixture.emit(_available(84, second: 1));
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);
    expect(find.text('84 ms'), findsNothing);

    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.checking));
    await tester.pump();
    fixture.emit(_available(88, second: 2));
    await tester.pump();
    expect(find.text('88 ms'), findsOneWidget);
  });

  testWidgets('transient service loading preserves resume updating but confirmed disconnect clears it', (tester) async {
    final fixture = await _mount(tester, t, initial: _available(84, second: 1));
    addTearDown(fixture.dispose);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);

    fixture.runningState = const AsyncLoading();
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);

    fixture.runningState = const AsyncData(false);
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsNothing);
    expect(find.text('84 ms'), findsNothing);
  });

  testWidgets('a late result after disconnect cannot return on reconnect or the next inactive state', (tester) async {
    final stale = _available(84, second: 1);
    final fixture = await _mount(tester, t, initial: stale);
    addTearDown(fixture.dispose);

    fixture.runningState = const AsyncData(false);
    await tester.pump();
    fixture.emit(stale);
    await tester.pump();
    fixture.runningState = const AsyncData(true);
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('84 ms'), findsNothing);
  });

  testWidgets('resume waiting is bounded and initial checking still uses the shimmer', (tester) async {
    final fixture = await _mount(tester, t, initial: _available(84, second: 1));
    addTearDown(fixture.dispose);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.idle));
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);

    fixture.emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.checking));
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    expect(find.text(t.common.unknown), findsOneWidget);
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(_isEnabled(tester, t.common.unknown), isTrue);

    await fixture.dispose();
    final checking = await _mount(
      tester,
      t,
      initial: const IosProxyMeasurementState(IosProxyMeasurementPhase.checking),
    );
    addTearDown(checking.dispose);
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    expect(find.text(t.pages.proxies.delay.updating), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await checking.dispose();
  });
}

bool _isEnabled(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData().flagsCollection.isEnabled ==
    ui.Tristate.isTrue;

IosProxyMeasurementState _available(int delay, {required int second}) => IosProxyMeasurementState(
  IosProxyMeasurementPhase.available,
  proxy: OutboundInfo(
    tag: 'active',
    groupSelectedTag: 'selected',
    urlTestDelay: delay,
    urlTestTime: Timestamp.fromDateTime(DateTime.utc(2026, 10, 21, 12, 0, second)),
  ),
);

Future<_Fixture> _mount(WidgetTester tester, Translations t, {required IosProxyMeasurementState initial}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  final states = StreamController<IosProxyMeasurementState>.broadcast();
  final running = StateProvider<AsyncValue<bool>>((ref) => const AsyncData(true));
  final container = ProviderContainer(
    overrides: [
      translationsProvider.overrideWith((ref) => t),
      serviceRunningProvider.overrideWith((ref) {
        final state = ref.watch(running);
        return switch (state) {
          AsyncData(:final value) => value,
          AsyncError(:final error, :final stackTrace) => Future<bool>.error(error, stackTrace),
          _ => Completer<bool>().future,
        };
      }),
      iosActiveProxyMeasurementStateProvider.overrideWith((ref) async* {
        yield initial;
        yield* states.stream;
      }),
      activeProxyNotifierProvider.overrideWith(_NoopProxy.new),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: IosActiveProxyDelayIndicator())),
    ),
  );
  await tester.pump();
  return _Fixture(tester, container, states, running);
}

class _Fixture {
  _Fixture(this.tester, this.container, this.states, this.running);

  final WidgetTester tester;
  final ProviderContainer container;
  final StreamController<IosProxyMeasurementState> states;
  final StateProvider<AsyncValue<bool>> running;
  bool _disposed = false;

  void emit(IosProxyMeasurementState state) => states.add(state);

  void emitError(Object error) => states.addError(error);

  AsyncValue<bool> get runningState => container.read(running);

  set runningState(AsyncValue<bool> state) => container.read(running.notifier).state = state;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
    await states.close();
  }
}

class _NoopProxy extends ActiveProxyNotifier {
  @override
  Stream<OutboundInfo> build() => const Stream.empty();

  @override
  Future<void> urlTest(String? tag) async {}
}
