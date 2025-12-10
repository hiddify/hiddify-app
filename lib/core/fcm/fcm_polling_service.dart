// TEMPORARILY DISABLED: Firebase Cloud Messaging
/*
import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:hiddify/core/fcm/fcm_message.dart';
import 'package:hiddify/core/fcm/fcm_polling_config.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// Desktop polling service for platforms without native FCM support (Linux, Windows, macOS fallback).
///
/// Since Firebase Cloud Messaging is not supported on Linux and Windows, this service
/// periodically polls a server endpoint for subscription updates and emits
/// them as FcmMessage objects compatible with the existing FcmNotifier.
///
/// **Platform-specific usage:**
/// - This service is designed for Linux, Windows, and macOS (as fallback when APNs is unavailable).
/// - Do not use this service on Android or iOS as it will conflict with
///   native FCM implementations and may cause duplicate notifications.
/// - On macOS, this service is used as a fallback if FCM/APNs initialization fails.
class FcmPollingService with InfraLogger {
  FcmPollingService({
    required DioHttpClient httpClient,
    Duration? pollingInterval,
    String? endpointUrl,
  })  : _httpClient = httpClient,
        _pollingInterval = pollingInterval ?? FcmPollingConfig.defaultInterval,
        _endpointUrl = endpointUrl ?? FcmPollingConfig.defaultEndpoint;

  final DioHttpClient _httpClient;
  final Duration _pollingInterval;
  final String _endpointUrl;

  NeatPeriodicTaskScheduler? _scheduler;
  final _messageController = StreamController<FcmMessage>.broadcast();
  String? _deviceId;
  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  Future<void>? _initFuture;

  /// Stream of FCM messages from polling.
  Stream<FcmMessage> get messageStream => _messageController.stream;

  /// Unique device identifier for polling.
  String? get deviceId => _deviceId;

  /// Initialize the service asynchronously.
  /// This must be called before [start()] to ensure proper initialization.
  Future<void> init() async {
    _initFuture ??= _initialize();
    await _initFuture;
  }

  Future<void> _initialize() async {
    try {
      // Generate or retrieve device ID
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(FcmPollingConfig.deviceIdKey);

      if (_deviceId == null || _deviceId!.isEmpty) {
        _deviceId = const Uuid().v4();
        await prefs.setString(FcmPollingConfig.deviceIdKey, _deviceId!);
        loggy.info('Generated new device ID: $_deviceId');
      } else {
        loggy.debug('Using existing device ID: $_deviceId');
      }

      // Initialize local notifications plugin
      _notificationsPlugin = FlutterLocalNotificationsPlugin();
      
      InitializationSettings initSettings;
      if (Platform.isLinux) {
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const linuxSettings = LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        );
        initSettings = const InitializationSettings(
          android: androidSettings,
          linux: linuxSettings,
        );
      } else if (Platform.isWindows) {
        // Windows notification settings (flutter_local_notifications supports Windows)
        initSettings = const InitializationSettings();
      } else if (Platform.isMacOS) {
        // macOS notification settings
        const macOSSettings = DarwinInitializationSettings();
        initSettings = const InitializationSettings(macOS: macOSSettings);
      } else {
        // Fallback for other platforms
        initSettings = const InitializationSettings();
      }

      await _notificationsPlugin!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) {
          // Notification tapped - handled by FcmNotifier
        },
      );

      // Create periodic scheduler
      _scheduler = NeatPeriodicTaskScheduler(
        name: 'fcm polling worker',
        interval: _pollingInterval,
        timeout: FcmPollingConfig.requestTimeout,
        task: _pollServer,
      );

      loggy.info('FCM polling service initialized for ${Platform.operatingSystem}');
    } catch (e, stackTrace) {
      loggy.error('Error initializing FCM polling service', e, stackTrace);
    }
  }

  Future<void> _pollServer() async {
    if (_deviceId == null) {
      loggy.warning('Cannot poll: device ID not initialized');
      return;
    }

    try {
      final url = '$_endpointUrl/updates/$_deviceId';
      loggy.debug('Polling server for updates: $url');

      final response = await _httpClient.get(
        url,
        cancelToken: null,
      );

      if (response.statusCode != 200) {
        loggy.warning('Polling request failed with status: ${response.statusCode}');
        return;
      }

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        loggy.warning('Polling response is not a JSON object');
        return;
      }

      final updates = data['updates'] as List<dynamic>?;
      if (updates == null) {
        loggy.warning('Polling response missing "updates" array');
        return;
      }

      if (updates.isEmpty) {
        loggy.debug('No updates available');
        return;
      }

      loggy.info('Received ${updates.length} update(s) from polling');

      // Process each update
      for (final updateData in updates) {
        try {
          if (updateData is! Map<String, dynamic>) {
            loggy.warning('Invalid update format: expected Map, got ${updateData.runtimeType}');
            continue;
          }

          final message = FcmMessage.fromMap(updateData);

          if (!message.isValid) {
            loggy.warning('Invalid FCM message: missing required fields');
            continue;
          }

          if (!message.hasValidUrl) {
            loggy.warning('Invalid FCM message URL: ${message.subscriptionUrl}');
            continue;
          }

          loggy.info(
            'Valid polling message: profileId=${message.profileId}, url=${message.subscriptionUrl}',
          );

          // Show desktop notification
          await _showNotification(message);

          // Emit message to stream for FcmNotifier to handle
          _messageController.add(message);
        } catch (e, stackTrace) {
          loggy.error('Error processing polling update', e, stackTrace);
        }
      }
    } catch (e, stackTrace) {
      loggy.error('Error polling server for updates', e, stackTrace);
      // Continue polling even if individual requests fail
    }
  }

  Future<void> _showNotification(FcmMessage message) async {
    try {
      if (_notificationsPlugin == null) {
        loggy.warning('Notifications plugin not initialized');
        return;
      }

      NotificationDetails notificationDetails;
      if (Platform.isLinux) {
        const linuxDetails = LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
        );
        notificationDetails = const NotificationDetails(linux: linuxDetails);
      } else if (Platform.isWindows) {
        // Windows notification details (if supported by flutter_local_notifications)
        notificationDetails = const NotificationDetails();
      } else if (Platform.isMacOS) {
        const macOSDetails = DarwinNotificationDetails();
        notificationDetails = const NotificationDetails(macOS: macOSDetails);
      } else {
        // Fallback for other platforms
        notificationDetails = const NotificationDetails();
      }

      await _notificationsPlugin!.show(
        0,
        'Profile Update Available',
        'Update for profile: ${message.profileId}',
        notificationDetails,
      );

      loggy.debug('Desktop notification shown for profile: ${message.profileId}');
    } catch (e, stackTrace) {
      loggy.error('Error showing notification', e, stackTrace);
    }
  }

  /// Start the periodic polling scheduler.
  /// Asserts that initialization has completed.
  Future<void> start() async {
    if (_initFuture != null) {
      await _initFuture;
    }
    _scheduler?.start();
    loggy.info('FCM polling service started');
  }

  /// Stop the periodic polling scheduler.
  void stop() {
    _scheduler?.stop();
    loggy.info('FCM polling service stopped');
  }

  /// Dispose of resources.
  void dispose() {
    stop();
    _messageController.close();
    loggy.debug('FCM polling service disposed');
  }
}
*/
