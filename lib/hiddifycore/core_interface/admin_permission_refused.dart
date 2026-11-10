/// The user did not give administrator permission for VPN mode: the system prompt was refused or
/// dismissed, or the user stopped waiting for it. Not a failure of the service itself, so the app
/// offers the choice between VPN and system proxy mode again instead of an error.
class AdminPermissionRefused implements Exception {
  const AdminPermissionRefused();

  @override
  String toString() => 'Administrator permission was not given, so VPN mode could not connect.';
}
