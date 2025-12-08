import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_colors.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

/// The central theme definition for the application.
/// 
/// This class configures [ThemeData] for both light and dark modes, including:
/// - Material 3 ColorScheme generation from a seed color.
/// - Custom font family support.
/// - Platform-specific page transitions.
/// - Theme extensions for custom components.
class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  
  final AppThemeMode mode;
  final String fontFamily;

  // Disable default page transitions on desktop for a snappier feel
  static const _desktopNoTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.windows: _NoTransitionsBuilder(),
      TargetPlatform.linux: _NoTransitionsBuilder(),
      TargetPlatform.macOS: _NoTransitionsBuilder(),
    },
  );

  /// Generates the light theme data.
  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final ColorScheme scheme = lightColorScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.brandColor,
          brightness: Brightness.light,
        );
        
    return _buildTheme(scheme);
  }

  /// Generates the dark theme data.
  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme = darkColorScheme ??
        ColorScheme.fromSeed(
          seedColor: mode.trueBlack ? Colors.white : AppColors.brandColor, // Monochrome if black mode
          brightness: Brightness.dark,
          dynamicSchemeVariant: mode.trueBlack ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
        
    // Adjust logic for True Black mode if enabled
    final Color scaffoldColor = mode.trueBlack ? Colors.black : scheme.surface;

    return _buildTheme(scheme, scaffoldBackgroundColor: scaffoldColor);
  }

  /// Internal helper to build ThemeData consistent across modes.
  ThemeData _buildTheme(ColorScheme scheme, {Color? scaffoldBackgroundColor}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: fontFamily,
      pageTransitionsTheme: _desktopNoTransitions,
      // Apply common component sub-themes here if needed:
      // cardTheme: CardTheme(...),
      // inputDecorationTheme: InputDecorationTheme(...),
      extensions: <ThemeExtension<dynamic>>{
        scheme.brightness == Brightness.dark
            ? ConnectionButtonTheme.dark
            : ConnectionButtonTheme.light,
        JsonEditorTheme.standard,
      },
    );
  }
}

/// A PageTransitionsBuilder that provides no transition animation.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
