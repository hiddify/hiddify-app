import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const safeDiagnosticJournalPreferencesKey = 'blizzard_safe_diagnostics_v1';

typedef SafeDiagnosticMetadata = ({String? version, String? buildNumber});

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
