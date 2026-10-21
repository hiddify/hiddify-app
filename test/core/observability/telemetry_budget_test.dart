import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';

void main() {
  late String? stored;
  late DateTime now;
  TelemetryBudget budget({int bytes = 100, int exceptions = 2}) => TelemetryBudget(
    read: () => stored,
    write: (value) async {
      stored = value;
      return true;
    },
    now: () => now,
    maxLogBytes: bytes,
    maxExceptions: exceptions,
  );

  setUp(() {
    stored = null;
    now = DateTime.utc(2026, 10, 21);
  });

  test('byte and exception caps survive a new client and concurrent reservations', () async {
    final first = budget();
    expect(await Future.wait([first.reserveLogs(60), first.reserveLogs(60)]), [true, false]);
    expect(await first.reserveException(), isTrue);
    final restarted = budget();
    expect(await restarted.reserveLogs(41), isFalse);
    expect(await restarted.reserveException(), isTrue);
    expect(await restarted.reserveException(), isFalse);
    expect((jsonDecode(stored!) as Map<String, dynamic>)['log_bytes'], 60);
  });

  test('UTC day rollover resets allowances but clock rollback does not', () async {
    final client = budget();
    expect(await client.reserveLogs(100), isTrue);
    now = DateTime.utc(2026, 10, 20);
    expect(await client.reserveLogs(1), isFalse);
    now = DateTime.utc(2026, 10, 22);
    expect(await client.reserveLogs(100), isTrue);
  });

  test('corrupt storage and failed persistence reject sending', () async {
    stored = '{invalid';
    expect(await budget().reserveLogs(1), isFalse);
    stored = null;
    final failed = TelemetryBudget(read: () => null, write: (_) async => false);
    expect(await failed.reserveLogs(1), isFalse);
    final throwing = TelemetryBudget(read: () => throw StateError('unavailable'), write: (_) async => true);
    expect(await throwing.reserveException(), isFalse);
  });

  test('no private events or credentials are persisted with counters', () async {
    await budget().reserveLogs(50);
    expect((jsonDecode(stored!) as Map).keys, unorderedEquals(['day', 'log_bytes', 'exceptions']));
  });
}
