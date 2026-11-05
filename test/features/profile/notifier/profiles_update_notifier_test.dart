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

  test('a failing profile counts from when its update fell due after the last success', () {
    final lastSuccess = DateTime(2026, 10, 1);
    expect(
      ForegroundProfilesUpdateNotifier.failingSince(lastSuccess, const Duration(hours: 12)),
      DateTime(2026, 10, 1, 12),
    );
    expect(ForegroundProfilesUpdateNotifier.failingSince(lastSuccess, null), lastSuccess);
    // broken for a month: gives up on the first failed run
    expect(
      ForegroundProfilesUpdateNotifier.gaveUp(
        ForegroundProfilesUpdateNotifier.failingSince(lastSuccess, const Duration(hours: 12)),
        DateTime(2026, 11, 6),
      ),
      isTrue,
    );
    // a long interval still gets three days of retries after it fell due
    expect(
      ForegroundProfilesUpdateNotifier.gaveUp(
        ForegroundProfilesUpdateNotifier.failingSince(lastSuccess, const Duration(days: 7)),
        DateTime(2026, 10, 9),
      ),
      isFalse,
    );
  });
}
