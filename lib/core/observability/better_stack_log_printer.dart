import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:hiddify/core/observability/telemetry_budget.dart';
import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/core/observability/telemetry_transport_attempt.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';

typedef BetterStackPost = Future<int> Function(Uri endpoint, String token, String body);
typedef RemoteOutboxRead = String? Function();
typedef RemoteOutboxWrite = Future<bool> Function(String value);
typedef RemoteAttemptRead = String? Function();
typedef RemoteAttemptWrite = Future<bool> Function(String value);
typedef BetterStackTimerFactory = Timer Function(Duration delay, void Function() callback);

bool isBetterStackLogsEndpoint(Uri endpoint) =>
    endpoint.scheme == 'https' &&
    endpoint.host.endsWith('.betterstackdata.com') &&
    endpoint.port == 443 &&
    endpoint.userInfo.isEmpty &&
    (endpoint.path.isEmpty || endpoint.path == '/') &&
    !endpoint.hasQuery &&
    !endpoint.hasFragment;

/// Exports only closed-schema diagnostic events. Never subscribes to VPN output.
final class BetterStackLogPrinter {
  BetterStackLogPrinter({
    required this.endpoint,
    required this.sessionId,
    String? version,
    String? buildNumber,
    required String token,
    required TelemetryBudget budget,
    BetterStackPost? post,
    DateTime Function()? now,
    this.flushInterval = const Duration(seconds: 10),
    this.autoFlush = true,
    RemoteOutboxRead? readOutbox,
    RemoteOutboxWrite? writeOutbox,
    RemoteAttemptRead? readLastAttempt,
    RemoteAttemptWrite? writeLastAttempt,
    RemoteAttemptRead? readLastTestAttempt,
    RemoteAttemptWrite? writeLastTestAttempt,
    BetterStackTimerFactory? createTimer,
  }) : _version = _safeMetadata(version, _versionPattern),
       _buildNumber = _safeMetadata(buildNumber, _buildPattern),
       _token = token,
       _budget = budget,
       _post = post,
       _now = now ?? DateTime.now,
       _writeOutbox = writeOutbox,
       _writeLastAttempt = writeLastAttempt,
       _writeLastTestAttempt = writeLastTestAttempt,
       _createTimer = createTimer ?? Timer.new,
       _active = token.isNotEmpty && isBetterStackLogsEndpoint(endpoint) && _sessionPattern.hasMatch(sessionId) {
    if (_active && readOutbox != null) _restore(readOutbox);
    if (_active) _restoreLastAttempt(readLastAttempt);
    if (_active) _restoreLastTestAttempt(readLastTestAttempt);
    if (!_active) {
      _state = TelemetryDeliveryState.disabled;
    } else if (_state == TelemetryDeliveryState.outboxStorageFailed) {
      // Keep a restore failure visible until a later event is durably saved.
    } else if (_lastTestOutcome == TelemetryTestOutcome.droppedExpired) {
      _state = TelemetryDeliveryState.droppedExpired;
    } else if (_budgetBlockedDay != null && _isBudgetBlockActive()) {
      _state = TelemetryDeliveryState.budgetLimited;
    } else if (_budgetFailureBlocked) {
      // Keep the closed budget storage/format failure set during re-evaluation.
    } else if (_attempts > 0) {
      _state = TelemetryDeliveryState.retryWaiting;
    } else {
      _state = _queue.isEmpty ? TelemetryDeliveryState.idle : TelemetryDeliveryState.pending;
    }
    _emitStatus();
    _schedule(flushInterval);
  }

  static const preferenceKey = 'betterstack_remote_outbox_v1';
  static const maxQueueLength = 100;
  static const maxBatchLength = 20;
  static const maxEventBytes = 2048;
  static const maxOutboxBytes = 64 * 1024;
  static const _outboxSchema = 'blizzard-remote-outbox/v1';
  static const _eventSchema = 'blizzard-remote-diagnostics/v1';
  static const _maxDroppedCount = 9007199254740991;
  static const _ttl = Duration(hours: 24);
  static const _cooldown = Duration(minutes: 5);
  static final _versionPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}$');
  static final _buildPattern = RegExp(r'^\d{1,9}$');
  static final _dayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _eventIdPattern = RegExp(r'^[0-9a-f]{16}$');
  static final _sessionPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
  static const _documentKeys = {
    'schema',
    'events',
    'retry_count',
    'paused_until',
    'budget_blocked_day',
    'dropped_count',
  };
  static const _commonEventKeys = {
    'schema',
    'platform',
    'environment',
    'app_version',
    'build_number',
    'session_id',
    'dt',
    'event_id',
    'level',
    'message',
  };
  static const _diagnosticPayloadKeys = {
    'sequence',
    'operation_id',
    'operation',
    'stage',
    'code',
    'duration_ms',
    'reachability',
  };
  static const _iosPingPayloadKeys = {
    'sequence',
    'operation_id',
    'operation',
    'stage',
    'code',
    'elapsed_ms',
    'reachability',
  };
  static const _testPayloadKeys = {'event', 'sequence'};

  final Uri endpoint;
  final String sessionId;
  final String _version;
  final String _buildNumber;
  final String _token;
  final TelemetryBudget _budget;
  final BetterStackPost? _post;
  final DateTime Function() _now;
  final RemoteOutboxWrite? _writeOutbox;
  final RemoteAttemptWrite? _writeLastAttempt;
  final RemoteAttemptWrite? _writeLastTestAttempt;
  final BetterStackTimerFactory _createTimer;
  final Duration flushInterval;
  final bool autoFlush;
  final Queue<Map<String, Object>> _queue = Queue();
  final StreamController<TelemetryDeliveryStatus> _statusController =
      StreamController<TelemetryDeliveryStatus>.broadcast(sync: true);
  final Map<String, DateTime> _repeated = {};
  final Set<String> _sendingEventIds = {};
  HttpClient? _client;
  Timer? _timer;
  Future<void>? _inFlight;
  Future<TelemetryTestResult>? _testEventInFlight;
  Future<void> _storagePending = Future.value();
  Future<void> _attemptStoragePending = Future.value();
  Future<void> _testAttemptStoragePending = Future.value();
  bool _active;
  bool _storageBlocked = false;
  bool _budgetFailureBlocked = false;
  int _attempts = 0;
  DateTime? _pausedUntil;
  DateTime? _scheduledAt;
  String? _budgetBlockedDay;
  int _droppedCount = 0;
  int _nextTestSequence = 1;
  TelemetryDeliveryState _state = TelemetryDeliveryState.disabled;
  DateTime? _lastAttemptAt;
  int? _lastHttpCode;
  String? _trackedTestEventId;
  TelemetryTestOutcome? _lastTestOutcome;
  TelemetryTransportAttempt? _lastAttempt;
  TelemetryAttemptStorageState _attemptStorageState = TelemetryAttemptStorageState.unconfigured;
  TelemetryTransportAttempt? _lastTestAttempt;
  TelemetryAttemptStorageState _testAttemptStorageState = TelemetryAttemptStorageState.unconfigured;
  int _attemptStorageGeneration = 0;
  int _testAttemptStorageGeneration = 0;
  TelemetryDeliveryStatus? _lastEmittedStatus;

  bool get active => _active;
  int get queuedCount => _queue.length;

  TelemetryDeliveryStatus get deliveryStatus {
    final budget = _budget.logSnapshot;
    final oldest = _queue.isEmpty ? null : DateTime.tryParse(_queue.first['dt']! as String);
    final oldestAge = oldest == null
        ? null
        : _now().toUtc().difference(oldest.toUtc()).inSeconds.clamp(0, _ttl.inSeconds);
    final nextAttempt = _state == TelemetryDeliveryState.budgetLimited
        ? _budgetResumeAt()
        : _state == TelemetryDeliveryState.retryWaiting
        ? (_pausedUntil ?? _scheduledAt)
        : null;
    return TelemetryDeliveryStatus(
      state: _state,
      pendingCount: _queue.length,
      oldestPendingAgeSeconds: oldestAge,
      budgetUsedBytes: budget.usedLogBytes,
      budgetRemainingBytes: budget.remainingLogBytes,
      nextAttemptAt: nextAttempt,
      lastAttemptAt: _lastAttemptAt,
      lastHttpCode: _lastHttpCode,
      lastTestOutcome: _lastTestOutcome,
      lastAttempt: _lastAttempt,
      attemptStorageState: _attemptStorageState,
      lastTestAttempt: _lastTestAttempt,
      testAttemptStorageState: _testAttemptStorageState,
    );
  }

  Stream<TelemetryDeliveryStatus> get deliveryStatuses => _statusController.stream;

  static String _safeMetadata(String? value, RegExp pattern) =>
      value != null && pattern.hasMatch(value) ? value : 'unknown';

  /// Receives typed journal events, never arbitrary application/VPN log records.
  void addDiagnostic(SafeDiagnosticEvent diagnostic) {
    _enqueue(
      diagnostic.toJson(),
      kind: 'diagnostic:${diagnostic.operation.name}:${diagnostic.stage.name}:${diagnostic.code.name}',
      sequence: diagnostic.sequence,
      failed: diagnostic.stage == DiagnosticStage.failed,
      throttleFailure: diagnostic.stage == DiagnosticStage.failed,
    );
  }

  bool addIosPingEvent(IosPingTraceEntry entry) {
    final failed = _isFailedIosPingEvent(entry.event);
    return _enqueue(
      {
        'sequence': entry.sequence,
        'operation_id': entry.operationId,
        'operation': 'ios_ping',
        'stage': failed ? 'failed' : 'state',
        'code': entry.event.name,
        'elapsed_ms': entry.elapsedMilliseconds,
        'reachability': 'not_checked',
      },
      kind: 'ios_ping:${entry.event.name}',
      sequence: entry.sequence,
      failed: failed,
      throttleFailure: false,
    );
  }

  bool addTestEvent() {
    if (_nextTestSequence > SafeDiagnosticEvent.maxCounter) return false;
    final sequence = _nextTestSequence++;
    final eventId = _eventId(sessionId, 'test_event', sequence);
    final retained = _enqueue(
      {'event': 'test_event', 'sequence': sequence},
      kind: 'test_event',
      sequence: sequence,
      failed: false,
      throttleFailure: false,
    );
    if (retained) {
      _trackedTestEventId = eventId;
      _lastTestOutcome = switch (_state) {
        TelemetryDeliveryState.budgetLimited => TelemetryTestOutcome.budgetLimited,
        TelemetryDeliveryState.budgetStateInvalid => TelemetryTestOutcome.budgetStateInvalid,
        TelemetryDeliveryState.budgetStorageFailed => TelemetryTestOutcome.budgetStorageFailed,
        _ => TelemetryTestOutcome.pending,
      };
      if (_state != TelemetryDeliveryState.retryWaiting &&
          _state != TelemetryDeliveryState.budgetLimited &&
          _state != TelemetryDeliveryState.budgetStateInvalid &&
          _state != TelemetryDeliveryState.budgetStorageFailed) {
        _state = TelemetryDeliveryState.pending;
      }
      _emitStatus();
    }
    return retained;
  }

  Future<TelemetryTestResult> sendTestEvent() {
    final running = _testEventInFlight;
    if (running != null) return running;
    late final Future<TelemetryTestResult> completed;
    completed = _sendTestEvent().whenComplete(() {
      if (identical(_testEventInFlight, completed)) _testEventInFlight = null;
    });
    _testEventInFlight = completed;
    return completed;
  }

  Future<TelemetryTestResult> _sendTestEvent() async {
    if (!addTestEvent()) {
      return TelemetryTestResult(outcome: _active ? TelemetryTestOutcome.rejected : TelemetryTestOutcome.disabled);
    }
    if (!await _persist()) {
      return TelemetryTestResult(outcome: _lastTestOutcome ?? TelemetryTestOutcome.outboxStorageFailed);
    }
    await flush();
    return TelemetryTestResult(outcome: _lastTestOutcome ?? TelemetryTestOutcome.pending);
  }

  bool _enqueue(
    Map<String, Object> payload, {
    required String kind,
    required int sequence,
    required bool failed,
    required bool throttleFailure,
  }) {
    if (!_active) return false;
    final now = _now().toUtc();
    if (_attempts >= 3 && _pausedUntil != null && !now.isBefore(_pausedUntil!)) {
      _attempts = 0;
      _pausedUntil = null;
    }
    if (throttleFailure) {
      final key = ['operation', 'stage', 'code'].map((key) => payload[key]).join(':');
      final previous = _repeated[key];
      if (previous != null && now.difference(previous) < const Duration(minutes: 1)) return false;
      if (_repeated.length >= 100) _repeated.remove(_repeated.keys.first);
      _repeated[key] = now;
    }
    final eventId = _eventId(sessionId, kind, sequence);
    final event = <String, Object>{
      ...payload,
      'schema': _eventSchema,
      'platform': 'ios',
      'environment': 'beta',
      'app_version': _version,
      'build_number': _buildNumber,
      'session_id': sessionId,
      'dt': now.toIso8601String(),
      'event_id': eventId,
      'level': failed ? 'error' : 'info',
      'message': payload['event'] ?? '${payload['operation']}.${payload['stage']}.${payload['code']}',
    };
    if (utf8.encode(jsonEncode(event)).length > maxEventBytes) return false;
    _queue.add(event);
    _fitBounds();
    final retained = _queue.any((queued) => queued['event_id'] == eventId);
    if (!retained) return false;
    if (_state == TelemetryDeliveryState.idle || _state == TelemetryDeliveryState.accepted) {
      _state = TelemetryDeliveryState.pending;
    }
    _emitStatus();
    unawaited(_persist());
    _schedule(flushInterval);
    return true;
  }

  void _schedule(Duration delay) {
    if (!autoFlush ||
        !_active ||
        _queue.isEmpty ||
        _timer != null ||
        _inFlight != null ||
        _storageBlocked ||
        _budgetFailureBlocked) {
      return;
    }
    final now = _now().toUtc();
    var scheduledDelay = delay;
    if (_attempts >= 3) {
      final pausedUntil = _pausedUntil;
      if (pausedUntil == null) return;
      if (now.isBefore(pausedUntil)) {
        scheduledDelay = pausedUntil.difference(now);
      } else {
        _attempts = 0;
        _pausedUntil = null;
        unawaited(_persist());
      }
    }
    final budgetBlockActive = _isBudgetBlockActive();
    if (_budgetFailureBlocked) return;
    if (budgetBlockActive) {
      final resumeAt = _budgetResumeAt();
      scheduledDelay = now.isBefore(resumeAt) ? resumeAt.difference(now) : Duration.zero;
    }
    _scheduledAt = now.add(scheduledDelay);
    _timer = _createTimer(scheduledDelay, () {
      _timer = null;
      _scheduledAt = null;
      unawaited(flush());
    });
    if (_state == TelemetryDeliveryState.retryWaiting || _state == TelemetryDeliveryState.budgetLimited) {
      _emitStatus();
    }
  }

  Future<void> flush() {
    final running = _inFlight;
    if (running != null) return running;
    _refreshRetryCooldown();
    if (!_active || _queue.isEmpty || _budgetFailureBlocked || _attempts >= 3) {
      _emitStatus();
      _schedule(flushInterval);
      return Future.value();
    }
    final budgetBlockActive = _isBudgetBlockActive();
    if (_budgetFailureBlocked || budgetBlockActive) {
      _emitStatus();
      _schedule(flushInterval);
      return Future.value();
    }
    _timer?.cancel();
    _timer = null;
    _scheduledAt = null;
    final sending = _sendBatch();
    late final Future<void> completed;
    completed = sending.whenComplete(() {
      _inFlight = null;
      final delay = _attempts == 0 ? flushInterval : Duration(seconds: 10 * (1 << _attempts));
      _schedule(delay);
    });
    _inFlight = completed;
    return completed;
  }

  Future<void> resumePending() async {
    if (!_active || _queue.isEmpty) return;
    _scheduledAt = null;
    _budgetFailureBlocked = false;
    if (!await _persist()) return;
    _refreshRetryCooldown();
    if (_attempts >= 3 || _isBudgetBlockActive()) {
      _emitStatus();
      _schedule(Duration.zero);
      return;
    }
    _state = TelemetryDeliveryState.pending;
    _emitStatus();
    await flush();
  }

  void _refreshRetryCooldown() {
    final pausedUntil = _pausedUntil;
    if (_attempts < 3 || pausedUntil == null || _now().toUtc().isBefore(pausedUntil)) return;
    _attempts = 0;
    _pausedUntil = null;
    _scheduledAt = null;
    if (_state == TelemetryDeliveryState.retryWaiting) {
      _state = _queue.isEmpty ? TelemetryDeliveryState.idle : TelemetryDeliveryState.pending;
    }
    unawaited(_persist());
  }

  Future<void> _sendBatch() async {
    _dropExpired();
    if (_queue.isEmpty) {
      if (_state == TelemetryDeliveryState.pending || _state == TelemetryDeliveryState.sending) {
        _state = TelemetryDeliveryState.idle;
        _emitStatus();
      }
      return;
    }
    final budgetSnapshot = _budget.logSnapshot;
    if (budgetSnapshot.outcome == TelemetryBudgetReserveOutcome.invalidStoredState) {
      _setBudgetFailure(TelemetryDeliveryState.budgetStateInvalid, TelemetryTestOutcome.budgetStateInvalid);
      return;
    }
    if (budgetSnapshot.outcome == TelemetryBudgetReserveOutcome.storageReadFailed) {
      _setBudgetFailure(TelemetryDeliveryState.budgetStorageFailed, TelemetryTestOutcome.budgetStorageFailed);
      return;
    }
    final batch = _fittingPrefix(budgetSnapshot.remainingLogBytes);
    if (batch.isEmpty) {
      _budgetBlockedDay = _today();
      _state = TelemetryDeliveryState.budgetLimited;
      _setTrackedTestOutcome(TelemetryTestOutcome.budgetLimited, _queue);
      await _persist();
      _emitStatus();
      return;
    }
    _sendingEventIds
      ..clear()
      ..addAll(batch.map((event) => event['event_id']! as String));
    if (!await _persist() || !_active) {
      _sendingEventIds.clear();
      return;
    }
    final body = jsonEncode(batch);
    final reservation = await _budget.reserveLogs(utf8.encode(body).length);
    switch (reservation.outcome) {
      case TelemetryBudgetReserveOutcome.reserved:
        break;
      case TelemetryBudgetReserveOutcome.limitExceeded:
        _budgetBlockedDay = _today();
        _state = TelemetryDeliveryState.budgetLimited;
        _setTrackedTestOutcome(TelemetryTestOutcome.budgetLimited, batch);
        await _persist();
        _sendingEventIds.clear();
        _emitStatus();
        return;
      case TelemetryBudgetReserveOutcome.invalidStoredState:
        _setBudgetFailure(
          TelemetryDeliveryState.budgetStateInvalid,
          TelemetryTestOutcome.budgetStateInvalid,
          batch: batch,
        );
        _sendingEventIds.clear();
        return;
      case TelemetryBudgetReserveOutcome.storageReadFailed:
      case TelemetryBudgetReserveOutcome.storageWriteFailed:
      case TelemetryBudgetReserveOutcome.invalidRequest:
        _setBudgetFailure(
          TelemetryDeliveryState.budgetStorageFailed,
          TelemetryTestOutcome.budgetStorageFailed,
          batch: batch,
        );
        _sendingEventIds.clear();
        return;
    }
    if (!_active) {
      _sendingEventIds.clear();
      return;
    }
    _state = TelemetryDeliveryState.sending;
    final attemptedAt = _now().toUtc();
    final tracked = _trackedTestEventId;
    final testEventId = tracked != null && batch.any((event) => event['event_id'] == tracked) ? tracked : null;
    _lastAttemptAt = attemptedAt;
    _lastHttpCode = null;
    _recordLastAttempt(
      TelemetryTransportAttempt(
        attemptedAt: attemptedAt,
        testEventId: testEventId,
        appVersion: _version,
        buildNumber: _buildNumber,
        stage: TelemetryTransportStage.beforeRequest,
        ackOwnEvent: testEventId == null ? null : false,
      ),
    );
    _emitStatus();
    int? status;
    TelemetryTransportOutcome? transportFailure;
    try {
      status = await (_post ?? _httpPost)(endpoint, _token, body).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _client?.close(force: true);
          _client = null;
          throw TimeoutException('Telemetry request timed out');
        },
      );
    } on TimeoutException {
      transportFailure = TelemetryTransportOutcome.timeout;
    } on TlsException {
      transportFailure = TelemetryTransportOutcome.tls;
    } on SocketException {
      transportFailure = TelemetryTransportOutcome.network;
    } catch (_) {
      transportFailure = TelemetryTransportOutcome.other;
      // No recursive logger call: the transport's own failures remain silent.
    }
    if (!_active) {
      _sendingEventIds.clear();
      return;
    }
    _lastHttpCode = status;
    _recordLastAttempt(
      TelemetryTransportAttempt(
        attemptedAt: attemptedAt,
        testEventId: testEventId,
        appVersion: _version,
        buildNumber: _buildNumber,
        stage: TelemetryTransportStage.afterRequest,
        outcome: status == null ? transportFailure ?? TelemetryTransportOutcome.other : TelemetryTransportOutcome.http,
        httpCode: status,
        ackOwnEvent: testEventId == null ? null : status != null && status >= 200 && status < 300,
      ),
    );
    if (status != null && status >= 200 && status < 300) {
      _setTrackedTestOutcome(TelemetryTestOutcome.accepted, batch);
      _removeAcknowledged(batch);
      _attempts = 0;
      _pausedUntil = null;
      _scheduledAt = null;
      _state = TelemetryDeliveryState.accepted;
      await _persist();
    } else if (status == 401 || status == 402 || status == 403) {
      _setTrackedTestOutcome(TelemetryTestOutcome.rejected, _queue);
      _active = false;
      _timer?.cancel();
      _timer = null;
      _queue.clear();
      _attempts = 0;
      _pausedUntil = null;
      _scheduledAt = null;
      _budgetBlockedDay = null;
      _state = TelemetryDeliveryState.rejected;
      await _persist();
      _client?.close(force: true);
      _client = null;
    } else if (status == null || status == 408 || status == 429 || status >= 500) {
      _attempts++;
      if (_attempts >= 3) _pausedUntil = _now().toUtc().add(_cooldown);
      _setTrackedTestOutcome(TelemetryTestOutcome.pending, batch);
      _state = TelemetryDeliveryState.retryWaiting;
      await _persist();
    } else {
      _setTrackedTestOutcome(TelemetryTestOutcome.rejected, batch);
      _removeAcknowledged(batch);
      _attempts = 0;
      _pausedUntil = null;
      _state = TelemetryDeliveryState.rejected;
      await _persist();
    }
    _sendingEventIds.clear();
    _emitStatus();
  }

  List<Map<String, Object>> _fittingPrefix(int remainingBytes) {
    final batch = <Map<String, Object>>[];
    for (final event in _queue.take(maxBatchLength)) {
      final candidate = [...batch, event];
      if (utf8.encode(jsonEncode(candidate)).length > remainingBytes) break;
      batch.add(event);
    }
    return batch;
  }

  void _setBudgetFailure(
    TelemetryDeliveryState state,
    TelemetryTestOutcome testOutcome, {
    Iterable<Map<String, Object>>? batch,
  }) {
    _budgetFailureBlocked = true;
    _state = state;
    _setTrackedTestOutcome(testOutcome, batch ?? _queue);
    _emitStatus();
  }

  void _setTrackedTestOutcome(TelemetryTestOutcome outcome, Iterable<Map<String, Object>> events) {
    final tracked = _trackedTestEventId;
    if (tracked != null && events.any((event) => event['event_id'] == tracked)) {
      _lastTestOutcome = outcome;
    }
  }

  void _removeAcknowledged(Iterable<Map<String, Object>> batch) {
    for (final event in batch) {
      _queue.remove(event);
    }
  }

  void _fitBounds() {
    while (_queue.length > maxQueueLength || utf8.encode(_encodeDocument()).length > maxOutboxBytes) {
      Map<String, Object>? candidate;
      for (final event in _queue) {
        if (!_sendingEventIds.contains(event['event_id'])) {
          candidate = event;
          break;
        }
      }
      if (candidate == null) break;
      _markDropped(candidate, TelemetryTestOutcome.droppedOverflow, TelemetryDeliveryState.droppedOverflow);
      _queue.remove(candidate);
      _droppedCount = (_droppedCount + 1).clamp(0, _maxDroppedCount);
    }
  }

  void _dropExpired() {
    final now = _now().toUtc();
    final expired = _queue
        .where((event) {
          final dt = DateTime.tryParse(event['dt']! as String);
          return dt == null || now.difference(dt.toUtc()) > _ttl;
        })
        .toList(growable: false);
    for (final event in expired) {
      if (_sendingEventIds.contains(event['event_id'])) continue;
      _markDropped(event, TelemetryTestOutcome.droppedExpired, TelemetryDeliveryState.droppedExpired);
      _queue.remove(event);
      _droppedCount = (_droppedCount + 1).clamp(0, _maxDroppedCount);
    }
    if (expired.isNotEmpty) {
      _emitStatus();
      unawaited(_persist());
    }
  }

  void _markDropped(Map<String, Object> event, TelemetryTestOutcome outcome, TelemetryDeliveryState state) {
    if (event['event_id'] == _trackedTestEventId) {
      _lastTestOutcome = outcome;
      _state = state;
    }
  }

  bool _isBudgetBlockActive() {
    final blocked = _budgetBlockedDay;
    if (blocked == null) return false;
    final today = _today();
    if (blocked.compareTo(today) >= 0) {
      final snapshot = _budget.logSnapshot;
      if (snapshot.outcome == TelemetryBudgetReserveOutcome.invalidStoredState) {
        _setBudgetFailure(TelemetryDeliveryState.budgetStateInvalid, TelemetryTestOutcome.budgetStateInvalid);
        return false;
      }
      if (snapshot.outcome == TelemetryBudgetReserveOutcome.storageReadFailed) {
        _setBudgetFailure(TelemetryDeliveryState.budgetStorageFailed, TelemetryTestOutcome.budgetStorageFailed);
        return false;
      }
      if (_fittingPrefix(snapshot.remainingLogBytes).isEmpty) return true;
    }
    _budgetBlockedDay = null;
    if (_state == TelemetryDeliveryState.budgetLimited) {
      _state = _queue.isEmpty ? TelemetryDeliveryState.idle : TelemetryDeliveryState.pending;
      if (_lastTestOutcome == TelemetryTestOutcome.budgetLimited) {
        _lastTestOutcome = TelemetryTestOutcome.pending;
      }
      _emitStatus();
    }
    unawaited(_persist());
    return false;
  }

  DateTime _budgetResumeAt() {
    final blocked = _budgetBlockedDay;
    if (blocked != null) {
      final start = DateTime.tryParse('${blocked}T00:00:00.000Z');
      if (start != null) return start.add(const Duration(days: 1));
    }
    final now = _now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1);
  }

  String _today() => _now().toUtc().toIso8601String().substring(0, 10);

  void _emitStatus() {
    if (_statusController.isClosed) return;
    final status = deliveryStatus;
    if (status == _lastEmittedStatus) return;
    _lastEmittedStatus = status;
    _statusController.add(status);
  }

  void _restoreLastAttempt(RemoteAttemptRead? reader) {
    if (reader == null && _writeLastAttempt == null) return;
    _attemptStorageState = TelemetryAttemptStorageState.persisted;
    if (reader == null) return;
    try {
      final stored = reader();
      if (stored == null) return;
      final restored = TelemetryTransportAttempt.decode(stored);
      _lastAttempt = restored;
      _lastAttemptAt = restored.attemptedAt;
      _lastHttpCode = restored.httpCode;
      if (restored.testEventId != null) {
        _lastTestAttempt = restored;
        _restoreTestOutcome(restored);
      }
    } catch (_) {
      _lastAttempt = null;
      _lastAttemptAt = null;
      _lastHttpCode = null;
      _attemptStorageState = TelemetryAttemptStorageState.failed;
    }
  }

  void _restoreLastTestAttempt(RemoteAttemptRead? reader) {
    if (reader == null && _writeLastTestAttempt == null) return;
    _testAttemptStorageState = TelemetryAttemptStorageState.persisted;
    final fallback = _lastTestAttempt;
    if (reader == null) {
      if (fallback != null) _repairLastTestAttempt(fallback);
      return;
    }
    try {
      final stored = reader();
      if (stored == null) {
        if (fallback != null) {
          _repairLastTestAttempt(fallback);
        } else {
          _testAttemptStorageState = TelemetryAttemptStorageState.failed;
        }
        return;
      }
      final restored = TelemetryTransportAttempt.decode(stored);
      if (restored.testEventId == null) throw const FormatException('missing test event');
      if (fallback != null && !_shouldReplaceRestoredTestAttempt(restored, fallback)) {
        if (restored != fallback) _repairLastTestAttempt(fallback);
        return;
      }
      _lastTestAttempt = restored;
      _restoreTestOutcome(restored);
    } catch (_) {
      if (fallback != null) {
        _repairLastTestAttempt(fallback);
      } else {
        _testAttemptStorageState = TelemetryAttemptStorageState.failed;
      }
    }
  }

  bool _shouldReplaceRestoredTestAttempt(TelemetryTransportAttempt candidate, TelemetryTransportAttempt current) {
    final timestampOrder = candidate.attemptedAt.compareTo(current.attemptedAt);
    if (timestampOrder != 0) return timestampOrder > 0;
    if (candidate.testEventId != current.testEventId) return false;
    return candidate.stage == TelemetryTransportStage.afterRequest &&
        current.stage == TelemetryTransportStage.beforeRequest;
  }

  void _repairLastTestAttempt(TelemetryTransportAttempt fallback) {
    if (_writeLastTestAttempt == null) {
      _testAttemptStorageState = TelemetryAttemptStorageState.failed;
      return;
    }
    _recordLastTestAttempt(fallback);
  }

  void _restoreTestOutcome(TelemetryTransportAttempt restored) {
    if (_trackedTestEventId != null) return;
    _lastTestOutcome = restored.ackOwnEvent == true
        ? TelemetryTestOutcome.accepted
        : restored.outcome == TelemetryTransportOutcome.http &&
              restored.httpCode != null &&
              restored.httpCode! >= 400 &&
              restored.httpCode! < 500 &&
              restored.httpCode != 408 &&
              restored.httpCode != 429
        ? TelemetryTestOutcome.rejected
        : TelemetryTestOutcome.pending;
  }

  void _recordLastAttempt(TelemetryTransportAttempt attempt) {
    _lastAttempt = attempt;
    _lastAttemptAt = attempt.attemptedAt;
    _lastHttpCode = attempt.httpCode;
    if (attempt.testEventId != null) _recordLastTestAttempt(attempt);
    final writer = _writeLastAttempt;
    if (writer == null) {
      _attemptStorageState = TelemetryAttemptStorageState.unconfigured;
      _emitStatus();
      return;
    }
    final generation = ++_attemptStorageGeneration;
    _attemptStorageState = TelemetryAttemptStorageState.pending;
    _emitStatus();
    final operation = _attemptStoragePending.then((_) async {
      var saved = false;
      try {
        saved = await writer(attempt.encode());
      } catch (_) {
        // The closed receipt is diagnostic only and never logs recursively.
      }
      if (generation == _attemptStorageGeneration) {
        _attemptStorageState = saved ? TelemetryAttemptStorageState.persisted : TelemetryAttemptStorageState.failed;
        _emitStatus();
      }
    });
    _attemptStoragePending = operation;
  }

  void _recordLastTestAttempt(TelemetryTransportAttempt attempt) {
    if (attempt.testEventId == null) return;
    _lastTestAttempt = attempt;
    final writer = _writeLastTestAttempt;
    if (writer == null) {
      _testAttemptStorageState = TelemetryAttemptStorageState.unconfigured;
      _emitStatus();
      return;
    }
    final generation = ++_testAttemptStorageGeneration;
    _testAttemptStorageState = TelemetryAttemptStorageState.pending;
    _emitStatus();
    final operation = _testAttemptStoragePending.then((_) async {
      var saved = false;
      try {
        saved = await writer(attempt.encode());
      } catch (_) {
        // The closed test receipt is diagnostic only and never logs recursively.
      }
      if (generation == _testAttemptStorageGeneration) {
        _testAttemptStorageState = saved ? TelemetryAttemptStorageState.persisted : TelemetryAttemptStorageState.failed;
        _emitStatus();
      }
    });
    _testAttemptStoragePending = operation;
  }

  Future<bool> _persist() {
    final writer = _writeOutbox;
    if (writer == null) {
      _storageBlocked = false;
      _onPersisted();
      return Future.value(true);
    }
    final operation = _storagePending.then((_) async {
      try {
        _fitBounds();
        final encoded = _encodeDocument();
        if (utf8.encode(encoded).length > maxOutboxBytes) {
          _onPersistenceFailure();
          return false;
        }
        final saved = await writer(encoded);
        if (saved) {
          _storageBlocked = false;
          _onPersisted();
        } else {
          _onPersistenceFailure();
        }
        return saved;
      } catch (_) {
        _onPersistenceFailure();
        return false;
      }
    });
    _storagePending = operation.then<void>((_) {});
    return operation;
  }

  void _onPersisted() {
    final tracked = _trackedTestEventId;
    if (tracked != null &&
        _queue.any((event) => event['event_id'] == tracked) &&
        _lastTestOutcome == TelemetryTestOutcome.pending &&
        _state == TelemetryDeliveryState.pending) {
      _lastTestOutcome = TelemetryTestOutcome.persisted;
    }
    if (_state == TelemetryDeliveryState.outboxStorageFailed && _queue.isNotEmpty) {
      _state = TelemetryDeliveryState.pending;
    }
    _emitStatus();
  }

  void _onPersistenceFailure() {
    _storageBlocked = true;
    _state = TelemetryDeliveryState.outboxStorageFailed;
    _setTrackedTestOutcome(TelemetryTestOutcome.outboxStorageFailed, _queue);
    _emitStatus();
  }

  String _encodeDocument() => jsonEncode({
    'schema': _outboxSchema,
    'events': _queue.toList(growable: false),
    'retry_count': _attempts.clamp(0, 3),
    'paused_until': _pausedUntil?.toIso8601String(),
    'budget_blocked_day': _budgetBlockedDay,
    'dropped_count': _droppedCount,
  });

  void _restore(RemoteOutboxRead readOutbox) {
    try {
      final stored = readOutbox();
      if (stored == null) return;
      if (utf8.encode(stored).length > maxOutboxBytes) throw const FormatException('oversized outbox');
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, dynamic> ||
          decoded.length != _documentKeys.length ||
          !decoded.keys.every(_documentKeys.contains) ||
          decoded['schema'] != _outboxSchema ||
          decoded['events'] is! List ||
          (decoded['events'] as List).length > maxQueueLength ||
          decoded['retry_count'] is! int ||
          (decoded['retry_count'] as int) < 0 ||
          (decoded['retry_count'] as int) > 3 ||
          decoded['dropped_count'] is! int ||
          (decoded['dropped_count'] as int) < 0 ||
          (decoded['dropped_count'] as int) > _maxDroppedCount) {
        throw const FormatException('invalid outbox document');
      }
      final pausedUntil = _optionalUtcDateTime(decoded['paused_until']);
      final budgetBlockedDay = decoded['budget_blocked_day'];
      if (budgetBlockedDay != null && (budgetBlockedDay is! String || !_dayPattern.hasMatch(budgetBlockedDay))) {
        throw const FormatException('invalid budget pause');
      }
      final retryCount = decoded['retry_count'] as int;
      if ((retryCount >= 3) != (pausedUntil != null)) throw const FormatException('invalid retry pause');

      final restored = <Map<String, Object>>[];
      var dropped = decoded['dropped_count'] as int;
      var maxTestSequence = 0;
      final now = _now().toUtc();
      for (final rawEvent in decoded['events'] as List) {
        final event = _validateEvent(rawEvent, now);
        if (event == null) {
          if (rawEvent is Map && rawEvent['event'] == 'test_event' && rawEvent['event_id'] is String) {
            _trackedTestEventId = rawEvent['event_id'] as String;
            _lastTestOutcome = TelemetryTestOutcome.droppedExpired;
            _state = TelemetryDeliveryState.droppedExpired;
          }
          dropped = (dropped + 1).clamp(0, _maxDroppedCount);
          continue;
        }
        restored.add(event);
        if (event['event'] == 'test_event') {
          maxTestSequence = (event['sequence']! as int) > maxTestSequence ? event['sequence']! as int : maxTestSequence;
          _trackedTestEventId = event['event_id']! as String;
          _lastTestOutcome = TelemetryTestOutcome.persisted;
        }
      }
      _queue.addAll(restored);
      _attempts = retryCount;
      _pausedUntil = pausedUntil;
      _budgetBlockedDay = budgetBlockedDay as String?;
      _droppedCount = dropped;
      _nextTestSequence = maxTestSequence + 1;
      if (dropped != decoded['dropped_count']) unawaited(_persist());
    } catch (_) {
      _queue.clear();
      _attempts = 0;
      _pausedUntil = null;
      _budgetBlockedDay = null;
      _droppedCount = 0;
      _nextTestSequence = 1;
      _state = TelemetryDeliveryState.outboxStorageFailed;
      unawaited(_persist());
    }
  }

  Map<String, Object>? _validateEvent(Object? rawEvent, DateTime now) {
    if (rawEvent is! Map<String, dynamic>) throw const FormatException('invalid outbox event');
    final keys = rawEvent.keys.toSet();
    final payloadKeys = keys.difference(_commonEventKeys);
    final isDiagnostic =
        payloadKeys.length == _diagnosticPayloadKeys.length && payloadKeys.containsAll(_diagnosticPayloadKeys);
    final isIosPing = payloadKeys.length == _iosPingPayloadKeys.length && payloadKeys.containsAll(_iosPingPayloadKeys);
    final isTest = payloadKeys.length == _testPayloadKeys.length && payloadKeys.containsAll(_testPayloadKeys);
    if (keys.length != _commonEventKeys.length + payloadKeys.length || (!isDiagnostic && !isIosPing && !isTest)) {
      throw const FormatException('invalid outbox event fields');
    }
    final version = rawEvent['app_version'];
    final build = rawEvent['build_number'];
    final eventSession = rawEvent['session_id'];
    final dtValue = rawEvent['dt'];
    final eventId = rawEvent['event_id'];
    if (rawEvent['schema'] != _eventSchema ||
        rawEvent['platform'] != 'ios' ||
        rawEvent['environment'] != 'beta' ||
        version is! String ||
        (version != 'unknown' && !_versionPattern.hasMatch(version)) ||
        build is! String ||
        (build != 'unknown' && !_buildPattern.hasMatch(build)) ||
        eventSession is! String ||
        !_sessionPattern.hasMatch(eventSession) ||
        dtValue is! String ||
        eventId is! String ||
        !_eventIdPattern.hasMatch(eventId) ||
        rawEvent['level'] is! String ||
        rawEvent['message'] is! String) {
      throw const FormatException('invalid outbox metadata');
    }
    final dt = DateTime.tryParse(dtValue);
    if (dt == null || !dt.isUtc || now.difference(dt) > _ttl) return null;

    late final String kind;
    late final int sequence;
    late final bool failed;
    late final String message;
    if (isDiagnostic) {
      final payload = Map<String, Object?>.fromEntries(
        _diagnosticPayloadKeys.map((key) => MapEntry(key, rawEvent[key])),
      );
      final diagnostic = SafeDiagnosticEvent.fromJson(payload);
      sequence = diagnostic.sequence;
      kind = 'diagnostic:${diagnostic.operation.name}:${diagnostic.stage.name}:${diagnostic.code.name}';
      failed = diagnostic.stage == DiagnosticStage.failed;
      message = '${diagnostic.operation.name}.${diagnostic.stage.name}.${diagnostic.code.name}';
    } else if (isIosPing) {
      final rawSequence = rawEvent['sequence'];
      final rawOperationId = rawEvent['operation_id'];
      final rawElapsed = rawEvent['elapsed_ms'];
      final code = rawEvent['code'];
      final event = code is String ? _iosPingEventByName(code) : null;
      if (rawSequence is! int ||
          rawOperationId is! int ||
          rawElapsed is! int ||
          event == null ||
          rawEvent['operation'] != 'ios_ping' ||
          rawEvent['reachability'] != 'not_checked') {
        throw const FormatException('invalid iOS ping event');
      }
      IosPingTraceEntry(
        sequence: rawSequence,
        event: event,
        operationId: rawOperationId,
        elapsedMilliseconds: rawElapsed,
      );
      sequence = rawSequence;
      kind = 'ios_ping:${event.name}';
      failed = _isFailedIosPingEvent(event);
      if (rawEvent['stage'] != (failed ? 'failed' : 'state')) throw const FormatException('invalid iOS ping stage');
      message = 'ios_ping.${failed ? 'failed' : 'state'}.${event.name}';
    } else {
      final rawSequence = rawEvent['sequence'];
      if (rawEvent['event'] != 'test_event' ||
          rawSequence is! int ||
          rawSequence < 1 ||
          rawSequence > SafeDiagnosticEvent.maxCounter) {
        throw const FormatException('invalid test event');
      }
      sequence = rawSequence;
      kind = 'test_event';
      failed = false;
      message = 'test_event';
    }
    if (rawEvent['event_id'] != _eventId(eventSession, kind, sequence) ||
        rawEvent['level'] != (failed ? 'error' : 'info') ||
        rawEvent['message'] != message) {
      throw const FormatException('invalid derived event metadata');
    }
    return rawEvent.cast<String, Object>();
  }

  static DateTime? _optionalUtcDateTime(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('invalid timestamp');
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) throw const FormatException('invalid timestamp');
    return parsed;
  }

  static IosPingEvent? _iosPingEventByName(String name) {
    for (final event in IosPingEvent.values) {
      if (event.name == name) return event;
    }
    return null;
  }

  static bool _isFailedIosPingEvent(IosPingEvent event) =>
      event.name.endsWith('Failed') || event.name.endsWith('TimedOut');

  static String _eventId(String session, String kind, int sequence) {
    var first = 0x811c9dc5;
    var second = 0x9e3779b9;
    for (final byte in utf8.encode('$session|$kind|$sequence')) {
      first = ((first ^ byte) * 0x01000193) & 0xffffffff;
      second = ((second ^ byte) * 0x85ebca6b) & 0xffffffff;
    }
    return '${first.toRadixString(16).padLeft(8, '0')}${second.toRadixString(16).padLeft(8, '0')}';
  }

  Future<int> _httpPost(Uri endpoint, String token, String body) async {
    final client = _client ??= (HttpClient()..connectionTimeout = const Duration(seconds: 5));
    final request = await client.postUrl(endpoint);
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.add(utf8.encode(body));
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  }

  Future<void> dispose({bool clearPending = false}) async {
    _active = false;
    _timer?.cancel();
    _timer = null;
    _scheduledAt = null;
    final inFlight = _inFlight;
    if (inFlight != null) await inFlight;
    await Future.wait([_attemptStoragePending, _testAttemptStoragePending]);
    _repeated.clear();
    _sendingEventIds.clear();
    if (clearPending) {
      _queue.clear();
      _attempts = 0;
      _pausedUntil = null;
      _budgetBlockedDay = null;
      _trackedTestEventId = null;
      _lastTestOutcome = TelemetryTestOutcome.disabled;
    }
    await _persist();
    _client?.close(force: true);
    _client = null;
    await _statusController.close();
  }
}
