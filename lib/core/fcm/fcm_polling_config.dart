// TEMPORARILY DISABLED: Firebase Cloud Messaging
/*
/// Configuration for the FCM polling service on Linux.
///
/// The polling service periodically checks a server endpoint for subscription updates
/// since Firebase Cloud Messaging is not supported on Linux desktop.
///
/// ## Server Endpoint
/// The service polls: `{endpoint}/updates/{deviceId}`
/// Expected JSON response:
/// ```json
/// {
///   "updates": [
///     {"subscriptionUrl": "https://...", "profileId": "profile-name"},
///     ...
///   ]
/// }
/// ```
///
/// ## Configuration
/// Override the endpoint at compile time:
/// ```bash
/// flutter build linux --dart-define=FCM_POLLING_ENDPOINT=https://custom.api/polling
/// ```
class FcmPollingConfig {
  /// Default polling endpoint URL.
  ///
  /// Can be overridden at compile time using:
  /// `flutter build linux --dart-define=FCM_POLLING_ENDPOINT=https://your-server.com/polling`
  static const String defaultEndpoint = String.fromEnvironment(
    'FCM_POLLING_ENDPOINT',
    defaultValue: 'https://api.hiddify.me/fcm-polling',
  );

  /// Default polling interval (matches profile auto-update interval).
  static const Duration defaultInterval = Duration(minutes: 15);

  /// SharedPreferences key for storing the device ID.
  static const String deviceIdKey = 'fcm_polling_device_id';

  /// Request timeout for polling requests.
  static const Duration requestTimeout = Duration(seconds: 30);
}
*/
