import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:hiddify/core/logger/log_bus.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'log_service.g.dart';

enum LogLevel {
  debug('debug', 'Debug'),
  info('info', 'Info'),
  warning('warning', 'Warning'),
  error('error', 'Error'),
  none('none', 'None');

  const LogLevel(this.value, this.label);
  final String value;
  final String label;
}

class LogEntry {
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
  });

  factory LogEntry.fromLine(String line) {
    final match = RegExp(
      r'\[([^\]]+)\]\s*\[([^\]]+)\]\s*\[([^\]]+)\]\s*(.*)',
    ).firstMatch(line);
    if (match != null) {
      return LogEntry(
        timestamp: DateTime.tryParse(match.group(1) ?? '') ?? DateTime.now(),
        level: _parseLevel(match.group(2) ?? 'info'),
        source: match.group(3) ?? 'unknown',
        message: match.group(4) ?? line,
      );
    }
    return LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      source: 'app',
      message: line,
    );
  }

  static LogLevel _parseLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
      case 'warn':
        return LogLevel.warning;
      case 'error':
      case 'err':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  final DateTime timestamp;
  final LogLevel level;
  final String source;
  final String message;

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';
}

@Riverpod(keepAlive: true)
LogService logService(Ref ref) => LogService();

class LogService {
  Future<String> getLogDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/logs');

    if (await FileSystemEntity.type(logDir.path) ==
        FileSystemEntityType.notFound) {
      await logDir.create(recursive: true);
    }
    return logDir.path;
  }

  Future<String> getCoreLogPath() async {
    final dir = await getLogDirectory();
    return '$dir/core.log';
  }

  Future<String> getAccessLogPath() async {
    final dir = await getLogDirectory();
    return '$dir/access.log';
  }

  Future<String> getAppLogPath() async {
    final dir = await getLogDirectory();
    return '$dir/app.log';
  }

  Stream<List<String>> streamLogs() => LoggerController.instance.logStream;

  Future<List<LogEntry>> readCoreLogs({int maxLines = 500}) async {
    final path = await getCoreLogPath();
    final file = File(path);

    if (await FileSystemEntity.type(path) == FileSystemEntityType.notFound) {
      return [];
    }

    final lines = await file.readAsLines();
    final start = lines.length > maxLines ? lines.length - maxLines : 0;
    return lines.sublist(start).map(LogEntry.fromLine).toList();
  }

  Future<List<LogEntry>> readAccessLogs({int maxLines = 500}) async {
    final path = await getAccessLogPath();
    final file = File(path);

    if (await FileSystemEntity.type(path) == FileSystemEntityType.notFound) {
      return [];
    }

    final lines = await file.readAsLines();
    final start = lines.length > maxLines ? lines.length - maxLines : 0;
    return lines.sublist(start).map(LogEntry.fromLine).toList();
  }

  Stream<List<LogEntry>> watchCoreLogs() async* {
    final path = await getCoreLogPath();
    final file = File(path);
    var lastLength = 0;

    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      final logs = await readCoreLogs();
      lastLength = (await file.readAsLines()).length;
      yield logs;
    }
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
        final lines = await file.readAsLines();
        if (lines.length != lastLength) {
          lastLength = lines.length;
          yield await readCoreLogs();
        }
      }
    }
  }

  Stream<List<LogEntry>> watchAccessLogs() async* {
    final path = await getAccessLogPath();
    final file = File(path);
    var lastLength = 0;

    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      final logs = await readAccessLogs();
      lastLength = (await file.readAsLines()).length;
      yield logs;
    }
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
        final lines = await file.readAsLines();
        if (lines.length != lastLength) {
          lastLength = lines.length;
          yield await readAccessLogs();
        }
      }
    }
  }

  void clearAppLogBuffer() {
    LoggerController.instance.clearBuffer();
  }

  Future<void> clearLogs() async {
    clearAppLogBuffer();
    LogBus.instance.clear();

    await clearCoreLog();
    await clearAccessLog();
    await _tryTruncateFile(await getAppLogPath());
  }

  Future<void> clearCoreLog() async {
    final path = await getCoreLogPath();
    final file = File(path);
    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      try {
        await file.writeAsString('');
      } catch (_) {}
    }
  }

  Future<void> clearAccessLog() async {
    final path = await getAccessLogPath();
    final file = File(path);
    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      try {
        await file.writeAsString('');
      } catch (_) {}
    }
  }

  Future<void> exportLogs() async {
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory('${tempDir.path}/hiddify_logs_export');

    if (await FileSystemEntity.type(exportDir.path) !=
        FileSystemEntityType.notFound) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create(recursive: true);

    await _writeLogBusSnapshot('${exportDir.path}/logbus.log');
    await _writeRedactedTailIfExists(
      sourcePath: await getAppLogPath(),
      destPath: '${exportDir.path}/app.log',
    );
    await _writeRedactedTailIfExists(
      sourcePath: await getCoreLogPath(),
      destPath: '${exportDir.path}/core.log',
    );
    await _writeRedactedTailIfExists(
      sourcePath: await getAccessLogPath(),
      destPath: '${exportDir.path}/access.log',
    );

    final encoder = ZipFileEncoder();
    final zipPath = '${tempDir.path}/hiddify_logs.zip';
    encoder.create(zipPath);
    await encoder.addDirectory(exportDir);
    await encoder.close();

    await SharePlus.instance.share(
      ShareParams(files: [XFile(zipPath)], text: 'Hiddify Logs'),
    );
  }

  Future<void> _tryTruncateFile(String path) async {
    try {
      final file = File(path);
      if (await FileSystemEntity.type(path) == FileSystemEntityType.notFound) {
        return;
      }
      await file.writeAsString('');
    } catch (_) {}
  }

  Future<void> _writeLogBusSnapshot(String destPath) async {
    final events = LogBus.instance.currentBuffer;

    final buffer = StringBuffer();
    for (final e in events) {
      final safeSource = e.source.trim().isEmpty ? 'unknown' : e.source;
      buffer.writeln(
        '${e.timestamp.toIso8601String()} [${e.kind.name}] [${e.severity.name}] [$safeSource] ${LogBus.redact(e.message)}',
      );
    }

    await File(destPath).writeAsString(buffer.toString());
  }

  Future<void> _writeRedactedTailIfExists({
    required String sourcePath,
    required String destPath,
    int maxBytes = 512 * 1024,
  }) async {
    final sourceFile = File(sourcePath);
    if (await FileSystemEntity.type(sourcePath) ==
        FileSystemEntityType.notFound) {
      return;
    }

    try {
      final length = await sourceFile.length();
      final start = length > maxBytes ? length - maxBytes : 0;

      final raf = await sourceFile.open();
      late String chunk;
      try {
        await raf.setPosition(start);
        final bytes = await raf.read(length - start);
        chunk = utf8.decode(bytes, allowMalformed: true);
      } finally {
        await raf.close();
      }

      if (start > 0) {
        final nl = chunk.indexOf('\n');
        if (nl != -1) {
          chunk = chunk.substring(nl + 1);
        }
      }

      await File(destPath).writeAsString(LogBus.redact(chunk));
    } catch (_) {}
  }

  Future<int> getLogSize() async {
    final dir = await getLogDirectory();
    final d = Directory(dir);
    if (await FileSystemEntity.type(dir) == FileSystemEntityType.notFound) {
      return 0;
    }

    var size = 0;
    await for (final entity in d.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
