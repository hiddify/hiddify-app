import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';
import 'package:hiddify/features/diagnostics/remote_diagnostic_subscription.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';

void main() {
  test('does not replay local history and exports each new event once across clear', () async {
    final journal = SafeDiagnosticJournal();
    void record() => journal.record(
      operation: DiagnosticOperation.connect,
      stage: DiagnosticStage.accepted,
      code: DiagnosticCode.started,
      operationId: journal.nextOperationId(),
    );
    record();
    await Future<void>.delayed(Duration.zero);
    final sent = <String>[];
    String? stored;
    final remote = BetterStackLogPrinter(
      endpoint: Uri.parse('https://s1.betterstackdata.com'),
      token: 'test',
      sessionId: '123e4567-e89b-42d3-a456-426614174000',
      version: 'PRIVATE_CANARY',
      buildNumber: 'PRIVATE_CANARY',
      budget: TelemetryBudget(read: () => stored, write: (value) async { stored = value; return true; }),
      autoFlush: false,
      post: (_, _, body) async { sent.add(body); return 202; },
    );
    final subscription = RemoteDiagnosticSubscription(journal, remote);
    await remote.flush();
    expect(sent, isEmpty);
    record();
    record();
    await Future<void>.delayed(Duration.zero);
    await remote.flush();
    final events = jsonDecode(sent.single) as List;
    expect(events.map((e) => e['sequence']), [2, 3]);
    expect(sent.single, isNot(contains('PRIVATE_CANARY')));
    journal.clear();
    record();
    await Future<void>.delayed(Duration.zero);
    await remote.flush();
    expect((jsonDecode(sent.last) as List).single['sequence'], 4);
    subscription.dispose();
    await remote.dispose();
    record();
    await Future<void>.delayed(Duration.zero);
    expect(remote.queuedCount, 0);
    journal.dispose();
  });
}
