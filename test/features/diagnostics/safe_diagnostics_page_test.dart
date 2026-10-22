import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/analytics/telemetry_delivery_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/home_presentation_providers.dart';
import 'package:hiddify/features/diagnostics/home_presentation_snapshot.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostics_page.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/log/overview/logs_overview_notifier.dart';
import 'package:hiddify/features/log/overview/logs_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _DeliveryAnalytics extends AnalyticsController {
  _DeliveryAnalytics({
    TelemetryDeliveryStatus status = const TelemetryDeliveryStatus.disabled(),
    this.outcome = TelemetryTestOutcome.disabled,
  }) {
    monitor.update(status);
  }

  final monitor = TelemetryDeliveryMonitor();
  TelemetryDeliveryStatus get status => monitor.status;
  set status(TelemetryDeliveryStatus value) => monitor.update(value);
  final TelemetryTestOutcome outcome;

  @override
  Future<bool> build() async {
    return false;
  }

  @override
  Future<TelemetryTestResult> sendTestEvent() async => TelemetryTestResult(outcome: outcome);
}

class _RawLogReadObserver extends ProviderObserver {
  final rawProvidersRead = <ProviderBase<Object?>>[];

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value, ProviderContainer container) {
    if (provider == logsOverviewNotifierProvider ||
        provider == debugModeNotifierProvider ||
        provider == logPathResolverProvider) {
      rawProvidersRead.add(provider);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SafeDiagnosticJournal journalWithEvent({Future<void> Function(String)? persist}) {
    final journal = SafeDiagnosticJournal(persist: persist);
    journal.record(
      operation: DiagnosticOperation.connect,
      stage: DiagnosticStage.accepted,
      code: DiagnosticCode.started,
      operationId: journal.nextOperationId(),
      durationMs: 17,
    );
    return journal;
  }

  Future<void> pumpPage(
    WidgetTester tester,
    SafeDiagnosticJournal journal, {
    Future<void> Function(String)? copyText,
    Widget? child,
    List<ProviderObserver> observers = const [],
    double textScale = 1,
    HomePresentationSnapshot? homePresentation,
    _DeliveryAnalytics? analytics,
  }) async {
    final deliveryAnalytics = analytics ?? _DeliveryAnalytics();
    addTearDown(deliveryAnalytics.monitor.dispose);
    await tester.pumpWidget(
      ProviderScope(
        observers: observers,
        overrides: [
          translationsProvider.overrideWith((ref) => AppLocale.en.buildSync()),
          safeDiagnosticJournalProvider.overrideWithValue(journal),
          safeDiagnosticMetadataProvider.overrideWithValue((version: '0.0.1', buildNumber: '5')),
          homePresentationSnapshotProvider.overrideWith((ref) => homePresentation),
          analyticsControllerProvider.overrideWith(() => deliveryAnalytics),
          telemetryDeliveryMonitorProvider.overrideWithValue(deliveryAnalytics.monitor),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: child ?? SafeDiagnosticsPage(copyText: copyText),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('copies the exact JSON shown in the report preview', (tester) async {
    final journal = journalWithEvent();
    addTearDown(journal.dispose);
    String? copied;
    await pumpPage(
      tester,
      journal,
      copyText: (value) async => copied = value,
      homePresentation: const HomePresentationSnapshot(
        asyncVariant: HomeAsyncVariant.loading,
        connectionValue: HomeConnectionValue.connected,
        labelChoice: HomeLabelChoice.empty,
        themePlatform: HomeThemePlatform.android,
        runtimeIos: true,
        reconnect: HomeReconnectValue.unknown,
        latencyBand: HomeLatencyBand.nonPositive,
        tickersEnabled: true,
        lifecycleState: HomeLifecycleState.resumed,
      ),
    );

    final preview = tester.widget<SelectableText>(find.byKey(const Key('safe-diagnostics-preview'))).data!;
    await tester.tap(find.byKey(const Key('safe-diagnostics-copy')));
    await tester.pump();

    expect(copied, preview);
    expect(jsonDecode(preview), {
      'schema': 'blizzard-safe-diagnostics/v1',
      'platform': 'ios',
      'reachability': 'not_checked',
      'version': '0.0.1',
      'build_number': '5',
      'home_presentation': {
        'async_variant': 'loading',
        'connection_value': 'connected',
        'label_choice': 'empty',
        'theme_platform': 'android',
        'runtime_ios': true,
        'reconnect': 'unknown',
        'latency_band': 'non_positive',
        'tickers_enabled': true,
        'lifecycle_state': 'resumed',
      },
      'ios_ping': {'schema': 'wir-ios-ping-trace/v1', 'events': []},
      'telemetry_delivery': {
        'schema': 'blizzard-telemetry-delivery/v1',
        'state': 'disabled',
        'pending_count': 0,
        'oldest_pending_age_seconds': null,
        'budget_used_bytes': 0,
        'budget_remaining_bytes': 0,
        'next_attempt_at': null,
        'last_attempt_at': null,
        'last_http_code': null,
        'last_test_outcome': null,
      },
      'events': [
        {
          'sequence': 1,
          'operation_id': 1,
          'operation': 'connect',
          'stage': 'accepted',
          'code': 'started',
          'duration_ms': 17,
          'reachability': 'not_checked',
        },
      ],
    });
    expect(find.text('Safe report copied'), findsOneWidget);
  });

  testWidgets('omits Home presentation before the first Home snapshot', (tester) async {
    final journal = journalWithEvent();
    addTearDown(journal.dispose);
    await pumpPage(tester, journal);

    final preview = tester.widget<SelectableText>(find.byKey(const Key('safe-diagnostics-preview'))).data!;
    expect(jsonDecode(preview), isNot(contains('home_presentation')));
  });

  testWidgets('clear persists an empty report and shows the empty state', (tester) async {
    final persisted = <String>[];
    final journal = journalWithEvent(persist: (value) async => persisted.add(value));
    addTearDown(journal.dispose);
    await journal.flush();
    await pumpPage(tester, journal);

    await tester.tap(find.byKey(const Key('safe-diagnostics-clear')));
    await tester.pump();
    await journal.flush();

    expect(find.text('No diagnostic events yet.'), findsOneWidget);
    final preview = tester.widget<SelectableText>(find.byKey(const Key('safe-diagnostics-preview'))).data!;
    expect((jsonDecode(preview) as Map<String, dynamic>)['events'], isEmpty);
    expect((jsonDecode(persisted.last) as Map<String, dynamic>)['events'], isEmpty);
  });

  testWidgets('copy failure is generic and does not expose the thrown value', (tester) async {
    const canary = 'private-copy-error-canary';
    final journal = journalWithEvent();
    addTearDown(journal.dispose);
    await pumpPage(tester, journal, copyText: (_) async => throw StateError(canary));

    await tester.tap(find.byKey(const Key('safe-diagnostics-copy')));
    await tester.pump();

    expect(find.text('Could not copy the safe report'), findsOneWidget);
    expect(find.textContaining(canary), findsNothing);
  });

  testWidgets('storage failure is generic and does not expose the thrown value', (tester) async {
    const canary = 'private-storage-error-canary';
    final journal = journalWithEvent(persist: (_) async => throw StateError(canary));
    addTearDown(journal.dispose);
    await journal.flush();
    await pumpPage(tester, journal);

    expect(find.text('The safe report could not be saved on this device'), findsOneWidget);
    expect(find.textContaining(canary), findsNothing);
  });

  testWidgets('empty journal renders an explicit empty state', (tester) async {
    final journal = SafeDiagnosticJournal();
    addTearDown(journal.dispose);
    await pumpPage(tester, journal);

    expect(find.text('No diagnostic events yet.'), findsOneWidget);
  });

  testWidgets('shows local remote-delivery status even before any diagnostic events', (tester) async {
    final journal = SafeDiagnosticJournal();
    addTearDown(journal.dispose);
    await pumpPage(tester, journal);

    expect(find.text('Remote delivery'), findsOneWidget);
    expect(find.byKey(const Key('telemetry-delivery-status')), findsOneWidget);
  });

  testWidgets('distinguishes the daily limit from local storage failures without cloud access', (tester) async {
    final journal = journalWithEvent();
    addTearDown(journal.dispose);
    final analytics = _DeliveryAnalytics(
      status: const TelemetryDeliveryStatus(
        state: TelemetryDeliveryState.budgetLimited,
        pendingCount: 2,
        budgetUsedBytes: 65536,
      ),
    );
    await pumpPage(tester, journal, analytics: analytics);
    await tester.pump();
    expect(find.text('Daily limit reached'), findsOneWidget);
    final preview = tester.widget<SelectableText>(find.byKey(const Key('safe-diagnostics-preview'))).data!;
    final document = jsonDecode(preview) as Map<String, Object?>;
    final delivery = Map<String, Object?>.from(document['telemetry_delivery']! as Map);
    expect(delivery['state'], 'budgetLimited');

    analytics.status = const TelemetryDeliveryStatus(state: TelemetryDeliveryState.outboxStorageFailed);
    await tester.pump();
    await tester.pump();
    expect(find.text('Local storage unavailable'), findsOneWidget);
    expect(find.text('Daily limit reached'), findsNothing);
  });

  testWidgets('test button reports ingest acceptance only from its completed result', (tester) async {
    final journal = journalWithEvent();
    addTearDown(journal.dispose);
    await pumpPage(tester, journal, analytics: _DeliveryAnalytics(outcome: TelemetryTestOutcome.accepted));
    await tester.tap(find.byKey(const Key('safe-diagnostics-send-test')));
    await tester.pump();
    expect(find.text('Ingest server accepted the test event'), findsOneWidget);
    expect(find.textContaining('queued for delivery'), findsNothing);
  });

  testWidgets('test button preserves pending result without claiming acceptance', (tester) async {
    final journal = journalWithEvent();
    addTearDown(journal.dispose);
    final analytics = _DeliveryAnalytics(outcome: TelemetryTestOutcome.pending);
    await pumpPage(tester, journal, analytics: analytics);
    await tester.tap(find.byKey(const Key('safe-diagnostics-send-test')));
    await tester.pump();
    expect(find.text('Saved locally; waiting to send'), findsOneWidget);
    expect(find.text('Ingest server accepted the test event'), findsNothing);

    analytics.status = const TelemetryDeliveryStatus(
      state: TelemetryDeliveryState.accepted,
      lastTestOutcome: TelemetryTestOutcome.accepted,
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Saved locally; waiting to send'), findsNothing);
    expect(find.text('Ingest server accepted the test event'), findsOneWidget);
  });

  testWidgets('copy and clear remain immediately reachable for a full report with large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final journal = SafeDiagnosticJournal();
    addTearDown(journal.dispose);
    for (var index = 0; index < SafeDiagnosticJournal.maxCapacity; index++) {
      journal.record(
        operation: DiagnosticOperation.connect,
        stage: DiagnosticStage.accepted,
        code: DiagnosticCode.started,
        operationId: journal.nextOperationId(),
      );
    }

    await pumpPage(tester, journal, textScale: 1.8);

    expect(find.byKey(const Key('safe-diagnostics-copy')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('safe-diagnostics-clear')).hitTestable(), findsOneWidget);
  });

  testWidgets('iOS Logs page returns the safe report before raw log providers are read', (tester) async {
    final journal = SafeDiagnosticJournal();
    final observer = _RawLogReadObserver();
    addTearDown(journal.dispose);
    await pumpPage(tester, journal, child: const LogsPage(isIos: true), observers: [observer]);

    expect(find.text('Safe diagnostics'), findsOneWidget);
    expect(find.byKey(const Key('safe-diagnostics-preview')), findsOneWidget);
    expect(observer.rawProvidersRead, isEmpty);
  });
}
