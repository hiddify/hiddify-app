import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/telemetry_delivery_status.dart';

void main() {
  test('status round-trips only bounded closed safe fields', () {
    final status = TelemetryDeliveryStatus(
      state: TelemetryDeliveryState.retryWaiting,
      pendingCount: 2,
      oldestPendingAgeSeconds: 12,
      budgetUsedBytes: 1024,
      budgetRemainingBytes: 64 * 1024 - 1024,
      nextAttemptAt: DateTime.utc(2026, 10, 22, 10),
      lastAttemptAt: DateTime.utc(2026, 10, 22, 9, 59),
      lastHttpCode: 503,
      lastTestOutcome: TelemetryTestOutcome.pending,
    );

    expect(TelemetryDeliveryStatus.fromJson(status.toJson()), status);
    expect(status.toJson().keys, {
      'schema',
      'state',
      'pending_count',
      'oldest_pending_age_seconds',
      'budget_used_bytes',
      'budget_remaining_bytes',
      'next_attempt_at',
      'last_attempt_at',
      'last_http_code',
      'last_test_outcome',
    });
  });

  test('disabled and normal constructors have safe zero defaults', () {
    expect(const TelemetryDeliveryStatus.disabled(), const TelemetryDeliveryStatus());
    expect(
      const TelemetryDeliveryStatus(state: TelemetryDeliveryState.budgetLimited).toJson()['state'],
      'budgetLimited',
    );
  });

  test('strict parser rejects unknown, malformed and non-UTC fields', () {
    final valid = const TelemetryDeliveryStatus().toJson();
    for (final invalid in [
      {...valid, 'private': 'forbidden'},
      {...valid, 'state': 'newUnknownState'},
      {...valid, 'pending_count': 101},
      {...valid, 'oldest_pending_age_seconds': 86401},
      {...valid, 'next_attempt_at': '2026-10-22T10:00:00'},
      {...valid, 'last_http_code': 99},
    ]) {
      expect(() => TelemetryDeliveryStatus.fromJson(invalid), throwsFormatException);
    }
  });

  test('test result contains only a closed outcome', () {
    const result = TelemetryTestResult(outcome: TelemetryTestOutcome.accepted);
    expect(result.outcome, TelemetryTestOutcome.accepted);
  });
}
