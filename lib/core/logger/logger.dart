import 'package:flutter/foundation.dart';
import 'package:loggy/loggy.dart';

class Logger {
  static final app = Loggy("app");
  static final bootstrap = Loggy("bootstrap");

  static void logFlutterError(FlutterErrorDetails details) {
    if (details.silent) {
      return;
    }

    final description = details.exceptionAsString();

    app.error(
      'Flutter Error: $description',
      details.exception,
      details.stack,
    );
  }

  static bool logPlatformDispatcherError(Object error, StackTrace stackTrace) {
    app.error(
      'PlatformDispatcherError: $error',
      error,
      stackTrace,
    );
    return true;
  }
}
