import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/cat/cat_ears_border.dart';
import 'package:hiddify/core/theme/cat/cat_peek_border.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/theme/cat/paw_slider_thumb_shape.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/gen/fonts.gen.dart';

/// Which cat the app is dressed as.
enum CatBreed {
  /// Light theme: a ginger tabby on cream.
  ginger,

  /// Dark theme: a grey cat with amber eyes on a night-purple page.
  night,

  /// True black theme: a black cat with glowing lime eyes.
  black;

  CatTheme get cat => switch (this) {
    ginger => CatTheme.ginger,
    night => CatTheme.night,
    black => CatTheme.black,
  };

  Brightness get brightness => this == ginger ? Brightness.light : Brightness.dark;

  ColorScheme get colorScheme => switch (this) {
    ginger =>
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFE8833A),
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      ).copyWith(
        primary: const Color(0xFFB85A16),
        tertiary: const Color(0xFFB4456A),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFFD9E2),
        onTertiaryContainer: const Color(0xFF3E001D),
      ),
    night => _nightScheme,
    black => _nightScheme.copyWith(
      primary: const Color(0xFFD4EF59),
      onPrimary: const Color(0xFF2B3400),
      primaryContainer: const Color(0xFF404C09),
      onPrimaryContainer: const Color(0xFFDBEA97),
      inversePrimary: const Color(0xFF586400),
      surface: Colors.black,
      surfaceDim: Colors.black,
      surfaceBright: const Color(0xFF26242B),
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0A090D),
      surfaceContainer: const Color(0xFF110F15),
      surfaceContainerHigh: const Color(0xFF19171E),
      surfaceContainerHighest: const Color(0xFF232027),
    ),
  };

  static ColorScheme get _nightScheme =>
      ColorScheme.fromSeed(seedColor: const Color(0xFF5E4B8B), brightness: Brightness.dark).copyWith(
        primary: const Color(0xFFE9C16C),
        onPrimary: const Color(0xFF402D00),
        primaryContainer: const Color(0xFF5C4300),
        onPrimaryContainer: const Color(0xFFFFDF9F),
        inversePrimary: const Color(0xFF795900),
        tertiary: const Color(0xFFFFB2BF),
        onTertiary: const Color(0xFF561D2B),
        tertiaryContainer: const Color(0xFF713341),
        onTertiaryContainer: const Color(0xFFFFD9DE),
      );
}

/// Builds the whole Material theme for a [CatBreed]: the palette, the rounded
/// font, and cat ears on buttons, cards, sheets, menus, tooltips and the
/// navigation indicator, a cat peeking over every dialog, paw thumbs on
/// sliders and switches.
ThemeData buildCatTheme(CatBreed breed, {required String fontFamily, List<String>? fontFamilyFallback}) {
  final ColorScheme scheme = breed.colorScheme;
  final CatTheme cat = breed.cat;
  final Color innerEar = cat.innerEar.withValues(alpha: breed == CatBreed.ginger ? .85 : .7);
  final bool roundFont = fontFamily == FontFamily.nunito;

  final ThemeData base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: fontFamily.isEmpty ? null : fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    scaffoldBackgroundColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>{ConnectionButtonTheme.light, cat},
    filledButtonTheme: FilledButtonThemeData(style: ButtonStyle(shape: catEarsForButtons(innerEar))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle(shape: catEarsForButtons(innerEar))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(shape: catEarsForButtons(innerEar))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: CatEarsBorder(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        earHeight: 11,
        earWidth: 16,
        earSpread: .12,
        innerEarColor: innerEar,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorShape: CatEarsBorder(earHeight: 8, earWidth: 12, earSpread: .15, innerEarColor: innerEar),
      indicatorColor: scheme.primaryContainer,
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorShape: CatEarsBorder(earHeight: 8, earWidth: 12, earSpread: .15, innerEarColor: innerEar),
      indicatorColor: scheme.primaryContainer,
    ),
    cardTheme: CardThemeData(
      shape: CatEarsBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        earHeight: 7,
        earWidth: 11,
        earInset: 24,
        innerEarColor: innerEar,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: CatPeekBorder(
        lineColor: scheme.onSurfaceVariant.withValues(alpha: .55),
        innerEarColor: cat.innerEar,
        irisColor: cat.iris,
        pupilColor: cat.pupil,
        blushColor: cat.blush,
      ),
    ),
    // the sheets' content sits on a plain Material, so the ears take the same color
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      modalBackgroundColor: scheme.surface,
      shape: CatEarsBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        earHeight: 20,
        earWidth: 30,
        earInset: 60,
        earTilt: .1,
        innerEarColor: innerEar,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: CatEarsBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        earHeight: 8,
        earWidth: 12,
        earInset: 20,
        innerEarColor: innerEar,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          CatEarsBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            earHeight: 8,
            earWidth: 12,
            earInset: 20,
            innerEarColor: innerEar,
          ),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: scheme.inverseSurface,
        shape: const CatEarsBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          earHeight: 5,
          earWidth: 8,
          earInset: 10,
        ),
      ),
      textStyle: TextStyle(color: scheme.onInverseSurface, fontFamily: fontFamily.isEmpty ? null : fontFamily),
    ),
    snackBarTheme: const SnackBarThemeData(
      shape: CatEarsBorder(borderRadius: BorderRadius.all(Radius.circular(12)), earHeight: 7, earInset: 20),
    ),
    chipTheme: const ChipThemeData(
      shape: CatEarsBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        earHeight: 4.5,
        earWidth: 7,
        earSpread: .1,
      ),
    ),
    sliderTheme: SliderThemeData(thumbShape: PawSliderThumbShape(pawColor: scheme.onPrimary)),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? const Icon(Icons.pets_rounded) : null,
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: scheme.primary),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(scheme.primary.withValues(alpha: .45)),
      radius: const Radius.circular(8),
    ),
  );

  if (!roundFont) return base;
  // the rounded font looks its best a little heavier than Material's defaults
  final TextTheme text = base.textTheme;
  return base.copyWith(
    textTheme: text.copyWith(
      displayLarge: text.displayLarge?.copyWith(fontWeight: FontWeight.w800),
      displayMedium: text.displayMedium?.copyWith(fontWeight: FontWeight.w800),
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      labelSmall: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall: text.bodySmall?.copyWith(fontWeight: FontWeight.w500),
    ),
  );
}

/// Ears for a button, per state: up and alert on press, a little twitch on
/// hover or focus, droopy when the button is disabled.
WidgetStateProperty<OutlinedBorder?> catEarsForButtons(Color innerEar) => WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.disabled)) {
    return CatEarsBorder(earHeight: 5.5, earTilt: .55, innerEarColor: innerEar.withValues(alpha: innerEar.a * .4));
  }
  if (states.contains(WidgetState.pressed)) {
    return CatEarsBorder(earHeight: 11, earTilt: -.1, innerEarColor: innerEar);
  }
  if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
    return CatEarsBorder(earHeight: 9.5, earTilt: .18, innerEarColor: innerEar);
  }
  return CatEarsBorder(earHeight: 8, innerEarColor: innerEar);
});
