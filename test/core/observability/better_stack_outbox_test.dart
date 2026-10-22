import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';

void main() {
  const session = '123e4567-e89b-42d3-a456-426614174000';
  late String? outbox;
  late String? budgetState;
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
    Future<bool> Function(String)? writeOutbox,
    bool autoFlush = false,
  }) => BetterStackLogPrinter(
    endpoint: Uri.parse('https://s1.betterstackdata.com'),
    sessionId: session,
    token: 'test',
    version: '0.0.1',
    buildNumber: '19',
    budget: telemetryBudget ?? budget(),
    now: () => now,
    autoFlush: autoFlush,
    flushInterval: Duration.zero,
    readOutbox: () => outbox,
    writeOutbox:
        writeOutbox ??
        (value) async {
          outbox = value;
          return true;
        },
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
    await remote.dispose();

    remote = printer(post: unavailable);
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

  test('budget refusal persists without retry spin until next UTC day', () async {
    final dailyBudget = budget(bytes: 1000);
    expect(await dailyBudget.reserveLogs(1000), isTrue);
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
}
