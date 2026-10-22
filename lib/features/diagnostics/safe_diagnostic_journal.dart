import 'dart:async';
import 'dart:convert';

import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/features/diagnostics/home_presentation_snapshot.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';

typedef SafeDiagnosticPersist = Future<void> Function(String snapshot);

final class SafeDiagnosticJournal {
  SafeDiagnosticJournal({String? restored, SafeDiagnosticPersist? persist, int capacity = maxCapacity})
    : _capacity = capacity,
      _persist = persist {
    if (capacity < 1 || capacity > maxCapacity) {
      throw RangeError.range(capacity, 1, maxCapacity, 'capacity');
    }
    if (restored != null) _restore(restored);
  }

  static const int maxCapacity = 128;
  static const int maxEncodedBytes = 64 * 1024;
  static const String schema = 'blizzard-safe-diagnostics/v1';
  static const Set<String> _requiredDocumentKeys = {'schema', 'platform', 'reachability', 'events'};
  static const Set<String> _optionalDocumentKeys = {
    'version',
    'build_number',
    'home_presentation',
    'ios_ping',
    'telemetry_delivery',
  };
  static final RegExp _versionPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}$');
  static final RegExp _buildPattern = RegExp(r'^\d{1,9}$');

  final int _capacity;
  final SafeDiagnosticPersist? _persist;
  final List<SafeDiagnosticEvent> _events = [];
  final StreamController<List<SafeDiagnosticEvent>> _changes = StreamController.broadcast();
  Future<void> _pendingPersistence = Future<void>.value();
  String? _latestPendingSnapshot;
  bool _persistenceRunning = false;
  int _nextSequence = 1;
  int _nextOperation = 1;
  bool _disposed = false;

  bool _persistenceFailed = false;

  bool get persistenceFailed => _persistenceFailed;

  List<SafeDiagnosticEvent> get events => List<SafeDiagnosticEvent>.unmodifiable(_events);

  Stream<List<SafeDiagnosticEvent>> get changes => _changes.stream;

  int nextOperationId() {
    if (_nextOperation > SafeDiagnosticEvent.maxCounter) {
      throw StateError('diagnostic operation id exhausted');
    }
    return _nextOperation++;
  }

  void record({
    required DiagnosticOperation operation,
    required DiagnosticStage stage,
    required DiagnosticCode code,
    required int operationId,
    int durationMs = 0,
  }) {
    if (_disposed) throw StateError('diagnostic journal is disposed');
    if (_nextSequence > SafeDiagnosticEvent.maxCounter) {
      throw StateError('diagnostic sequence exhausted');
    }
    final event = SafeDiagnosticEvent(
      sequence: _nextSequence++,
      operationId: operationId,
      operation: operation,
      stage: stage,
      code: code,
      durationMs: durationMs,
    );
    if (_events.length == _capacity) _events.removeAt(0);
    _events.add(event);
    _emitAndPersist();
  }

  void clear() {
    if (_disposed) throw StateError('diagnostic journal is disposed');
    _events.clear();
    _emitAndPersist();
  }

  Future<void> flush() async {
    await _pendingPersistence;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _changes.close();
  }

  String exportJson({
    String? version,
    String? buildNumber,
    HomePresentationSnapshot? homePresentation,
    IosPingTraceSnapshot? iosPing,
    TelemetryDeliveryStatus? telemetryDelivery,
  }) => _encodeDocument(
    events: _events,
    version: _safeVersion(version),
    buildNumber: _safeBuildNumber(buildNumber),
    homePresentation: homePresentation,
    iosPing: iosPing,
    telemetryDelivery: telemetryDelivery,
  );

  void _restore(String restored) {
    try {
      if (utf8.encode(restored).length > maxEncodedBytes) return;
      final decoded = jsonDecode(restored);
      if (decoded is! Map<String, dynamic>) return;
      final keys = decoded.keys.toSet();
      if (!_requiredDocumentKeys.every(keys.contains) ||
          keys.any((key) => !_requiredDocumentKeys.contains(key) && !_optionalDocumentKeys.contains(key)) ||
          decoded['schema'] != schema ||
          decoded['platform'] != 'ios' ||
          decoded['reachability'] != 'not_checked') {
        return;
      }
      if (decoded.containsKey('version') && !_isSafeMetadata(decoded['version'], _versionPattern)) return;
      if (decoded.containsKey('build_number') && !_isSafeMetadata(decoded['build_number'], _buildPattern)) return;
      if (decoded.containsKey('home_presentation')) {
        final rawHomePresentation = decoded['home_presentation'];
        if (rawHomePresentation is! Map) return;
        HomePresentationSnapshot.fromJson(Map<String, Object?>.from(rawHomePresentation));
      }
      if (decoded.containsKey('ios_ping')) {
        final rawPing = decoded['ios_ping'];
        if (rawPing is! Map) return;
        IosPingTraceSnapshot.fromJson(Map<String, Object?>.from(rawPing));
      }
      if (decoded.containsKey('telemetry_delivery')) {
        final rawDelivery = decoded['telemetry_delivery'];
        if (rawDelivery is! Map) return;
        TelemetryDeliveryStatus.fromJson(Map<String, Object?>.from(rawDelivery));
      }
      final rawEvents = decoded['events'];
      if (rawEvents is! List) return;
      final parsed = <SafeDiagnosticEvent>[];
      var previousSequence = 0;
      var maxOperation = 0;
      for (final rawEvent in rawEvents) {
        if (rawEvent is! Map) return;
        final event = SafeDiagnosticEvent.fromJson(Map<String, Object?>.from(rawEvent));
        if (event.sequence <= previousSequence) return;
        previousSequence = event.sequence;
        if (event.operationId > maxOperation) maxOperation = event.operationId;
        parsed.add(event);
      }
      _nextSequence = parsed.isEmpty ? 1 : parsed.last.sequence + 1;
      _nextOperation = maxOperation + 1;
      final start = parsed.length > _capacity ? parsed.length - _capacity : 0;
      _events.addAll(parsed.skip(start));
    } on Object {
      _events.clear();
      _nextSequence = 1;
      _nextOperation = 1;
    }
  }

  bool _isSafeMetadata(Object? value, RegExp pattern) =>
      value == 'unknown' || value is String && pattern.hasMatch(value);

  String _safeVersion(String? value) => value != null && _versionPattern.hasMatch(value) ? value : 'unknown';

  String _safeBuildNumber(String? value) => value != null && _buildPattern.hasMatch(value) ? value : 'unknown';

  void _emitAndPersist() {
    final snapshot = events;
    _changes.add(snapshot);
    final persist = _persist;
    if (persist == null) return;
    final encoded = _encodeDocument(events: snapshot);
    _latestPendingSnapshot = encoded;
    if (_persistenceRunning) return;
    _persistenceRunning = true;
    _pendingPersistence = _drainPersistence(persist);
  }

  Future<void> _drainPersistence(SafeDiagnosticPersist persist) async {
    while (_latestPendingSnapshot != null) {
      final snapshot = _latestPendingSnapshot!;
      _latestPendingSnapshot = null;
      try {
        await persist(snapshot);
        _persistenceFailed = false;
      } on Object {
        _persistenceFailed = true;
      }
    }
    _persistenceRunning = false;
  }

  String _encodeDocument({
    required Iterable<SafeDiagnosticEvent> events,
    String? version,
    String? buildNumber,
    HomePresentationSnapshot? homePresentation,
    IosPingTraceSnapshot? iosPing,
    TelemetryDeliveryStatus? telemetryDelivery,
  }) {
    final encodedEvents = events.map((event) => event.toJson()).toList(growable: true);
    String encode() => jsonEncode({
      'schema': schema,
      'platform': 'ios',
      'reachability': 'not_checked',
      if (version != null) 'version': version,
      if (buildNumber != null) 'build_number': buildNumber,
      if (homePresentation != null) 'home_presentation': homePresentation.toJson(),
      if (iosPing != null) 'ios_ping': iosPing.toJson(),
      if (telemetryDelivery != null) 'telemetry_delivery': telemetryDelivery.toJson(),
      'events': encodedEvents,
    });

    var result = encode();
    while (utf8.encode(result).length > maxEncodedBytes && encodedEvents.isNotEmpty) {
      encodedEvents.removeAt(0);
      result = encode();
    }
    return result;
  }
}
