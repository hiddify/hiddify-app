// ignore_for_file: parameter_assignments

import 'package:dartx/dartx.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart' as pb;
import 'package:tint/tint.dart';

abstract class LogParser {
  static LogEntity parseLogProto(pb.LogMessage message) {
    final level = switch (message.level) {
      pb.LogLevel.DEBUG => LogLevel.debug,
      pb.LogLevel.INFO => LogLevel.info,
      pb.LogLevel.WARNING => LogLevel.warn,
      pb.LogLevel.ERROR => LogLevel.error,
      pb.LogLevel.FATAL => LogLevel.fatal,
      _ => LogLevel.debug,
    };

    return LogEntity(level: level, time: message.time.toDateTime(), message: message.message);
  }

  static LogEntity parseSingbox(String log) {
    log = log.strip();
    DateTime? time;
    if (log.length > 25) {
      time = DateTime.tryParse(log.substring(6, 25));
    }
    if (time != null) {
      log = log.substring(26);
    }
    final level = LogLevel.values.firstOrNullWhere((e) {
      if (log.startsWith(e.name.toUpperCase())) {
        log = log.removePrefix(e.name.toUpperCase());
        return true;
      }
      return false;
    });
    return LogEntity(level: level, time: time, message: log.trim());
  }
}
