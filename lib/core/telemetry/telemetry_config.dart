/// Configuration constants for panel telemetry.
///
/// Set via `--dart-define=PANEL_API_BASE_URL=https://your-panel.example.com`
/// at build time. If the value is empty (default), all telemetry is disabled.
abstract class TelemetryConfig {
  /// Base URL of the panel backend (no trailing slash).
  /// Empty string means telemetry is disabled.
  static const panelBaseUrl = String.fromEnvironment(
    'PANEL_API_BASE_URL',
    defaultValue: '',
  );

  /// Whether telemetry is enabled (panel URL was provided at compile time).
  static bool get isEnabled => panelBaseUrl.isNotEmpty;

  /// HTTP timeout for telemetry requests.
  static const timeout = Duration(seconds: 5);

  /// Minimum interval between heartbeat pings.
  static const heartbeatInterval = Duration(hours: 6);

  // SharedPreferences keys
  static const installIdKey = 'install_id';
  static const lastHeartbeatKey = 'telemetry_last_heartbeat_at';
}
