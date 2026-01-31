import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directories_provider.g.dart';

@Riverpod(keepAlive: true)
class AppDirectories extends _$AppDirectories with InfraLogger {
  final _methodChannel = const MethodChannel('com.hiddify.app/platform');

  @override
  Future<Directories> build() async {
    final Directories dirs;
    if (Platform.isIOS) {
      final paths = await _methodChannel.invokeMethod<Map<String, dynamic>>(
        'get_paths',
      );
      loggy.debug('paths: $paths');
      dirs = (
        baseDir: Directory(paths?['base']! as String),
        workingDir: Directory(paths?['working']! as String),
        tempDir: Directory(paths?['temp']! as String),
      );
    } else {
      final baseDir = await getApplicationSupportDirectory();
      final workingDir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : baseDir;
      final tempDir = await getTemporaryDirectory();
      dirs = (baseDir: baseDir, workingDir: workingDir!, tempDir: tempDir);
    }

    if (!dirs.baseDir.existsSync()) {
      await dirs.baseDir.create(recursive: true);
    }
    if (!dirs.workingDir.existsSync()) {
      await dirs.workingDir.create(recursive: true);
    }

    return dirs;
  }

  static Future<Directory> getDatabaseDirectory() {
    if (Platform.isIOS || Platform.isMacOS) {
      return getLibraryDirectory();
    } else if (Platform.isWindows || Platform.isLinux) {
      return getApplicationSupportDirectory();
    }
    return getApplicationDocumentsDirectory();
  }
}
