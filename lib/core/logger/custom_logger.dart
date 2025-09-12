import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:loggy/loggy.dart';

class ConsolePrinter extends LoggyPrinter {
  const ConsolePrinter({
    this.showColors = false,
  });

  final bool showColors;

  static final _levelPens = {
    LogLevel.debug: (AnsiPen()..xterm(244)), // gray-ish
    LogLevel.info: (AnsiPen()..xterm(35)),
    LogLevel.warning: (AnsiPen()..xterm(214)),
    LogLevel.error: (AnsiPen()..xterm(196)),
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
      logLevel = "[${record.level.name.toUpperCase()}]".padRight(10);
    }

    final pen = colorize ? levelPen(record.level) ?? AnsiPen() : AnsiPen();

    stdout.writeln(
      pen(
        '$time $logLevel [${record.loggerName}]$callerFrame${record.message}',
      ),
    );

    if (record.error != null) {
      stdout.writeln(record.error);
    }

    if (record.stackTrace != null) {
      stdout.writeln(record.stackTrace);
    }
  }

  AnsiPen? levelPen(LogLevel level) {
    return _levelPens[level];
  }
}

class FileLogPrinter extends LoggyPrinter {
  FileLogPrinter(
    String filePath, {
    this.minLevel = LogLevel.debug,
  }) : _logFile = File(filePath);

  final File _logFile;
  LogLevel minLevel;

  late final _sink = _logFile.openWrite(
    mode: FileMode.append,
  );

  @override
  void onLog(LogRecord record) {
    // Skip logs below the configured minimum level
    if (record.level.priority < minLevel.priority) return;
    final time = record.time.toIso8601String().split('T')[1];
    _sink.writeln("$time - $record");
    if (record.error != null) {
      _sink.writeln(record.error);
    }
    if (record.stackTrace != null) {
      _sink.writeln(record.stackTrace);
    }
  }

  void dispose() {
    _sink.close();
  }
}
