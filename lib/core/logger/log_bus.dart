import 'dart:async';

enum LogKind { app, core, access, process, system }

enum LogSeverity { debug, info, warning, error }

class LogEvent {
  LogEvent({
    required this.severity,
    required this.kind,
    required this.source,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final DateTime timestamp;
  final LogSeverity severity;
  final LogKind kind;
  final String source;
  final String message;
}

class LogBus {
  LogBus._();

  static final LogBus instance = LogBus._();

  static const int _defaultMaxBuffer = 2000;

  final StreamController<List<LogEvent>> _controller =
      StreamController<List<LogEvent>>.broadcast();

  final List<LogEvent> _buffer = <LogEvent>[];
  final List<LogEvent> _pendingEvents = <LogEvent>[];
  Timer? _debounceTimer;

  bool redactSensitive = true;
  int maxBuffer = _defaultMaxBuffer;

  Stream<List<LogEvent>> get stream => _controller.stream;

  List<LogEvent> get currentBuffer => List<LogEvent>.unmodifiable(_buffer);

  void add(LogEvent event) {
    _pendingEvents.add(event);
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 100), _flush);
  }

  void _flush() {
    if (_pendingEvents.isEmpty) return;

    for (final event in _pendingEvents) {
      final safeEvent = redactSensitive
          ? LogEvent(
              timestamp: event.timestamp,
              severity: event.severity,
              kind: event.kind,
              source: event.source,
              message: _redact(event.message),
            )
          : event;
      _buffer.add(safeEvent);
    }
    _pendingEvents.clear();

    final overflow = _buffer.length - maxBuffer;
    if (overflow > 0) {
      _buffer.removeRange(0, overflow);
    }

    _controller.add(List<LogEvent>.unmodifiable(_buffer));
  }

  void clear() {
    _buffer.clear();
    _pendingEvents.clear();
    _controller.add(const <LogEvent>[]);
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _controller.close();
  }

  static String redact(String input) => _redact(input);

  static String _redact(String input) {
    var out = input;

    out = out.replaceAllMapped(
      RegExp(r'\b(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\b'),
      (m) => '${m[1]}.${m[2]}.*.*',
    );

    out = out.replaceAllMapped(
      RegExp(
        r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
      ),
      (_) => '[REDACTED-UUID]',
    );

    out = out.replaceAllMapped(
      RegExp(
        r'\b(password|pass|psk|token|secret)=([^\s&]+)',
        caseSensitive: false,
      ),
      (m) => '${m[1]}=[REDACTED]',
    );

    out = out.replaceAllMapped(
      RegExp(r'\b(?:[0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}\b'),
      (m) {
        final raw = m[0] ?? '';
        final parts = raw.split(':').where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}::/32';
        }
        if (parts.isNotEmpty) {
          return '${parts[0]}::/16';
        }
        return '::/0';
      },
    );

    return out;
  }
}
