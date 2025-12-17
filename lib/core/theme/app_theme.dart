import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hiddify/core/theme/app_colors.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/app_tokens.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  const AppTheme(this.mode, this.fontFamily);

  final AppThemeMode mode;
  final String fontFamily;

  static const _desktopNoTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.windows: _NoTransitionsBuilder(),
      TargetPlatform.linux: _NoTransitionsBuilder(),
      TargetPlatform.macOS: _NoTransitionsBuilder(),
    },
  );

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final scheme =
        lightColorScheme ??
        ColorScheme.fromSeed(seedColor: AppColors.brandColor);

    return _buildTheme(scheme);
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final scheme =
        darkColorScheme ??
        ColorScheme.fromSeed(
          seedColor: mode.trueBlack
              ? Colors.white
              : AppColors.brandColor, 
          brightness: Brightness.dark,
          dynamicSchemeVariant: mode.trueBlack
              ? DynamicSchemeVariant.monochrome
              : DynamicSchemeVariant.tonalSpot,
        );

    final scaffoldColor = mode.trueBlack
        ? Colors.black
        : const Color(0xFF0D0D0F);

    return _buildTheme(scheme, scaffoldBackgroundColor: scaffoldColor);
  }

  ThemeData _buildTheme(ColorScheme scheme, {Color? scaffoldBackgroundColor}) {
    final useGoogleFont =
        fontFamily.isEmpty ||
        fontFamily == 'Emoji' ||
        (!fontFamily.toLowerCase().contains('shabnam'));

    final effectiveFontFamily = useGoogleFont
        ? GoogleFonts.outfit().fontFamily
        : fontFamily;

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: effectiveFontFamily,
      pageTransitionsTheme: _desktopNoTransitions,
      extensions: <ThemeExtension<dynamic>>{
        if (scheme.brightness == Brightness.dark)
          ConnectionButtonTheme.dark
        else
          ConnectionButtonTheme.light,
        AppTokens.fromScheme(
          scheme,
          trueBlack: mode.trueBlack,
          scaffoldBackgroundColor: scaffoldBackgroundColor,
        ),
        JsonEditorTheme.standard,
      },
    );

    var textTheme = baseTheme.textTheme;
    if (useGoogleFont) {
      textTheme = GoogleFonts.outfitTextTheme(textTheme);
    } else {
      textTheme = textTheme.apply(fontFamily: fontFamily);
    }

    return baseTheme.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBackgroundColor ?? scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
