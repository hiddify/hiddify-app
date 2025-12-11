import 'package:flutter/foundation.dart';
import 'package:loggy/loggy.dart';

class Logger {
  static final app = Loggy('app');
  static final bootstrap = Loggy('bootstrap');

  static void logFlutterError(FlutterErrorDetails details) {
    if (_isKnownViewportHitTestBug(details)) {
      return;
    }

    if (details.silent) {
      return;
    }

    final description = details.exceptionAsString();

    app.error('Flutter Error: $description', details.exception, details.stack);
  }

  static bool _isKnownViewportHitTestBug(FlutterErrorDetails details) {
    final description = details.exceptionAsString();
    if (!description.contains('Null check operator used on a null value')) {
      return false;
    }

    final stack = details.stack?.toString() ?? '';
    return stack.contains('RenderViewportBase.hitTestChildren');
  }

  static bool logPlatformDispatcherError(Object error, StackTrace stackTrace) {
    app.error('PlatformDispatcherError: $error', error, stackTrace);
    return true;
  }
}
