import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/features/home/widget/orca/glass_kit.dart';

/// Dark "liquid glass" theme used for every page except the home screen's own
/// painted widgets. Pages get a transparent scaffold (the aurora background is
/// painted once behind the whole app, see `app.dart`), translucent bordered
/// cards, and neon accents.
///
/// The system's dynamic color scheme is ignored on purpose: the look depends on
/// a fixed palette. Light mode and "true black" keep Hiddify's original themes.
ThemeData orcaGlassTheme(String fontFamily) {
  const navy = Color(0xFF0A0F3A);
  final border = Colors.white.withValues(alpha: 0.12);

  final scheme = ColorScheme.fromSeed(
    seedColor: OrcaColors.blue,
    brightness: Brightness.dark,
  ).copyWith(
    primary: OrcaColors.cyan,
    onPrimary: OrcaColors.bgTop,
    secondary: OrcaColors.violet,
    tertiary: OrcaColors.pink,
    surface: OrcaColors.bgMid,
    onSurface: OrcaColors.textPrimary,
    onSurfaceVariant: OrcaColors.textSecondary,
    primaryContainer: OrcaColors.blue.withValues(alpha: 0.30),
    onPrimaryContainer: OrcaColors.textPrimary,
    secondaryContainer: OrcaColors.violet.withValues(alpha: 0.30),
    onSecondaryContainer: OrcaColors.textPrimary,
    surfaceContainerHighest: Colors.white.withValues(alpha: 0.08),
    outline: Colors.white.withValues(alpha: 0.25),
    outlineVariant: Colors.white.withValues(alpha: 0.10),
  );

  OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: navy,
    dividerColor: Colors.white.withValues(alpha: 0.08),
    extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light},
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: OrcaColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      shadowColor: OrcaColors.violet.withValues(alpha: 0.4),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: OrcaColors.cyan,
      textColor: OrcaColors.textPrimary,
      subtitleTextStyle: const TextStyle(color: OrcaColors.textSecondary),
      selectedColor: OrcaColors.cyan,
      selectedTileColor: OrcaColors.blue.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: navy.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: border),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: navy.withValues(alpha: 0.97),
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: navy.withValues(alpha: 0.97),
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: border),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: navy.withValues(alpha: 0.98),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF111A5E),
      contentTextStyle: const TextStyle(color: OrcaColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: OrcaColors.violet,
      foregroundColor: Colors.white,
      elevation: 6,
      focusElevation: 6,
      hoverElevation: 8,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: OrcaColors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OrcaColors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: OrcaColors.cyan,
        side: BorderSide(color: OrcaColors.cyan.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: OrcaColors.cyan),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: inputBorder(border),
      enabledBorder: inputBorder(border),
      focusedBorder: inputBorder(OrcaColors.cyan, 1.6),
      errorBorder: inputBorder(Colors.redAccent),
      focusedErrorBorder: inputBorder(Colors.redAccent, 1.6),
      labelStyle: const TextStyle(color: OrcaColors.textSecondary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : OrcaColors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? OrcaColors.blue
            : Colors.white.withValues(alpha: 0.10),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? OrcaColors.cyan.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? OrcaColors.blue : Colors.transparent,
      ),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: OrcaColors.cyan,
      thumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: OrcaColors.cyan),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: OrcaColors.blue.withValues(alpha: 0.35),
      selectedIconTheme: const IconThemeData(color: OrcaColors.cyan),
      selectedLabelTextStyle: const TextStyle(color: OrcaColors.cyan),
    ),
  );
}
