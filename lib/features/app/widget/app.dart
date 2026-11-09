import 'dart:async';

import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/app_based_routing/overview/app_based_routing_notifier.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/connection/widget/connection_wrapper.dart';
import 'package:hiddify/features/crash_report/notifier/crash_report_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/shortcut/shortcut_wrapper.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/widget/window_wrapper.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upgrader/upgrader.dart';

bool _debugAccessibility = false;
bool isOnPauseCalled = false;

class App extends HookConsumerWidget with WidgetsBindingObserver, PresLogger {
  const App({super.key});

  void onPause(WidgetRef ref) {
    if (PlatformUtils.isDesktop) return;
    isOnPauseCalled = true;
    ref.read(hiddifyCoreServiceProvider).closeFront();
  }

  void onResume(WidgetRef ref) {
    // if (PlatformUtils.isDesktop) return;
    ref.read(hiddifyCoreServiceProvider).init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isOnPauseCalled && PlatformUtils.isAndroid) ref.invalidate(appBasedRoutingProvider);
      isOnPauseCalled = false;
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    setupStateListener(ref);
    final router = ref.watch(goRouterNotiferProvider);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);
    final theme = AppTheme(themeMode, locale.preferredFontFamily);
    final upgrader = ref.watch(upgraderProvider);
    final reduceAnimations = ref.watch(Preferences.reduceAnimations);
    final activeBreakpoint = Breakpoint(context).activeBreakpoint;

    ref.listen(foregroundProfilesUpdateNotifierProvider, (_, _) {});
    if (PlatformUtils.isAndroid) ref.listen(appBasedRoutingProvider, (_, _) {});
    if (PlatformUtils.isDesktop) ref.listen(systemTrayNotifierProvider, (_, _) {});

    // a crash in the previous run is offered for sending once the first frame is up
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(crashReportNotifierProvider.notifier).checkOnStart();
      });
      // outside a store, a new release is offered once a day, a while after the start
      final updateCheck = Timer(const Duration(seconds: 20), () async {
        final release = await ref.read(appUpdateNotifierProvider.notifier).checkOnStart();
        if (release == null) return;
        await ref
            .read(dialogNotifierProvider.notifier)
            .showNewVersion(
              currentVersion: ref.read(appInfoProvider).requireValue.presentVersion,
              newVersion: release,
              canIgnore: true,
            );
      });
      return updateCheck.cancel;
    }, const []);

    // updating ActiveBreakpointNotifier value
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeBreakpointNotifierProvider.notifier).update(activeBreakpoint);
      });
      return null;
    }, [activeBreakpoint]);
    // Animations stop while the app cannot be seen: they kept a CPU core busy
    // and drained laptop batteries with the window in the background. Hidden
    // and paused already stop the frames, but on Wayland a minimized window is
    // only inactive (GTK is not told it was minimized), as is a window without
    // focus, so on desktop inactive stops them too. On a phone inactive is a
    // moment under the notification shade or a system dialog, still on screen.
    final animate = switch (useAppLifecycleState()) {
      null || AppLifecycleState.resumed => true,
      AppLifecycleState.inactive => !PlatformUtils.isDesktop,
      AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached => false,
    };
    return TickerMode(
      enabled: animate,
      child: WindowWrapper(
        ShortcutWrapper(
          ConnectionWrapper(
            DynamicColorBuilder(
              builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
                return MaterialApp.router(
                  routerConfig: router,
                  scaffoldMessengerKey: appScaffoldMessengerKey,
                  locale: locale.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode.flutterThemeMode,
                  theme: theme.lightTheme(lightColorScheme),
                  darkTheme: theme.darkTheme(darkColorScheme),
                  title: Constants.appName,
                  builder: (context, child) {
                    final theme = Theme.of(context);
                    // the setting adds to the system's reduce motion, which the animations here follow
                    if (reduceAnimations) {
                      child = MediaQuery(
                        data: MediaQuery.of(context).copyWith(disableAnimations: true),
                        child: child ?? const SizedBox(),
                      );
                    }
                    child = SnackBarHost(
                      child: upgrader == null
                          ? child ?? const SizedBox()
                          : UpgradeAlert(
                              upgrader: upgrader,
                              navigatorKey: router.routerDelegate.navigatorKey,
                              child: child ?? const SizedBox(),
                            ),
                    );
                    if (kDebugMode && _debugAccessibility) {
                      return AccessibilityTools(checkFontOverflows: true, child: child);
                    }
                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      // Icons only: the bars are transparent and the page draws behind them.
                      value: SystemUiOverlayStyle(
                        statusBarIconBrightness: theme.brightness == Brightness.dark
                            ? Brightness.light
                            : Brightness.dark,
                        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
                            ? Brightness.light
                            : Brightness.dark,
                      ),
                      child: child,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build1(BuildContext context, WidgetRef ref) {
  //   setupStateListener(ref);
  //   // setupQuickSettings(ref);
  //   final router = ref.watch(routerProvider);
  //   final locale = ref.watch(localePreferencesProvider);
  //   final themeMode = ref.watch(themePreferencesProvider);
  //   final theme = AppTheme(themeMode, locale.preferredFontFamily);
  //   final upgrader = ref.watch(upgraderProvider);

  //   ref.listen(foregroundProfilesUpdateNotifierProvider, (_, __) {});

  //   return WindowWrapper(
  //     TrayWrapper(
  //       ShortcutWrapper(
  //         ConnectionWrapper(
  //           PlatformProvider(
  //               settings: PlatformSettingsData(
  //                 iosUsesMaterialWidgets: true,
  //               ),
  //               builder: (context) => DynamicColorBuilder(
  //                     builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
  //                       return PlatformApp.router(
  //                         routerConfig: router,
  //                         locale: locale.flutterLocale,
  //                         supportedLocales: AppLocaleUtils.supportedLocales,
  //                         localizationsDelegates: GlobalMaterialLocalizations.delegates,
  //                         debugShowCheckedModeBanner: false,
  //                         material: (context, platform) => MaterialAppRouterData(
  //                           theme: theme.lightTheme(lightColorScheme),
  //                           darkTheme: theme.darkTheme(darkColorScheme),
  //                           themeMode: themeMode.flutterThemeMode,
  //                         ),
  //                         cupertino: (context, platform) {
  //                           final sysDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

  //                           return CupertinoAppRouterData(theme: theme.cupertinoThemeData(sysDark, lightColorScheme, darkColorScheme));
  //                         },
  //                         title: Constants.appName,
  //                         builder: (context, child) {
  //                           child = UpgradeAlert(
  //                             upgrader: upgrader,
  //                             navigatorKey: router.routerDelegate.navigatorKey,
  //                             child: child ?? const SizedBox(),
  //                           );
  //                           if (kDebugMode && _debugAccessibility) {
  //                             return AccessibilityTools(
  //                               checkFontOverflows: true,
  //                               child: child,
  //                             );
  //                           }
  //                           return child;
  //                         },
  //                       );
  //                     },
  //                   )),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void setupStateListener(WidgetRef ref) {
    useEffect(() {
      // The engine calls the listener directly, so a pause is seen even when no frame is drawn in the
      // background. Inactive (a dialog, the notification shade) is not a pause and closes nothing.
      // On desktop a window losing focus is inactive too, so coming back from inactive alone sets
      // nothing up again: doing it on every focus change reconnected to the core, reloaded what
      // watches it, and made the home page blink.
      var away = true;
      void handle(AppLifecycleState state) {
        loggy.info("app state: $state");
        if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) away = true;
        if (state == AppLifecycleState.paused) onPause(ref);
        if (state == AppLifecycleState.resumed && away) {
          away = false;
          onResume(ref);
        }
      }

      final initial = WidgetsBinding.instance.lifecycleState;
      if (initial != null) handle(initial);
      final listener = AppLifecycleListener(onStateChange: handle);
      return listener.dispose;
    }, const []);
  }
}
