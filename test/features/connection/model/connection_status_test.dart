import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';

void main() {
  group("canRestoreConnection", () {
    test("allows a normal disconnected state", () {
      expect(const ConnectionStatus.disconnected().canRestoreConnection, isTrue);
    });

    test("rejects a disconnected state with a failure", () {
      expect(
        const ConnectionStatus.disconnected(ConnectionFailure.unexpected("startup failed")).canRestoreConnection,
        isFalse,
      );
    });

    test("rejects active and transitional states", () {
      expect(const ConnectionStatus.connecting().canRestoreConnection, isFalse);
      expect(const ConnectionStatus.connected().canRestoreConnection, isFalse);
      expect(const ConnectionStatus.disconnecting().canRestoreConnection, isFalse);
    });
  });
}
