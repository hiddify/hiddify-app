import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/features.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

Future<void> lazyBootstrap(
  WidgetsBinding widgetsBinding,
  Environment env,
) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggerController.preInit();
  ErrorHandler.init();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError =
      Logger.logPlatformDispatcherError;

  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(
    overrides: [environmentProvider.overrideWith((ref) => env)],
  );

  await _init(
    'preferences',
    () => container.read(sharedPreferencesProvider.future),
  );

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(900, 700),
      minimumSize: Size(400, 600),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      final prefs = container.read(sharedPreferencesProvider).requireValue;
      final silentStart = prefs.getBool('silent_start') ?? false;
      if (!silentStart) {
        await windowManager.show();
        await windowManager.focus();
      }
    });
  }

  await _init(
    'directories',
    () => container.read(appDirectoriesProvider.future),
  );

  if (Platform.isAndroid || Platform.isIOS) {
    await _safeInit('core setup', () async {
      await const MethodChannel('com.hiddify.app/method').invokeMethod('setup');
    });
  }

  final logDir = await container.read(logServiceProvider).getLogDirectory();
  LoggerController.init(File('$logDir/app.log').path);

  final appInfo = await _init(
    'app info',
    () => container.read(appInfoProvider.future),
  );

  await _init('locale preload', () async {
    final locale = container.read(localePreferencesProvider);
    try {
      await locale.build();
      Logger.bootstrap.debug('preloaded locale: ${locale.name}');
    } catch (e, stackTrace) {
      Logger.bootstrap.error(
        'failed to preload locale [${locale.name}]',
        e,
        stackTrace,
      );
    }
  });

  const debug = kDebugMode;
  await _init(
    'logger controller',
    () => LoggerController.postInit(debugMode: debug),
  );

  Logger.bootstrap.info(appInfo.format());

  if (Platform.isAndroid) {
    await _safeInit('android display mode', () async {
      await FlutterDisplayMode.setHighRefreshRate();
    });
  }

  await _safeInit('geo assets', () async {
    final geoService = container.read(geoAssetServiceProvider);
    await geoService.ensureAssetsExist();
  });

  await _safeInit('resource manager', () async {
    final resourceManager = container.read(resourceManagerProvider);
    await resourceManager.initialize();
  });

  await _safeInit('process manager', () async {
    final processManager = container.read(processManagerProvider);
    await processManager.initialize();
  });

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await _safeInit('tray service', () async {
      await container.read(trayServiceProvider.future);
    });
  }

  Logger.bootstrap.info('bootstrap took [${stopWatch.elapsedMilliseconds}ms]');
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
  Logger.bootstrap.info('initializing [$name]');
  Future<T> func() => timeout != null
      ? initializer().timeout(Duration(milliseconds: timeout))
      : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug(
      '[$name] initialized in ${stopWatch.elapsedMilliseconds}ms',
    );
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error('[$name] error initializing', e, stackTrace);
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
  Logger.bootstrap.info('initializing [$name]');
  Future<T> func() => timeout != null
      ? initializer().timeout(Duration(milliseconds: timeout))
      : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug(
      '[$name] initialized in ${stopWatch.elapsedMilliseconds}ms',
    );
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.warning(
      '[$name] initialization skipped (non-critical)',
      e,
      stackTrace,
    );
    return null;
  } finally {
    stopWatch.stop();
  }
}
