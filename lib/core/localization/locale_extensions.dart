import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/gen/translations.g.dart';

extension AppLocaleX on AppLocale {
  String get preferredFontFamily => switch (this) {
    AppLocale.fa => FontFamily.shabnam,
    // scripts the cat theme's rounded font doesn't draw keep the platform's own
    AppLocale.ar || AppLocale.zhCn || AppLocale.zhTw => kIsWeb || !Platform.isWindows ? "" : FontFamily.emoji,
    _ => FontFamily.nunito,
  };

  String get localeName => switch (flutterLocale.toString()) {
    "ar" => "العربية",
    "en" => "English",
    "es" => "Spanish",
    "fa" => "فارسی",
    "fr" => "Français",
    "id" => "Indonesian",
    "pt_BR" => "Portuguese (Brazil)",
    "ru" => "Русский",
    "tr" => "Türkçe",
    "zh" || "zh_CN" => "中文 (中国)",
    "zh_TW" => "中文 (台湾)",
    _ => "Unknown",
  };
}
