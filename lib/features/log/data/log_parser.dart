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
    return LogEntity(
      level: level,
      time: time,
      message: log.trim(),
    );
  }

  static LogEntity parseApp(String log) {
    log = log.strip();
    const sep = ' - ';
    final i = log.indexOf(sep);
    if (i > 0) {
      log = log.substring(i + sep.length);
    }
    final level = LogLevel.values.firstOrNullWhere(
      (e) {
        final tag = '[${e.name.toUpperCase()}]';
        if (log.startsWith(tag)) {
          log = log.removePrefix(tag).trimLeft();
          return true;
        }
        return false;
      },
    );
    return LogEntity(
      level: level,
      message: log.trim(),
    );
  }
}
