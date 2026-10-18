import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
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
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        observers: observers,
        overrides: [
          translationsProvider.overrideWith((ref) => AppLocale.en.buildSync()),
          safeDiagnosticJournalProvider.overrideWithValue(journal),
          safeDiagnosticMetadataProvider.overrideWithValue((version: '0.0.1', buildNumber: '5')),
          homePresentationSnapshotProvider.overrideWith((ref) => homePresentation),
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
