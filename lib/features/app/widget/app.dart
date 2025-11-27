import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/connection/widget/connection_wrapper.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/shortcut/shortcut_wrapper.dart';
import 'package:hiddify/features/system_tray/widget/system_tray_wrapper.dart';
import 'package:hiddify/features/window/widget/window_wrapper.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upgrader/upgrader.dart';

bool _debugAccessibility = false;

class App extends HookConsumerWidget with PresLogger {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);
    final theme = AppTheme(themeMode, locale.preferredFontFamily);

    ref.listen(foregroundProfilesUpdateProvider, (_, _) {});

    return WindowWrapper(
      TrayWrapper(
        ShortcutWrapper(
          ConnectionWrapper(
            DynamicColorBuilder(
              builder:
                  (
                    ColorScheme? lightColorScheme,
                    ColorScheme? darkColorScheme,
                  ) {
                    return MaterialApp.router(
                      routerConfig: router,
                      locale: locale.flutterLocale,
                      supportedLocales: AppLocaleUtils.supportedLocales,
                      localizationsDelegates:
                          GlobalMaterialLocalizations.delegates,
                      debugShowCheckedModeBanner: false,
                      themeMode: themeMode.flutterThemeMode,
                      theme: theme.lightTheme(lightColorScheme),
                      darkTheme: theme.darkTheme(darkColorScheme),
                      title: Constants.appName,
                      builder: (context, child) {
                        if (!PlatformUtils.isDesktop) {
                          final upgrader = ref.watch(upgraderProvider);
                          child = UpgradeAlert(
                            upgrader: upgrader,
                            navigatorKey: router.routerDelegate.navigatorKey,
                            child: child ?? const SizedBox(),
                          );
                        } else {
                          child = child ?? const SizedBox();
                        }
                        if (kDebugMode && _debugAccessibility) {
                          return AccessibilityTools(
                            checkFontOverflows: true,
                            child: child,
                          );
                        }
                        return child;
                      },
                    );
                  },
            ),
          ),
        ),
      ),
    );
  }
}
