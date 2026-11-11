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
    _ => "Unknown",
  };
}
