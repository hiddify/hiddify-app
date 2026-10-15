import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists and restores the safe journal through one dedicated preference key', () async {
    SharedPreferences.setMockInitialValues({'unrelated': 'keep-me'});
    final preferences = await SharedPreferences.getInstance();
    final first = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWith((ref) => preferences)]);

    final journal = first.read(safeDiagnosticJournalProvider);
    journal.record(
      operation: DiagnosticOperation.connect,
      stage: DiagnosticStage.requested,
      code: DiagnosticCode.none,
      operationId: journal.nextOperationId(),
    );
    await journal.flush();

    expect(preferences.getString('unrelated'), 'keep-me');
    expect(preferences.getKeys(), {'unrelated', safeDiagnosticJournalPreferencesKey});
    final persisted = preferences.getString(safeDiagnosticJournalPreferencesKey);
    expect(persisted, isNotNull);
    first.dispose();

    final second = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWith((ref) => preferences)]);
    addTearDown(second.dispose);
    expect(second.read(safeDiagnosticJournalProvider).events, hasLength(1));
    expect(preferences.getString(safeDiagnosticJournalPreferencesKey), persisted);
  });

  test('ignores a stored value with the wrong type', () async {
    SharedPreferences.setMockInitialValues({safeDiagnosticJournalPreferencesKey: 7});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWith((ref) => preferences)]);
    addTearDown(container.dispose);

    expect(container.read(safeDiagnosticJournalProvider).events, isEmpty);
  });
}
