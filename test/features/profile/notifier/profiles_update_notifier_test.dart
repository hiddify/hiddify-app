import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';

void main() {
  test('a profile failing its updates for 3 days is no longer updated on its own', () {
    final now = DateTime(2026, 11, 4, 12);
    bool gaveUp(Duration? failing) =>
        ForegroundProfilesUpdateNotifier.gaveUp(failing == null ? null : now.subtract(failing), now);
    expect(gaveUp(null), isFalse);
    expect(gaveUp(const Duration(days: 2, hours: 23)), isFalse);
    expect(gaveUp(const Duration(days: 3)), isTrue);
    expect(gaveUp(const Duration(days: 10)), isTrue);
  });
}
