import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme_policy.dart';

void main() {
  test('ships Woman in Red as dark-only without an appearance picker', () {
    expect(AppThemePolicy.themeMode, ThemeMode.dark);
    expect(AppThemePolicy.showAppearancePicker, isFalse);
  });

  test('uses the iOS dark status-bar appearance contract', () {
    const background = Color(0xFF010203);
    final style = AppThemePolicy.systemUiOverlayStyle(background);

    expect(style.statusBarColor, background);
    expect(style.statusBarBrightness, Brightness.dark);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarColor, background);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });
}
