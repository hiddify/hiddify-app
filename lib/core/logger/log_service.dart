import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'log_service.g.dart';

/// Log levels matching Xray-core log levels
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

/// Log entry with timestamp, level, and message
class LogEntry {
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
  });

  factory LogEntry.fromLine(String line) {
    // Parse log line: [timestamp] [level] [source] message
    final match = RegExp(r'\[([^\]]+)\]\s*\[([^\]]+)\]\s*\[([^\]]+)\]\s*(.*)').firstMatch(line);
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

  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';
}

@Riverpod(keepAlive: true)
LogService logService(Ref ref) => LogService();

class LogService {
  Future<String> getLogDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/logs');
    // ignore: avoid_slow_async_io
    if (!await logDir.exists()) {
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

  /// Read core logs from file
  Future<List<LogEntry>> readCoreLogs({int maxLines = 500}) async {
    final path = await getCoreLogPath();
    final file = File(path);
    // ignore: avoid_slow_async_io
    if (!await file.exists()) return [];
    
    final lines = await file.readAsLines();
    final start = lines.length > maxLines ? lines.length - maxLines : 0;
    return lines.sublist(start).map(LogEntry.fromLine).toList();
  }

  /// Read access logs from file
  Future<List<LogEntry>> readAccessLogs({int maxLines = 500}) async {
    final path = await getAccessLogPath();
    final file = File(path);
    // ignore: avoid_slow_async_io
    if (!await file.exists()) return [];
    
    final lines = await file.readAsLines();
    final start = lines.length > maxLines ? lines.length - maxLines : 0;
    return lines.sublist(start).map(LogEntry.fromLine).toList();
  }

  /// Watch core log file for changes
  Stream<List<LogEntry>> watchCoreLogs() async* {
    final path = await getCoreLogPath();
    final file = File(path);
    
    // Initial read
    // ignore: avoid_slow_async_io
    if (await file.exists()) {
      yield await readCoreLogs();
    }

    // Watch for changes
    await for (final _ in file.parent.watch()) {
      // ignore: avoid_slow_async_io
      if (await file.exists()) {
        yield await readCoreLogs();
      }
    }
  }

  Future<void> clearLogs() async {
    final dir = await getLogDirectory();
    final d = Directory(dir);
    // ignore: avoid_slow_async_io
    if (await d.exists()) {
      await d.delete(recursive: true);
      await d.create(recursive: true);
    }
  }

  Future<void> clearCoreLog() async {
    final path = await getCoreLogPath();
    final file = File(path);
    // ignore: avoid_slow_async_io
    if (await file.exists()) {
      await file.writeAsString('');
    }
  }

  Future<void> clearAccessLog() async {
    final path = await getAccessLogPath();
    final file = File(path);
    // ignore: avoid_slow_async_io
    if (await file.exists()) {
      await file.writeAsString('');
    }
  }

  Future<void> exportLogs() async {
    final dir = await getLogDirectory();
    final encoder = ZipFileEncoder();
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/hiddify_logs.zip';
    encoder.create(zipPath);
    await encoder.addDirectory(Directory(dir));
    await encoder.close();
    
    await SharePlus.instance.share(ShareParams(files: [XFile(zipPath)], text: 'Hiddify Logs'));
  }

  /// Get log file size
  Future<int> getLogSize() async {
    final dir = await getLogDirectory();
    final d = Directory(dir);
    // ignore: avoid_slow_async_io
    if (!await d.exists()) return 0;
    
    var size = 0;
    await for (final entity in d.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// Format file size for display
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
