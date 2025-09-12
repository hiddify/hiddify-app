import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_migration.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/singbox/service/singbox_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
// sentry_riverpod_observer is re-exported from utils.dart; explicit import not needed
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

Future<void> lazyBootstrap(
  WidgetsBinding widgetsBinding,
  Environment env,
) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError = Logger.logPlatformDispatcherError;

  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWithValue(env),
    ],
  );

  // Mount the app ASAP to avoid initial freeze; continue boot in background.
  runApp(
    ProviderScope(
      observers: [SentryRiverpodObserver()],
      parent: container,
      child: SentryUserInteractionWidget(
        child: const App(),
      ),
    ),
  );

  await _init(
    "directories",
    () => container.read(appDirectoriesProvider.future),
  );
  LoggerController.init(container.read(logPathResolverProvider).appFile().path);

  // Initialize locale and translations EARLY with enhanced loading
  // Initialize locale and translations deterministically to avoid UI flicker
  await _init(
    "locale preferences",
    () async {
      final locale = container.read(localePreferencesProvider);
      Logger.bootstrap.debug("Setting up locale: ${locale.name}");

      // Build EN fallback once to ensure immediate strings
      AppLocale.en.buildSync();

      // Prime translations cache for selected locale; async will refresh provider
      try {
        container.read(translationsProvider);
        container.invalidate(translationsProvider);
        container.read(translationsProvider);
        Logger.bootstrap.debug("Translations primed for ${locale.name}");
      } catch (e) {
        Logger.bootstrap.warning("Translation prime failed: $e");
      }
    },
  );

  final appInfo = await _init(
    "app info",
    () => container.read(appInfoProvider.future),
  );
  await _init(
    "preferences",
    () => container.read(sharedPreferencesProvider.future),
  );

  final enableAnalytics = await container.read(analyticsControllerProvider.future);
  if (enableAnalytics) {
    await _init(
      "analytics",
      () => container.read(analyticsControllerProvider.notifier).enableAnalytics(),
    );
  }

  await _init(
    "preferences migration",
    () async {
      try {
        await PreferencesMigration(
          sharedPreferences: container.read(sharedPreferencesProvider).requireValue,
        ).migrate();
      } catch (e, stackTrace) {
        Logger.bootstrap.error("preferences migration failed", e, stackTrace);
        if (env == Environment.dev) rethrow;
        Logger.bootstrap.info("clearing preferences");
        await container.read(sharedPreferencesProvider).requireValue.clear();
      }
    },
  );

  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  if (PlatformUtils.isDesktop) {
    await _init(
      "window controller",
      () => container.read(windowNotifierProvider.future),
    );

    final silentStart = container.read(Preferences.silentStart);
    Logger.bootstrap.debug("silent start [${silentStart ? "Enabled" : "Disabled"}]");

    try {
      await container.read(windowNotifierProvider.notifier).open(focus: !silentStart);
      Logger.bootstrap.debug("Main window opened");
    } catch (e, st) {
      Logger.bootstrap.error("Window open failed", e, st);
      try {
        if (PlatformUtils.isDesktop) {
          await windowManager.waitUntilReadyToShow();
          await windowManager.show();
          await windowManager.focus();
        }
      } catch (fallbackError) {
        Logger.bootstrap.error("Fallback window show also failed", fallbackError);
      }
    }
    await _init(
      "auto start service",
      () => container.read(autoStartNotifierProvider.future),
    );
  }
  await _init(
    "logs repository",
    () => container.read(logRepositoryProvider.future),
  );
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  await _init(
    "profile repository",
    () => container.read(profileRepositoryProvider.future),
  );

  await _safeInit(
    "active profile",
    () => container.read(activeProfileProvider.future),
    timeout: 1000,
  );
  await _safeInit(
    "deep link service",
    () => container.read(deepLinkNotifierProvider.future),
    timeout: 1000,
  );
  await _init(
    "sing-box",
    () => container.read(singboxServiceProvider).init(),
  );
  if (PlatformUtils.isDesktop) {
    await _safeInit(
      "system tray",
      () => container.read(systemTrayNotifierProvider.future),
      timeout: 10000, // 10 seconds timeout for all platforms
    );
  }

  if (Platform.isAndroid) {
    await _safeInit(
      "android display mode",
      () async {
        await FlutterDisplayMode.setHighRefreshRate();
      },
    );
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  FlutterNativeSplash.remove();
}

Future<T> _init<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null ? initializer().timeout(Duration(milliseconds: timeout)) : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    return result;
  } catch (error, stackTrace) {
    Logger.bootstrap.error("error initializing [$name]", error, stackTrace);
    rethrow;
  }
}

Future<T?> _safeInit<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (error, stackTrace) {
    if (error is TimeoutException) {
      Logger.bootstrap.warning("timeout initializing [$name]", error);
    } else {
      Logger.bootstrap.error("error initializing [$name]", error, stackTrace);
    }
    return null;
  }
}
