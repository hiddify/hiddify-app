import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/utils/ip_utils.dart';

void main() {
  group(
    "obscureIp",
    () {
      test(
        "Should obscure parts of ipv4",
        () {
          const ipv4 = "1.1.1.1";
          final obscured = obscureIp(ipv4);
          expect(obscured, "1.*.*.1");
        },
      );

      test(
        "Should obscure parts of full ipv6",
        () {
          const ipv6 = "FEDC:BA98:7654:3210:FEDC:BA98:7654:3210";
          final obscured = obscureIp(ipv6);
          expect(obscured, "FEDC:****:****:****:****:****:****:****");
        },
      );

      test(
        "Should obscure parts of ipv6",
        () {
          const ipv6 = "::1";
          final obscured = obscureIp(ipv6);
          expect(obscured, "::*");
        },
      );
    },
  );
}
