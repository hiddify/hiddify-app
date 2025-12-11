import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'log_service.g.dart';

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

  Stream<List<String>> streamLogs() => LoggerController.instance.logStream;

  Future<void> clearLogs() async {
    final dir = await getLogDirectory();
    final d = Directory(dir);
    // ignore: avoid_slow_async_io
    if (await d.exists()) {
      await d.delete(recursive: true);
    }
    // Also notify logger controller if needed, but file printer is append-only for now
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
}
