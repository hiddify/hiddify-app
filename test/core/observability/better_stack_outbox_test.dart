import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';
import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/core/observability/telemetry_transport_attempt.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';

void main() {
  const session = '123e4567-e89b-42d3-a456-426614174000';
  late String? outbox;
  late String? budgetState;
  late String? attemptReceipt;
  late String? testAttemptReceipt;
  late DateTime now;
  late List<String> sent;

  TelemetryBudget budget({int bytes = 1024 * 1024}) => TelemetryBudget(
    read: () => budgetState,
    write: (value) async {
      budgetState = value;
      return true;
    },
    now: () => now,
    maxLogBytes: bytes,
  );

  BetterStackLogPrinter printer({
    BetterStackPost? post,
    TelemetryBudget? telemetryBudget,
    RemoteOutboxRead? readOutbox,
    Future<bool> Function(String)? writeOutbox,
    RemoteAttemptRead? readLastAttempt,
    RemoteAttemptWrite? writeLastAttempt,
    RemoteAttemptRead? readLastTestAttempt,
    RemoteAttemptWrite? writeLastTestAttempt,
    BetterStackTimerFactory? createTimer,
    String sessionId = session,
    bool autoFlush = false,
  }) => BetterStackLogPrinter(
    endpoint: Uri.parse('https://s1.betterstackdata.com'),
    sessionId: sessionId,
    token: 'test',
    version: '0.0.1',
    buildNumber: '19',
    budget: telemetryBudget ?? budget(),
    now: () => now,
    autoFlush: autoFlush,
    flushInterval: Duration.zero,
    readOutbox: readOutbox ?? () => outbox,
    writeOutbox:
        writeOutbox ??
        (value) async {
          outbox = value;
          return true;
        },
    readLastAttempt: readLastAttempt ?? () => attemptReceipt,
    writeLastAttempt:
        writeLastAttempt ??
        (value) async {
          attemptReceipt = value;
          return true;
        },
    readLastTestAttempt: readLastTestAttempt ?? () => testAttemptReceipt,
    writeLastTestAttempt:
        writeLastTestAttempt ??
        (value) async {
          testAttemptReceipt = value;
          return true;
        },
    createTimer: createTimer,
    post:
        post ??
        (_, _, body) async {
          sent.add(body);
          return 202;
        },
  );

  SafeDiagnosticEvent diagnostic(int sequence) => SafeDiagnosticEvent(
    sequence: sequence,
    operationId: sequence,
    operation: DiagnosticOperation.connect,
    stage: DiagnosticStage.accepted,
    code: DiagnosticCode.started,
  );

  List<dynamic> persistedEvents() => (jsonDecode(outbox!) as Map)['events']! as List;

  setUp(() {
    outbox = null;
    budgetState = null;
    attemptReceipt = null;
    testAttemptReceipt = null;
    now = DateTime.utc(2026, 10, 22, 9);
    sent = [];
  });

  test('offline dispose and restart preserve original metadata before online delivery', () async {
    final offline = printer(post: (_, _, _) => Future.error(StateError('offline')));
    offline.addDiagnostic(diagnostic(1));
    await offline.flush();
    final original = ((jsonDecode(outbox!) as Map)['events'] as List).single as Map;
    final originalDt = original['dt'];
    final originalId = original['event_id'];
    await offline.dispose();

    now = now.add(const Duration(hours: 2));
    final online = printer();
    expect(online.queuedCount, 1);
    await online.flush();
    final replayed = (jsonDecode(sent.single) as List).single as Map;
    expect(replayed['dt'], originalDt);
    expect(replayed['event_id'], originalId);
    expect(replayed['session_id'], session);
    expect(persistedEvents(), isEmpty);
    await online.dispose();
  });

  test('clock rollback preserves a known safe future-stamped event', () async {
    var remote = printer();
    remote.addDiagnostic(diagnostic(1));
    await remote.dispose();

    now = now.subtract(const Duration(hours: 1));
    remote = printer();
    expect(remote.queuedCount, 1);
    await remote.flush();
    expect(sent, hasLength(1));
    await remote.dispose();
  });

  test('acknowledging an in-flight batch preserves a concurrent enqueue', () async {
    final response = Completer<int>();
    final remote = printer(
      post: (_, _, body) {
        sent.add(body);
        return response.future;
      },
    );
    remote.addDiagnostic(diagnostic(1));
    final flush = remote.flush();
    await Future<void>.delayed(Duration.zero);
    // A repeated typed event has the same stable ID; acknowledgement still
    // removes only the map that was part of the captured batch.
    remote.addDiagnostic(diagnostic(1));
    response.complete(202);
    await flush;
    expect(remote.queuedCount, 1);
    final persisted = ((jsonDecode(outbox!) as Map)['events'] as List).cast<Map>();
    expect(persisted.single['sequence'], 1);
    await remote.dispose();
  });

  test('an enqueue during persistence is not sent before its own durable copy', () async {
    final secondWriteStarted = Completer<void>();
    final releaseSecondWrite = Completer<bool>();
    final thirdWriteStarted = Completer<void>();
    final releaseThirdWrite = Completer<bool>();
    var writeCount = 0;
    Future<bool> controlledWrite(String value) async {
      writeCount++;
      if (writeCount == 1) {
        outbox = value;
        return true;
      }
      if (writeCount == 2) {
        secondWriteStarted.complete();
        final saved = await releaseSecondWrite.future;
        if (saved) outbox = value;
        return saved;
      }
      if (writeCount == 3) {
        thirdWriteStarted.complete();
        final saved = await releaseThirdWrite.future;
        if (saved) outbox = value;
        return saved;
      }
      outbox = value;
      return true;
    }

    final remote = printer(writeOutbox: controlledWrite);
    remote.addDiagnostic(diagnostic(1));
    await Future<void>.delayed(Duration.zero);
    final flush = remote.flush();
    await secondWriteStarted.future;
    remote.addDiagnostic(diagnostic(2));
    releaseSecondWrite.complete(true);
    await thirdWriteStarted.future;
    await Future<void>.delayed(Duration.zero);

    final batch = (jsonDecode(sent.single) as List).cast<Map<String, dynamic>>();
    final sentSequences = batch.map((event) => event['sequence']).toList();
    releaseThirdWrite.complete(false);
    await flush;
    expect(sentSequences, [1]);
    expect(remote.queuedCount, 1);
    await remote.dispose();
  });

  test('failed persistence prevents network I/O and retains the pending event', () async {
    final remote = printer(writeOutbox: (_) async => false);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    expect(sent, isEmpty);
    expect(remote.queuedCount, 1);
    await remote.dispose();
  });

  test('circuit breaker cooldown survives restart and requires expiry enqueue or explicit resume', () async {
    var attempts = 0;
    Future<int> unavailable(Uri _, String _, String _) async {
      attempts++;
      return 503;
    }

    var remote = printer(post: unavailable);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await remote.flush();
    await remote.flush();
    expect(attempts, 3);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.retryWaiting);
    expect(remote.deliveryStatus.nextAttemptAt, now.add(const Duration(minutes: 5)));
    await remote.dispose();

    remote = printer(post: unavailable);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.retryWaiting);
    expect(remote.deliveryStatus.nextAttemptAt, now.add(const Duration(minutes: 5)));
    await remote.flush();
    remote.addDiagnostic(diagnostic(2));
    await remote.flush();
    expect(attempts, 3);
    now = now.add(const Duration(minutes: 5));
    remote.addDiagnostic(diagnostic(3));
    await remote.flush();
    expect(attempts, 4);
    await remote.dispose();

    remote = printer(post: unavailable);
    await remote.resumePending();
    expect(attempts, 5);
    await remote.dispose();
  });

  test('three failures wake once after cooldown without a new enqueue', () async {
    var requests = 0;
    final timers = <_ManualTimer>[];
    final remote = printer(
      autoFlush: true,
      createTimer: (delay, callback) {
        final timer = _ManualTimer(delay, callback);
        timers.add(timer);
        return timer;
      },
      post: (_, _, _) async {
        requests++;
        return 503;
      },
    );
    remote.addDiagnostic(diagnostic(1));
    for (var i = 0; i < 3; i++) {
      await remote.flush();
    }
    final cooldown = timers.last;
    expect(requests, 3);
    expect(cooldown.delay, const Duration(minutes: 5));
    expect(remote.deliveryStatus.nextAttemptAt, now.add(const Duration(minutes: 5)));

    now = now.add(const Duration(minutes: 5));
    cooldown.fire();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(requests, 4);
    await remote.dispose();
  });

  test('manual test preserves exhausted retry cooldown without another request', () async {
    var requests = 0;
    final remote = printer(
      post: (_, _, _) async {
        requests++;
        return 503;
      },
    );
    remote.addDiagnostic(diagnostic(1));
    for (var i = 0; i < 3; i++) {
      await remote.flush();
    }
    final nextAttempt = remote.deliveryStatus.nextAttemptAt;
    final result = await remote.sendTestEvent();
    expect(requests, 3);
    expect(result.outcome, TelemetryTestOutcome.pending);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.retryWaiting);
    expect(remote.deliveryStatus.nextAttemptAt, nextAttempt);
    await remote.dispose();
  });

  test('manual test preserves an existing daily budget block', () async {
    final dailyBudget = budget(bytes: 1000);
    await dailyBudget.reserveLogs(1000);
    final remote = printer(telemetryBudget: dailyBudget);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.budgetLimited);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetLimited);
    expect(remote.deliveryStatus.nextAttemptAt, DateTime.utc(2026, 10, 23));
    expect(sent, isEmpty);
    expect(remote.deliveryStatus.budgetUsedBytes, 1000);
    await remote.dispose();
  });

  test('budget refusal persists without retry spin until next UTC day', () async {
    final dailyBudget = budget(bytes: 1000);
    expect((await dailyBudget.reserveLogs(1000)).outcome, TelemetryBudgetReserveOutcome.reserved);
    final remote = printer(telemetryBudget: dailyBudget, autoFlush: true);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(sent, isEmpty);
    expect(remote.queuedCount, 1);
    now = now.add(const Duration(days: 1));
    await remote.flush();
    expect(sent, hasLength(1));
    await remote.dispose();
  });

  test('persisted same-day budget blocker is removed when upgraded remainder fits FIFO', () async {
    var remote = printer(telemetryBudget: budget(bytes: 1));
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await remote.dispose();
    expect((jsonDecode(outbox!) as Map)['budget_blocked_day'], '2026-10-22');

    budgetState = jsonEncode({
      'day': '2026-10-22',
      'log_bytes': 74880,
      'exceptions': 0,
      'month': '2026-10',
      'monthly_exceptions': 0,
    });
    remote = printer(
      telemetryBudget: TelemetryBudget(
        read: () => budgetState,
        write: (value) async {
          budgetState = value;
          return true;
        },
        now: () => now,
      ),
    );
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.pending);
    await remote.flush();
    expect(sent, hasLength(1));
    expect((jsonDecode(budgetState!) as Map)['log_bytes'], 74880 + utf8.encode(sent.single).length);
    await remote.dispose();
  });

  test('persisted same-day budget blocker remains when first FIFO event does not fit', () async {
    var remote = printer(telemetryBudget: budget(bytes: 1));
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await remote.dispose();

    budgetState = jsonEncode({
      'day': '2026-10-22',
      'log_bytes': 256 * 1024 - 1,
      'exceptions': 0,
      'month': '2026-10',
      'monthly_exceptions': 0,
    });
    remote = printer(
      telemetryBudget: TelemetryBudget(
        read: () => budgetState,
        write: (value) async {
          budgetState = value;
          return true;
        },
        now: () => now,
      ),
    );
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetLimited);
    await remote.flush();
    expect(sent, isEmpty);
    expect((jsonDecode(budgetState!) as Map)['log_bytes'], 256 * 1024 - 1);
    await remote.dispose();
  });

  test('UTC rollover timer resumes a budget-blocked queue without a new enqueue', () async {
    final dailyBudget = budget(bytes: 1000);
    expect((await dailyBudget.reserveLogs(1000)).outcome, TelemetryBudgetReserveOutcome.reserved);
    var remote = printer(telemetryBudget: dailyBudget);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await remote.dispose();

    final timers = <_ManualTimer>[];
    remote = printer(
      telemetryBudget: budget(bytes: 1000),
      autoFlush: true,
      createTimer: (delay, callback) {
        final timer = _ManualTimer(delay, callback);
        timers.add(timer);
        return timer;
      },
    );
    final rollover = timers.single;
    expect(rollover.delay, const Duration(hours: 15));
    now = DateTime.utc(2026, 10, 23);
    rollover.fire();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(sent, hasLength(1));
    await remote.dispose();
  });

  test('clock rollback keeps future budget blocker and schedules its next UTC boundary', () async {
    var remote = printer(telemetryBudget: budget(bytes: 1));
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await remote.dispose();

    now = DateTime.utc(2026, 10, 21, 9);
    final timers = <_ManualTimer>[];
    remote = printer(
      telemetryBudget: budget(bytes: 1),
      autoFlush: true,
      createTimer: (delay, callback) {
        final timer = _ManualTimer(delay, callback);
        timers.add(timer);
        return timer;
      },
    );
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetLimited);
    expect(remote.deliveryStatus.nextAttemptAt, DateTime.utc(2026, 10, 23));
    expect(timers.single.delay, const Duration(hours: 39));
    expect(sent, isEmpty);
    await remote.dispose();
  });

  test('legacy same-day 90 KiB use waits without reset then resumes next UTC day', () async {
    budgetState = jsonEncode({
      'day': '2026-10-22',
      'log_bytes': 90 * 1024,
      'exceptions': 0,
      'month': '2026-10',
      'monthly_exceptions': 0,
    });
    final dailyBudget = TelemetryBudget(
      read: () => budgetState,
      write: (value) async {
        budgetState = value;
        return true;
      },
      now: () => now,
      maxLogBytes: 64 * 1024,
    );
    final remote = printer(telemetryBudget: dailyBudget);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    expect(sent, isEmpty);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetLimited);
    expect((jsonDecode(budgetState!) as Map)['log_bytes'], 90 * 1024);

    now = now.add(const Duration(days: 1));
    await remote.flush();
    expect(sent, hasLength(1));
    expect((jsonDecode(budgetState!) as Map)['log_bytes'], utf8.encode(sent.single).length);
    await remote.dispose();
  });

  test('corrupt private or unknown persisted events are rejected without sending', () async {
    for (final value in [
      '{invalid',
      jsonEncode({
        'schema': 'blizzard-remote-outbox/v1',
        'events': [
          {
            'sequence': 1,
            'operation_id': 1,
            'operation': 'ios_ping',
            'stage': 'state',
            'code': 'refreshTapped',
            'elapsed_ms': 0,
            'reachability': 'not_checked',
            'schema': 'blizzard-remote-diagnostics/v1',
            'platform': 'ios',
            'environment': 'beta',
            'app_version': 'PRIVATE_CANARY',
            'build_number': '19',
            'session_id': session,
            'dt': now.toIso8601String(),
            'event_id': '0000000000000000',
            'level': 'info',
            'message': 'ios_ping.state.refreshTapped',
            'private': 'PRIVATE_CANARY',
          },
        ],
        'retry_count': 0,
        'paused_until': null,
        'budget_blocked_day': null,
        'dropped_count': 0,
      }),
    ]) {
      outbox = value;
      final remote = printer();
      expect(remote.queuedCount, 0);
      await remote.flush();
      expect(sent, isEmpty);
      await remote.dispose();
    }
  });

  test('restore failures stay observable through empty repair and recover after a real save', () async {
    for (final readOutbox in <RemoteOutboxRead>[() => '{invalid', () => throw StateError('PRIVATE_STORAGE_ERROR')]) {
      final remote = printer(readOutbox: readOutbox);
      expect(remote.deliveryStatus.state, TelemetryDeliveryState.outboxStorageFailed);

      await Future<void>.delayed(Duration.zero);
      expect(remote.deliveryStatus.state, TelemetryDeliveryState.outboxStorageFailed);

      remote.addDiagnostic(diagnostic(1));
      await remote.flush();
      expect(remote.deliveryStatus.state, TelemetryDeliveryState.accepted);
      expect(sent, hasLength(1));
      await remote.dispose();
      sent.clear();
    }
  });

  test('expired events are dropped and queue document stays within both caps', () async {
    var remote = printer();
    for (var i = 1; i <= 150; i++) {
      remote.addIosPingEvent(
        IosPingTraceEntry(sequence: i, event: IosPingEvent.refreshTapped, operationId: i, elapsedMilliseconds: i),
      );
    }
    await remote.dispose();
    expect(utf8.encode(outbox!).length, lessThanOrEqualTo(BetterStackLogPrinter.maxOutboxBytes));
    final document = jsonDecode(outbox!) as Map;
    expect((document['events'] as List).length, lessThanOrEqualTo(BetterStackLogPrinter.maxQueueLength));
    expect(document['dropped_count'], greaterThan(0));

    now = now.add(const Duration(hours: 25));
    remote = printer();
    expect(remote.queuedCount, 0);
    await remote.dispose();
  });

  test('explicit disable clears persisted events while ordinary dispose preserves them', () async {
    var remote = printer();
    remote.addDiagnostic(diagnostic(1));
    await remote.dispose();
    expect(persistedEvents(), hasLength(1));
    remote = printer();
    await remote.dispose(clearPending: true);
    expect(persistedEvents(), isEmpty);
  });

  test('credential rejection clears persisted queue including concurrent events', () async {
    final response = Completer<int>();
    final remote = printer(
      post: (_, _, body) {
        sent.add(body);
        return response.future;
      },
    );
    remote.addDiagnostic(diagnostic(1));
    final flush = remote.flush();
    await Future<void>.delayed(Duration.zero);
    remote.addDiagnostic(diagnostic(2));
    response.complete(401);
    await flush;
    expect(remote.active, isFalse);
    expect(remote.queuedCount, 0);
    expect(persistedEvents(), isEmpty);
    await remote.dispose();
  });

  test('async test result is accepted only for its exact 2xx batch', () async {
    final firstResponse = Completer<int>();
    final remote = printer(
      post: (_, _, body) {
        sent.add(body);
        return sent.length == 1 ? firstResponse.future : Future.value(202);
      },
    );
    remote.addDiagnostic(diagnostic(1));
    final firstFlush = remote.flush();
    await Future<void>.delayed(Duration.zero);

    final testResult = remote.sendTestEvent();
    await Future<void>.delayed(Duration.zero);
    firstResponse.complete(202);
    await firstFlush;
    expect((await testResult).outcome, TelemetryTestOutcome.persisted);
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.persisted);
    expect(remote.deliveryStatus.lastAttempt?.testEventId, isNull);
    expect(remote.deliveryStatus.lastAttempt?.ackOwnEvent, isNull);

    await remote.flush();
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.accepted);
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.accepted);
    expect(remote.deliveryStatus.lastAttempt?.testEventId, isNotNull);
    expect(remote.deliveryStatus.lastAttempt?.ackOwnEvent, isTrue);
    expect(sent, hasLength(2));
    await remote.dispose();
  });

  test('accepted test receipt survives an ordinary send and restart', () async {
    var remote = printer();
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.accepted);
    await Future<void>.delayed(Duration.zero);
    final saved = TelemetryTransportAttempt.decode(testAttemptReceipt!);
    expect(saved.outcome, TelemetryTransportOutcome.http);
    expect(saved.httpCode, 202);
    expect(saved.ackOwnEvent, isTrue);
    expect(saved.appVersion, '0.0.1');
    expect(saved.buildNumber, '19');
    expect(saved.toJson().keys, isNot(contains('hostname')));
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await Future<void>.delayed(Duration.zero);
    expect(TelemetryTransportAttempt.decode(attemptReceipt!).testEventId, isNull);
    expect(TelemetryTransportAttempt.decode(testAttemptReceipt!), saved);
    await remote.dispose();

    remote = printer(sessionId: '223e4567-e89b-42d3-a456-426614174000');
    expect(remote.deliveryStatus.lastAttempt?.testEventId, isNull);
    expect(remote.deliveryStatus.lastTestAttempt, saved);
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.accepted);
    expect(remote.deliveryStatus.pendingCount, 0);
    expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.persisted);
    await remote.dispose();
  });

  test('rejected test receipt survives an ordinary send and restart', () async {
    var requests = 0;
    var remote = printer(post: (_, _, _) async => requests++ == 0 ? 422 : 202);
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.rejected);
    await Future<void>.delayed(Duration.zero);
    final saved = TelemetryTransportAttempt.decode(testAttemptReceipt!);
    expect(saved.httpCode, 422);
    expect(saved.ackOwnEvent, isFalse);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await Future<void>.delayed(Duration.zero);
    expect(TelemetryTransportAttempt.decode(attemptReceipt!).testEventId, isNull);
    expect(TelemetryTransportAttempt.decode(testAttemptReceipt!), saved);
    await remote.dispose();

    remote = printer(sessionId: '223e4567-e89b-42d3-a456-426614174000');
    expect(remote.deliveryStatus.lastTestAttempt, saved);
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.rejected);
    await remote.dispose();
  });

  test('attempt storage failures are visible but never block the network', () async {
    final remote = printer(writeLastAttempt: (_) async => false);
    final result = await remote.sendTestEvent();
    await Future<void>.delayed(Duration.zero);
    expect(result.outcome, TelemetryTestOutcome.accepted);
    expect(sent, hasLength(1));
    expect(remote.deliveryStatus.attemptStorageState, TelemetryAttemptStorageState.failed);
    await remote.dispose();
  });

  test('test receipt storage failure remains visible after an ordinary successful send', () async {
    final remote = printer(writeLastTestAttempt: (_) async => false);
    expect((await remote.sendTestEvent()).outcome, TelemetryTestOutcome.accepted);
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    await Future<void>.delayed(Duration.zero);
    expect(sent, hasLength(2));
    expect(remote.deliveryStatus.attemptStorageState, TelemetryAttemptStorageState.persisted);
    expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.failed);
    expect(remote.deliveryStatus.lastTestAttempt?.testEventId, isNotNull);
    await remote.dispose();
  });

  test('newer general own-test receipt wins when dedicated test storage is stale', () async {
    var rejectNext = false;
    var failTestWrites = false;
    Future<bool> writeTestAttempt(String value) async {
      if (failTestWrites) return false;
      testAttemptReceipt = value;
      return true;
    }

    var remote = printer(writeLastTestAttempt: writeTestAttempt, post: (_, _, _) async => rejectNext ? 422 : 202);
    expect((await remote.sendTestEvent()).outcome, TelemetryTestOutcome.accepted);
    await Future<void>.delayed(Duration.zero);
    final accepted = TelemetryTransportAttempt.decode(testAttemptReceipt!);

    now = now.add(const Duration(minutes: 1));
    rejectNext = true;
    failTestWrites = true;
    expect((await remote.sendTestEvent()).outcome, TelemetryTestOutcome.rejected);
    await Future<void>.delayed(Duration.zero);
    final rejected = TelemetryTransportAttempt.decode(attemptReceipt!);
    expect(rejected.testEventId, isNot(accepted.testEventId));
    expect(rejected.httpCode, 422);
    expect(TelemetryTransportAttempt.decode(testAttemptReceipt!), accepted);
    await remote.dispose();

    remote = printer(sessionId: '223e4567-e89b-42d3-a456-426614174000', writeLastTestAttempt: writeTestAttempt);
    await Future<void>.delayed(Duration.zero);
    expect(remote.deliveryStatus.lastTestAttempt, rejected);
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.rejected);
    expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.failed);
    await remote.dispose();
  });

  test('after-request general receipt wins over stale before-request test receipt', () async {
    var testWrites = 0;
    Future<bool> writeTestAttempt(String value) async {
      testWrites++;
      if (testWrites > 1) return false;
      testAttemptReceipt = value;
      return true;
    }

    var remote = printer(writeLastTestAttempt: writeTestAttempt);
    expect((await remote.sendTestEvent()).outcome, TelemetryTestOutcome.accepted);
    await Future<void>.delayed(Duration.zero);
    final completed = TelemetryTransportAttempt.decode(attemptReceipt!);
    final stale = TelemetryTransportAttempt.decode(testAttemptReceipt!);
    expect(completed.testEventId, stale.testEventId);
    expect(completed.stage, TelemetryTransportStage.afterRequest);
    expect(stale.stage, TelemetryTransportStage.beforeRequest);
    await remote.dispose();

    remote = printer(sessionId: '223e4567-e89b-42d3-a456-426614174000', writeLastTestAttempt: (_) async => false);
    await Future<void>.delayed(Duration.zero);
    expect(remote.deliveryStatus.lastTestAttempt, completed);
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.accepted);
    expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.failed);
    await remote.dispose();
  });

  test('equal-time different test IDs keep and repair the general receipt', () async {
    final general = TelemetryTransportAttempt(
      attemptedAt: now,
      testEventId: '1111111111111111',
      appVersion: '0.0.1',
      buildNumber: '19',
      stage: TelemetryTransportStage.afterRequest,
      outcome: TelemetryTransportOutcome.http,
      httpCode: 202,
      ackOwnEvent: true,
    );
    final dedicated = TelemetryTransportAttempt(
      attemptedAt: now,
      testEventId: '2222222222222222',
      appVersion: '0.0.1',
      buildNumber: '19',
      stage: TelemetryTransportStage.afterRequest,
      outcome: TelemetryTransportOutcome.http,
      httpCode: 422,
      ackOwnEvent: false,
    );
    attemptReceipt = general.encode();
    testAttemptReceipt = dedicated.encode();

    final remote = printer();
    expect(remote.deliveryStatus.lastTestAttempt, general);
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.accepted);
    expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.pending);
    await Future<void>.delayed(Duration.zero);
    expect(TelemetryTransportAttempt.decode(testAttemptReceipt!), general);
    expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.persisted);
    await remote.dispose();
  });

  test('missing or corrupt dedicated receipt is repaired from the general receipt', () async {
    final general = TelemetryTransportAttempt(
      attemptedAt: now,
      testEventId: '1111111111111111',
      appVersion: '0.0.1',
      buildNumber: '19',
      stage: TelemetryTransportStage.afterRequest,
      outcome: TelemetryTransportOutcome.http,
      httpCode: 202,
      ackOwnEvent: true,
    );
    attemptReceipt = general.encode();

    for (final stored in <String?>[null, '{bad']) {
      testAttemptReceipt = stored;
      final remote = printer();
      expect(remote.deliveryStatus.lastTestAttempt, general);
      expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.pending);
      await Future<void>.delayed(Duration.zero);
      expect(TelemetryTransportAttempt.decode(testAttemptReceipt!), general);
      expect(remote.deliveryStatus.testAttemptStorageState, TelemetryAttemptStorageState.persisted);
      await remote.dispose();
    }
  });

  test('hanging attempt storage leaves a pending warning without blocking HTTP', () async {
    final hangingWrite = Completer<bool>();
    final remote = printer(writeLastAttempt: (_) => hangingWrite.future);
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.accepted);
    expect(sent, hasLength(1));
    expect(remote.deliveryStatus.attemptStorageState, TelemetryAttemptStorageState.pending);
    var disposeCompleted = false;
    final disposing = remote.dispose().whenComplete(() => disposeCompleted = true);
    await Future<void>.delayed(Duration.zero);
    expect(disposeCompleted, isFalse);
    hangingWrite.complete(true);
    await disposing;
  });

  test('dispose drains receipt writes before the caller clears their keys', () async {
    final releaseWrites = Completer<void>();
    Future<bool> writeAttempt(String value) async {
      await releaseWrites.future;
      attemptReceipt = value;
      return true;
    }

    Future<bool> writeTestAttempt(String value) async {
      await releaseWrites.future;
      testAttemptReceipt = value;
      return true;
    }

    final remote = printer(writeLastAttempt: writeAttempt, writeLastTestAttempt: writeTestAttempt);
    expect((await remote.sendTestEvent()).outcome, TelemetryTestOutcome.accepted);
    expect(sent, hasLength(1));

    var disposeCompleted = false;
    final cleared = remote.dispose(clearPending: true).then((_) {
      disposeCompleted = true;
      attemptReceipt = null;
      testAttemptReceipt = null;
    });
    await Future<void>.delayed(Duration.zero);
    expect(disposeCompleted, isFalse);

    releaseWrites.complete();
    await cleared;
    await Future<void>.delayed(Duration.zero);
    expect(attemptReceipt, isNull);
    expect(testAttemptReceipt, isNull);
  });

  test('bad attempt storage is isolated from compatible old outbox restore', () async {
    var remote = printer();
    remote.addDiagnostic(diagnostic(1));
    await remote.dispose();

    remote = printer(readLastAttempt: () => '{bad');
    expect(remote.queuedCount, 1);
    expect(remote.deliveryStatus.attemptStorageState, TelemetryAttemptStorageState.failed);
    await remote.flush();
    expect(sent, hasLength(1));
    await remote.dispose();
  });

  test('transport failures persist only their closed category', () async {
    final cases = <(Object, TelemetryTransportOutcome)>[
      (TimeoutException('PRIVATE_TIMEOUT'), TelemetryTransportOutcome.timeout),
      (SocketException('PRIVATE_NETWORK'), TelemetryTransportOutcome.network),
      (HandshakeException('PRIVATE_TLS'), TelemetryTransportOutcome.tls),
      (StateError('PRIVATE_OTHER'), TelemetryTransportOutcome.other),
    ];
    for (final (error, expected) in cases) {
      outbox = null;
      budgetState = null;
      attemptReceipt = null;
      final remote = printer(post: (_, _, _) => Future<int>.error(error));
      final result = await remote.sendTestEvent();
      await Future<void>.delayed(Duration.zero);
      expect(result.outcome, TelemetryTestOutcome.pending);
      final receipt = TelemetryTransportAttempt.decode(attemptReceipt!);
      expect(receipt.outcome, expected);
      expect(receipt.httpCode, isNull);
      expect(receipt.ackOwnEvent, isFalse);
      expect(attemptReceipt, isNot(contains('PRIVATE_')));
      await remote.dispose();
    }
  });

  test('dispose cancels the single pending wake timer', () async {
    final timers = <_ManualTimer>[];
    final remote = printer(
      autoFlush: true,
      createTimer: (delay, callback) {
        final timer = _ManualTimer(delay, callback);
        timers.add(timer);
        return timer;
      },
    );
    remote.addDiagnostic(diagnostic(1));
    expect(timers.single.isActive, isTrue);
    await remote.dispose();
    expect(timers.single.isActive, isFalse);
    timers.single.fire();
    await Future<void>.delayed(Duration.zero);
    expect(sent, isEmpty);
  });

  test('overlapping manual test requests share one exact result and one event', () async {
    final response = Completer<int>();
    final requestStarted = Completer<void>();
    final remote = printer(
      post: (_, _, body) {
        sent.add(body);
        requestStarted.complete();
        return response.future;
      },
    );

    final first = remote.sendTestEvent();
    await requestStarted.future;
    final second = remote.sendTestEvent();

    expect(identical(first, second), isTrue);
    expect(remote.queuedCount, 1);
    response.complete(202);
    final firstResult = await first;
    final secondResult = await second;
    expect(firstResult.outcome, TelemetryTestOutcome.accepted);
    expect(secondResult.outcome, TelemetryTestOutcome.accepted);
    expect(sent, hasLength(1));
    expect(jsonDecode(sent.single) as List, hasLength(1));
    await remote.dispose();
  });

  test('status stream exposes queue budget retry and safe request outcomes', () async {
    final updates = <TelemetryDeliveryStatus>[];
    final remote = printer(
      post: (_, _, body) async {
        sent.add(body);
        return 503;
      },
    );
    final subscription = remote.deliveryStatuses.listen(updates.add);
    final result = await remote.sendTestEvent();

    expect(result.outcome, TelemetryTestOutcome.pending);
    expect(remote.deliveryStatus.pendingCount, 1);
    expect(remote.deliveryStatus.oldestPendingAgeSeconds, 0);
    expect(remote.deliveryStatus.budgetUsedBytes, greaterThan(0));
    expect(remote.deliveryStatus.budgetRemainingBytes, lessThan(1024 * 1024));
    expect(remote.deliveryStatus.lastAttemptAt, now);
    expect(remote.deliveryStatus.lastHttpCode, 503);
    expect(updates.map((status) => status.state), contains(TelemetryDeliveryState.sending));
    expect(updates.map((status) => status.state), contains(TelemetryDeliveryState.retryWaiting));
    await subscription.cancel();
    await remote.dispose();
  });

  test('budget corruption and budget persistence failure are not day-cap pauses', () async {
    budgetState = '{invalid';
    var remote = printer();
    var result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.budgetStateInvalid);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetStateInvalid);
    expect(remote.deliveryStatus.nextAttemptAt, isNull);
    expect(sent, isEmpty);
    result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.budgetStateInvalid);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetStateInvalid);
    await remote.dispose();

    budgetState = null;
    var failBudgetWrite = true;
    final failingBudget = TelemetryBudget(
      read: () => budgetState,
      write: (value) async {
        if (failBudgetWrite) return false;
        budgetState = value;
        return true;
      },
      now: () => now,
      maxLogBytes: 1024 * 1024,
    );
    remote = printer(telemetryBudget: failingBudget);
    result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.budgetStorageFailed);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetStorageFailed);
    expect(remote.deliveryStatus.nextAttemptAt, isNull);
    expect(sent, isEmpty);

    result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.budgetStorageFailed);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetStorageFailed);
    expect(sent, isEmpty);

    failBudgetWrite = false;
    await remote.resumePending();
    expect(sent, hasLength(1));
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.accepted);
    await remote.dispose();
  });

  test('manual test preserves an existing budget write failure without another write', () async {
    var writes = 0;
    final failingBudget = TelemetryBudget(
      read: () => null,
      write: (_) async {
        writes++;
        return false;
      },
      now: () => now,
    );
    final remote = printer(telemetryBudget: failingBudget);
    await remote.sendTestEvent();
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.budgetStorageFailed);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetStorageFailed);
    expect(writes, 1);
    expect(sent, isEmpty);
    await remote.dispose();
  });

  test('near the daily cap sends the exact serialized FIFO prefix that fits', () async {
    var remote = printer();
    remote.addDiagnostic(diagnostic(1));
    await remote.flush();
    final oneEventBytes = utf8.encode(sent.single).length;
    await remote.dispose();

    outbox = null;
    budgetState = null;
    sent = [];
    remote = printer(telemetryBudget: budget(bytes: oneEventBytes));
    remote.addDiagnostic(diagnostic(1));
    remote.addDiagnostic(diagnostic(2));
    await remote.flush();

    final delivered = (jsonDecode(sent.single) as List).cast<Map<String, dynamic>>();
    expect(delivered.map((event) => event['sequence']), [1]);
    expect(utf8.encode(sent.single).length, oneEventBytes);
    expect(remote.queuedCount, 1);
    expect(remote.deliveryStatus.budgetRemainingBytes, 0);
    await remote.dispose();
  });

  test('too-small daily remainder retains the FIFO event without HTTP', () async {
    final remote = printer(telemetryBudget: budget(bytes: 1));
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.budgetLimited);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.budgetLimited);
    expect(remote.deliveryStatus.pendingCount, 1);
    expect(remote.deliveryStatus.nextAttemptAt, DateTime.utc(2026, 10, 23));
    expect(sent, isEmpty);
    await remote.dispose();
  });

  test('other 4xx is a terminal rejected test outcome, never accepted', () async {
    final remote = printer(
      post: (_, _, body) async {
        sent.add(body);
        return 422;
      },
    );
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.rejected);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.rejected);
    expect(remote.deliveryStatus.lastHttpCode, 422);
    expect(remote.queuedCount, 0);
    await remote.dispose();
  });

  test('tracked test ends as dropped when TTL or queue bounds remove it', () async {
    var remote = printer(telemetryBudget: budget(bytes: 1));
    expect(remote.addTestEvent(), isTrue);
    now = now.add(const Duration(hours: 25));
    await remote.flush();
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.droppedExpired);
    await remote.dispose();

    now = DateTime.utc(2026, 10, 22, 9);
    outbox = null;
    budgetState = null;
    remote = printer(telemetryBudget: budget(bytes: 1));
    expect(remote.addTestEvent(), isTrue);
    for (var sequence = 1; sequence <= BetterStackLogPrinter.maxQueueLength; sequence++) {
      remote.addDiagnostic(diagnostic(sequence));
    }
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.droppedOverflow);
    expect(remote.queuedCount, BetterStackLogPrinter.maxQueueLength);
    await remote.dispose();
  });

  test('outbox storage failure recovers on explicit resume without a day pause', () async {
    var failOutboxWrite = true;
    final remote = printer(
      writeOutbox: (value) async {
        if (failOutboxWrite) return false;
        outbox = value;
        return true;
      },
    );
    final result = await remote.sendTestEvent();
    expect(result.outcome, TelemetryTestOutcome.outboxStorageFailed);
    expect(remote.deliveryStatus.state, TelemetryDeliveryState.outboxStorageFailed);
    expect(remote.deliveryStatus.nextAttemptAt, isNull);
    expect(sent, isEmpty);

    failOutboxWrite = false;
    await remote.resumePending();
    expect(sent, hasLength(1));
    expect(remote.deliveryStatus.lastTestOutcome, TelemetryTestOutcome.accepted);
    await remote.dispose();
  });
}

final class _ManualTimer implements Timer {
  _ManualTimer(this.delay, this._callback);

  final Duration delay;
  final void Function() _callback;
  bool _active = true;
  int _tick = 0;

  void fire() {
    if (!_active) return;
    _active = false;
    _tick = 1;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;
}
