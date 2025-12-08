import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> lazyBootstrap(
  WidgetsBinding widgetsBinding,
  Environment env,
) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError =
      Logger.logPlatformDispatcherError;

  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(
    overrides: [environmentProvider.overrideWith((ref) => env)],
  );

  await _init(
    "directories",
    () => container.read(appDirectoriesProvider.future),
  );
  
  final dirs = container.read(appDirectoriesProvider).requireValue;
  LoggerController.init(File("${dirs.baseDir.path}/app.log").path);

  final appInfo = await _init(
    "app info",
    () => container.read(appInfoProvider.future),
  );
  await _init(
    "preferences",
    () => container.read(sharedPreferencesProvider.future),
  );

  await _init("locale preload", () async {
    final locale = container.read(localePreferencesProvider);
    try {
      await locale.build();
      Logger.bootstrap.debug("preloaded locale: ${locale.name}");
    } catch (e, stackTrace) {
      Logger.bootstrap.error(
        "failed to preload locale [${locale.name}]",
        e,
        stackTrace,
      );
    }
  });

  final debug = kDebugMode;
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  if (Platform.isAndroid) {
    await _safeInit("android display mode", () async {
      await FlutterDisplayMode.setHighRefreshRate();
    });
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  runApp(UncontrolledProviderScope(container: container, child: const App()));

  FlutterNativeSplash.remove();
}

Future<T> _init<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null
      ? initializer().timeout(Duration(milliseconds: timeout))
      : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug(
      "[$name] initialized in ${stopWatch.elapsedMilliseconds}ms",
    );
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[$name] error initializing", e, stackTrace);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _safeInit<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null
      ? initializer().timeout(Duration(milliseconds: timeout))
      : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug(
      "[$name] initialized in ${stopWatch.elapsedMilliseconds}ms",
    );
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.warning(
      "[$name] initialization skipped (non-critical)",
      e,
      stackTrace,
    );
    return null;
  } finally {
    stopWatch.stop();
  }
}
