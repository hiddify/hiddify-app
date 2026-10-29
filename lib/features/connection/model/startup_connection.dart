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
