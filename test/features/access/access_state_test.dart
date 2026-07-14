import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/access/model/access_state.dart';

void main() {
  final now = DateTime.utc(2026, 7, 14, 12);

  test('maps loading before all other states', () {
    expect(AccessState.derive(loading: true, hasProfile: false, now: now), AccessState.loading);
  });

  test('maps missing profile to no access', () {
    expect(AccessState.derive(hasProfile: false, now: now), AccessState.notConfigured);
  });

  test('maps a profile without subscription metadata to active cached access', () {
    expect(AccessState.derive(hasProfile: true, now: now), AccessState.activeMetadataUnavailable);
  });

  test('maps future and past expiration explicitly', () {
    expect(
      AccessState.derive(hasProfile: true, expiresAt: now.add(const Duration(days: 1)), now: now),
      AccessState.active,
    );
    expect(
      AccessState.derive(hasProfile: true, expiresAt: now.subtract(const Duration(seconds: 1)), now: now),
      AccessState.expired,
    );
  });

  test('maps repository errors to temporarily unavailable', () {
    expect(
      AccessState.derive(hasProfile: true, error: const FormatException('offline'), now: now),
      AccessState.temporarilyUnavailable,
    );
  });
}
