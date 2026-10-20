import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';

void main() {
  test('uses a bounded ring and keeps the configured capacity within limits', () {
    final trace = IosPingTrace(capacity: 2, elapsedMilliseconds: () => 10);
    addTearDown(trace.dispose);

    trace.record(IosPingEvent.refreshTapped);
    trace.record(IosPingEvent.refreshIssued);
    trace.record(IosPingEvent.refreshCompleted);

    expect(trace.snapshot.events.map((entry) => entry.event), [
      IosPingEvent.refreshIssued,
      IosPingEvent.refreshCompleted,
    ]);
    expect(() => IosPingTrace(capacity: 0), throwsRangeError);
    expect(() => IosPingTrace(capacity: IosPingTrace.maxCapacity + 1), throwsRangeError);
  });

  test('rejects snapshots over capacity and with nonincreasing sequences', () {
    final overCapacity = List<IosPingTraceEntry>.generate(
      IosPingTraceSnapshot.maxCapacity + 1,
      (index) => IosPingTraceEntry(
        sequence: index + 1,
        event: IosPingEvent.refreshTapped,
        operationId: 0,
        elapsedMilliseconds: 0,
      ),
    );
    final duplicate = [
      IosPingTraceEntry(sequence: 1, event: IosPingEvent.refreshTapped, operationId: 0, elapsedMilliseconds: 0),
      IosPingTraceEntry(sequence: 1, event: IosPingEvent.refreshIssued, operationId: 0, elapsedMilliseconds: 0),
    ];
    final descending = [
      IosPingTraceEntry(sequence: 2, event: IosPingEvent.refreshTapped, operationId: 0, elapsedMilliseconds: 0),
      IosPingTraceEntry(sequence: 1, event: IosPingEvent.refreshIssued, operationId: 0, elapsedMilliseconds: 0),
    ];

    expect(() => IosPingTraceSnapshot(overCapacity), throwsRangeError);
    expect(() => IosPingTraceSnapshot(duplicate), throwsRangeError);
    expect(() => IosPingTraceSnapshot(descending), throwsRangeError);
  });

  test('assigns increasing operation ids and permits operation zero', () {
    final trace = IosPingTrace(elapsedMilliseconds: () => 0);
    addTearDown(trace.dispose);

    final first = trace.nextOperationId();
    final second = trace.nextOperationId();
    trace.record(IosPingEvent.coreSetupStarted);
    trace.record(IosPingEvent.coreSetupCompleted, operationId: second);

    expect(first, 1);
    expect(second, 2);
    expect(trace.snapshot.events.map((entry) => entry.operationId), [0, 2]);
  });

  test('clamps callback elapsed time and uses immutable snapshot copies', () {
    var elapsed = -100;
    final trace = IosPingTrace(elapsedMilliseconds: () => elapsed);
    addTearDown(trace.dispose);

    trace.record(IosPingEvent.measurementCreated);
    final before = trace.snapshot;
    elapsed = IosPingTrace.maxElapsedMilliseconds + 100;
    trace.record(IosPingEvent.measurementReady);

    expect(before.events, hasLength(1));
    expect(before.events.single.elapsedMilliseconds, 0);
    expect(trace.snapshot.events.last.elapsedMilliseconds, IosPingTrace.maxElapsedMilliseconds);

    final json = before.toJson();
    (json['events']! as List<Object?>).clear();
    expect(before.events, hasLength(1));
  });

  test('serializes only the closed schema and parses a valid snapshot', () {
    final trace = IosPingTrace(elapsedMilliseconds: () => 42);
    addTearDown(trace.dispose);
    trace.record(IosPingEvent.probeSnapshotFresh, operationId: 7);

    final json = trace.snapshot.toJson();
    expect(json, {
      'schema': 'wir-ios-ping-trace/v1',
      'events': [
        {'sequence': 1, 'event': 'probeSnapshotFresh', 'operation_id': 7, 'elapsed_ms': 42},
      ],
    });
    final parsed = IosPingTraceSnapshot.fromJson(json);
    expect(parsed.toJson(), json);
  });

  test('strict parser rejects private metadata, unknown enums and invalid bounds', () {
    final valid = <String, Object?>{'schema': 'wir-ios-ping-trace/v1', 'events': <Object?>[]};
    final validEvent = <String, Object?>{'sequence': 1, 'event': 'refreshTapped', 'operation_id': 0, 'elapsed_ms': 0};
    valid['events'] = [validEvent];

    expect(() => IosPingTraceSnapshot.fromJson({...valid, 'private': 'token'}), throwsFormatException);
    expect(
      () => IosPingTraceSnapshot.fromJson({
        ...valid,
        'events': [
          {...validEvent, 'path': '/private/file'},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => IosPingTraceSnapshot.fromJson({
        ...valid,
        'events': [
          <String, Object?>{'sequence': 1, 'event': 'raw-string-event', 'operation_id': 0, 'elapsed_ms': 0},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => IosPingTraceSnapshot.fromJson({
        ...valid,
        'events': [
          <String, Object?>{
            'sequence': 1,
            'event': 'refreshTapped',
            'operation_id': IosPingTrace.maxCounter + 1,
            'elapsed_ms': 0,
          },
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => IosPingTraceSnapshot.fromJson({
        ...valid,
        'events': [
          <String, Object?>{'sequence': 2, 'event': 'refreshTapped', 'operation_id': 0, 'elapsed_ms': 0},
          <String, Object?>{'sequence': 2, 'event': 'refreshIssued', 'operation_id': 0, 'elapsed_ms': 0},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => IosPingTraceSnapshot.fromJson({
        'schema': 'wir-ios-ping-trace/v1',
        'events': List<Object?>.filled(IosPingTrace.maxCapacity + 1, validEvent),
      }),
      throwsFormatException,
    );
  });

  test('changes is an asynchronous broadcast stream', () async {
    final trace = IosPingTrace(elapsedMilliseconds: () => 3);
    addTearDown(trace.dispose);
    final first = <IosPingTraceSnapshot>[];
    final second = <IosPingTraceSnapshot>[];
    final subscription1 = trace.changes.listen(first.add);
    final subscription2 = trace.changes.listen(second.add);
    addTearDown(subscription1.cancel);
    addTearDown(subscription2.cancel);

    trace.record(IosPingEvent.refreshTapped);
    expect(first, isEmpty);
    expect(second, isEmpty);
    await Future<void>.delayed(Duration.zero);

    expect(first, hasLength(1));
    expect(second, hasLength(1));
    expect(first.single.events.single.event, IosPingEvent.refreshTapped);
  });

  test('dispose is idempotent and later records are ignored', () async {
    final trace = IosPingTrace(elapsedMilliseconds: () => 1);
    final changes = <IosPingTraceSnapshot>[];
    final subscription = trace.changes.listen(changes.add);
    addTearDown(subscription.cancel);

    trace.record(IosPingEvent.corePauseQueued);
    trace.dispose();
    trace.dispose();
    trace.record(IosPingEvent.corePauseCompleted);
    await Future<void>.delayed(Duration.zero);

    expect(trace.snapshot.events.map((entry) => entry.event), [IosPingEvent.corePauseQueued]);
    expect(changes, hasLength(1));
  });

  test('clear empties synchronously, streams an empty snapshot, and preserves counters', () async {
    final trace = IosPingTrace(elapsedMilliseconds: () => 1);
    final changes = <IosPingTraceSnapshot>[];
    final subscription = trace.changes.listen(changes.add);
    addTearDown(subscription.cancel);

    final firstOperation = trace.nextOperationId();
    trace.record(IosPingEvent.refreshTapped, operationId: firstOperation);
    await Future<void>.delayed(Duration.zero);
    changes.clear();

    trace.clear();
    expect(trace.snapshot.events, isEmpty);
    expect(changes, isEmpty);
    await Future<void>.delayed(Duration.zero);

    expect(changes, hasLength(1));
    expect(changes.single.events, isEmpty);

    final secondOperation = trace.nextOperationId();
    trace.record(IosPingEvent.refreshIssued, operationId: secondOperation);
    await Future<void>.delayed(Duration.zero);
    expect(trace.snapshot.events.single.sequence, 2);
    expect(trace.snapshot.events.single.operationId, 2);

    trace.dispose();
    trace.clear();
    expect(trace.snapshot.events, hasLength(1));
  });
}
