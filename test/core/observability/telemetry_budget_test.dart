import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';

void main() {
  late String? stored;
  late DateTime now;
  TelemetryBudget budget({int bytes = 100, int exceptions = 2, int monthlyExceptions = 10}) => TelemetryBudget(
    read: () => stored,
    write: (value) async {
      stored = value;
      return true;
    },
    now: () => now,
    maxLogBytes: bytes,
    maxExceptions: exceptions,
    maxMonthlyExceptions: monthlyExceptions,
  );

  setUp(() {
    stored = null;
    now = DateTime.utc(2026, 10, 21);
  });

  test('byte and exception caps survive a new client and concurrent reservations', () async {
    final first = budget();
    final reservations = await Future.wait([first.reserveLogs(60), first.reserveLogs(60)]);
    expect(reservations.map((result) => result.outcome), [
      TelemetryBudgetReserveOutcome.reserved,
      TelemetryBudgetReserveOutcome.limitExceeded,
    ]);
    expect(reservations.first.remainingLogBytes, 40);
    expect(reservations.last.remainingLogBytes, 40);
    expect(await first.reserveException(), isTrue);
    final restarted = budget();
    expect((await restarted.reserveLogs(41)).outcome, TelemetryBudgetReserveOutcome.limitExceeded);
    expect(await restarted.reserveException(), isTrue);
    expect(await restarted.reserveException(), isFalse);
    expect((jsonDecode(stored!) as Map<String, dynamic>)['log_bytes'], 60);
  });

  test('UTC day rollover resets allowances but clock rollback does not', () async {
    final client = budget();
    expect((await client.reserveLogs(100)).outcome, TelemetryBudgetReserveOutcome.reserved);
    now = DateTime.utc(2026, 10, 20);
    expect((await client.reserveLogs(1)).outcome, TelemetryBudgetReserveOutcome.limitExceeded);
    now = DateTime.utc(2026, 10, 22);
    expect((await client.reserveLogs(100)).outcome, TelemetryBudgetReserveOutcome.reserved);
  });

  test('UTC month cap survives daily rollovers and resets in a new month', () async {
    final client = budget(exceptions: 1, monthlyExceptions: 3);
    expect(await client.reserveException(), isTrue);
    now = DateTime.utc(2026, 10, 22);
    expect(await client.reserveException(), isTrue);
    now = DateTime.utc(2026, 10, 23);
    expect(await client.reserveException(), isTrue);
    now = DateTime.utc(2026, 10, 24);
    expect(await client.reserveException(), isFalse);
    now = DateTime.utc(2026, 11);
    expect(await client.reserveException(), isTrue);
    final value = jsonDecode(stored!) as Map<String, dynamic>;
    expect(value['month'], '2026-11');
    expect(value['monthly_exceptions'], 1);
  });

  test('original day-only document migrates without granting extra exceptions', () async {
    stored = jsonEncode({'day': '2026-10-21', 'log_bytes': 10, 'exceptions': 1});
    final client = budget(monthlyExceptions: 3);
    expect(await client.reserveException(), isTrue);
    final value = jsonDecode(stored!) as Map<String, dynamic>;
    expect(value, {'day': '2026-10-21', 'log_bytes': 10, 'exceptions': 2, 'month': '2026-10', 'monthly_exceptions': 2});
  });

  test('legacy exception overage does not block the independent log budget', () async {
    stored = jsonEncode({'day': '2026-10-21', 'log_bytes': 10, 'exceptions': 50});
    final client = budget();
    expect((await client.reserveLogs(1)).outcome, TelemetryBudgetReserveOutcome.reserved);
    final value = jsonDecode(stored!) as Map<String, dynamic>;
    expect(value['log_bytes'], 11);
    expect(value['monthly_exceptions'], 50);
  });

  test('legacy log overage does not block the independent exception budget', () async {
    stored = jsonEncode({'day': '2026-10-21', 'log_bytes': 256 * 1024, 'exceptions': 0});
    final client = budget();
    expect(await client.reserveException(), isTrue);
    final value = jsonDecode(stored!) as Map<String, dynamic>;
    expect(value['log_bytes'], 256 * 1024);
    expect(value['exceptions'], 1);
  });

  test('clock rollback cannot reset the monthly exception counter', () async {
    final client = budget(monthlyExceptions: 1);
    expect(await client.reserveException(), isTrue);
    now = DateTime.utc(2026, 9, 30);
    expect(await client.reserveException(), isFalse);
  });

  test('default caps are conservative for free telemetry quotas', () {
    final client = TelemetryBudget(read: () => null, write: (_) async => true);
    expect(client.maxLogBytes, 64 * 1024);
    expect(client.maxExceptions, 1);
    expect(client.maxMonthlyExceptions, 10);
  });

  test('corrupt storage and failed persistence reject sending', () async {
    stored = '{invalid';
    expect((await budget().reserveLogs(1)).outcome, TelemetryBudgetReserveOutcome.invalidStoredState);
    stored = null;
    final failed = TelemetryBudget(read: () => null, write: (_) async => false);
    expect((await failed.reserveLogs(1)).outcome, TelemetryBudgetReserveOutcome.storageWriteFailed);
    final throwing = TelemetryBudget(read: () => throw StateError('unavailable'), write: (_) async => true);
    expect(await throwing.reserveException(), isFalse);
  });

  test('read-only log snapshot preserves legacy use without resetting it', () {
    stored = jsonEncode({
      'day': '2026-10-21',
      'log_bytes': 90 * 1024,
      'exceptions': 0,
      'month': '2026-10',
      'monthly_exceptions': 0,
    });
    final client = budget(bytes: 64 * 1024);
    expect(client.logSnapshot.usedLogBytes, 90 * 1024);
    expect(client.logSnapshot.remainingLogBytes, 0);
    expect(client.logSnapshot.outcome, TelemetryBudgetReserveOutcome.limitExceeded);
    expect((jsonDecode(stored!) as Map)['log_bytes'], 90 * 1024);
    now = DateTime.utc(2026, 10, 22);
    expect(client.logSnapshot.usedLogBytes, 0);
    expect(client.logSnapshot.remainingLogBytes, 64 * 1024);
  });

  test('read-only snapshot distinguishes corrupt and unavailable storage', () {
    stored = '{invalid';
    expect(budget().logSnapshot.outcome, TelemetryBudgetReserveOutcome.invalidStoredState);
    final unavailable = TelemetryBudget(read: () => throw StateError('unavailable'), write: (_) async => true);
    expect(unavailable.logSnapshot.outcome, TelemetryBudgetReserveOutcome.storageReadFailed);
  });

  test('no private events or credentials are persisted with counters', () async {
    await budget().reserveLogs(50);
    expect(
      (jsonDecode(stored!) as Map).keys,
      unorderedEquals(['day', 'log_bytes', 'exceptions', 'month', 'monthly_exceptions']),
    );
  });
}
