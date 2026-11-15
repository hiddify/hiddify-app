import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/utils/validators.dart';

void main() {
  group('isDomainSuffix', () {
    test('accepts what sing-box domain_suffix takes', () {
      for (final value in ['.com', '.ir', 'ir', 'noon.com', '.noon.com', 'mtalk.google.com', 'xn--mgba3a4f16a.ir']) {
        expect(isDomainSuffix(value), isTrue, reason: value);
      }
    });

    test('rejects malformed values', () {
      for (final value in ['', '.', '..com', 'noon..com', 'noon.com.', '.c', 'noon com', 'http://noon.com', '*.noon.com']) {
        expect(isDomainSuffix(value), isFalse, reason: value);
      }
    });
  });
}
