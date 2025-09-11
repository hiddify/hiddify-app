import 'package:flutter/widgets.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Global extension to easily access translations from any BuildContext
extension TranslationsExtension on BuildContext {
  /// Get translations for the current locale
  Translations get t {
    try {
      // Try to get from provider container
      final container = ProviderScope.containerOf(this);
      return container.read(translationsProvider);
    } catch (e) {
      // Fallback to English if provider access fails
      return AppLocale.en.buildSync();
    }
  }
}

/// Global getter for accessing translations without BuildContext
Translations get t {
  return AppLocale.en.buildSync(); // Default fallback
}
