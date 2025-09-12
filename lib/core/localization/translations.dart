import 'package:flutter/foundation.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:hiddify/core/localization/translations_extension.dart';
export 'package:hiddify/gen/translations.g.dart';

part 'translations.g.dart';

// Simple cache to avoid repeated deferred loading
final Map<AppLocale, Translations> _loadedTranslations = {};

@Riverpod(keepAlive: true)
Translations translations(Ref ref) {
  final locale = ref.watch(localePreferencesProvider);

  // Return cached translation if available
  if (_loadedTranslations.containsKey(locale)) {
    return _loadedTranslations[locale]!;
  }

  // For English, always buildSync (no deferred loading)
  if (locale == AppLocale.en) {
    final translation = locale.buildSync();
    _loadedTranslations[locale] = translation;
    return translation;
  }

  // For other locales, try buildSync first with enhanced loading
  try {
    final translation = locale.buildSync();
    _loadedTranslations[locale] = translation;
    if (kDebugMode) Logger.app.debug('✅ Locale ${locale.name} loaded successfully');
    return translation;
  } catch (e) {
    if (kDebugMode) Logger.app.warning('⚠️ Locale ${locale.name} buildSync failed: $e');

    // Ensure English fallback is available while we load target locale
    if (!_loadedTranslations.containsKey(AppLocale.en)) {
      _loadedTranslations[AppLocale.en] = AppLocale.en.buildSync();
    }

    // Load target locale asynchronously, then invalidate this provider to refresh UI
    () async {
      try {
        final trans = await locale.build();
        _loadedTranslations[locale] = trans;
        if (kDebugMode) Logger.app.debug('✅ Locale ${locale.name} loaded asynchronously');
        // trigger a rebuild so UI switches from fallback EN to target locale
        ref.invalidate(translationsProvider);
      } catch (error) {
        if (kDebugMode) Logger.app.warning('❌ Failed to load locale ${locale.name} asynchronously: $error');
      }
    }();

    return _loadedTranslations[AppLocale.en]!;
  }
}
/// Clear the translations cache
void clearTranslationsCache() {
  _loadedTranslations.clear();
  if (kDebugMode) Logger.app.debug('🗑️ Translations cache cleared');
}
