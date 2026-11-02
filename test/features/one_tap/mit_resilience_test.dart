import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/one_tap/mit_resilience.dart';

void main() {
  final start = DateTime(2026);
  const online = MitVpnEnvironment(networkAvailable: true, permissionGranted: true, stopEpoch: 7);
  MitRecoveryPlan plan() => MitRecoveryPlan()..start(7);
  String? poll(MitRecoveryPlan p, int second, {ConnectionStatus status = const Disconnected(),
    MitVpnEnvironment environment = online, String current = 'primary', List<String> backups = const ['backup-a', 'backup-b']}) =>
      p.next(now: start.add(Duration(seconds: second)), status: status, environment: environment,
        currentProfile: current, backups: backups);

  test('retries only after grace, with backoff and ordered explicitly selected backups', () {
    final p = plan();
    expect(poll(p, 0), isNull);
    expect(poll(p, 2), isNull);
    expect(poll(p, 3), 'primary');
    expect(poll(p, 10), isNull);
    expect(poll(p, 11), 'primary');
    expect(poll(p, 30), isNull);
    expect(poll(p, 31), 'backup-a');
    expect(poll(p, 76, current: 'backup-a'), 'backup-a');
    expect(poll(p, 166, current: 'backup-a'), 'backup-b');
    expect(poll(p, 256, current: 'backup-b'), 'backup-b');
    expect(poll(p, 400, current: 'backup-b'), isNull);
    expect(p.armed, isFalse);
    expect(p.attempts, 6);
    expect(poll(p, 10000), isNull);
  });

  test('does not change a healthy profile or cycle back after a single healthy ping', () {
    final p = plan();
    poll(p, 0); expect(poll(p, 3), 'primary');
    expect(poll(p, 8, status: const Connected()), isNull);
    expect(poll(p, 20, status: const Connected()), isNull);
    expect(p.attempts, 1);
    poll(p, 21); expect(poll(p, 24), 'primary');
    expect(poll(p, 44), 'backup-a');
  });

  test('requires two stable minutes to reset the retry budget', () {
    final p = plan();
    poll(p, 0); poll(p, 3);
    poll(p, 4, status: const Connected());
    poll(p, 123, status: const Connected());
    expect(p.attempts, 1);
    poll(p, 124, status: const Connected());
    expect(p.attempts, 0);
    poll(p, 130); expect(poll(p, 133), 'primary');
  });

  test('network outage does not spend attempts and restores after network returns', () {
    final p = plan();
    const offline = MitVpnEnvironment(permissionGranted: true, stopEpoch: 7);
    for (final second in [0, 30, 60, 300]) { expect(poll(p, second, environment: offline), isNull); }
    expect(p.attempts, 0);
    expect(poll(p, 301), 'primary');
  });

  test('a stale connected event cannot grant a fresh budget while physical network is absent', () {
    final p = plan(); poll(p, 0); poll(p, 3);
    const offline = MitVpnEnvironment(permissionGranted: true, stopEpoch: 7);
    poll(p, 4, status: const Connected(), environment: offline);
    poll(p, 200, status: const Connected(), environment: offline);
    expect(p.attempts, 1);
  });

  test('waiting, connecting and unavailable core have a 45 second grace', () {
    for (final status in [const Waiting(), const Connecting(), const NoAvailableProxies()]) {
      final p = plan();
      expect(poll(p, 0, status: status), isNull);
      expect(poll(p, 44, status: status), isNull);
      expect(poll(p, 45, status: status), 'primary');
    }
  });

  test('manual stop cancels pending attempts and invalidates in-flight decisions', () {
    final p = plan(); poll(p, 0); final generation = p.generation;
    p.cancel();
    expect(p.generation, isNot(generation));
    expect(poll(p, 100), isNull);
    p.start(7); poll(p, 200);
    expect(poll(p, 203), 'primary');
    expect(p.attempts, 1);
  });

  test('notification stop or revoked permission permanently cancels the session', () {
    for (final env in [const MitVpnEnvironment(networkAvailable: true, permissionGranted: true, stopEpoch: 8),
      const MitVpnEnvironment(networkAvailable: true, stopEpoch: 7)]) {
      final p = plan(); poll(p, 0);
      expect(poll(p, 3, environment: env), isNull);
      expect(p.armed, isFalse);
      expect(poll(p, 100), isNull);
    }
  });

  test('without backups retries stay on the current profile and remain bounded', () {
    final p = plan(); poll(p, 0, backups: []);
    for (final second in [3, 11, 31, 76, 166, 256]) {
      expect(poll(p, second, backups: []), 'primary');
    }
    expect(poll(p, 400, backups: []), isNull);
    expect(p.armed, isFalse);
  });

  test('manual disconnect and hot reload cannot initiate an automatic start', () {
    final p = plan();
    expect(poll(p, 0, status: const Disconnecting()), isNull);
    expect(poll(p, 100, status: const HotReloading()), isNull);
    expect(p.attempts, 0);
  });

  test('diagnostic uses an allowlist even when core errors and recovery strings contain secrets', () {
    const secret = 'vpn://secret-token PrivateKey=secret server.example 192.0.2.99';
    final report = mitSafeDiagnosticReport(status: const Disconnected(UnexpectedConnectionFailure(secret)),
      recovery: const MitRecoveryView(active: true, phase: secret, attempt: 999),
      autoRecovery: true, backupCount: 2,
      environment: const MitVpnEnvironment(alwaysOn: true, lockdown: false));
    final data = jsonDecode(report) as Map;
    expect(data['connection'], 'disconnected');
    expect(data['recovery'], 'unknown');
    expect(data['attempt'], 6);
    expect(data['always_on'], true); expect(data['lockdown'], false);
    for (final value in ['vpn://', 'PrivateKey', 'secret-token', 'server.example', '192.0.2.99']) {
      expect(report, isNot(contains(value)));
    }
    expect(data.keys.toSet(), {'app','version','build','platform','connection','auto_recovery','recovery',
      'attempt','backup_count','network_available','vpn_permission','always_on','lockdown'});
  });
}
