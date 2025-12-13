import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hiddify/core/logger/log_bus.dart';

class LogBusBridge {
  LogBusBridge._();

  static final LogBusBridge instance = LogBusBridge._();

  final LogBus _bus = LogBus.instance;

  Timer? _timer;
  bool _started = false;

  String? _corePath;
  String? _accessPath;

  int _corePos = 0;
  int _accessPos = 0;

  String _coreCarry = '';
  String _accessCarry = '';

  bool _pollingCore = false;
  bool _pollingAccess = false;

  Future<void> ensureStarted({
    required String coreLogPath,
    required String accessLogPath,
    bool includeExisting = false,
  }) async {
    if (_started) return;
    _started = true;

    _corePath = coreLogPath;
    _accessPath = accessLogPath;

    if (includeExisting) {
      _corePos = 0;
      _accessPos = 0;
      _coreCarry = '';
      _accessCarry = '';
    } else {
      _corePos = await _initialFilePosition(coreLogPath);
      _accessPos = await _initialFilePosition(accessLogPath);
      _coreCarry = '';
      _accessCarry = '';
    }

    _timer ??= Timer.periodic(const Duration(milliseconds: 350), (_) {
      unawaited(_pollCore());
      unawaited(_pollAccess());
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _started = false;

    _corePath = null;
    _accessPath = null;

    _corePos = 0;
    _accessPos = 0;
    _coreCarry = '';
    _accessCarry = '';
  }

  Future<void> _pollCore() async {
    if (_pollingCore) return;
    _pollingCore = true;
    try {
      final path = _corePath;
      if (path == null) return;
      final file = File(path);
      if (!await file.exists()) return;

      final length = await file.length();
      if (length < _corePos) {
        _corePos = 0;
        _coreCarry = '';
      }
      if (length == _corePos) return;

      final raf = await file.open();
      try {
        await raf.setPosition(_corePos);
        final bytes = await raf.read(length - _corePos);
        _corePos = length;

        final chunk = utf8.decode(bytes, allowMalformed: true);
        _coreCarry = _emitLines(
          kind: LogKind.core,
          source: 'core',
          defaultSeverity: LogSeverity.info,
          data: _coreCarry + chunk,
          carrySetter: (v) => _coreCarry = v,
        );
      } finally {
        await raf.close();
      }
    } finally {
      _pollingCore = false;
    }
  }

  Future<void> _pollAccess() async {
    if (_pollingAccess) return;
    _pollingAccess = true;
    try {
      final path = _accessPath;
      if (path == null) return;
      final file = File(path);
      if (!await file.exists()) return;

      final length = await file.length();
      if (length < _accessPos) {
        _accessPos = 0;
        _accessCarry = '';
      }
      if (length == _accessPos) return;

      final raf = await file.open();
      try {
        await raf.setPosition(_accessPos);
        final bytes = await raf.read(length - _accessPos);
        _accessPos = length;

        final chunk = utf8.decode(bytes, allowMalformed: true);
        _accessCarry = _emitLines(
          kind: LogKind.access,
          source: 'access',
          defaultSeverity: LogSeverity.info,
          data: _accessCarry + chunk,
          carrySetter: (v) => _accessCarry = v,
        );
      } finally {
        await raf.close();
      }
    } finally {
      _pollingAccess = false;
    }
  }

  String _emitLines({
    required LogKind kind,
    required String source,
    required LogSeverity defaultSeverity,
    required String data,
    required void Function(String) carrySetter,
  }) {
    final normalized = data.replaceAll('\r\n', '\n');
    final parts = normalized.split('\n');

    var carry = '';
    if (!normalized.endsWith('\n')) {
      carry = parts.removeLast();
    }

    for (final raw in parts) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      _addParsedLine(kind: kind, source: source, defaultSeverity: defaultSeverity, line: line);
    }

    carrySetter(carry);
    return carry;
  }

  void _addParsedLine({
    required LogKind kind,
    required String source,
    required LogSeverity defaultSeverity,
    required String line,
  }) {
    var timestamp = DateTime.now();
    var msg = line;

    final tsMatch = _goLogPrefix.firstMatch(line);
    if (tsMatch != null) {
      final year = int.tryParse(tsMatch.group(1) ?? '');
      final month = int.tryParse(tsMatch.group(2) ?? '');
      final day = int.tryParse(tsMatch.group(3) ?? '');
      final hour = int.tryParse(tsMatch.group(4) ?? '');
      final minute = int.tryParse(tsMatch.group(5) ?? '');
      final second = int.tryParse(tsMatch.group(6) ?? '');
      final microsRaw = tsMatch.group(7) ?? '';
      final rest = tsMatch.group(8) ?? '';

      if (year != null && month != null && day != null && hour != null && minute != null && second != null) {
        final micros = _parseMicros(microsRaw);
        final millis = micros ~/ 1000;
        final microsR = micros % 1000;
        timestamp = DateTime(year, month, day, hour, minute, second, millis, microsR);
        msg = rest.trimLeft();
      }
    }

    var severity = defaultSeverity;

    final sevMatch = _severityPrefix.firstMatch(msg);
    if (sevMatch != null) {
      final sev = (sevMatch.group(1) ?? '').toLowerCase();
      final rest = (sevMatch.group(2) ?? '').trimLeft();
      msg = rest;

      switch (sev) {
        case 'error':
          severity = LogSeverity.error;
          break;
        case 'warning':
          severity = LogSeverity.warning;
          break;
        case 'info':
          severity = LogSeverity.info;
          break;
        case 'debug':
          severity = LogSeverity.debug;
          break;
        default:
          severity = defaultSeverity;
          break;
      }
    } else if (kind == LogKind.access) {
      final lower = msg.toLowerCase();
      if (lower.contains(' rejected ') || lower.contains('rejected')) {
        severity = LogSeverity.warning;
      }
    }

    _bus.add(
      LogEvent(
        timestamp: timestamp,
        severity: severity,
        kind: kind,
        source: source,
        message: msg,
      ),
    );
  }

  static int _parseMicros(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    final padded = digits.length >= 6 ? digits.substring(0, 6) : digits.padRight(6, '0');
    return int.tryParse(padded) ?? 0;
  }

  static final RegExp _goLogPrefix =
      RegExp(r'^(\d{4})\/(\d{2})\/(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\.(\d+)\s+(.*)$');

  static final RegExp _severityPrefix =
      RegExp(r'^\[([^\]]+)\]\s*(.*)$');

  static Future<int> _initialFilePosition(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return file.length();
  }
}
