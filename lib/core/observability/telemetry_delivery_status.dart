enum TelemetryDeliveryState {
  disabled,
  idle,
  pending,
  sending,
  retryWaiting,
  budgetLimited,
  budgetStateInvalid,
  budgetStorageFailed,
  outboxStorageFailed,
  accepted,
  rejected,
  droppedExpired,
  droppedOverflow,
}

enum TelemetryTestOutcome {
  disabled,
  persisted,
  pending,
  accepted,
  budgetLimited,
  budgetStateInvalid,
  budgetStorageFailed,
  outboxStorageFailed,
  rejected,
  droppedExpired,
  droppedOverflow,
}

final class TelemetryTestResult {
  const TelemetryTestResult({required this.outcome});

  final TelemetryTestOutcome outcome;
}

/// A closed, local-only view of telemetry delivery. It never contains payloads,
/// transport errors, response bodies, credentials, addresses, or headers.
final class TelemetryDeliveryStatus {
  const TelemetryDeliveryStatus({
    this.state = TelemetryDeliveryState.disabled,
    this.pendingCount = 0,
    this.oldestPendingAgeSeconds,
    this.budgetUsedBytes = 0,
    this.budgetRemainingBytes = 0,
    this.nextAttemptAt,
    this.lastAttemptAt,
    this.lastHttpCode,
    this.lastTestOutcome,
  });

  const TelemetryDeliveryStatus.disabled() : this();

  static const schema = 'blizzard-telemetry-delivery/v1';
  static const _maxSafeInteger = 9007199254740991;
  static const _keys = {
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
  };

  final TelemetryDeliveryState state;
  final int pendingCount;
  final int? oldestPendingAgeSeconds;
  final int budgetUsedBytes;
  final int budgetRemainingBytes;
  final DateTime? nextAttemptAt;
  final DateTime? lastAttemptAt;
  final int? lastHttpCode;
  final TelemetryTestOutcome? lastTestOutcome;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'state': state.name,
    'pending_count': pendingCount,
    'oldest_pending_age_seconds': oldestPendingAgeSeconds,
    'budget_used_bytes': budgetUsedBytes,
    'budget_remaining_bytes': budgetRemainingBytes,
    'next_attempt_at': nextAttemptAt?.toUtc().toIso8601String(),
    'last_attempt_at': lastAttemptAt?.toUtc().toIso8601String(),
    'last_http_code': lastHttpCode,
    'last_test_outcome': lastTestOutcome?.name,
  };

  factory TelemetryDeliveryStatus.fromJson(Map<String, Object?> json) {
    if (json.length != _keys.length || !json.keys.every(_keys.contains) || json['schema'] != schema) {
      throw const FormatException('invalid telemetry delivery status fields');
    }
    final state = _enumByName(TelemetryDeliveryState.values, json['state']);
    final testOutcome = json['last_test_outcome'] == null
        ? null
        : _enumByName(TelemetryTestOutcome.values, json['last_test_outcome']);
    final pendingCount = _boundedInt(json['pending_count'], max: 100);
    final oldestAge = _optionalBoundedInt(json['oldest_pending_age_seconds'], max: 24 * 60 * 60);
    final usedBytes = _boundedInt(json['budget_used_bytes'], max: _maxSafeInteger);
    final remainingBytes = _boundedInt(json['budget_remaining_bytes'], max: _maxSafeInteger);
    final nextAttempt = _optionalUtcDateTime(json['next_attempt_at']);
    final lastAttempt = _optionalUtcDateTime(json['last_attempt_at']);
    final httpCode = _optionalBoundedInt(json['last_http_code'], min: 100, max: 599);
    return TelemetryDeliveryStatus(
      state: state,
      pendingCount: pendingCount,
      oldestPendingAgeSeconds: oldestAge,
      budgetUsedBytes: usedBytes,
      budgetRemainingBytes: remainingBytes,
      nextAttemptAt: nextAttempt,
      lastAttemptAt: lastAttempt,
      lastHttpCode: httpCode,
      lastTestOutcome: testOutcome,
    );
  }

  static T _enumByName<T extends Enum>(List<T> values, Object? raw) {
    if (raw is! String) throw const FormatException('invalid telemetry delivery status enum');
    for (final value in values) {
      if (value.name == raw) return value;
    }
    throw const FormatException('unknown telemetry delivery status enum');
  }

  static int _boundedInt(Object? raw, {int min = 0, required int max}) {
    if (raw is! int || raw < min || raw > max) {
      throw const FormatException('invalid telemetry delivery status counter');
    }
    return raw;
  }

  static int? _optionalBoundedInt(Object? raw, {int min = 0, required int max}) =>
      raw == null ? null : _boundedInt(raw, min: min, max: max);

  static DateTime? _optionalUtcDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) throw const FormatException('invalid telemetry delivery timestamp');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null || !parsed.isUtc) throw const FormatException('invalid telemetry delivery timestamp');
    return parsed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelemetryDeliveryStatus &&
          state == other.state &&
          pendingCount == other.pendingCount &&
          oldestPendingAgeSeconds == other.oldestPendingAgeSeconds &&
          budgetUsedBytes == other.budgetUsedBytes &&
          budgetRemainingBytes == other.budgetRemainingBytes &&
          nextAttemptAt == other.nextAttemptAt &&
          lastAttemptAt == other.lastAttemptAt &&
          lastHttpCode == other.lastHttpCode &&
          lastTestOutcome == other.lastTestOutcome;

  @override
  int get hashCode => Object.hash(
    state,
    pendingCount,
    oldestPendingAgeSeconds,
    budgetUsedBytes,
    budgetRemainingBytes,
    nextAttemptAt,
    lastAttemptAt,
    lastHttpCode,
    lastTestOutcome,
  );
}
