import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/startup_connection.dart';

void main() {
  group("shouldRestoreConnectionOnStartup", () {
    test("restores on desktop when the user had it running and a profile is active", () {
      expect(shouldRestoreConnectionOnStartup(isDesktop: true, startedByUser: true, hasActiveProfile: true), isTrue);
    });

    test("does not restore when the user never started it", () {
      expect(shouldRestoreConnectionOnStartup(isDesktop: true, startedByUser: false, hasActiveProfile: true), isFalse);
    });

    test("does not restore without an active profile", () {
      expect(shouldRestoreConnectionOnStartup(isDesktop: true, startedByUser: true, hasActiveProfile: false), isFalse);
    });

    test("does not restore on mobile", () {
      expect(shouldRestoreConnectionOnStartup(isDesktop: false, startedByUser: true, hasActiveProfile: true), isFalse);
    });

    test("does not restart a tunnel already restored by the platform", () {
      expect(
        shouldRestoreConnectionOnStartup(
          isDesktop: true,
          startedByUser: true,
          hasActiveProfile: true,
          isAlreadyRunning: true,
        ),
        isFalse,
      );
    });
  });

  group("startup connect retries", () {
    test("tries at least three times", () {
      expect(startupConnectAttempts, greaterThanOrEqualTo(3));
    });

    test("the first attempt is immediate and later ones wait longer", () {
      expect(startupConnectRetryDelay(1), Duration.zero);
      for (var attempt = 2; attempt <= startupConnectAttempts; attempt++) {
        expect(startupConnectRetryDelay(attempt), greaterThan(startupConnectRetryDelay(attempt - 1)));
      }
    });
  });
}
