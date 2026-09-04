import "package:flutter_test/flutter_test.dart";
import "package:hiddify/features/connection/model/connection_failure.dart";
import "package:hiddify/hiddifycore/core_start_failure.dart";
import "package:hiddify/utils/platform_utils.dart";

void main() {
  group("isPrivilegeError", () {
    test("detects the tun permission errors reported by the core", () {
      expect(
        isPrivilegeError("manager start inbound/tun[tun-in]: configure tun interface: operation not permitted"),
        isTrue,
      );
      expect(isPrivilegeError("CreateFile failed: Access is denied."), isTrue);
      expect(isPrivilegeError("permission denied"), isTrue);
      // Windows ERROR_PRIVILEGE_NOT_HELD (1314), raised by wintun without elevation.
      expect(isPrivilegeError("A required privilege is not held by the client."), isTrue);
    });

    test("does not flag unrelated failures", () {
      expect(isPrivilegeError("dial tcp 1.2.3.4:443: i/o timeout"), isFalse);
      expect(isPrivilegeError("decode config at index 0: invalid character"), isFalse);
      expect(isPrivilegeError(""), isFalse);
    });
  });

  group("backgroundCoreStartFailure", () {
    test("keeps the original cause for unrelated failures", () {
      expect(
        backgroundCoreStartFailure("address already in use"),
        isA<UnexpectedConnectionFailure>().having((f) => f.error, "error", contains("address already in use")),
      );
    });

    test("falls back to the generic message when the core reports nothing", () {
      expect(backgroundCoreStartFailure(""), isA<UnexpectedConnectionFailure>());
    });

    test("reports privilege failures as an actionable error", () {
      // `flutter test` runs on a desktop host, where the tunnel needs elevation.
      expect(PlatformUtils.isDesktop, isTrue);
      expect(
        backgroundCoreStartFailure("configure tun interface: operation not permitted"),
        isA<MissingPrivilege>(),
      );
    });
  });
}
