import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/overview/sections/general_page.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(overrides: [rulesNotifierProvider.overrideWith(_NoRules.new)]);
    await container.read(sharedPreferencesProvider.future);
  });
  tearDown(() => container.dispose());

  Map<String, dynamic> coreOptions() => container.read(ConfigOptions.singboxConfigOptions).toJson();

  test('the download of the URL test is off by default', () {
    expect(ConfigOptions.urlTestDownloadSizes.first, 0, reason: 'the slider starts at off');
    expect(coreOptions()['url-test-download-size'], 0);
  });

  test('the size picked goes to the core in kilobytes, under the key it reads', () async {
    await container.read(ConfigOptions.urlTestDownloadSize.notifier).update(64);
    expect(coreOptions()['url-test-download-size'], 64);
  });

  test('the slider offers the recommended size, marked as such', () {
    expect(ConfigOptions.urlTestDownloadSizes, contains(ConfigOptions.urlTestDownloadRecommended));
    final t = AppLocale.en.buildSync();
    expect(urlTestDownloadSizeLabel(t, 0), 'Off');
    expect(urlTestDownloadSizeLabel(t, 32), '32 KB per test (recommended)');
    expect(urlTestDownloadSizeLabel(t, 64), '64 KB per test');
  });

  test('a size the slider does not offer is not taken, from an import either', () async {
    await container.read(ConfigOptions.urlTestDownloadSize.notifier).update(32);
    await container.read(ConfigOptions.urlTestDownloadSize.notifier).update(100000000);
    expect(container.read(ConfigOptions.urlTestDownloadSize), 32);
  });

  test('a stored size the slider does not offer reads as off', () async {
    SharedPreferences.setMockInitialValues({'url-test-download-size': 100000000});
    container.dispose();
    container = ProviderContainer(overrides: [rulesNotifierProvider.overrideWith(_NoRules.new)]);
    await container.read(sharedPreferencesProvider.future);
    expect(coreOptions()['url-test-download-size'], 0);
  });
}

class _NoRules extends RulesNotifier {
  @override
  List<Rule> build() => [];
}
