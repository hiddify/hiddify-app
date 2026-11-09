/// Decides whether the tunnel should be brought back up when the desktop app starts.
///
/// Only desktop restores the previous session: mobile relies on the platform VPN
/// service and the quick-settings tile, which bring their own lifecycle.
bool shouldRestoreConnectionOnStartup({
  required bool isDesktop,
  required bool startedByUser,
  required bool hasActiveProfile,
  bool isAlreadyRunning = false,
}) => isDesktop && startedByUser && hasActiveProfile && !isAlreadyRunning;

/// How many times the desktop app tries to restore the tunnel on startup. Right after a
/// login autostart the network, the service or the core is often not ready yet, and one
/// failed try left the user disconnected with an error (#2482).
const startupConnectAttempts = 3;

/// The wait before startup attempt [attempt] (1-based); it grows so a slow network
/// or service has time to come up.
Duration startupConnectRetryDelay(int attempt) => Duration(seconds: 3 * (attempt - 1));
