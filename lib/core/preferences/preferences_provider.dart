import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async {
  final logger = Loggy("preferences");
  SharedPreferences? sharedPreferences;

  logger.debug("initializing preferences");
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (e) {
    logger.error("error initializing preferences", e);
    if (!Platform.isWindows && !Platform.isLinux) {
      rethrow;
    }
    // https://github.com/flutter/flutter/issues/89211
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'shared_preferences.json'));
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  return sharedPreferences ??= await SharedPreferences.getInstance();
}
