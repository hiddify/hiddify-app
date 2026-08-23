import 'package:logging/logging.dart';

/// package:logging names its levels FINE and SEVERE; loggy named them debug and
/// error. Rather than rewrite hundreds of call sites, the two old names are kept
/// as aliases here.
///
/// This is the single reason the migration does not touch the ~200 classes that
/// write logs.
extension LogLevelCompat on Logger {
  /// alias for [fine]
  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      fine(message, error, stackTrace);

  /// alias for [severe]
  void error(Object? message, [Object? err, StackTrace? stackTrace]) =>
      severe(message, err, stackTrace);
}
