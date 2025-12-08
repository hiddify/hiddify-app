import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';

part 'log_service.g.dart';

@Riverpod(keepAlive: true)
LogService logService(Ref ref) => LogService();

class LogService {
  Future<String> getLogDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/logs');
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

  Stream<List<String>> streamLogs() async* {
    final path = await getCoreLogPath();
    final file = File(path);
    // Simple tail implementation
    // In real world, file watcher or periodic read
    while (true) {
      if (await file.exists()) {
        final lines = await file.readAsLines();
        // Return last 100 lines
        yield lines.length > 100 ? lines.sublist(lines.length - 100) : lines;
      } else {
        yield ["Log file not found..."];
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> clearLogs() async {
    final dir = await getLogDirectory();
    final d = Directory(dir);
    if (await d.exists()) {
      await d.delete(recursive: true);
    }
  }

  Future<void> exportLogs() async {
    final dir = await getLogDirectory();
    final encoder = ZipFileEncoder();
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/hiddify_logs.zip';
    encoder.create(zipPath);
    encoder.addDirectory(Directory(dir));
    encoder.close();
    
    await Share.shareXFiles([XFile(zipPath)], text: 'Hiddify Logs');
  }
}
