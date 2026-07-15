import 'package:flutter/services.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';

abstract final class AppThemePolicy {
  static const appThemeMode = AppThemeMode.dark;
  static final themeMode = appThemeMode.flutterThemeMode;
  static const showAppearancePicker = false;

  static SystemUiOverlayStyle systemUiOverlayStyle(Color background) => SystemUiOverlayStyle(
    statusBarColor: background,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
