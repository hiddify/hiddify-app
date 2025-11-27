import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';

enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
  fatal,
  panic;

  /// [LogLevel] selectable by user as preference
  static List<LogLevel> get choices => values.takeFirst(4);

  Color? get color => switch (this) {
    trace => Colors.lightBlueAccent,
    debug => Colors.grey,
    info => Colors.lightGreen,
    warn => Colors.orange,
    error => Colors.redAccent,
    fatal => Colors.red,
    panic => Colors.red,
  };
}
