import 'dart:async';
import 'dart:io';

import 'package:loggy/loggy.dart';

class ConsolePrinter extends LoggyPrinter {
  const ConsolePrinter({this.showColors = false});

  final bool showColors;

  static final _levelColors = {
    LogLevel.debug: AnsiColor(
      foregroundColor: AnsiColor.grey(0.5),
      italic: true,
    ),
    LogLevel.info: AnsiColor(foregroundColor: 35),
    LogLevel.warning: AnsiColor(foregroundColor: 214),
    LogLevel.error: AnsiColor(foregroundColor: 196),
  };

  @override
  void onLog(LogRecord record) {
    final colorize = showColors && stdout.supportsAnsiEscapes;
    final time = record.time.toIso8601String().split('T')[1];
    final callerFrame = record.callerFrame == null
        ? ' '
        : ' (${record.callerFrame?.location}) ';

    final String logLevel;
    if (colorize) {
      logLevel = record.level.name.toUpperCase().padRight(8);
    } else {
      logLevel = '[${record.level.name.toUpperCase()}]'.padRight(10);
    }

    final color = showColors
        ? levelColor(record.level) ?? AnsiColor()
        : AnsiColor();

    // ignore: avoid_print
    print(
      color(
        '$time $logLevel [${record.loggerName}]$callerFrame${record.message}',
      ),
    );

    if (record.stackTrace != null) {
      // ignore: avoid_print
      print(record.stackTrace);
    }
  }

  AnsiColor? levelColor(LogLevel level) => _levelColors[level];
}

class FileLogPrinter extends LoggyPrinter {
  FileLogPrinter(String filePath, {this.minLevel = LogLevel.debug})
      : _logFile = File(filePath);

  final File _logFile;
  final LogLevel minLevel;

  late final _sink = _logFile.openWrite(mode: FileMode.writeOnlyAppend);

  @override
  void onLog(LogRecord record) {
    final time = record.time.toIso8601String().split('T')[1];
    _sink.writeln('$time - $record');
    if (record.error != null) {
      _sink.writeln(record.error);
    }
    if (record.stackTrace != null) {
      _sink.writeln(record.stackTrace);
    }
  }

  void dispose() {
    try {
      unawaited(_sink.close());
    } catch (_) {}
  }
}

class StreamLogPrinter extends LoggyPrinter {
  final _controller = StreamController<List<String>>.broadcast();
  final List<String> _buffer = [];

  Stream<List<String>> get logStream => _controller.stream;

  @override
  void onLog(LogRecord record) {
    final time = record.time.toIso8601String().split('T')[1];
    final logLine = '$time - ${record.message}';
    _buffer.add(logLine);
    if (_buffer.length > 200) {
      _buffer.removeAt(0);
    }
    _controller.add(List.from(_buffer));
  }
  
  void dispose() {
    unawaited(_controller.close());
  }
}
