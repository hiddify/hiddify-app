import 'package:flutter/foundation.dart';
import 'package:hiddify/core/logger/log_level_compat.dart';
import 'package:logging/logging.dart' as logging;

// Re-exported so every file that already imports this one also gets the
// debug() and error() aliases in scope. A Dart extension is only visible
// where it is imported, so without this each call site would need its own
// import.
export 'package:hiddify/core/logger/log_level_compat.dart';

/// The two loggers that belong to no class, so no mixin can name them, plus the
/// handlers for errors nobody caught.
///
/// The class name stays `Logger` so the existing `Logger.bootstrap.info(...)`
/// call sites keep working; package:logging's own Logger is aliased to avoid
/// the clash.
class Logger {
  static final app = logging.Logger('app');
  static final bootstrap = logging.Logger('bootstrap');

  /// Errors thrown while Flutter itself was working — building, laying out,
  /// painting, or running one of its callbacks.
  static void logFlutterError(FlutterErrorDetails details) {
    if (details.silent) {
      return;
    }

    final description = details.exceptionAsString();

    app.error('Flutter Error: $description', details.exception, details.stack);
  }

  /// Errors that never touched a widget — an unawaited future, a timer, a
  /// stream with no error handler.
  ///
  /// Returning true tells the engine the error is handled, so the app is not
  /// killed.
  static bool logPlatformDispatcherError(Object error, StackTrace stackTrace) {
    app.error('PlatformDispatcherError: $error', error, stackTrace);
    return true;
  }
}
