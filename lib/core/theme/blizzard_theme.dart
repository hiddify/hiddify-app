import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';

// The verified visual candidate is enabled by default; explicit false preserves the legacy skin.
const blizzardVisuals = bool.fromEnvironment('BLIZZARD_VISUALS', defaultValue: true);

@immutable
class BlizzardEligibility extends ThemeExtension<BlizzardEligibility> {
  const BlizzardEligibility({required this.mode, this.applied = false});
  final AppThemeMode mode;
  final bool applied;
  bool get permitsDark => mode == AppThemeMode.dark || mode == AppThemeMode.system;

  @override
  BlizzardEligibility copyWith({AppThemeMode? mode, bool? applied}) =>
      BlizzardEligibility(mode: mode ?? this.mode, applied: applied ?? this.applied);

  @override
  BlizzardEligibility lerp(covariant BlizzardEligibility? other, double t) => other == null || t < 0.5 ? this : other;
}

/// Creates only local presentation data; never changes the global theme factory.
abstract final class BlizzardTheme {
  static ThemeData from(ThemeData base, {bool highContrast = false}) {
    final material = BlizzardMaterials(highContrast: highContrast);
    final persian = base.textTheme.bodyLarge?.fontFamily == 'Shabnam';
    final textFont = persian ? 'Shabnam' : '.SF Pro Text';
    final displayFont = persian ? 'Shabnam' : '.SF Pro Display';
    TextStyle role(double size, {FontWeight weight = FontWeight.w400, bool display = false}) => TextStyle(
      inherit: false,
      textBaseline: TextBaseline.alphabetic,
      fontFamily: display ? displayFont : textFont,
      fontSize: size,
      fontWeight: weight,
      height: display ? 1.25 : 1.3,
      color: BlizzardPalette.primary,
    );
    final text = base.textTheme
        .apply(fontFamily: textFont, bodyColor: BlizzardPalette.primary, displayColor: BlizzardPalette.primary)
        .copyWith(
          headlineLarge: role(34, display: true),
          headlineMedium: role(28, display: true),
          headlineSmall: role(22, weight: FontWeight.w600, display: true),
          titleLarge: role(22, weight: FontWeight.w600, display: true),
          titleMedium: role(17, weight: FontWeight.w600),
          titleSmall: role(15, weight: FontWeight.w500),
          bodyLarge: role(17),
          bodyMedium: role(17),
          bodySmall: role(14),
          labelLarge: role(14, weight: FontWeight.w500),
          labelMedium: role(14, weight: FontWeight.w500),
          labelSmall: role(12),
        );
    final scheme = base.colorScheme.copyWith(
      primary: BlizzardPalette.accent,
      onPrimary: BlizzardPalette.background,
      primaryContainer: BlizzardPalette.selected,
      onPrimaryContainer: BlizzardPalette.primary,
      secondary: BlizzardPalette.accent,
      onSecondary: BlizzardPalette.background,
      secondaryContainer: BlizzardPalette.selected,
      onSecondaryContainer: BlizzardPalette.primary,
      tertiary: BlizzardPalette.secondary,
      onTertiary: BlizzardPalette.background,
      surface: material.content,
      onSurface: BlizzardPalette.primary,
      onSurfaceVariant: BlizzardPalette.secondary,
      surfaceContainerLowest: BlizzardPalette.background,
      surfaceContainerLow: material.content,
      surfaceContainer: material.content,
      surfaceContainerHigh: material.control,
      surfaceContainerHighest: material.control,
      surfaceTint: Colors.transparent,
      error: BlizzardPalette.error,
      onError: BlizzardPalette.background,
      errorContainer: material.control,
      onErrorContainer: BlizzardPalette.error,
      outline: material.edge,
      outlineVariant: BlizzardPalette.separator,
      inverseSurface: BlizzardPalette.primary,
      onInverseSurface: BlizzardPalette.background,
      inversePrimary: BlizzardPalette.selected,
      shadow: BlizzardPalette.shadow,
      scrim: BlizzardPalette.scrim,
    );
    RoundedRectangleBorder shape(double radius) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
      shape: WidgetStatePropertyAll(shape(BlizzardRadii.row)),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
    );
    return base.copyWith(
      colorScheme: scheme,
      canvasColor: material.content,
      cardColor: material.content,
      primaryColor: BlizzardPalette.accent,
      scaffoldBackgroundColor: BlizzardPalette.background,
      textTheme: text,
      primaryTextTheme: text,
      disabledColor: BlizzardPalette.disabled,
      dividerColor: BlizzardPalette.separator,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [
        ...base.extensions.values.where((extension) => extension is! BlizzardEligibility),
        if (base.extension<BlizzardEligibility>() case final eligibility?) eligibility.copyWith(applied: true),
      ],
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: BlizzardPalette.background,
        foregroundColor: BlizzardPalette.primary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: material.content,
        surfaceTintColor: Colors.transparent,
        shape: shape(BlizzardRadii.card),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        textColor: BlizzardPalette.primary,
        iconColor: BlizzardPalette.secondary,
        tileColor: material.content,
        selectedTileColor: BlizzardPalette.selected,
        selectedColor: BlizzardPalette.primary,
        minVerticalPadding: 12,
        minTileHeight: 44,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(color: BlizzardPalette.secondary),
        shape: shape(BlizzardRadii.row),
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
      elevatedButtonTheme: ElevatedButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button.copyWith(side: WidgetStatePropertyAll(BorderSide(color: material.edge))),
      ),
      textButtonTheme: TextButtonThemeData(style: button),
      iconButtonTheme: IconButtonThemeData(style: button),
      searchBarTheme: base.searchBarTheme.copyWith(backgroundColor: WidgetStatePropertyAll(material.control)),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: material.content,
        labelStyle: text.bodyMedium?.copyWith(color: BlizzardPalette.secondary),
        hintStyle: text.bodyMedium?.copyWith(color: BlizzardPalette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BlizzardRadii.field),
          borderSide: BorderSide(color: material.edge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BlizzardRadii.field),
          borderSide: BorderSide(color: material.edge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BlizzardRadii.field),
          borderSide: const BorderSide(color: BlizzardPalette.accent, width: 2),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: material.content,
        surfaceTintColor: Colors.transparent,
        shape: shape(BlizzardRadii.dialog),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: material.content,
        modalBackgroundColor: material.content,
        surfaceTintColor: Colors.transparent,
        shape: shape(BlizzardRadii.sheet),
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: material.control,
        surfaceTintColor: Colors.transparent,
        shape: shape(BlizzardRadii.row),
        textStyle: text.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(material.control),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(shape(BlizzardRadii.row)),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: BlizzardMetrics.dockHeight,
        backgroundColor: material.control,
        surfaceTintColor: Colors.transparent,
        indicatorColor: BlizzardPalette.selected,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
    );
  }

  /// Flutter resolves monospace to the platform system fixed-width font.
  /// On iOS this requests the system fallback rather than bundling SF Mono.
  static TextStyle codeStyle(ThemeData theme) =>
      TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4, color: theme.colorScheme.onSurface);
}
