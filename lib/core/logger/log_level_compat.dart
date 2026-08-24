import 'package:logging/logging.dart';

/// Short level names, so every level the engine can produce has one.
///
/// package:logging calls its levels FINEST, FINE, INFO, WARNING, SEVERE and
/// SHOUT. `info` and `warning` already match what loggy used, so only the other
/// four need a name here. `debug` and `error` are what the existing ~200 call
/// sites use, which is why the migration does not have to touch them.
///
/// An extension is only visible where it is imported, so this file is
/// re-exported from logger.dart and custom_loggers.dart — the two files those
/// call sites already import.
extension LogLevelCompat on Logger {
  /// FINEST — engine TRACE. The most detailed level, off unless you are
  /// chasing one specific thing.
  void trace(Object? message, [Object? error, StackTrace? stackTrace]) =>
      finest(message, error, stackTrace);

  /// FINE — engine DEBUG. Developer detail, not shown by default.
  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      fine(message, error, stackTrace);

  /// SEVERE — engine ERROR, and anything that failed and mattered.
  void error(Object? message, [Object? err, StackTrace? stackTrace]) =>
      severe(message, err, stackTrace);

  /// SHOUT — engine FATAL. Above error, for the engine giving up.
  void fatal(Object? message, [Object? error, StackTrace? stackTrace]) =>
      shout(message, error, stackTrace);
}
