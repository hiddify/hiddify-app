import 'dart:convert';

enum TelemetryBudgetReserveOutcome {
  reserved,
  limitExceeded,
  invalidStoredState,
  storageReadFailed,
  storageWriteFailed,
  invalidRequest,
}

final class TelemetryBudgetReservation {
  const TelemetryBudgetReservation({
    required this.outcome,
    required this.usedLogBytes,
    required this.remainingLogBytes,
  });

  final TelemetryBudgetReserveOutcome outcome;
  final int usedLogBytes;
  final int remainingLogBytes;

  bool get allowed => outcome == TelemetryBudgetReserveOutcome.reserved;
}

typedef TelemetryBudgetSnapshot = TelemetryBudgetReservation;

final class _BudgetState {
  const _BudgetState({
    required this.day,
    required this.month,
    required this.usedBytes,
    required this.usedExceptions,
    required this.usedMonthlyExceptions,
  });

  final String day;
  final String month;
  final int usedBytes;
  final int usedExceptions;
  final int usedMonthlyExceptions;
}

/// Conservative per-installation caps, shared by all sessions and builds.
/// These complement Better Stack's account-wide quota; they cannot replace it.
final class TelemetryBudget {
  TelemetryBudget({
    required String? Function() read,
    required Future<bool> Function(String) write,
    DateTime Function()? now,
    this.maxLogBytes = 256 * 1024,
    this.maxExceptions = 1,
    this.maxMonthlyExceptions = 10,
  }) : _read = read,
       _write = write,
       _now = now ?? DateTime.now;

  static const preferenceKey = 'betterstack_daily_budget_v1';
  final String? Function() _read;
  final Future<bool> Function(String) _write;
  final DateTime Function() _now;
  final int maxLogBytes;
  final int maxExceptions;
  final int maxMonthlyExceptions;
  Future<void> _pending = Future.value();

  /// Reads current log usage without resetting or persisting any counters.
  TelemetryBudgetSnapshot get logSnapshot {
    try {
      final state = _readState();
      final remaining = (maxLogBytes - state.usedBytes).clamp(0, maxLogBytes);
      return TelemetryBudgetSnapshot(
        outcome: remaining == 0 ? TelemetryBudgetReserveOutcome.limitExceeded : TelemetryBudgetReserveOutcome.reserved,
        usedLogBytes: state.usedBytes,
        remainingLogBytes: remaining,
      );
    } on FormatException {
      return const TelemetryBudgetSnapshot(
        outcome: TelemetryBudgetReserveOutcome.invalidStoredState,
        usedLogBytes: 0,
        remainingLogBytes: 0,
      );
    } catch (_) {
      return const TelemetryBudgetSnapshot(
        outcome: TelemetryBudgetReserveOutcome.storageReadFailed,
        usedLogBytes: 0,
        remainingLogBytes: 0,
      );
    }
  }

  Future<TelemetryBudgetReservation> reserveLogs(int bytes) => _reserve(bytes, 0);

  /// Compatibility for the existing Sentry wrapper. Logs use the typed result.
  Future<bool> reserveException() async => (await _reserve(0, 1)).allowed;

  Future<TelemetryBudgetReservation> _reserve(int bytes, int exceptions) {
    final result = _pending.then((_) async {
      if (bytes < 0 || exceptions < 0) {
        return const TelemetryBudgetReservation(
          outcome: TelemetryBudgetReserveOutcome.invalidRequest,
          usedLogBytes: 0,
          remainingLogBytes: 0,
        );
      }
      late final _BudgetState state;
      try {
        state = _readState();
      } on FormatException {
        return const TelemetryBudgetReservation(
          outcome: TelemetryBudgetReserveOutcome.invalidStoredState,
          usedLogBytes: 0,
          remainingLogBytes: 0,
        );
      } catch (_) {
        return const TelemetryBudgetReservation(
          outcome: TelemetryBudgetReserveOutcome.storageReadFailed,
          usedLogBytes: 0,
          remainingLogBytes: 0,
        );
      }

      final remaining = (maxLogBytes - state.usedBytes).clamp(0, maxLogBytes);
      if (bytes > remaining ||
          exceptions > 0 &&
              (state.usedExceptions + exceptions > maxExceptions ||
                  state.usedMonthlyExceptions + exceptions > maxMonthlyExceptions)) {
        return TelemetryBudgetReservation(
          outcome: TelemetryBudgetReserveOutcome.limitExceeded,
          usedLogBytes: state.usedBytes,
          remainingLogBytes: remaining,
        );
      }

      final nextBytes = state.usedBytes + bytes;
      final encoded = jsonEncode({
        'day': state.day,
        'log_bytes': nextBytes,
        'exceptions': state.usedExceptions + exceptions,
        'month': state.month,
        'monthly_exceptions': state.usedMonthlyExceptions + exceptions,
      });
      try {
        // Persist before network I/O; failures and retries consume the budget.
        if (!await _write(encoded)) {
          return TelemetryBudgetReservation(
            outcome: TelemetryBudgetReserveOutcome.storageWriteFailed,
            usedLogBytes: state.usedBytes,
            remainingLogBytes: remaining,
          );
        }
      } catch (_) {
        return TelemetryBudgetReservation(
          outcome: TelemetryBudgetReserveOutcome.storageWriteFailed,
          usedLogBytes: state.usedBytes,
          remainingLogBytes: remaining,
        );
      }
      return TelemetryBudgetReservation(
        outcome: TelemetryBudgetReserveOutcome.reserved,
        usedLogBytes: nextBytes,
        remainingLogBytes: (maxLogBytes - nextBytes).clamp(0, maxLogBytes),
      );
    });
    _pending = result.then<void>((_) {});
    return result;
  }

  _BudgetState _readState() {
    final today = _now().toUtc().toIso8601String().substring(0, 10);
    final thisMonth = today.substring(0, 7);
    final stored = _read();
    if (stored == null) {
      return _BudgetState(day: today, month: thisMonth, usedBytes: 0, usedExceptions: 0, usedMonthlyExceptions: 0);
    }
    final value = jsonDecode(stored);
    if (value is! Map<String, dynamic> ||
        (value.length != 3 && value.length != 5) ||
        value['day'] is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value['day'] as String) ||
        value['log_bytes'] is! int ||
        value['exceptions'] is! int) {
      throw const FormatException('invalid telemetry budget');
    }
    final previousDay = value['day'] as String;
    final hasMonthlyCounters = value.length == 5;
    final previousMonth = hasMonthlyCounters ? value['month'] : previousDay.substring(0, 7);
    final previousMonthlyExceptions = hasMonthlyCounters ? value['monthly_exceptions'] : value['exceptions'];
    if (previousMonth is! String ||
        !RegExp(r'^\d{4}-\d{2}$').hasMatch(previousMonth) ||
        previousMonthlyExceptions is! int) {
      throw const FormatException('invalid telemetry budget');
    }

    // Clock rollback must not grant another daily or monthly allowance.
    final preserveDay = previousDay.compareTo(today) >= 0;
    final preserveMonth = previousMonth.compareTo(thisMonth) >= 0;
    final usedBytes = preserveDay ? value['log_bytes'] as int : 0;
    final usedExceptions = preserveDay ? value['exceptions'] as int : 0;
    final usedMonthlyExceptions = preserveMonth ? previousMonthlyExceptions : 0;
    if (usedBytes < 0 || usedExceptions < 0 || usedMonthlyExceptions < 0) {
      throw const FormatException('invalid telemetry budget');
    }
    return _BudgetState(
      day: preserveDay ? previousDay : today,
      month: preserveMonth ? previousMonth : thisMonth,
      usedBytes: usedBytes,
      usedExceptions: usedExceptions,
      usedMonthlyExceptions: usedMonthlyExceptions,
    );
  }
}
