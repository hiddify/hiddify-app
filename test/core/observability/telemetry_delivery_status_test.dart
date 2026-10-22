import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/core/observability/telemetry_transport_attempt.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';

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
      lastAttempt: TelemetryTransportAttempt(
        attemptedAt: DateTime.utc(2026, 10, 22, 9, 59),
        testEventId: '0123456789abcdef',
        appVersion: '0.0.1',
        buildNumber: '22',
        stage: TelemetryTransportStage.afterRequest,
        outcome: TelemetryTransportOutcome.http,
        httpCode: 503,
        ackOwnEvent: false,
      ),
      attemptStorageState: TelemetryAttemptStorageState.persisted,
      lastTestAttempt: TelemetryTransportAttempt(
        attemptedAt: DateTime.utc(2026, 10, 22, 9, 58),
        testEventId: 'fedcba9876543210',
        appVersion: '0.0.1',
        buildNumber: '22',
        stage: TelemetryTransportStage.afterRequest,
        outcome: TelemetryTransportOutcome.http,
        httpCode: 202,
        ackOwnEvent: true,
      ),
      testAttemptStorageState: TelemetryAttemptStorageState.persisted,
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
      'last_attempt',
      'attempt_storage_state',
      'last_test_attempt',
      'test_attempt_storage_state',
    });
  });

  test('strict v1 status imports without dropping its surrounding diagnostic journal', () {
    final restored = TelemetryDeliveryStatus.fromJson({
      'schema': 'blizzard-telemetry-delivery/v1',
      'state': 'retryWaiting',
      'pending_count': 2,
      'oldest_pending_age_seconds': 12,
      'budget_used_bytes': 1024,
      'budget_remaining_bytes': 64512,
      'next_attempt_at': '2026-10-22T10:00:00.000Z',
      'last_attempt_at': '2026-10-22T09:59:00.000Z',
      'last_http_code': 503,
      'last_test_outcome': 'pending',
    });

    expect(restored.state, TelemetryDeliveryState.retryWaiting);
    expect(restored.pendingCount, 2);
    expect(restored.lastAttempt, isNull);
    expect(restored.lastTestAttempt, isNull);
    expect(restored.attemptStorageState, TelemetryAttemptStorageState.unconfigured);
    expect(restored.testAttemptStorageState, TelemetryAttemptStorageState.unconfigured);
  });

  test('legacy v1 delivery status preserves events when a safe journal restores', () {
    final journal = SafeDiagnosticJournal(
      restored: jsonEncode({
        'schema': 'blizzard-safe-diagnostics/v1',
        'platform': 'ios',
        'reachability': 'not_checked',
        'events': [
          {
            'sequence': 1,
            'operation_id': 1,
            'operation': 'connect',
            'stage': 'accepted',
            'code': 'started',
            'duration_ms': 0,
            'reachability': 'not_checked',
          },
        ],
        'telemetry_delivery': {
          'schema': 'blizzard-telemetry-delivery/v1',
          'state': 'accepted',
          'pending_count': 0,
          'oldest_pending_age_seconds': null,
          'budget_used_bytes': 1024,
          'budget_remaining_bytes': 64512,
          'next_attempt_at': null,
          'last_attempt_at': '2026-10-22T09:59:00.000Z',
          'last_http_code': 202,
          'last_test_outcome': 'accepted',
        },
      }),
    );
    addTearDown(journal.dispose);

    expect(journal.events, hasLength(1));
    expect(journal.events.single.sequence, 1);
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
