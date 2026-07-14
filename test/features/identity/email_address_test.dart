import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/identity/model/email_address.dart';

void main() {
  group('normalizeOptionalEmail', () {
    test('returns null for blank optional email', () {
      expect(normalizeOptionalEmail('  '), isNull);
    });

    test('trims and lowercases a valid address', () {
      expect(normalizeOptionalEmail('  User.Name@Example.COM '), 'user.name@example.com');
    });
  });

  group('isValidEmail', () {
    test('accepts a practical email address', () {
      expect(isValidEmail('user+vpn@example.co.uk'), isTrue);
    });

    test('rejects addresses without a complete domain', () {
      expect(isValidEmail('user@example'), isFalse);
      expect(isValidEmail('user@'), isFalse);
    });

    test('rejects whitespace and multiple at signs', () {
      expect(isValidEmail('user name@example.com'), isFalse);
      expect(isValidEmail('user@@example.com'), isFalse);
    });
  });
}
