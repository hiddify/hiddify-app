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
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t = AppLocale.en.buildSync();

  testWidgets('manual refresh exposes pending, sanitized error, and retry feedback', (tester) async {
    final firstAttempt = Completer<void>();
    final proxy = _PendingProxy(firstAttempt);
    final measurementStates = StreamController<IosProxyMeasurementState>.broadcast();
    addTearDown(measurementStates.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translationsProvider.overrideWith((ref) => t),
          serviceRunningProvider.overrideWith((ref) => true),
          iosActiveProxyMeasurementStateProvider.overrideWith((ref) async* {
            yield const IosProxyMeasurementState(IosProxyMeasurementPhase.idle);
            yield* measurementStates.stream;
          }),
          activeProxyNotifierProvider.overrideWith(() => proxy),
        ],
        child: const MaterialApp(home: Scaffold(body: IosActiveProxyDelayIndicator())),
      ),
    );
    await tester.pump();

    expect(find.text(t.common.unknown), findsOneWidget);
    expect(find.byType(ShimmerSkeleton), findsNothing);

    proxy.failFirstAttempt = true;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(proxy.calls, 1);
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    expect(find.text(t.pages.proxies.delay.testing), findsNothing);

    final pendingSemantics = tester.getSemantics(find.bySemanticsLabel(t.pages.proxies.delay.testing));
    final pendingFlags = pendingSemantics.getSemanticsData().flagsCollection;
    expect(pendingFlags.isButton, isTrue);
    expect(pendingFlags.isEnabled, ui.Tristate.isFalse);
    expect(pendingSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap), isFalse);

    firstAttempt.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(find.text(t.errors.unexpected), findsOneWidget);
    expect(find.text('private raw detail'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel(t.errors.unexpected)).getSemanticsData().flagsCollection.isEnabled,
      ui.Tristate.isTrue,
    );

    measurementStates.add(
      IosProxyMeasurementState(IosProxyMeasurementPhase.available, proxy: OutboundInfo(urlTestDelay: 84)),
    );
    await tester.pump();
    expect(find.text('84 ms'), findsOneWidget);
    expect(find.text(t.errors.unexpected), findsNothing);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(proxy.calls, 2);
    expect(find.text(t.errors.unexpected), findsNothing);
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(find.text('84 ms'), findsOneWidget);

    await tester.pump(const Duration(microseconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('pending refresh cannot update an unmounted indicator', (tester) async {
    final gate = Completer<void>();
    final proxy = _PendingProxy(gate)..failFirstAttempt = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translationsProvider.overrideWith((ref) => t),
          serviceRunningProvider.overrideWith((ref) => true),
          iosActiveProxyMeasurementStateProvider.overrideWith(
            (ref) => Stream.value(const IosProxyMeasurementState(IosProxyMeasurementPhase.idle)),
          ),
          activeProxyNotifierProvider.overrideWith(() => proxy),
        ],
        child: const MaterialApp(home: Scaffold(body: IosActiveProxyDelayIndicator())),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    await tester.pump(const Duration(microseconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _PendingProxy extends ActiveProxyNotifier {
  _PendingProxy(this.firstAttempt);

  final Completer<void> firstAttempt;
  int calls = 0;
  bool failFirstAttempt = false;

  @override
  Stream<OutboundInfo> build() => Stream.value(OutboundInfo());

  @override
  Future<void> urlTest(String? tag) async {
    calls++;
    if (calls == 1) {
      await firstAttempt.future;
      if (failFirstAttempt) throw StateError('private raw detail');
    }
  }
}
