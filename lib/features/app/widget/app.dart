import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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

    final upgrader = ref.watch(upgraderProvider);

    ref.listen(foregroundProfilesUpdateNotifierProvider, (_, __) {});

    return WindowWrapper(
      TrayWrapper(
        ShortcutWrapper(
          ConnectionWrapper(
            PlatformProvider(
                // initialPlatform: TargetPlatform.android,
                settings: PlatformSettingsData(
                  iosUsesMaterialWidgets: true,
                  // iosUseZeroPaddingForAppbarPlatformIcon: true,
                ),
                builder: (context) => DynamicColorBuilder(
                      builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
                        return PlatformApp.router(
                          routerConfig: router,

                          locale: locale.flutterLocale,
                          supportedLocales: AppLocaleUtils.supportedLocales,
                          localizationsDelegates: GlobalMaterialLocalizations.delegates,
                          debugShowCheckedModeBanner: false,
                          material: (context, platform) => MaterialAppRouterData(
                            theme: theme.lightTheme(lightColorScheme),
                            darkTheme: theme.darkTheme(darkColorScheme),
                            themeMode: themeMode.flutterThemeMode,
                          ),
                          cupertino: (context, platform) {
                            var isDark = themeMode.flutterThemeMode == ThemeMode.dark;

                            if (themeMode.flutterThemeMode == ThemeMode.system) {
                              isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
                            }

                            final defaultCupertinoTheme = CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light);
                            final defaultMaterialTheme = isDark ? theme.darkTheme(darkColorScheme) : theme.lightTheme(lightColorScheme);
                            final cupertinoTheme = defaultCupertinoTheme;
                            final a = MaterialBasedCupertinoThemeData(
                              materialTheme: defaultMaterialTheme.copyWith(
                                cupertinoOverrideTheme: CupertinoThemeData(
                                  brightness: Brightness.dark,
                                  barBackgroundColor: defaultCupertinoTheme.barBackgroundColor,
                                  scaffoldBackgroundColor: defaultCupertinoTheme.scaffoldBackgroundColor,

                                  //   textTheme: CupertinoTextThemeData(
                                  //     // primaryColor: Colors.white,
                                  //     navActionTextStyle: darkDefaultCupertinoTheme.textTheme.navActionTextStyle.copyWith(
                                  //         // color: const Color(0xF0F9F9F9),
                                  //         ),
                                  //     navLargeTitleTextStyle: darkDefaultCupertinoTheme.textTheme.navLargeTitleTextStyle.copyWith(color: const Color(0xF0F9F9F9)),
                                ),
                              ),
                              // ),
                            );
                            return CupertinoAppRouterData(theme: cupertinoTheme);
                          },
                          // themeMode: themeMode.flutterThemeMode,
                          // theme: theme.lightTheme(lightColorScheme),
                          // darkTheme: theme.darkTheme(darkColorScheme),
                          title: Constants.appName,
                          builder: (context, child) {
                            child = UpgradeAlert(
                              upgrader: upgrader,
                              navigatorKey: router.routerDelegate.navigatorKey,
                              child: child ?? const SizedBox(),
                            );
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
                    )),
          ),
        ),
      ),
    );
  }
}
