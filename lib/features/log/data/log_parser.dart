// ignore_for_file: parameter_assignments

import 'package:dartx/dartx.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:tint/tint.dart';

abstract class LogParser {
  static LogEntity parseSingbox(String log) {
    log = log.strip();
    DateTime? time;
    if (log.length > 25) {
      time = DateTime.tryParse(log.substring(6, 25));
    }
    if (time != null) {
      log = log.substring(26);
    }
    final level = LogLevel.values.firstOrNullWhere(
      (e) {
        if (log.startsWith(e.name.toUpperCase())) {
          log = log.removePrefix(e.name.toUpperCase());
          return true;
        }
        return false;
      },
    );
    // Provide default values for nullable parameters
    return LogEntity(
      level: level ?? LogLevel.info, // Already fixed!
      time: time ?? DateTime.now(), // Already fixed!
      message: log.trim(),
    );
  }
}
