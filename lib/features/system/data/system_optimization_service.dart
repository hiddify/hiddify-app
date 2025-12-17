// ignore_for_file: unreachable_from_main
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_optimization_service.g.dart';

@Riverpod(keepAlive: true)
SystemOptimizationService systemOptimizationService(Ref ref) =>
    SystemOptimizationService();

class SystemOptimizationService {
  Future<void> requestDisableBatteryOptimization() async {
    if (Platform.isAndroid) {
      Logger.permission.info('Requesting ignore battery optimizations');
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        Logger.permission.debug('Permission not granted, requesting...');
        await Permission.ignoreBatteryOptimizations.request();
      } else {
        Logger.permission.debug('Ignore battery optimizations already granted');
      }
    }
  }

  Future<void> initBackgroundService() async {
    Logger.system.info('Initializing background service');
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'hiddify_core_service',
        initialNotificationTitle: 'Hiddify Core',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    unawaited(service.stopSelf());
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;
