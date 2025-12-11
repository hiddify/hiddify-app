import 'package:hiddify/core/utils/preferences_utils.dart';

/// Core preferences for basic Xray-core settings
/// Advanced settings are in separate files:
/// - fragment_settings.dart
/// - dns_settings.dart
/// - tls_settings.dart
/// - transport_settings.dart
/// - mux_settings.dart
/// - routing_settings.dart
/// - inbound_settings.dart
/// - sockopt_settings.dart
abstract class CorePreferences {
  /// Custom config content (JSON format)
  static final configContent = PreferencesNotifier.create<String, String>(
    'core_config_content',
    '',
  );

  /// Asset path for geoip.dat and geosite.dat
  static final assetPath = PreferencesNotifier.create<String, String>(
    'core_asset_path',
    '',
  );

  /// Core mode: vpn (TUN) or proxy (SOCKS/HTTP)
  static final coreMode = PreferencesNotifier.create<String, String>(
    'core_mode',
    'proxy',
  );

  /// Enable core logging
  static final enableLogging = PreferencesNotifier.create<bool, bool>(
    'enable_logging',
    false,
  );

  /// Log level: none, error, warning, info, debug
  static final logLevel = PreferencesNotifier.create<String, String>(
    'log_level',
    'warning',
  );

  /// Available core modes
  static const List<String> availableCoreModes = ['proxy', 'vpn'];

  /// Available log levels
  static const List<String> availableLogLevels = [
    'none',
    'error',
    'warning',
    'info',
    'debug',
  ];
}
