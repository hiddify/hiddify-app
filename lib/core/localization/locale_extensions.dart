import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/gen/translations.g.dart';

extension AppLocaleX on AppLocale {
  String get preferredFontFamily =>
      this == AppLocale.fa ? FontFamily.shabnam : (kIsWeb || !Platform.isWindows ? "" : FontFamily.emoji);

  String get localeName => switch (flutterLocale.toString()) {
    "ar" => "العربية",
    "en" => "English",
    "es" => "Spanish",
    "fa" => "فارسی",
    "fr" => "Français",
    "id" => "Indonesian",
    "ko" => "한국어",
    "nl" => "Nederlands",
    "pt_BR" => "Portuguese (Brazil)",
    "ru" => "Русский",
    "tk" => "Türkmençe",
    "tr" => "Türkçe",
    "zh" || "zh_CN" => "中文 (中国)",
    "zh_TW" => "中文 (台湾)",
    "be" => "Беларуская",
    "am" => "አማርኛ",
    "ur" => "اردو",
    "ps" => "پښتو",
    "bn" => "বাংলা",
    "uz" => "Oʻzbekcha",
    "az" => "Azərbaycan dili",
    "kk" => "Қазақша",
    "my" => "မြန်မာဘာသာ",
    "ky" => "Кыргызча",
    "tg" => "Тоҷикӣ",
    "hy" => "Հայերեն",
    "uk" => "Українська",
    "hi" => "हिन्दी",
    "de" => "Deutsch",
    "it" => "Italiano",
    _ => "Unknown",
  };

  /// The country whose flag stands for the language in the language picker: for a language spoken
  /// in several countries, the one it comes from or is most spoken in. Persian has Iran's, which
  /// [IPCountryFlag] draws with the lion and sun.
  String get flagCountryCode => switch (flutterLocale.toString()) {
    "ar" => "sa",
    "en" => "gb",
    "es" => "es",
    "fa" => "ir",
    "fr" => "fr",
    "id" => "id",
    "pt_BR" => "br",
    "ru" => "ru",
    "tr" => "tr",
    "zh" || "zh_CN" => "cn",
    "zh_TW" => "tw",
    "am" => "et",
    "az" => "az",
    "be" => "by",
    "bn" => "bd",
    "de" => "de",
    "hi" => "in",
    "hy" => "am",
    "it" => "it",
    "kk" => "kz",
    "ko" => "kr",
    "ky" => "kg",
    "my" => "mm",
    "nl" => "nl",
    "ps" => "af",
    "tg" => "tj",
    "tk" => "tm",
    "uk" => "ua",
    "ur" => "pk",
    "uz" => "uz",
    _ => "",
  };
}
