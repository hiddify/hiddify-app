import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';

const _rawCanary = 'vless://private.example.invalid:443?token=secret-token';
const _uuidCanary = '12345678-1234-4234-8234-123456789abc';
const _stackCanary = 'private stack frame';

final class _Poison {
  @override
  String toString() => throw StateError('diagnostics read a raw error');
}

Map<String, Object> _eventJson({
  required int sequence,
  required int operationId,
  String operation = 'connect',
  String stage = 'accepted',
  String code = 'none',
  int durationMs = 12,
}) => {
  'sequence': sequence,
  'operation_id': operationId,
  'operation': operation,
  'stage': stage,
  'code': code,
  'duration_ms': durationMs,
  'reachability': 'not_checked',
};

String _persisted(List<Map<String, Object>> events) => jsonEncode({
  'schema': 'blizzard-safe-diagnostics/v1',
  'platform': 'ios',
  'reachability': 'not_checked',
  'events': events,
});

void main() {
  group('closed failure mapping', () {
    test('maps every failure by subtype without reading payload or stack', () {
      final cases = <(ConnectionFailure, DiagnosticCode)>[
        (ConnectionFailure.unexpected(_Poison(), StackTrace.fromString(_stackCanary)), DiagnosticCode.unexpected),
        (const ConnectionFailure.missingVpnPermission(_rawCanary), DiagnosticCode.vpnPermissionDenied),
        (
          const ConnectionFailure.missingNotificationPermission(_rawCanary),
          DiagnosticCode.notificationPermissionDenied,
        ),
        (const ConnectionFailure.missingPrivilege(), DiagnosticCode.privilegeRequired),
        (const ConnectionFailure.invalidConfigOption(_rawCanary), DiagnosticCode.invalidConfigOption),
        (const ConnectionFailure.invalidConfig(_rawCanary), DiagnosticCode.invalidConfig),
        (const ConnectionFailure.backgroundCoreNotAvailable(_rawCanary), DiagnosticCode.coreUnavailable),
        (const ConnectionFailure.missiingWarpLicense(), DiagnosticCode.warpLicenseRequired),
      ];

      for (final (failure, expected) in cases) {
        expect(diagnosticCodeForFailure(failure), expected);
      }
    });
  });

  group('SafeDiagnosticEvent', () {
    test('round-trips only its fixed closed schema', () {
      final event = SafeDiagnosticEvent(
        sequence: 7,
        operationId: 3,
        operation: DiagnosticOperation.reconnect,
        stage: DiagnosticStage.failed,
        code: DiagnosticCode.coreUnavailable,
        durationMs: 42,
      );

      final encoded = event.toJson();
      expect(encoded.keys, ['sequence', 'operation_id', 'operation', 'stage', 'code', 'duration_ms', 'reachability']);
      expect(encoded, {
        'sequence': 7,
        'operation_id': 3,
        'operation': 'reconnect',
        'stage': 'failed',
        'code': 'coreUnavailable',
        'duration_ms': 42,
        'reachability': 'not_checked',
      });
      expect(SafeDiagnosticEvent.fromJson(encoded), event);
    });

    test('bounds duration at construction', () {
      SafeDiagnosticEvent event(int duration) => SafeDiagnosticEvent(
        sequence: 1,
        operationId: 1,
        operation: DiagnosticOperation.connect,
        stage: DiagnosticStage.accepted,
        code: DiagnosticCode.none,
        durationMs: duration,
      );

      expect(event(-1).durationMs, 0);
      expect(event(3600001).durationMs, 3600000);
    });

    test('reserves operation id zero only for unsolicited tunnel state', () {
      final unsolicited = SafeDiagnosticEvent(
        sequence: 1,
        operationId: 0,
        operation: DiagnosticOperation.tunnel,
        stage: DiagnosticStage.state,
        code: DiagnosticCode.started,
      );

      expect(SafeDiagnosticEvent.fromJson(unsolicited.toJson()), unsolicited);
      expect(
        () => SafeDiagnosticEvent(
          sequence: 1,
          operationId: 0,
          operation: DiagnosticOperation.connect,
          stage: DiagnosticStage.state,
          code: DiagnosticCode.started,
        ),
        throwsRangeError,
      );
      expect(
        () => SafeDiagnosticEvent(
          sequence: 1,
          operationId: 0,
          operation: DiagnosticOperation.tunnel,
          stage: DiagnosticStage.accepted,
          code: DiagnosticCode.started,
        ),
        throwsRangeError,
      );
    });

    test('rejects counters outside the safe integer range', () {
      expect(
        () => SafeDiagnosticEvent(
          sequence: SafeDiagnosticEvent.maxCounter + 1,
          operationId: 1,
          operation: DiagnosticOperation.connect,
          stage: DiagnosticStage.requested,
          code: DiagnosticCode.none,
        ),
        throwsRangeError,
      );
      expect(
        () => SafeDiagnosticEvent.fromJson(_eventJson(sequence: 1, operationId: SafeDiagnosticEvent.maxCounter + 1)),
        throwsFormatException,
      );
    });

    test('strict parser rejects extra, missing, mistyped and unknown values', () {
      final valid = _eventJson(sequence: 1, operationId: 1);
      final invalid = <Map<String, Object?>>[
        {...valid, 'raw_error': _rawCanary},
        Map<String, Object?>.of(valid)..remove('code'),
        {...valid, 'sequence': true},
        {...valid, 'operation_id': 0},
        {...valid, 'operation': 'retry-with-$_uuidCanary'},
        {...valid, 'stage': 'stack:$_stackCanary'},
        {...valid, 'code': 'raw:$_rawCanary'},
        {...valid, 'duration_ms': -1},
        {...valid, 'reachability': 'reachable'},
      ];

      for (final value in invalid) {
        expect(() => SafeDiagnosticEvent.fromJson(value), throwsFormatException, reason: jsonEncode(value));
      }
    });
  });

  group('SafeDiagnosticJournal', () {
    test('assigns sequences, bounds capacity and exposes immutable snapshots', () {
      final journal = SafeDiagnosticJournal(capacity: 2);
      addTearDown(journal.dispose);
      final firstOperation = journal.nextOperationId();
      final secondOperation = journal.nextOperationId();

      journal.record(
        operation: DiagnosticOperation.setup,
        stage: DiagnosticStage.requested,
        code: DiagnosticCode.none,
        operationId: firstOperation,
      );
      journal.record(
        operation: DiagnosticOperation.connect,
        stage: DiagnosticStage.accepted,
        code: DiagnosticCode.started,
        operationId: secondOperation,
        durationMs: 4,
      );
      journal.record(
        operation: DiagnosticOperation.tunnel,
        stage: DiagnosticStage.state,
        code: DiagnosticCode.started,
        operationId: secondOperation,
        durationMs: 5,
      );

      expect((firstOperation, secondOperation), (1, 2));
      expect(journal.events.map((event) => event.sequence), [2, 3]);
      expect(() => journal.events.add(journal.events.first), throwsUnsupportedError);
      expect(() => journal.events.first.toJson()['code'] = _rawCanary, returnsNormally);
      expect(journal.events.first.code, DiagnosticCode.started);
    });

    test('broadcasts immutable snapshots and clear emits an empty snapshot', () async {
      final journal = SafeDiagnosticJournal();
      addTearDown(journal.dispose);
      final emissions = <List<SafeDiagnosticEvent>>[];
      final subscription = journal.changes.listen(emissions.add);
      addTearDown(subscription.cancel);

      journal.record(
        operation: DiagnosticOperation.connect,
        stage: DiagnosticStage.requested,
        code: DiagnosticCode.none,
        operationId: journal.nextOperationId(),
      );
      journal.clear();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
      expect(emissions.first, hasLength(1));
      expect(() => emissions.first.clear(), throwsUnsupportedError);
      expect(emissions.last, isEmpty);
    });

    test('a listener can clear during delivery without reviving the recorded event', () async {
      final persisted = <String>[];
      final escaped = <Object>[];
      final journal = SafeDiagnosticJournal(persist: (snapshot) async => persisted.add(snapshot));
      addTearDown(journal.dispose);

      await runZonedGuarded(() async {
        final subscription = journal.changes.listen((events) {
          if (events.isNotEmpty) journal.clear();
        });
        addTearDown(subscription.cancel);

        journal.record(
          operation: DiagnosticOperation.connect,
          stage: DiagnosticStage.requested,
          code: DiagnosticCode.none,
          operationId: journal.nextOperationId(),
        );
        await Future<void>.delayed(Duration.zero);
        await journal.flush();
      }, (error, _) => escaped.add(error));

      expect(escaped, isEmpty);
      expect(journal.events, isEmpty);
      expect((jsonDecode(persisted.last) as Map<String, dynamic>)['events'], isEmpty);
    });

    test('restores strict safe data, caps at 128 and seeds ids above restored maxima', () {
      final restoredEvents = List.generate(130, (index) => _eventJson(sequence: index + 1, operationId: index + 10));
      final journal = SafeDiagnosticJournal(restored: _persisted(restoredEvents));
      addTearDown(journal.dispose);

      expect(journal.events, hasLength(128));
      expect(journal.events.first.sequence, 3);
      expect(journal.events.last.sequence, 130);
      expect(journal.nextOperationId(), 140);
      journal.record(
        operation: DiagnosticOperation.disconnect,
        stage: DiagnosticStage.accepted,
        code: DiagnosticCode.stopped,
        operationId: 140,
      );
      expect(journal.events.last.sequence, 131);
    });

    test('rejects malformed, oversized, raw and extra restored payloads', () {
      final validEvent = _eventJson(sequence: 1, operationId: 1);
      final payloads = <String>[
        '{',
        'x' * (64 * 1024 + 1),
        jsonEncode({
          'schema': 'blizzard-safe-diagnostics/v1',
          'platform': 'ios',
          'reachability': 'not_checked',
          'events': [validEvent],
          'raw_error': _rawCanary,
        }),
        _persisted([
          {...validEvent, 'stack_trace': '$_stackCanary $_uuidCanary'},
        ]),
      ];

      for (final payload in payloads) {
        final journal = SafeDiagnosticJournal(restored: payload);
        expect(journal.events, isEmpty);
        expect(journal.nextOperationId(), 1);
        journal.dispose();
      }
    });

    test('coalesces a stalled persistence backlog to the latest snapshot', () async {
      final writes = <String>[];
      final firstEntered = Completer<void>();
      final releaseFirst = Completer<void>();
      var calls = 0;
      final journal = SafeDiagnosticJournal(
        persist: (snapshot) async {
          calls++;
          if (calls == 1) {
            firstEntered.complete();
            await releaseFirst.future;
          }
          writes.add(snapshot);
        },
      );
      addTearDown(journal.dispose);

      final operationId = journal.nextOperationId();
      journal.record(
        operation: DiagnosticOperation.connect,
        stage: DiagnosticStage.requested,
        code: DiagnosticCode.none,
        operationId: operationId,
      );
      await firstEntered.future;
      for (var index = 0; index < 1000; index++) {
        journal.record(
          operation: DiagnosticOperation.connect,
          stage: DiagnosticStage.accepted,
          code: DiagnosticCode.started,
          operationId: operationId,
        );
      }
      journal.clear();
      expect(writes, isEmpty);
      releaseFirst.complete();
      await journal.flush();

      expect(writes, hasLength(2));
      expect((jsonDecode(writes.first) as Map<String, dynamic>)['events'], hasLength(1));
      expect((jsonDecode(writes.last) as Map<String, dynamic>)['events'], isEmpty);
    });

    test('persistence failures never escape record or flush and later success clears the flag', () async {
      var fail = true;
      final journal = SafeDiagnosticJournal(
        persist: (_) async {
          if (fail) throw _Poison();
        },
      );
      addTearDown(journal.dispose);

      expect(
        () => journal.record(
          operation: DiagnosticOperation.connect,
          stage: DiagnosticStage.failed,
          code: DiagnosticCode.unexpected,
          operationId: journal.nextOperationId(),
        ),
        returnsNormally,
      );
      await expectLater(journal.flush(), completes);
      expect(journal.persistenceFailed, isTrue);

      fail = false;
      journal.clear();
      await expectLater(journal.flush(), completes);
      expect(journal.persistenceFailed, isFalse);
    });

    test('exports a bounded fixed report and validates metadata', () {
      final journal = SafeDiagnosticJournal();
      addTearDown(journal.dispose);
      for (var index = 0; index < 128; index++) {
        journal.record(
          operation: DiagnosticOperation.tunnel,
          stage: DiagnosticStage.state,
          code: DiagnosticCode.started,
          operationId: journal.nextOperationId(),
          durationMs: 3600001,
        );
      }

      final valid = journal.exportJson(version: '4.1.1', buildNumber: '40101');
      final validJson = jsonDecode(valid) as Map<String, dynamic>;
      expect(validJson.keys, ['schema', 'platform', 'reachability', 'version', 'build_number', 'events']);
      expect(validJson['version'], '4.1.1');
      expect(validJson['build_number'], '40101');
      expect(validJson['events'], hasLength(128));
      expect(utf8.encode(valid).length, lessThanOrEqualTo(64 * 1024));
      expect(valid, isNot(contains(_rawCanary)));
      expect(valid, isNot(contains(_uuidCanary)));
      expect(valid, isNot(contains(_stackCanary)));

      final invalid =
          jsonDecode(journal.exportJson(version: '4.1.1-$_rawCanary', buildNumber: '1234567890'))
              as Map<String, dynamic>;
      expect(invalid['version'], 'unknown');
      expect(invalid['build_number'], 'unknown');
    });

    test('rejects capacity outside the supported 1 through 128 range', () {
      expect(() => SafeDiagnosticJournal(capacity: 0), throwsRangeError);
      expect(() => SafeDiagnosticJournal(capacity: 129), throwsRangeError);
    });
  });
}
