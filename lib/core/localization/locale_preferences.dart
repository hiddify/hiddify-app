import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_preferences.g.dart';

@Riverpod(keepAlive: true)
class LocalePreferences extends _$LocalePreferences {
  @override
  AppLocale build() {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    final persisted = prefsAsync.maybeWhen(
      data: (prefs) => prefs.getString("locale"),
      orElse: () => null,
    );
    if (persisted == null) return AppLocale.en;
    try {
      // Prefer exact match by both language and country if present
      final parsed = AppLocaleUtils.parse(persisted);
      return parsed;
    } catch (_) {
      try {
        return AppLocale.values.firstWhere((l) => l.languageCode == persisted);
      } catch (e) {
        return AppLocale.en;
      }
    }
  }

  Future<void> changeLocale(AppLocale value) async {
    // Persist simple language code for stability across platforms (e.g., fa)
    await ref.read(sharedPreferencesProvider).requireValue.setString("locale", value.languageCode);
    // Updating state triggers re-build of translationsProvider (it watches this provider)
    state = value;
  }
}
