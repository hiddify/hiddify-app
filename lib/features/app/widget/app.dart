import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/font_preferences.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themePreferencesProvider);
    final locale = ref.watch(localePreferencesProvider);
    final font = ref.watch(fontPreferencesProvider);
    final appTheme = AppTheme(themeMode, font.fontFamily);

    return TranslationProvider(
      child: MaterialApp.router(
        title: 'Hiddify',
        debugShowCheckedModeBanner: false,
        theme: appTheme.lightTheme(null),
        darkTheme: appTheme.darkTheme(null),
        themeMode: themeMode.flutterThemeMode,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
          scrollbars: false,
        ),
        locale: locale.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
        builder: (context, child) {
          final data = MediaQuery.of(context);
          return MediaQuery(
            data: data.copyWith(
              textScaler: TextScaler.linear(font.scaleFactor),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
