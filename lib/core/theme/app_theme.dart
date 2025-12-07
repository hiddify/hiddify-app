import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
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
    final ColorScheme scheme =
        lightColorScheme ??
        ColorScheme.fromSeed(seedColor: const Color(0xFF293CA0));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      pageTransitionsTheme: _desktopNoTransitions,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light,
        JsonEditorTheme.standard,
      },
    );
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme =
        darkColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF293CA0),
          brightness: Brightness.dark,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mode.trueBlack ? Colors.black : scheme.surface,
      fontFamily: fontFamily,
      pageTransitionsTheme: _desktopNoTransitions,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.dark,
        JsonEditorTheme.standard,
      },
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
  ) {
    return child;
  }
}
