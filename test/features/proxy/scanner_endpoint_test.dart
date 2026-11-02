import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';

void main() {
  group("splitScannerEndpoint", () {
    test("finds an IPv6 endpoint", () {
      final parts = splitScannerEndpoint("WARP · MASQUE · 🔍 [2606:4700:103:0:18fb:8f38:926d:87ab]:443");
      expect(parts?.before, "WARP · MASQUE");
      expect(parts?.endpoint, "[2606:4700:103:0:18fb:8f38:926d:87ab]:443");
      expect(parts?.after, "");
    });

    test("keeps the status mark after an IPv4 endpoint", () {
      final parts = splitScannerEndpoint("WARP · WG · 🔍 162.159.198.2:4443 ⏳ Connecting...");
      expect(parts?.before, "WARP · WG");
      expect(parts?.endpoint, "162.159.198.2:4443");
      expect(parts?.after, " ⏳ Connecting...");
    });

    test("finds nothing in other types", () {
      for (final type in ["WARP · WG · 🔍 Not found", "WARP 🔍 Searching...", "VLESS"]) {
        expect(splitScannerEndpoint(type), isNull);
      }
    });
  });
}
