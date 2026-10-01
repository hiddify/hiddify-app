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
  ///
  /// Captures the call site when the caller does not pass a stack, so the log
  /// line can say which method and line it came from. An error with no location
  /// is the hardest kind to chase, and errors are rare enough to afford it.
  void error(Object? message, [Object? err, StackTrace? stackTrace]) =>
      severe(message, err, stackTrace ?? StackTrace.current);

  /// SHOUT — engine FATAL. Above error, for the engine giving up.
  void fatal(Object? message, [Object? error, StackTrace? stackTrace]) =>
      shout(message, error, stackTrace ?? StackTrace.current);
}

/// The engine's words for a level, which is the vocabulary the whole app shows.
///
/// package:logging spells them FINEST, FINE, INFO, WARNING, SEVERE. The engine
/// says trace, debug, info, warn, error. Two names for one idea is one too many
/// when the log level setting and the level filter sit on the same page, so the
/// engine's win: they are the ones the user already picks from.
extension LevelNaming on Level {
  String get shortName => switch (this) {
    Level.FINEST || Level.FINER => 'trace',
    Level.FINE || Level.CONFIG => 'debug',
    Level.INFO => 'info',
    Level.WARNING => 'warn',
    Level.SEVERE => 'error',
    Level.SHOUT => 'fatal',
    _ => name.toLowerCase(),
  };
}

/// The levels worth offering as a filter. FINER, CONFIG and SHOUT are never
/// produced by anything here, so listing them would only be noise.
const uiLevels = <Level>[
  Level.FINEST,
  Level.FINE,
  Level.INFO,
  Level.WARNING,
  Level.SEVERE,
];
