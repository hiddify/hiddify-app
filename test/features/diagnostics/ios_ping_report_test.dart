import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostics_page.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trace helpers preserve operation identity without preferences', () {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWith((ref) => throw StateError('must not read preferences'))],
    );
    addTearDown(container.dispose);
    final operation = container.read(
      Provider((ref) {
        final id = beginIosPingOperation(ref, IosPingEvent.coreResumeQueued);
        recordIosPingEvent(ref, IosPingEvent.coreResumeStarted, operationId: id);
        return id;
      }),
    );
    final events = container.read(iosPingTraceProvider).snapshot.events;
    expect(operation, greaterThan(0));
    expect(events.map((entry) => entry.event), [IosPingEvent.coreResumeQueued, IosPingEvent.coreResumeStarted]);
    expect(events.map((entry) => entry.operationId), [operation, operation]);
  });

  test('trace provider failure cannot affect the operation being observed', () {
    final container = ProviderContainer(
      overrides: [iosPingTraceProvider.overrideWith((ref) => throw StateError('private canary'))],
    );
    addTearDown(container.dispose);
    expect(
      () => container.read(
        Provider((ref) {
          expect(beginIosPingOperation(ref, IosPingEvent.coreResumeQueued), 0);
          recordIosPingEvent(ref, IosPingEvent.coreResumeFailed);
        }),
      ),
      returnsNormally,
    );
  });

  test('safe report exports the bounded trace and validates it on restore', () {
    final trace = IosPingTrace();
    addTearDown(trace.dispose);
    trace.record(IosPingEvent.coreResumeQueued, operationId: trace.nextOperationId());
    final journal = _journal();
    addTearDown(journal.dispose);
    final document = jsonDecode(journal.exportJson(iosPing: trace.snapshot)) as Map<String, dynamic>;
    expect(document['ios_ping'], trace.snapshot.toJson());
    final restored = SafeDiagnosticJournal(restored: jsonEncode(document));
    addTearDown(restored.dispose);
    expect(restored.events, hasLength(1));

    final raw = Map<String, dynamic>.from(document);
    raw['ios_ping'] = {...trace.snapshot.toJson(), 'private_url': 'vless://canary.invalid?token=private-canary'};
    final rejected = SafeDiagnosticJournal(restored: jsonEncode(raw));
    addTearDown(rejected.dispose);
    expect(rejected.events, isEmpty);
  });

  test('valid incoming trace does not discard existing journal events', () {
    final journal = _journal();
    final trace = IosPingTrace()..record(IosPingEvent.refreshCoreNotReady);
    addTearDown(journal.dispose);
    addTearDown(trace.dispose);
    final document = jsonDecode(journal.exportJson()) as Map<String, dynamic>;
    document['ios_ping'] = trace.snapshot.toJson();
    final restored = SafeDiagnosticJournal(restored: jsonEncode(document));
    addTearDown(restored.dispose);
    expect(restored.events, hasLength(1));
  });

  testWidgets('preview and copied report include live trace without initializing measurement', (tester) async {
    final journal = _journal();
    final trace = IosPingTrace()..record(IosPingEvent.coreResumeQueued, operationId: 1);
    addTearDown(journal.dispose);
    addTearDown(trace.dispose);
    final observer = _Reads();
    String? copied;
    await tester.pumpWidget(
      ProviderScope(
        observers: [observer],
        overrides: [
          translationsProvider.overrideWith((ref) => AppLocale.en.buildSync()),
          safeDiagnosticJournalProvider.overrideWithValue(journal),
          safeDiagnosticMetadataProvider.overrideWithValue((version: '0.0.1', buildNumber: '15')),
          iosPingTraceProvider.overrideWithValue(trace),
        ],
        child: MaterialApp(home: SafeDiagnosticsPage(copyText: (value) async => copied = value)),
      ),
    );
    await tester.pump();
    trace.record(IosPingEvent.coreResumeStarted, operationId: 1);
    await tester.pump();
    await tester.pump();
    final preview = tester.widget<SelectableText>(find.byKey(const Key('safe-diagnostics-preview'))).data!;
    final document = jsonDecode(preview) as Map<String, dynamic>;
    expect(document['ios_ping'], trace.snapshot.toJson());
    await tester.tap(find.byKey(const Key('safe-diagnostics-copy')));
    await tester.pump();
    expect(copied, preview);
    expect(observer.providers, isNot(contains(iosActiveProxyMeasurementProvider)));
    expect(observer.providers, isNot(contains(hiddifyCoreServiceProvider)));
    expect(observer.providers, isNot(contains(connectionNotifierProvider)));
    expect(observer.providers, isNot(contains(proxyRepositoryProvider)));
    expect(observer.providers, isNot(contains(sharedPreferencesProvider)));
    await tester.tap(find.byKey(const Key('safe-diagnostics-clear')));
    await tester.pump();
    await tester.pump();
    expect(trace.snapshot.events, isEmpty, reason: 'Clear report must also clear the visible ping trace.');
    expect(journal.events, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

SafeDiagnosticJournal _journal() {
  final journal = SafeDiagnosticJournal();
  journal.record(
    operation: DiagnosticOperation.connect,
    stage: DiagnosticStage.accepted,
    code: DiagnosticCode.started,
    operationId: 1,
  );
  return journal;
}

class _Reads extends ProviderObserver {
  final providers = <ProviderBase<Object?>>[];

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value, ProviderContainer container) {
    providers.add(provider);
  }
}
