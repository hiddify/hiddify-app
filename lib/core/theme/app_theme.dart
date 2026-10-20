import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

/// SpriteNet "Deep Matte Cyberpunk" palette: matte dark planes, neon lime accents.
abstract class SpriteNetColors {
  static const canvas = Color(0xFF0F0F11);
  static const surface = Color(0xFF18181C);
  static const surfaceHigh = Color(0xFF222228);
  static const outline = Color(0xFF2E2E36);
  static const lime = Color(0xFF8DFF19);
  static const limeLight = Color(0xFFC7FF55);
  static const onLime = Color(0xFF0F0F11);
  static const alert = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFF2F2F5);
  static const textSecondary = Color(0xFF9A9AA6);
  static const idle = Color(0xFF5C6B5A);
}

/// SpriteNet has no light mode: every theme getter returns the same dark theme,
/// and dynamic (wallpaper) colors are ignored to keep the brand palette exact.
class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: SpriteNetColors.lime,
    onPrimary: SpriteNetColors.onLime,
    primaryContainer: Color(0xFF2A3D12),
    onPrimaryContainer: SpriteNetColors.limeLight,
    secondary: SpriteNetColors.lime,
    onSecondary: SpriteNetColors.onLime,
    secondaryContainer: SpriteNetColors.surfaceHigh,
    onSecondaryContainer: SpriteNetColors.textPrimary,
    tertiary: SpriteNetColors.limeLight,
    onTertiary: SpriteNetColors.onLime,
    error: SpriteNetColors.alert,
    onError: Colors.white,
    errorContainer: Color(0xFF3A1414),
    onErrorContainer: Color(0xFFFFB4B4),
    surface: SpriteNetColors.canvas,
    onSurface: SpriteNetColors.textPrimary,
    onSurfaceVariant: SpriteNetColors.textSecondary,
    surfaceDim: SpriteNetColors.canvas,
    surfaceBright: SpriteNetColors.surfaceHigh,
    surfaceContainerLowest: SpriteNetColors.canvas,
    surfaceContainerLow: Color(0xFF141417),
    surfaceContainer: SpriteNetColors.surface,
    surfaceContainerHigh: SpriteNetColors.surfaceHigh,
    surfaceContainerHighest: Color(0xFF2A2A31),
    outline: SpriteNetColors.outline,
    outlineVariant: Color(0xFF24242B),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: SpriteNetColors.textPrimary,
    onInverseSurface: SpriteNetColors.canvas,
    inversePrimary: Color(0xFF3F6B0B),
    surfaceTint: Colors.transparent,
  );

  ThemeData lightTheme(ColorScheme? lightColorScheme) => darkTheme(null);

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    const scheme = colorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: SpriteNetColors.canvas,
      canvasColor: SpriteNetColors.canvas,
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: SpriteNetColors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SpriteNetColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: SpriteNetColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: SpriteNetColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SpriteNetColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: SpriteNetColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color(0xFF2A3D12),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: SpriteNetColors.surface,
        indicatorColor: Color(0xFF2A3D12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? SpriteNetColors.onLime : SpriteNetColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? SpriteNetColors.lime : SpriteNetColors.surfaceHigh,
        ),
      ),
      dividerColor: SpriteNetColors.outline,
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.spriteNet},
    );
  }

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    const def = CupertinoThemeData(brightness: Brightness.dark);
    final defaultMaterialTheme = darkTheme(darkColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ),
          barBackgroundColor: SpriteNetColors.canvas,
          scaffoldBackgroundColor: SpriteNetColors.canvas,
        ),
      ),
    );
  }
}
