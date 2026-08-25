import 'package:flutter/foundation.dart';
import 'package:hiddify/utils/custom_loggers.dart';

// Re-exported so every file that already imports this one also gets the short
// level names in scope. A Dart extension is only visible where it is imported,
// so without this each call site would need its own import.
export 'package:hiddify/core/logger/log_level_compat.dart';

/// The two loggers that belong to no class, so no mixin can name them, plus the
/// handlers for errors nobody caught.
///
/// The class name stays `Logger` because the existing
/// `Logger.bootstrap.info(...)` call sites say it. Both loggers come from the
/// factories in custom_loggers.dart, so their names carry a category like
/// every other logger.
class Logger {
  static final app = appLogger('uncaught');
  static final bootstrap = bootLogger('startup');

  /// Errors thrown while Flutter itself was working — building, laying out,
  /// painting, or running one of its callbacks.
  static void logFlutterError(FlutterErrorDetails details) {
    // FlutterError.onError defaults to presentError, which prints the full
    // formatted report. Assigning this handler replaced it, which is why
    // crashes used to arrive as one terse line. Keep the report in debug.
    if (kDebugMode) {
      FlutterError.presentError(details);
    }

    if (details.silent) {
      return;
    }

    // library and context are what exceptionAsString() leaves out: which part
    // of Flutter failed, and what it was doing at the time.
    final library = details.library ?? 'unknown library';
    final context = details.context == null ? '' : ' ${details.context}';

    app.error(
      'Flutter error in $library$context: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
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
