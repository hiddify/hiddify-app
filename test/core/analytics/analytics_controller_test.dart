import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('analytics is opt-in for a fresh installation', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWith((ref) => preferences)],
    );
    addTearDown(container.dispose);
    await container.read(sharedPreferencesProvider.future);

    expect(await container.read(analyticsControllerProvider.future), isFalse);
  });

  test('preserves an explicit analytics opt-in', () async {
    SharedPreferences.setMockInitialValues({enableAnalyticsPrefKey: true});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWith((ref) => preferences)],
    );
    addTearDown(container.dispose);
    await container.read(sharedPreferencesProvider.future);

    expect(await container.read(analyticsControllerProvider.future), isTrue);
  });
}
