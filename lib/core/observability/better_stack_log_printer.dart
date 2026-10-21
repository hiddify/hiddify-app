import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';


typedef BetterStackPost = Future<int> Function(Uri endpoint, String token, String body);

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
  }) : _version = _safeMetadata(version, RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}$')),
       _buildNumber = _safeMetadata(buildNumber, RegExp(r'^\d{1,9}$')),
       _token = token,
       _budget = budget,
       _post = post,
       _now = now ?? DateTime.now,
       _active = token.isNotEmpty && isBetterStackLogsEndpoint(endpoint);

  static const maxQueueLength = 100;
  static const maxBatchLength = 20;
  static const maxEventBytes = 2048;
  final Uri endpoint;
  final String sessionId;
  final String _version;
  final String _buildNumber;
  final String _token;
  final TelemetryBudget _budget;
  final BetterStackPost? _post;
  final DateTime Function() _now;
  final Duration flushInterval;
  final bool autoFlush;
  final Queue<Map<String, Object>> _queue = Queue();
  final Map<String, DateTime> _repeated = {};
  HttpClient? _client;
  Timer? _timer;
  Future<void>? _inFlight;
  bool _active;
  int _attempts = 0;

  bool get active => _active;
  int get queuedCount => _queue.length;

  static String _safeMetadata(String? value, RegExp pattern) =>
      value != null && pattern.hasMatch(value) ? value : 'unknown';

  /// Receives typed journal events, never arbitrary application/VPN log records.
  void addDiagnostic(SafeDiagnosticEvent diagnostic) {
    _enqueue(diagnostic.toJson(), failed: diagnostic.stage == DiagnosticStage.failed);
  }

  bool addTestEvent() => _enqueue(const {'event': 'test_event'}, failed: false);

  bool _enqueue(Map<String, Object> payload, {required bool failed}) {
    if (!_active || _queue.length >= maxQueueLength) return false;
    if (failed) {
      final key = ['operation', 'stage', 'code'].map((key) => payload[key]).join(':');
      final now = _now().toUtc();
      final previous = _repeated[key];
      if (previous != null && now.difference(previous) < const Duration(minutes: 1)) return false;
      if (_repeated.length >= 100) _repeated.remove(_repeated.keys.first);
      _repeated[key] = now;
    }
    final event = <String, Object>{
      ...payload,
      'schema': 'blizzard-remote-diagnostics/v1',
      'platform': 'ios',
      'environment': 'beta',
      'app_version': _version,
      'build_number': _buildNumber,
      'session_id': sessionId,
      'dt': _now().toUtc().toIso8601String(),
      'level': failed ? 'error' : 'info',
      'message': payload['event'] ?? '${payload['operation']}.${payload['stage']}.${payload['code']}',
    };
    if (utf8.encode(jsonEncode(event)).length > maxEventBytes) return false;
    _queue.add(event);
    _schedule(flushInterval);
    return true;
  }

  void _schedule(Duration delay) {
    if (!autoFlush || !_active || _queue.isEmpty || _timer != null || _inFlight != null) return;
    _timer = Timer(delay, () {
      _timer = null;
      unawaited(flush());
    });
  }

  Future<void> flush() {
    final running = _inFlight;
    if (running != null) return running;
    if (!_active || _queue.isEmpty) return Future.value();
    _timer?.cancel();
    _timer = null;
    final sending = _sendBatch();
    final completed = sending.whenComplete(() {
      _inFlight = null;
      _schedule(_attempts == 0 ? flushInterval : Duration(seconds: 10 * (1 << _attempts)));
    });
    _inFlight = completed;
    return completed;
  }

  Future<void> _sendBatch() async {
    final batch = _queue.take(maxBatchLength).toList(growable: false);
    final body = jsonEncode(batch);
    if (!await _budget.reserveLogs(utf8.encode(body).length)) {
      _queue.clear();
      return;
    }
    if (!_active) return;
    int? status;
    try {
      status = await (_post ?? _httpPost)(endpoint, _token, body).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _client?.close(force: true);
          _client = null;
          throw TimeoutException('Telemetry request timed out');
        },
      );
    } catch (_) {
      // No recursive logger call: the transport's own failures remain silent.
    }
    if (!_active) return;
    if (status != null && status >= 200 && status < 300) {
      _discard(batch.length);
      _attempts = 0;
    } else if (status == 402 || status == 401 || status == 403) {
      // Free quota exhausted / invalid credentials: no retry storm this session.
      await dispose();
    } else if (status == null || status == 408 || status == 429 || status >= 500) {
      if (++_attempts >= 3) {
        _discard(batch.length);
        _attempts = 0;
      }
    } else {
      _discard(batch.length);
      _attempts = 0;
    }
  }

  void _discard(int count) {
    for (var i = 0; i < count && _queue.isNotEmpty; i++) {
      _queue.removeFirst();
    }
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

  Future<void> dispose() async {
    _active = false;
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    _repeated.clear();
    _client?.close(force: true);
  }
}
