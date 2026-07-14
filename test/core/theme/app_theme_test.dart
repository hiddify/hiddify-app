import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';

void main() {
  final theme = AppTheme(AppThemeMode.system, 'Shabnam').darkTheme(null);

  test('does not install future light semantics at runtime', () {
    final lightTheme = AppTheme(AppThemeMode.system, 'Shabnam').lightTheme(null);

    expect(lightTheme.extension<NovaThemeData>(), isNull);
  });

  test('builds a dark Woman in Red color scheme independent of dynamic color', () {
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, NovaColors.ritualRed);
    expect(theme.colorScheme.secondary, NovaColors.ritualRed);
    expect(theme.colorScheme.surface, NovaColors.surface);
    expect(theme.scaffoldBackgroundColor, NovaColors.voidBackground);
    expect(theme.extension<NovaThemeData>(), NovaThemeData.dark);
  });

  test('themes navigation, grouped content, controls, and overlays', () {
    expect(theme.appBarTheme.backgroundColor, NovaColors.voidBackground);
    expect(theme.cardTheme.color, NovaColors.surface);
    expect(theme.listTileTheme.selectedColor, NovaColors.ritualRed);
    expect(theme.listTileTheme.selectedTileColor, NovaThemeData.dark.accentFill);
    expect(theme.bottomSheetTheme.backgroundColor, NovaColors.elevatedSurface);
    expect(theme.dialogTheme.backgroundColor, NovaColors.elevatedSurface);
    expect(theme.inputDecorationTheme.fillColor, NovaColors.surface);
    expect(theme.progressIndicatorTheme.color, NovaColors.ritualRed);
  });
}
