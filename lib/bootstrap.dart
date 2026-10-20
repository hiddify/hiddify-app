import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_migration.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/startup/ios_startup_gate.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';

import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/riverpod_observer.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> lazyBootstrap(WidgetsBinding widgetsBinding, Environment env) async {
  if (PlatformUtils.isIOS) {
    return bootstrapIos(widgetsBinding, env);
  }
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }
  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError = Logger.logPlatformDispatcherError;

  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(overrides: [environmentProvider.overrideWithValue(env)]);

  await _init("directories", () => container.read(appDirectoriesProvider.future));
  LoggerController.init(container.read(logPathResolverProvider).appFile().path);

  final appInfo = await _init("app info", () => container.read(appInfoProvider.future));
  await _init("preferences", () => container.read(sharedPreferencesProvider.future));

  final enableAnalytics = await container.read(analyticsControllerProvider.future);
  if (enableAnalytics) {
    await _init("analytics", () => container.read(analyticsControllerProvider.notifier).enableAnalytics());
  }

  await _init("preferences migration", () async {
    try {
      await PreferencesMigration(sharedPreferences: container.read(sharedPreferencesProvider).requireValue).migrate();
    } catch (e, stackTrace) {
      Logger.bootstrap.error("preferences migration failed", e, stackTrace);
      if (env == Environment.dev) rethrow;
      Logger.bootstrap.info("clearing preferences");
      await container.read(sharedPreferencesProvider).requireValue.clear();
    }
  });

  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  if (PlatformUtils.isDesktop) {
    await _init("window controller", () => container.read(windowNotifierProvider.future));

    final silentStart = container.read(Preferences.silentStart);
    Logger.bootstrap.debug("silent start [${silentStart ? "Enabled" : "Disabled"}]");
    if (!silentStart) {
      await container.read(windowNotifierProvider.notifier).show(focus: false);
    } else {
      Logger.bootstrap.debug("silent start, remain hidden accessible via tray");
    }
    await _init("auto start service", () => container.read(autoStartNotifierProvider.future));
  }
  await _init("logs repository", () => container.read(logRepositoryProvider.future));
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  await _init("profile repository", () => container.read(profileRepositoryProvider.future));

  await _init("translations", () => container.read(translationsProvider.future));

  await _safeInit("active profile", () => container.read(activeProfileProvider.future), timeout: 1000);
  await _init("hiddify-core", () => container.read(hiddifyCoreServiceProvider).init());

  if (!kIsWeb) {
    // await _safeInit(
    //   "deep link service",
    //   () => container.read(deepLinkNotifierProvider.future),
    //   timeout: 1000,
    // );

    if (PlatformUtils.isDesktop) {
      await _safeInit("system tray", () => container.read(systemTrayNotifierProvider.future), timeout: 1000);
    }

    if (PlatformUtils.isAndroid) {
      await _safeInit("android display mode", () async {
        await FlutterDisplayMode.setHighRefreshRate();
      });
    }
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  runApp(
    ProviderScope(
      parent: container,
      observers: [RiverpodObserver()],
      child: SentryUserInteractionWidget(child: const App()),
    ),
  );

  if (!kIsWeb) {
    FlutterNativeSplash.remove();
  }
  // SentryFlutter.s(DateTime.now().toUtc());
}

Future<T> _init<T>(String name, Future<T> Function() initializer, {int? timeout}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null ? initializer().timeout(Duration(milliseconds: timeout)) : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[$name] error initializing", e, stackTrace);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _safeInit<T>(String name, Future<T> Function() initializer, {int? timeout}) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (e) {
    return null;
  }
}

/// iOS mounts recovery UI before initializing any application dependency.
Future<void> bootstrapIos(
  WidgetsBinding widgetsBinding,
  Environment env, {
  IosStartupGate? startupGate,
  Future<Directories> Function()? initializeDirectories,
  ProviderContainer Function()? containerFactory,
  VoidCallback? removeSplash,
}) async {
  final gate = startupGate ?? IosStartupGate();
  if (removeSplash == null) FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(IosStartupShell(gate: gate, locale: widgetsBinding.platformDispatcher.locale));
  widgetsBinding.addPostFrameCallback((_) {
    (removeSplash ?? FlutterNativeSplash.remove)();
  });

  try {
    // Keep one container alive even if a native operation outlives its watchdog.
    final container =
        containerFactory?.call() ??
        ProviderContainer(overrides: [environmentProvider.overrideWithValue(env)], observers: [RiverpodObserver()]);
    await gate.runStage(IosStartupStage.preparing, () async {
      LoggerController.preInit();
      FlutterError.onError = Logger.logFlutterError;
      widgetsBinding.platformDispatcher.onError = Logger.logPlatformDispatcherError;
    });
    await gate.runStage(
      IosStartupStage.directories,
      initializeDirectories ?? () => container.read(appDirectoriesProvider.future),
    );
    await gate.runStage(IosStartupStage.logger, () async {
      LoggerController.init(container.read(logPathResolverProvider).appFile().path);
    });
    final appInfo = await gate.runStage(IosStartupStage.appInfo, () => container.read(appInfoProvider.future));
    await gate.runStage(IosStartupStage.preferences, () => container.read(sharedPreferencesProvider.future));
    final enableAnalytics = await gate.runStage(
      IosStartupStage.analyticsPreferences,
      () => container.read(analyticsControllerProvider.future),
    );
    if (enableAnalytics) {
      await gate.runStage(
        IosStartupStage.analytics,
        () => container.read(analyticsControllerProvider.notifier).enableAnalytics(),
      );
    }
    await gate.runStage(
      IosStartupStage.preferencesMigration,
      () => migrateIosBootstrapPreferences(container.read(sharedPreferencesProvider).requireValue),
    );
    await gate.runStage(IosStartupStage.logsRepository, () => container.read(logRepositoryProvider.future));
    await gate.runStage(IosStartupStage.loggerController, () async {
      final debug = container.read(debugModeNotifierProvider) || kDebugMode;
      await LoggerController.postInit(debug);
      Logger.bootstrap.info(appInfo.format());
    });
    await gate.runStage(IosStartupStage.profileRepository, () => container.read(profileRepositoryProvider.future));
    await gate.runStage(IosStartupStage.translations, () => container.read(translationsProvider.future));
    await gate.runStage(IosStartupStage.activeProfile, () => container.read(activeProfileProvider.future));
    await gate.runStage(
      IosStartupStage.core,
      () => container.read(hiddifyCoreServiceProvider).init(requireSuccess: true),
    );
    gate.complete();
    if (gate.state != IosStartupState.ready) return;
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: SentryUserInteractionWidget(child: const App()),
      ),
    );
  } on Object {
    // Classification is closed; the recovery report never includes error text.
    gate.fail();
  }
}

Future<void> migrateIosBootstrapPreferences(SharedPreferences preferences, {Future<void> Function()? migrate}) async {
  await (migrate ?? PreferencesMigration(sharedPreferences: preferences).migrate)();
}
