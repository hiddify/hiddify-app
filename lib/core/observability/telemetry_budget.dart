import 'dart:convert';

/// Conservative per-installation caps, shared by all sessions and builds.
/// These complement Better Stack's account-wide quota; they cannot replace it.
final class TelemetryBudget {
  TelemetryBudget({
    required String? Function() read,
    required Future<bool> Function(String) write,
    DateTime Function()? now,
    this.maxLogBytes = 256 * 1024,
    this.maxExceptions = 50,
  }) : _read = read,
       _write = write,
       _now = now ?? DateTime.now;

  static const preferenceKey = 'betterstack_daily_budget_v1';
  final String? Function() _read;
  final Future<bool> Function(String) _write;
  final DateTime Function() _now;
  final int maxLogBytes;
  final int maxExceptions;
  Future<void> _pending = Future.value();

  Future<bool> reserveLogs(int bytes) => _reserve(bytes, 0);
  Future<bool> reserveException() => _reserve(0, 1);

  Future<bool> _reserve(int bytes, int exceptions) {
    final result = _pending.then((_) async {
      try {
        if (bytes < 0 || exceptions < 0) return false;
        final today = _now().toUtc().toIso8601String().substring(0, 10);
        final stored = _read();
        var day = today;
        var usedBytes = 0;
        var usedExceptions = 0;
        if (stored != null) {
          final value = jsonDecode(stored);
          if (value is! Map<String, dynamic> ||
              value['day'] is! String ||
              !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value['day'] as String) ||
              value['log_bytes'] is! int ||
              value['exceptions'] is! int) {
            return false;
          }
          final previousDay = value['day'] as String;
          // A clock rollback must not grant another daily allowance.
          if (previousDay.compareTo(today) >= 0) {
            day = previousDay;
            usedBytes = value['log_bytes'] as int;
            usedExceptions = value['exceptions'] as int;
          }
          if (usedBytes < 0 || usedExceptions < 0) return false;
        }
        if (usedBytes + bytes > maxLogBytes || usedExceptions + exceptions > maxExceptions) return false;
        // Persist before network I/O; failures and retries consume the budget too.
        return await _write(
          jsonEncode({'day': day, 'log_bytes': usedBytes + bytes, 'exceptions': usedExceptions + exceptions}),
        );
      } catch (_) {
        // Storage failure must neither flood telemetry nor affect the app.
        return false;
      }
    });
    _pending = result.then<void>((_) {});
    return result;
  }
}
