import 'dart:async';

enum IosPingEvent {
  appInactive,
  appHidden,
  appPaused,
  appResumed,
  appDetached,
  corePauseQueued,
  corePauseStarted,
  corePauseStatusCancel,
  corePauseCloseFront,
  corePauseCancelFg,
  corePauseCancelBg,
  corePauseCloseNormal,
  corePauseCloseFfi,
  corePauseCompleted,
  corePauseFailed,
  coreResumeQueued,
  coreResumeStarted,
  coreResumeCompleted,
  coreResumeFailed,
  coreSetupStarted,
  coreSetupFrontRequested,
  coreSetupFrontReady,
  coreSetupStatusRequested,
  coreSetupStatusReady,
  coreSetupListenersRequested,
  coreSetupCompleted,
  coreSetupFailed,
  coreSetupFirstHelloFailed,
  coreSetupNativeFailed,
  coreSetupSecondHelloFailed,
  coreSetupPreferencesFailed,
  coreSetupHelloTimedOut,
  coreSetupNativeTimedOut,
  coreSetupHelloFailed,
  coreSetupGrpcOk,
  coreSetupGrpcCancelled,
  coreSetupGrpcUnknown,
  coreSetupGrpcInvalidArgument,
  coreSetupGrpcDeadlineExceeded,
  coreSetupGrpcNotFound,
  coreSetupGrpcAlreadyExists,
  coreSetupGrpcPermissionDenied,
  coreSetupGrpcResourceExhausted,
  coreSetupGrpcFailedPrecondition,
  coreSetupGrpcAborted,
  coreSetupGrpcOutOfRange,
  coreSetupGrpcUnimplemented,
  coreSetupGrpcInternal,
  coreSetupGrpcUnavailable,
  coreSetupGrpcDataLoss,
  coreSetupGrpcUnauthenticated,
  coreSetupLoopbackReachable,
  coreSetupLoopbackUnreachable,
  coreRestarted,
  measurementCreated,
  measurementReady,
  measurementBlocked,
  measurementSuspended,
  measurementChecking,
  measurementAvailable,
  measurementUnavailable,
  measurementFailed,
  measurementTimedOut,
  refreshTapped,
  refreshNotConnected,
  refreshNotResumed,
  refreshCoreNotReady,
  hapticRequested,
  hapticCompleted,
  refreshInvalidated,
  refreshIssued,
  refreshCompleted,
  refreshRecoveryCompleted,
  refreshFailed,
  probeStreamEmpty,
  probeStreamUsable,
  probeSnapshotFresh,
  probeSnapshotTimeMissing,
  probeSnapshotBeforeRequest,
  probeSnapshotUnchanged,
  probeSnapshotNoDelay,
  probeSnapshotOutOfRange,
  probeIdentityChanged,
  probeStreamClosed,
  probeRequestIssued,
  probeRequestCompleted,
  probeRequestFailed,
  probeStreamFailed,
}

final class IosPingTraceEntry {
  IosPingTraceEntry({
    required this.sequence,
    required this.event,
    required this.operationId,
    required this.elapsedMilliseconds,
  }) {
    _checkCounter(sequence, 'sequence', allowZero: false);
    _checkCounter(operationId, 'operationId', allowZero: true);
    _checkElapsed(elapsedMilliseconds);
  }

  IosPingTraceEntry._copy(IosPingTraceEntry other)
    : sequence = other.sequence,
      event = other.event,
      operationId = other.operationId,
      elapsedMilliseconds = other.elapsedMilliseconds;

  final int sequence;
  final IosPingEvent event;
  final int operationId;
  final int elapsedMilliseconds;

  int get elapsedMs => elapsedMilliseconds;
}

final class IosPingTraceSnapshot {
  IosPingTraceSnapshot(Iterable<IosPingTraceEntry> entries) : events = _freezeEntries(entries);

  final List<IosPingTraceEntry> events;

  static const String schema = 'wir-ios-ping-trace/v1';
  static const int maxCapacity = 128;
  static const int maxCounter = 9007199254740991;
  static const int maxElapsedMilliseconds = 2592000000;
  static const Set<String> _documentKeys = {'schema', 'events'};
  static const Set<String> _entryKeys = {'sequence', 'event', 'operation_id', 'elapsed_ms'};

  Map<String, Object> toJson() => {
    'schema': schema,
    'events': events
        .map(
          (entry) => <String, Object>{
            'sequence': entry.sequence,
            'event': entry.event.name,
            'operation_id': entry.operationId,
            'elapsed_ms': entry.elapsedMilliseconds,
          },
        )
        .toList(),
  };

  factory IosPingTraceSnapshot.fromJson(Map<String, Object?> json) {
    if (json.length != _documentKeys.length ||
        _hasUnknownKey(json.keys.cast<Object?>(), _documentKeys) ||
        json['schema'] != schema) {
      throw const FormatException('invalid iOS ping trace document');
    }

    final rawEvents = json['events'];
    if (rawEvents is! List || rawEvents.length > maxCapacity) {
      throw const FormatException('invalid iOS ping trace events');
    }

    final entries = <IosPingTraceEntry>[];
    var previousSequence = 0;
    for (final rawEvent in rawEvents) {
      if (rawEvent is! Map || rawEvent.length != _entryKeys.length || _hasUnknownKey(rawEvent.keys, _entryKeys)) {
        throw const FormatException('invalid iOS ping trace event fields');
      }

      final sequence = rawEvent['sequence'];
      final eventName = rawEvent['event'];
      final operationId = rawEvent['operation_id'];
      final elapsedMilliseconds = rawEvent['elapsed_ms'];
      if (sequence is! int ||
          sequence < 1 ||
          sequence > maxCounter ||
          sequence <= previousSequence ||
          eventName is! String ||
          operationId is! int ||
          operationId < 0 ||
          operationId > maxCounter ||
          elapsedMilliseconds is! int ||
          elapsedMilliseconds < 0 ||
          elapsedMilliseconds > maxElapsedMilliseconds) {
        throw const FormatException('invalid iOS ping trace event value');
      }
      final event = _eventByName(eventName);
      if (event == null) {
        throw const FormatException('unknown iOS ping trace event');
      }
      entries.add(
        IosPingTraceEntry(
          sequence: sequence,
          event: event,
          operationId: operationId,
          elapsedMilliseconds: elapsedMilliseconds,
        ),
      );
      previousSequence = sequence;
    }
    return IosPingTraceSnapshot(entries);
  }
}

final class IosPingTrace {
  IosPingTrace({this.capacity = defaultCapacity, int Function()? elapsedMilliseconds})
    : _elapsedMilliseconds = elapsedMilliseconds {
    if (capacity < 1 || capacity > maxCapacity) {
      throw RangeError.range(capacity, 1, maxCapacity, 'capacity');
    }
    _stopwatch = Stopwatch()..start();
  }

  static const int defaultCapacity = 96;
  static const int maxCapacity = 128;
  static const int maxCounter = 9007199254740991;
  static const int maxElapsedMilliseconds = IosPingTraceSnapshot.maxElapsedMilliseconds;

  final int Function()? _elapsedMilliseconds;
  final int capacity;
  final List<IosPingTraceEntry> _events = [];
  final StreamController<IosPingTraceSnapshot> _changes = StreamController.broadcast();
  late final Stopwatch _stopwatch;
  int _nextSequence = 1;
  int _nextOperation = 1;
  bool _disposed = false;

  Stream<IosPingTraceSnapshot> get changes => _changes.stream;
  IosPingTraceSnapshot get snapshot => IosPingTraceSnapshot(_events);

  int nextOperationId() {
    if (_nextOperation > maxCounter) {
      throw StateError('iOS ping trace operation id exhausted');
    }
    return _nextOperation++;
  }

  void record(IosPingEvent event, {int operationId = 0}) {
    if (_disposed) return;
    _checkCounter(operationId, 'operationId', allowZero: true);
    if (_nextSequence > maxCounter) {
      throw StateError('iOS ping trace sequence exhausted');
    }
    final entry = IosPingTraceEntry(
      sequence: _nextSequence++,
      event: event,
      operationId: operationId,
      elapsedMilliseconds: _clampElapsed(_readElapsed()),
    );
    if (_events.length == capacity) _events.removeAt(0);
    _events.add(entry);
    _changes.add(snapshot);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _changes.close();
  }

  void clear() {
    if (_disposed) return;
    _events.clear();
    _changes.add(snapshot);
  }

  int _readElapsed() {
    try {
      return _elapsedMilliseconds?.call() ?? _stopwatch.elapsedMilliseconds;
    } catch (_) {
      return 0;
    }
  }
}

IosPingEvent? _eventByName(String name) {
  for (final event in IosPingEvent.values) {
    if (event.name == name) return event;
  }
  return null;
}

int _clampElapsed(int elapsedMilliseconds) => elapsedMilliseconds.clamp(0, IosPingTrace.maxElapsedMilliseconds);

void _checkCounter(int value, String name, {required bool allowZero}) {
  final minimum = allowZero ? 0 : 1;
  if (value < minimum || value > IosPingTrace.maxCounter) {
    throw RangeError.range(value, minimum, IosPingTrace.maxCounter, name);
  }
}

void _checkElapsed(int elapsedMilliseconds) {
  if (elapsedMilliseconds < 0 || elapsedMilliseconds > IosPingTrace.maxElapsedMilliseconds) {
    throw RangeError.range(elapsedMilliseconds, 0, IosPingTrace.maxElapsedMilliseconds, 'elapsedMilliseconds');
  }
}

bool _hasUnknownKey(Iterable<Object?> keys, Set<String> allowed) =>
    keys.any((key) => key is! String || !allowed.contains(key));

List<IosPingTraceEntry> _freezeEntries(Iterable<IosPingTraceEntry> entries) {
  final copies = <IosPingTraceEntry>[];
  var previousSequence = 0;
  for (final entry in entries) {
    if (copies.length == IosPingTraceSnapshot.maxCapacity) {
      throw RangeError.range(copies.length + 1, 0, IosPingTraceSnapshot.maxCapacity, 'events');
    }
    if (entry.sequence <= previousSequence) {
      throw RangeError('snapshot event sequences must be strictly increasing');
    }
    copies.add(IosPingTraceEntry._copy(entry));
    previousSequence = entry.sequence;
  }
  return List<IosPingTraceEntry>.unmodifiable(copies);
}
