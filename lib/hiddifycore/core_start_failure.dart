import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/utils/platform_utils.dart';

/// Fragments reported by the core (or by the OS underneath it) when the tunnel
/// cannot be created because the process lacks the required privileges.
///
/// Linux and macOS surface `operation not permitted` while configuring the tun
/// interface, Windows surfaces `access is denied` or an elevation requirement
/// from the wintun driver, and mobile surfaces a denied VPN permission request.
const List<String> privilegeErrorFragments = [
  "operation not permitted",
  "permission denied",
  "access is denied",
  "requires elevation",
  "required privilege is not held",
  "insufficient privileges",
  "must be run as root",
  "denied",
];

/// Whether [message] describes a failure caused by insufficient privileges.
bool isPrivilegeError(String message) {
  final normalized = message.toLowerCase();
  return privilegeErrorFragments.any((fragment) => normalized.contains(fragment));
}

/// Maps a background core start failure onto a [ConnectionFailure] that keeps
/// the original cause instead of collapsing every failure into one generic
/// string.
///
/// Privilege failures become an actionable error: on desktop the tunnel needs
/// administrator/root rights, on mobile it needs a VPN permission grant.
ConnectionFailure backgroundCoreStartFailure(String message) {
  if (isPrivilegeError(message)) {
    return PlatformUtils.isDesktop
        ? const ConnectionFailure.missingPrivilege()
        : ConnectionFailure.missingVpnPermission(message);
  }
  return ConnectionFailure.unexpected(
    message.isEmpty ? "failed to start background core" : "failed to start background core: $message",
  );
}
