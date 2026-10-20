import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const safeDiagnosticJournalPreferencesKey = 'blizzard_safe_diagnostics_v1';

typedef SafeDiagnosticMetadata = ({String? version, String? buildNumber});

final iosPingTraceProvider = Provider<IosPingTrace>((ref) {
  final trace = IosPingTrace();
  ref.onDispose(trace.dispose);
  return trace;
});

int beginIosPingOperation(Ref ref, IosPingEvent event) {
  try {
    final trace = ref.read(iosPingTraceProvider);
    final id = trace.nextOperationId();
    trace.record(event, operationId: id);
    return id;
  } on Object {
    return 0;
  }
}

void recordIosPingEvent(Ref ref, IosPingEvent event, {int operationId = 0}) {
  try {
    ref.read(iosPingTraceProvider).record(event, operationId: operationId);
  } on Object {
    // Diagnostics must not change the operation being observed.
  }
}

final safeDiagnosticJournalProvider = Provider<SafeDiagnosticJournal>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider).requireValue;
  final journal = SafeDiagnosticJournal(
    restored: _restoredJournal(preferences),
    persist: (snapshot) async {
      final saved = await preferences.setString(safeDiagnosticJournalPreferencesKey, snapshot);
      if (!saved) throw StateError('safe diagnostic persistence failed');
    },
  );
  ref.onDispose(journal.dispose);
  return journal;
});

String? _restoredJournal(SharedPreferences preferences) {
  try {
    return preferences.getString(safeDiagnosticJournalPreferencesKey);
  } on Object {
    return null;
  }
}

final safeDiagnosticMetadataProvider = Provider<SafeDiagnosticMetadata>((ref) {
  final appInfo = ref.watch(appInfoProvider);
  return switch (appInfo) {
    AsyncData(:final value) => (version: value.version, buildNumber: value.buildNumber),
    _ => (version: null, buildNumber: null),
  };
});
