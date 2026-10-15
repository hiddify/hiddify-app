import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/logger/custom_logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/logger/safe_log_record.dart';
import 'package:loggy/loggy.dart';
// ignore: depend_on_referenced_packages
import 'package:stack_trace/stack_trace.dart';

const _hostileMarkers = <String>[
  'https://private.example.invalid/sub?token=fixture-secret',
  '10.23.45.67',
  '123e4567-e89b-12d3-a456-426614174000',
  'fixture-private-key',
  'ProfileConfig{password: fixture-secret}',
];

class _PoisonObject {
  @override
  String toString() => throw StateError('unsafe object was serialized');
}

class _RecordingPrinter extends LoggyPrinter {
  final records = <LogRecord>[];

  @override
  void onLog(LogRecord record) => records.add(record);
}

void main() {
  test('safe transform replaces every arbitrary LogRecord field with a closed record', () {
    final hostile = LogRecord(
      LogLevel.error,
      _hostileMarkers.join(' '),
      'logger-${_hostileMarkers[2]}',
      _PoisonObject(),
      StackTrace.fromString('stack ${_hostileMarkers[0]}'),
      Zone.current,
      _PoisonObject(),
      Frame(Uri.parse('file:///private/${_hostileMarkers[3]}'), 42, 7, 'caller-${_hostileMarkers[4]}'),
    );

    final safe = safeLogRecord(hostile);

    expect(safe.level, LogLevel.error);
    expect(safe.message, 'safe_diagnostic.log.error');
    expect(safe.loggerName, 'safe_diagnostics');
    expect(safe.error, isNull);
    expect(safe.stackTrace, isNull);
    expect(safe.zone, isNull);
    expect(safe.object, isNull);
    expect(safe.callerFrame, isNull);
    final serialized =
        '${safe.message}|${safe.loggerName}|${safe.error}|${safe.stackTrace}|${safe.object}|${safe.callerFrame}';
    for (final marker in _hostileMarkers) {
      expect(serialized, isNot(contains(marker)));
    }
  });

  test('safe transform preserves only allowlisted severity and derives a fixed code from it', () {
    final cases = <(LogLevel, LogLevel, String)>[
      (LogLevel.debug, LogLevel.debug, 'safe_diagnostic.log.debug'),
      (LogLevel.info, LogLevel.info, 'safe_diagnostic.log.info'),
      (LogLevel.warning, LogLevel.warning, 'safe_diagnostic.log.warning'),
      (LogLevel.error, LogLevel.error, 'safe_diagnostic.log.error'),
      (const LogLevel('CustomSecret', 37), LogLevel.info, 'safe_diagnostic.log.info'),
      (LogLevel.all, LogLevel.info, 'safe_diagnostic.log.info'),
      (LogLevel.off, LogLevel.info, 'safe_diagnostic.log.info'),
    ];

    for (final (input, expectedLevel, expectedCode) in cases) {
      final safe = safeLogRecord(LogRecord(input, 'arbitrary', 'arbitrary'));
      expect(safe.level, expectedLevel);
      expect(safe.message, expectedCode);
    }
  });

  test('safe printer sanitizes before forwarding to any concrete sink', () {
    final delegate = _RecordingPrinter();
    final printer = SafeLoggyPrinter(delegate);

    printer.onLog(
      LogRecord(
        LogLevel.warning,
        _hostileMarkers.join(' '),
        _hostileMarkers[2],
        _PoisonObject(),
        StackTrace.fromString(_hostileMarkers[4]),
        Zone.current,
        _PoisonObject(),
      ),
    );

    expect(delegate.records, hasLength(1));
    final forwarded = delegate.records.single;
    expect(forwarded.message, 'safe_diagnostic.log.warning');
    expect(forwarded.loggerName, 'safe_diagnostics');
    expect(forwarded.error, isNull);
    expect(forwarded.stackTrace, isNull);
    expect(forwarded.object, isNull);
  });

  test('safe printer keeps hostile content out of real console output', () {
    final output = <String>[];

    runZoned(
      () => const SafeLoggyPrinter(ConsolePrinter()).onLog(
        LogRecord(
          LogLevel.error,
          _hostileMarkers.join(' '),
          _hostileMarkers[2],
          _PoisonObject(),
          StackTrace.fromString(_hostileMarkers[4]),
          Zone.current,
          _PoisonObject(),
        ),
      ),
      zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => output.add(line)),
    );

    final serialized = output.join('\n');
    expect(serialized, contains('safe_diagnostic.log.error'));
    expect(serialized, contains('safe_diagnostics'));
    for (final marker in _hostileMarkers) {
      expect(serialized, isNot(contains(marker)));
    }
  });

  test('logger controller preserves the original record away from iOS', () {
    expect(Platform.isIOS, isFalse, reason: 'this deterministic check runs in the macOS test host');
    final console = _RecordingPrinter();
    final secondary = _RecordingPrinter();
    final controller = LoggerController(console, {'secondary': secondary});
    final original = LogRecord(LogLevel.error, _hostileMarkers[0], _hostileMarkers[2], _PoisonObject());

    controller.onLog(original);

    expect(console.records.single, same(original));
    expect(secondary.records.single, same(original));
  });
}
