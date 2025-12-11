import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class App extends HookConsumerWidget with PresLogger {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);
    final theme = AppTheme(themeMode, locale.preferredFontFamily);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) => MaterialApp.router(
          routerConfig: router,
          locale: locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          debugShowCheckedModeBanner: false,
          themeMode: themeMode.flutterThemeMode,
          theme: theme.lightTheme(lightColorScheme),
          darkTheme: theme.darkTheme(darkColorScheme),
          title: Constants.appName,
          builder: (context, child) => child ?? const SizedBox(),
        ),
    );
  }
}
