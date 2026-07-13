import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';

void main() {
  test('uses the Woman in Red seed color for light and dark themes', () {
    const brandRed = Color(0xFFFF2D3E);
    final theme = AppTheme(AppThemeMode.system, 'Shabnam');

    expect(theme.lightTheme(null).colorScheme.primary, ColorScheme.fromSeed(seedColor: brandRed).primary);
    expect(
      theme.darkTheme(null).colorScheme.primary,
      ColorScheme.fromSeed(seedColor: brandRed, brightness: Brightness.dark).primary,
    );
  });
}
