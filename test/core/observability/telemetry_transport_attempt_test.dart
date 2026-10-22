import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/telemetry_transport_attempt.dart';

void main() {
  test('round-trips only the bounded closed transport-attempt schema', () {
    final attempt = TelemetryTransportAttempt(
      attemptedAt: DateTime.utc(2026, 10, 22, 9, 15),
      testEventId: '0123456789abcdef',
      appVersion: '0.0.1',
      buildNumber: '22',
      stage: TelemetryTransportStage.afterRequest,
      outcome: TelemetryTransportOutcome.http,
      httpCode: 202,
      ackOwnEvent: true,
    );

    final encoded = attempt.encode();
    expect(TelemetryTransportAttempt.decode(encoded), attempt);
    expect(utf8.encode(encoded).length, lessThanOrEqualTo(TelemetryTransportAttempt.maxBytes));
    expect((jsonDecode(encoded) as Map).keys, {
      'schema',
      'attempted_at',
      'test_event_id',
      'app_version',
      'build_number',
      'stage',
      'outcome',
      'http_code',
      'ack_own_event',
    });
  });

  test('strict parser rejects private fields and inconsistent outcomes', () {
    final valid = TelemetryTransportAttempt(
      attemptedAt: DateTime.utc(2026, 10, 22, 9, 15),
      appVersion: '0.0.1',
      buildNumber: '22',
      stage: TelemetryTransportStage.afterRequest,
      outcome: TelemetryTransportOutcome.network,
    ).toJson();

    for (final invalid in [
      {...valid, 'hostname': 'private.invalid'},
      {...valid, 'attempted_at': '2026-10-22T09:15:00'},
      {...valid, 'test_event_id': 'not-an-event'},
      {...valid, 'outcome': 'http', 'http_code': null},
      {...valid, 'outcome': 'network', 'http_code': 503},
      {...valid, 'test_event_id': null, 'ack_own_event': false},
      {...valid, 'test_event_id': '0123456789abcdef', 'ack_own_event': null},
    ]) {
      expect(() => TelemetryTransportAttempt.fromJson(invalid), throwsFormatException);
    }
  });

  test('before-request record has no result and no-test ACK stays unknown', () {
    final before = TelemetryTransportAttempt(
      attemptedAt: DateTime.utc(2026, 10, 22, 9, 15),
      testEventId: '0123456789abcdef',
      appVersion: '0.0.1',
      buildNumber: '22',
      stage: TelemetryTransportStage.beforeRequest,
      ackOwnEvent: false,
    );
    expect(TelemetryTransportAttempt.decode(before.encode()), before);

    final ordinary = TelemetryTransportAttempt(
      attemptedAt: DateTime.utc(2026, 10, 22, 9, 16),
      appVersion: '0.0.1',
      buildNumber: '22',
      stage: TelemetryTransportStage.afterRequest,
      outcome: TelemetryTransportOutcome.http,
      httpCode: 202,
    );
    expect(ordinary.ackOwnEvent, isNull);
    expect(TelemetryTransportAttempt.decode(ordinary.encode()), ordinary);
  });
}
