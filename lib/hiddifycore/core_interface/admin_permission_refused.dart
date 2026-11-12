/// The user did not give administrator permission for VPN mode: the system prompt was refused or
/// dismissed, or the user stopped waiting for it. Not a failure of the service itself, so the app
/// offers the choice between VPN and system proxy mode again instead of an error.
class AdminPermissionRefused implements Exception {
  const AdminPermissionRefused();

  @override
  String toString() => 'Administrator permission was not given, so VPN mode could not connect.';
}

/// The VPN service could not be installed or started, with the reason to show the user as it is
/// (a [StateError] would read "Bad state: ...").
class VpnServiceFailure implements Exception {
  const VpnServiceFailure(this.message);

  final String message;

  /// No pkexec to ask for the administrator password: a minimal desktop, or an AppImage on one.
  static const noAdminPrompt = VpnServiceFailure(
    'VPN mode needs pkexec to ask for the administrator password, and it is not installed: '
    'install the pkexec package (polkit) and try again, or use system proxy mode.',
  );

  @override
  String toString() => message;
}
