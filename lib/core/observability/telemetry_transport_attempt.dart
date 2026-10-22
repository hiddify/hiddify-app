import 'dart:convert';

enum TelemetryTransportStage { beforeRequest, afterRequest }

enum TelemetryTransportOutcome { http, timeout, network, tls, other }

/// A bounded local receipt for one transport attempt. It intentionally excludes
/// endpoints, addresses, credentials, headers, payloads and exception text.
final class TelemetryTransportAttempt {
  const TelemetryTransportAttempt({
    required this.attemptedAt,
    this.testEventId,
    required this.appVersion,
    required this.buildNumber,
    required this.stage,
    this.outcome,
    this.httpCode,
    this.ackOwnEvent,
  });

  static const preferenceKey = 'betterstack_transport_attempt_v1';
  static const lastTestPreferenceKey = 'betterstack_test_attempt_v1';
  static const schema = 'blizzard-transport-attempt/v1';
  static const maxBytes = 512;
  static final _eventIdPattern = RegExp(r'^[0-9a-f]{16}$');
  static final _versionPattern = RegExp(r'^(?:unknown|\d{1,3}\.\d{1,3}\.\d{1,3})$');
  static final _buildPattern = RegExp(r'^(?:unknown|\d{1,9})$');
  static const _keys = {
    'schema',
    'attempted_at',
    'test_event_id',
    'app_version',
    'build_number',
    'stage',
    'outcome',
    'http_code',
    'ack_own_event',
  };

  final DateTime attemptedAt;
  final String? testEventId;
  final String appVersion;
  final String buildNumber;
  final TelemetryTransportStage stage;
  final TelemetryTransportOutcome? outcome;
  final int? httpCode;
  final bool? ackOwnEvent;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'attempted_at': attemptedAt.toUtc().toIso8601String(),
    'test_event_id': testEventId,
    'app_version': appVersion,
    'build_number': buildNumber,
    'stage': stage.name,
    'outcome': outcome?.name,
    'http_code': httpCode,
    'ack_own_event': ackOwnEvent,
  };

  String encode() {
    final json = toJson();
    TelemetryTransportAttempt.fromJson(json);
    final encoded = jsonEncode(json);
    if (utf8.encode(encoded).length > maxBytes) throw const FormatException('oversized transport attempt');
    return encoded;
  }

  factory TelemetryTransportAttempt.decode(String encoded) {
    if (utf8.encode(encoded).length > maxBytes) throw const FormatException('oversized transport attempt');
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) throw const FormatException('invalid transport attempt');
    return TelemetryTransportAttempt.fromJson(decoded);
  }

  factory TelemetryTransportAttempt.fromJson(Map<String, Object?> json) {
    if (json.length != _keys.length || !json.keys.every(_keys.contains) || json['schema'] != schema) {
      throw const FormatException('invalid transport attempt fields');
    }
    final attemptedAt = _utcDateTime(json['attempted_at']);
    final testEventId = json['test_event_id'];
    if (testEventId != null && (testEventId is! String || !_eventIdPattern.hasMatch(testEventId))) {
      throw const FormatException('invalid transport attempt event');
    }
    final appVersion = json['app_version'];
    final buildNumber = json['build_number'];
    if (appVersion is! String ||
        !_versionPattern.hasMatch(appVersion) ||
        buildNumber is! String ||
        !_buildPattern.hasMatch(buildNumber)) {
      throw const FormatException('invalid transport attempt metadata');
    }
    final stage = _enumByName(TelemetryTransportStage.values, json['stage']);
    final outcome = json['outcome'] == null ? null : _enumByName(TelemetryTransportOutcome.values, json['outcome']);
    final rawHttpCode = json['http_code'];
    if (rawHttpCode != null && (rawHttpCode is! int || rawHttpCode < 100 || rawHttpCode > 599)) {
      throw const FormatException('invalid transport attempt HTTP code');
    }
    final httpCode = rawHttpCode as int?;
    final ackOwnEvent = json['ack_own_event'];
    if (ackOwnEvent != null && ackOwnEvent is! bool) throw const FormatException('invalid transport attempt ACK');
    if ((testEventId == null) != (ackOwnEvent == null))
      throw const FormatException('inconsistent transport attempt ACK');
    if (stage == TelemetryTransportStage.beforeRequest) {
      if (outcome != null || httpCode != null || ackOwnEvent == true) {
        throw const FormatException('invalid before-request result');
      }
    } else {
      if (outcome == null || (outcome == TelemetryTransportOutcome.http) != (httpCode != null)) {
        throw const FormatException('inconsistent transport attempt outcome');
      }
      if (ackOwnEvent == true && (outcome != TelemetryTransportOutcome.http || httpCode! < 200 || httpCode >= 300)) {
        throw const FormatException('invalid transport attempt ACK');
      }
    }
    return TelemetryTransportAttempt(
      attemptedAt: attemptedAt,
      testEventId: testEventId as String?,
      appVersion: appVersion,
      buildNumber: buildNumber,
      stage: stage,
      outcome: outcome,
      httpCode: httpCode,
      ackOwnEvent: ackOwnEvent as bool?,
    );
  }

  static T _enumByName<T extends Enum>(List<T> values, Object? raw) {
    if (raw is! String) throw const FormatException('invalid transport attempt enum');
    for (final value in values) {
      if (value.name == raw) return value;
    }
    throw const FormatException('unknown transport attempt enum');
  }

  static DateTime _utcDateTime(Object? raw) {
    if (raw is! String) throw const FormatException('invalid transport attempt timestamp');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null || !parsed.isUtc) throw const FormatException('invalid transport attempt timestamp');
    return parsed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelemetryTransportAttempt &&
          attemptedAt == other.attemptedAt &&
          testEventId == other.testEventId &&
          appVersion == other.appVersion &&
          buildNumber == other.buildNumber &&
          stage == other.stage &&
          outcome == other.outcome &&
          httpCode == other.httpCode &&
          ackOwnEvent == other.ackOwnEvent;

  @override
  int get hashCode =>
      Object.hash(attemptedAt, testEventId, appVersion, buildNumber, stage, outcome, httpCode, ackOwnEvent);
}
