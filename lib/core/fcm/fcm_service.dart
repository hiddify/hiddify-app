// TEMPORARILY DISABLED: Firebase Cloud Messaging
/*
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hiddify/core/fcm/fcm_message.dart';
import 'package:hiddify/firebase_options.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// Top-level function for handling background messages.
///
/// This function runs in a separate isolate when the app is terminated or in the background.
///
/// **Current Behavior:**
/// This handler is intentionally left minimal in Dart because:
/// - Android/iOS native layers handle background notifications with notification payloads
/// - Data-only message processing is not performed here in the background isolate
/// - The actual message processing happens in `FcmNotifier` when the app is opened
/// - Riverpod dependencies cannot be used in this background isolate
///
/// **Future Data-Only Message Support:**
/// If data-only messages (messages without notification payload) need to be processed
/// in the background, this handler should be extended to:
/// 1. Initialize Firebase in the background isolate (already done below)
/// 2. Process the message data payload
/// 3. Perform any necessary background operations
///
/// Currently, data-only messages received while the app is terminated will be handled
/// when the app is next opened via `FirebaseMessaging.instance.getInitialMessage()`.
///
/// Must be a top-level function, not a class method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate if not already initialized
  // This is required for any Firebase operations in the background isolate
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase may already be initialized, ignore the error
    // This is expected if the app was recently running
  }

  // Basic logging for background message delivery validation
  // This helps verify that background messages are being received
  print('[FCM Background Handler] Message received: messageId=${message.messageId}, '
      'notification=${message.notification != null}, '
      'data=${message.data.isNotEmpty}');

  // Note: Actual message processing is deferred to when the app opens.
  // For messages with notification payloads, the native layer handles display.
  // For data-only messages, processing occurs in FcmNotifier when the app is opened.
  // This design avoids introducing Riverpod dependencies into the background isolate.
}

/// Callback type for handling background/terminated messages
typedef BackgroundMessageHandler = Future<void> Function(RemoteMessage message);

class FcmService with InfraLogger {
  FcmService() {
    _initialize();
  }

  String? _currentToken;
  final _messageController = StreamController<FcmMessage>.broadcast();
  BackgroundMessageHandler? _backgroundMessageHandler;
  RemoteMessage? _pendingInitialMessage;

  /// Stream of FCM messages received in foreground
  Stream<FcmMessage> get messageStream => _messageController.stream;

  /// Current FCM token
  String? get currentToken => _currentToken;

  /// Register a handler for background/terminated messages.
  /// This handler will be called for messages opened from background or terminated state,
  /// bypassing the foreground message stream (which shows action toasts).
  void setBackgroundMessageHandler(BackgroundMessageHandler handler) {
    _backgroundMessageHandler = handler;

    // Process any pending initial message now that handler is registered
    if (_pendingInitialMessage != null) {
      loggy.debug('Processing pending initial message now that handler is registered');
      _handleBackgroundOrTerminatedMessage(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  Future<void> _initialize() async {
    try {
      // Request notification permissions on iOS/macOS
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        loggy.info('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        loggy.info('User granted provisional notification permission');
      } else {
        loggy.warning('User declined or has not granted notification permission');
      }

      // Get FCM token
      await _refreshToken();

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) {
          loggy.info('FCM token refreshed');
          _currentToken = newToken;
          // Token can be sent to backend here if needed
        },
        onError: (error) {
          loggy.error('Error refreshing FCM token', error);
        },
      );

      // Handle foreground messages (app is open and visible)
      // These go through the message stream to show action toasts
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          loggy.debug('Foreground message received: ${message.messageId}');
          _handleForegroundMessage(message);
        },
        onError: (error) {
          loggy.error('Error handling foreground message', error);
        },
      );

      // Handle background messages (user taps notification while app is in background)
      // These bypass the action toast since user already tapped the notification
      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          loggy.debug('Background message opened: ${message.messageId}');
          _handleBackgroundOrTerminatedMessage(message);
        },
        onError: (error) {
          loggy.error('Error handling background message', error);
        },
      );

      // Background message handler is registered in bootstrap.dart before Firebase initialization

      // Check if app was opened from a terminated state via notification
      // These bypass the action toast since user already tapped the notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        loggy.debug('App opened from terminated state via notification: ${initialMessage.messageId}');
        // Store the message if handler isn't registered yet, otherwise process immediately
        if (_backgroundMessageHandler != null) {
          _handleBackgroundOrTerminatedMessage(initialMessage);
        } else {
          _pendingInitialMessage = initialMessage;
        }
      }
    } catch (e, stackTrace) {
      loggy.error('Error initializing FCM service', e, stackTrace);
    }
  }

  Future<void> _refreshToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        loggy.debug('FCM token: ${token}'); // FIXME: only debug, remove in prod
        loggy.info('FCM token obtained: ${token.substring(0, 20)}...');
        _currentToken = token;
        // Token can be sent to backend here if needed
      } else {
        loggy.warning('FCM token is null');
      }
    } catch (e, stackTrace) {
      loggy.error('Error getting FCM token', e, stackTrace);
    }
  }

  /// Handle foreground messages (app is open and visible).
  /// These messages go through the message stream to show action toasts.
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) {
        loggy.warning('FCM message has no data payload');
        return;
      }

      loggy.debug('Parsing FCM message data: $data');

      final fcmMessage = FcmMessage.fromMap(data);
      if (!fcmMessage.isValid) {
        loggy.warning('FCM message is invalid: missing required fields');
        return;
      }

      if (!fcmMessage.hasValidUrl) {
        loggy.warning('FCM message has invalid URL: ${fcmMessage.subscriptionUrl}');
        return;
      }

      loggy.info(
        'Valid FCM message received: profileId=${fcmMessage.profileId}, url=${fcmMessage.subscriptionUrl}',
      );

      // Emit message to stream for FcmNotifier to handle (shows action toast)
      _messageController.add(fcmMessage);
    } catch (e, stackTrace) {
      loggy.error('Error parsing FCM message', e, stackTrace);
    }
  }

  /// Handle background/terminated messages (user tapped notification).
  /// These messages bypass the action toast and directly update the profile.
  void _handleBackgroundOrTerminatedMessage(RemoteMessage message) {
    if (_backgroundMessageHandler != null) {
      loggy.debug('Routing background/terminated message to handler');
      _backgroundMessageHandler!(message);
    } else {
      loggy.warning(
        'Background message received but no handler registered yet. '
        'This should not happen for onMessageOpenedApp, but may happen for getInitialMessage.',
      );
      // Fallback: route through stream if handler not available
      // This should only happen if getInitialMessage is processed before handler registration
      _handleForegroundMessage(message);
    }
  }

  void dispose() {
    _messageController.close();
  }
}
*/
