import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/diagnostics/remote_ios_ping_subscription.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late IosPingTrace trace;
  late BetterStackLogPrinter remote;
  late List<Map<String, dynamic>> sent;
  late RemoteIosPingSubscription subscription;

  setUp(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    trace = IosPingTrace(elapsedMilliseconds: () => 42);
    sent = [];
    remote = BetterStackLogPrinter(
      endpoint: Uri.parse('https://s1.betterstackdata.com'),
      token: 'test-only',
      sessionId: '123e4567-e89b-42d3-a456-426614174000',
      version: '0.0.1',
      buildNumber: '21',
      budget: TelemetryBudget(read: () => null, write: (_) async => true),
      autoFlush: false,
      post: (_, _, body) async {
        sent.addAll((jsonDecode(body) as List).cast<Map<String, dynamic>>());
        return 202;
      },
    );
  });

  tearDown(() async {
    subscription.dispose();
    await remote.dispose();
    trace.dispose();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  test('exports the bounded startup trace then each new event once across clear', () async {
    trace.record(IosPingEvent.coreResumeQueued, operationId: 1);
    subscription = RemoteIosPingSubscription(trace, remote);
    trace.record(IosPingEvent.coreSetupStarted, operationId: 2);
    trace.record(IosPingEvent.coreResumeCompleted, operationId: 1);
    await Future<void>.delayed(Duration.zero);
    await remote.flush();
    final ping = sent.where((event) => event['operation'] == 'ios_ping');
    expect(ping.map((event) => event['sequence']), [1, 2, 3]);
    trace.clear();
    trace.record(IosPingEvent.measurementTimedOut, operationId: 3);
    await Future<void>.delayed(Duration.zero);
    await remote.flush();
    expect(sent.where((event) => event['operation'] == 'ios_ping').map((event) => event['sequence']), [1, 2, 3, 4]);
    expect(sent.map((event) => event['event_id']).toSet().length, sent.length);
  });

  test('records lifecycle changes once and sends pending diagnostics after resume', () async {
    subscription = RemoteIosPingSubscription(trace, remote);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    await remote.flush();
    expect(trace.snapshot.events.map((entry) => entry.event.name), [
      'appInactive',
      'appHidden',
      'appPaused',
      'appResumed',
    ]);
    expect(sent.map((event) => event['code']), contains('appResumed'));
  });

  test('disposing detaches both trace and lifecycle observers', () async {
    subscription = RemoteIosPingSubscription(trace, remote);
    subscription.dispose();
    trace.record(IosPingEvent.refreshTapped, operationId: 7);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await Future<void>.delayed(Duration.zero);
    await remote.flush();
    expect(sent, isEmpty);
    expect(trace.snapshot.events.map((entry) => entry.event), [IosPingEvent.refreshTapped]);
  });

  test('explicit cursor prevents replay of old and opted-out events on reenable', () async {
    trace.record(IosPingEvent.coreResumeQueued, operationId: 1);
    subscription = RemoteIosPingSubscription(trace, remote);
    await remote.flush();
    subscription.dispose();
    trace.record(IosPingEvent.refreshTapped, operationId: 2);
    await Future<void>.delayed(Duration.zero);
    final before = sent.length;
    subscription = RemoteIosPingSubscription(trace, remote, afterSequence: trace.snapshot.events.last.sequence);
    trace.record(IosPingEvent.refreshIssued, operationId: 3);
    await Future<void>.delayed(Duration.zero);
    await remote.flush();
    expect(sent.skip(before).map((event) => event['sequence']), [3]);
  });
}
