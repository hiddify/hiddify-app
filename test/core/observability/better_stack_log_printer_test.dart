import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';

void main() {
  late String? stored;
  late DateTime now;
  late List<String> sent;
  late BetterStackLogPrinter printer;
  late int response;

  SafeDiagnosticEvent record({bool failed = false}) => SafeDiagnosticEvent(
    sequence: 1,
    operationId: 1,
    operation: DiagnosticOperation.connect,
    stage: failed ? DiagnosticStage.failed : DiagnosticStage.accepted,
    code: failed ? DiagnosticCode.coreUnavailable : DiagnosticCode.started,
  );

  TelemetryBudget budget({int bytes = 256 * 1024}) => TelemetryBudget(
    read: () => stored,
    write: (value) async {
      stored = value;
      return true;
    },
    now: () => now,
    maxLogBytes: bytes,
  );

  setUp(() {
    stored = null;
    now = DateTime.utc(2026, 10, 21);
    sent = [];
    response = 202;
    printer = BetterStackLogPrinter(
      endpoint: Uri.parse('https://s1.us-west-2a.betterstackdata.com'),
      sessionId: '123e4567-e89b-42d3-a456-426614174000',
      token: 'write-only-test-token',
      budget: budget(),
      autoFlush: false,
      now: () => now,
      post: (endpoint, token, body) async {
        sent.add(body);
        return response;
      },
    );
  });

  tearDown(() => printer.dispose());

  test('exports only a typed journal event and safe build metadata', () async {
    printer.addDiagnostic(record());
    await printer.flush();
    final decoded = (jsonDecode(sent.single) as List).single as Map;
    expect(decoded['operation'], 'connect');
    expect(decoded['stage'], 'accepted');
    expect(decoded['code'], 'started');
    expect(decoded['schema'], 'blizzard-remote-diagnostics/v1');
    expect(decoded['app_version'], 'unknown');
    expect(decoded.keys.toSet(), {
      'sequence', 'operation_id', 'operation', 'stage', 'code', 'duration_ms',
      'reachability', 'schema', 'platform', 'environment', 'app_version',
      'build_number', 'session_id', 'dt', 'level', 'message',
    });
  });

  test('explicit test event is distinguishable from connection events', () async {
    expect(printer.addTestEvent(), isTrue);
    await printer.flush();
    final decoded = (jsonDecode(sent.single) as List).single as Map;
    expect(decoded['event'], 'test_event');
    expect(decoded['message'], 'test_event');
  });

  test('quota and credential responses disable sending and clear pending data', () async {
    response = 402;
    printer.addDiagnostic(record());
    await printer.flush();
    printer.addDiagnostic(record());
    await printer.flush();
    expect(sent.length, 1);
    expect(printer.active, isFalse);
    expect(printer.queuedCount, 0);
  });

  test('retryable responses have a bounded retry count and consume byte budget', () async {
    response = 503;
    printer.addDiagnostic(record());
    await printer.flush();
    await printer.flush();
    await printer.flush();
    await printer.flush();
    expect(sent.length, 3);
    expect(printer.queuedCount, 0);
    expect((jsonDecode(stored!) as Map<String, dynamic>)['log_bytes'], utf8.encode(sent.join()).length);
  });

  test('transport exceptions stay isolated and eventually discard the failed batch', () async {
    await printer.dispose();
    var attempts = 0;
    printer = BetterStackLogPrinter(
      endpoint: Uri.parse('https://s1.us-west-2a.betterstackdata.com'),
      sessionId: '123e4567-e89b-42d3-a456-426614174000',
      token: 'test',
      budget: budget(),
      autoFlush: false,
      post: (_, _, _) {
        attempts++;
        return Future.error(StateError('network unavailable'));
      },
    );
    printer.addDiagnostic(record());
    for (var i = 0; i < 4; i++) {
      await printer.flush();
    }
    expect(attempts, 3);
    expect(printer.queuedCount, 0);
  });

  test('repeated errors are throttled without using operation IDs as deduplication keys', () async {
    printer.addDiagnostic(record(failed: true));
    printer.addDiagnostic(record(failed: true));
    await printer.flush();
    expect((jsonDecode(sent.single) as List).length, 1);
    now = now.add(const Duration(minutes: 1));
    printer.addDiagnostic(record(failed: true));
    await printer.flush();
    expect(sent.length, 2);
  });

  test('offline queue and outgoing batches are bounded', () async {
    for (var i = 0; i < 150; i++) {
      printer.addDiagnostic(record());
    }
    expect(printer.queuedCount, BetterStackLogPrinter.maxQueueLength);
    await printer.flush();
    expect((jsonDecode(sent.single) as List).length, BetterStackLogPrinter.maxBatchLength);
    expect(printer.queuedCount, 80);
  });

  test('persisted daily cap prevents the network request', () async {
    await printer.dispose();
    printer = BetterStackLogPrinter(
      endpoint: Uri.parse('https://s1.us-west-2a.betterstackdata.com'),
      sessionId: '123e4567-e89b-42d3-a456-426614174000',
      token: 'test',
      budget: budget(bytes: 1),
      autoFlush: false,
      post: (_, _, body) async {
        sent.add(body);
        return 202;
      },
    );
    printer.addDiagnostic(record());
    await printer.flush();
    expect(sent, isEmpty);
    expect(printer.queuedCount, 0);
  });

  test('overlapping flushes send once and disposal stops future requests', () async {
    await printer.dispose();
    final completion = Completer<int>();
    printer = BetterStackLogPrinter(
      endpoint: Uri.parse('https://s1.us-west-2a.betterstackdata.com'),
      sessionId: '123e4567-e89b-42d3-a456-426614174000',
      token: 'test',
      budget: budget(),
      autoFlush: false,
      post: (_, _, body) {
        sent.add(body);
        return completion.future;
      },
    );
    printer.addDiagnostic(record());
    final first = printer.flush();
    final second = printer.flush();
    completion.complete(202);
    await Future.wait([first, second]);
    expect(sent.length, 1);
    await printer.dispose();
    printer.addDiagnostic(record());
    await printer.flush();
    expect(sent.length, 1);
  });

  test('only HTTPS Better Stack ingestion hosts are accepted', () {
    for (final url in [
      'http://s1.betterstackdata.com',
      'https://betterstackdata.com.attacker.invalid',
      'https://s1.betterstackdata.com?token=test',
      'https://test@s1.betterstackdata.com',
      'https://s1.betterstackdata.com:444',
      'https://s1.betterstackdata.com/path',
    ]) {
      expect(isBetterStackLogsEndpoint(Uri.parse(url)), isFalse, reason: url);
    }
  });
}
