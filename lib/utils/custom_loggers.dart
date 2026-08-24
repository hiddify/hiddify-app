import 'package:logging/logging.dart';

// Re-exported so every class that mixes in a logger also gets the short level
// names — trace, debug, error, fatal. A Dart extension is only visible where it
// is imported, so without this line each of the ~200 call sites would need its
// own import.
export 'package:hiddify/core/logger/log_level_compat.dart';

/// The layer a log line came from is decided by which mixin the class uses, and
/// becomes a prefix on the logger name: `ui.`, `app.` or `infra.`. Engine lines
/// use `core`, see core/logger/core_logger.dart.
///
/// The prefix is what makes the logs page able to filter a whole layer in or
/// out, and the `$runtimeType` part means a renamed class cannot leave a stale
/// name behind.
///
/// The getter is called `loggy` for one reason: it is what the call sites
/// already say. Renaming it would touch every class that writes a log.

/// presentation layer — widgets and pages
mixin PresLogger {
  Logger get loggy => Logger('ui.$runtimeType');
}

/// application layer — notifiers and controllers
mixin AppLogger {
  Logger get loggy => Logger('app.$runtimeType');
}

/// data layer — repositories, data sources, services
mixin InfraLogger {
  Logger get loggy => Logger('infra.$runtimeType');
}

/// Implemented by anything that already holds a logger, so a mixin like
/// [ExceptionHandler] can use it without demanding a particular layer.
abstract class LoggerMixin {
  LoggerMixin(this.loggy);

  final Logger loggy;
}
