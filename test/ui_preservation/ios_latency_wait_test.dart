import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../support/connection_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t = AppLocale.en.buildSync();

  Future<_RetryProxy> mount(
    WidgetTester tester, {
    IosProxyMeasurementState snapshot = const IosProxyMeasurementState(IosProxyMeasurementPhase.idle),
    IosActiveProxyMeasurement? measurement,
    bool running = true,
  }) async {
    final proxy = _RetryProxy(measurement);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translationsProvider.overrideWith((ref) => t),
          serviceRunningProvider.overrideWith((ref) => running),
          connectionNotifierProvider.overrideWith(
            () => ButtonConnectionSpy(AsyncData(running ? const Connected() : const Disconnected()), []),
          ),
          activeProxyNotifierProvider.overrideWith(() => proxy),
          iosActiveProxyMeasurementEnabledProvider.overrideWithValue(true),
          iosActiveProxyMeasurementStateProvider.overrideWith((ref) {
            if (measurement != null) {
              ref.onDispose(measurement.dispose);
              return measurement.states;
            }
            return Stream.value(snapshot);
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(body: Column(children: [ActiveProxyDelayIndicator(), ActiveProxyFooter()])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return proxy;
  }

  testWidgets('iOS unknown latency cannot display an unbounded active measurement', (tester) async {
    await mount(tester);
    await tester.pump(const Duration(seconds: 16));
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(find.text(t.common.unknown), findsOneWidget);
    expect(find.byType(IPCountryFlag), findsNothing);
    expect(find.text(t.pages.proxies.unknownIp), findsNothing);
  });

  testWidgets('checking shows shimmer and hides a footer without a real outbound', (tester) async {
    await mount(tester, snapshot: const IosProxyMeasurementState(IosProxyMeasurementPhase.checking));
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    expect(find.byType(IPCountryFlag), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);
    await tester.pump(const Duration(microseconds: 1));
  });

  for (final ip in ['192.0.2.1', '']) {
    testWidgets(
      'available latency renders real name/type and ${ip.isEmpty ? 'independent unknown IP' : 'synthetic IP'}',
      (tester) async {
        await mount(
          tester,
          snapshot: IosProxyMeasurementState(
            IosProxyMeasurementPhase.available,
            proxy: OutboundInfo(
              tag: 'synthetic-active',
              tagDisplay: 'Synthetic active',
              type: 'vless',
              urlTestDelay: 84,
              ipinfo: IpInfo(ip: ip),
            ),
          ),
        );
        expect(find.text('84 ms'), findsOneWidget);
        expect(find.text('Synthetic active'), findsOneWidget);
        expect(find.text('vless'), findsOneWidget);
        expect(find.byType(ShimmerSkeleton), findsNothing);
        if (ip.isEmpty) {
          expect(find.byType(IPText), findsNothing);
          expect(find.text(t.pages.proxies.unknownIp), findsOneWidget);
        } else {
          expect(tester.widget<IPText>(find.byType(IPText)).ip, ip);
          expect(find.byType(UnknownIPText), findsNothing);
        }
      },
    );
  }

  for (final phase in [
    IosProxyMeasurementPhase.timedOut,
    IosProxyMeasurementPhase.failed,
    IosProxyMeasurementPhase.unavailable,
  ]) {
    testWidgets('$phase stops shimmer and retry invokes the existing measurement action', (tester) async {
      final proxy = await mount(tester, snapshot: IosProxyMeasurementState(phase));
      expect(find.byType(ShimmerSkeleton), findsNothing);
      expect(
        find.text(phase == IosProxyMeasurementPhase.timedOut ? t.common.timeout : t.common.unknown),
        findsOneWidget,
      );
      expect(find.byType(IPCountryFlag), findsNothing);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(proxy.tags, ['']);
    });
  }

  testWidgets('real unanswered measurement reaches timeout at 15 seconds and retry starts another attempt', (
    tester,
  ) async {
    final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
    addTearDown(events.close);
    var requests = 0;
    final measurement = IosActiveProxyMeasurement(
      watch: () => events.stream,
      request: () async {
        requests++;
      },
    );
    await mount(tester, measurement: measurement);
    unawaited(measurement.refresh().catchError((Object _) {}));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    expect(requests, 1);
    await tester.pump(const Duration(seconds: 14));
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(find.text(t.common.timeout), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(requests, 2);
    await tester.pump();
    await tester.pump();
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    await tester.pump(const Duration(microseconds: 1));
    // Dispose while the retry is active to also exercise cancellation cleanup.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('disconnected iOS hides latency and footer even when a measurement is checking', (tester) async {
    await mount(tester, running: false, snapshot: const IosProxyMeasurementState(IosProxyMeasurementPhase.checking));
    expect(find.byType(ShimmerSkeleton), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(find.byType(IPCountryFlag), findsNothing);
    expect(find.text(t.common.unknown), findsNothing);
  });
}

// Only spies on the widget action; provider tests cover the real notifier.
class _RetryProxy extends FixtureProxy {
  _RetryProxy(this.measurement) : super(0);
  final IosActiveProxyMeasurement? measurement;
  final tags = <String>[];

  @override
  Future<void> urlTest(String? tag) async {
    tags.add(tag ?? '');
    await measurement?.refresh();
  }
}
