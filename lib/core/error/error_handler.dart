import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/logger/logger.dart';

/// Global error handler for the application
class ErrorHandler {
  static bool _initialized = false;

  /// Initialize global error handling
  static void init() {
    if (_initialized) return;
    _initialized = true;

    // Handle Flutter errors
    FlutterError.onError = (details) {
      _handleFlutterError(details);
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }

  static void _handleFlutterError(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    
    // Log the error
    Logger.app.error('Flutter Error: $message', details.exception, details.stack);

    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  static void _handlePlatformError(Object error, StackTrace stack) {
    Logger.app.error('Platform Error: $error', error, stack);
  }

  /// Show error dialog to user
  static void showError(BuildContext context, String message, {String? title}) {
    unawaited(showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: Text(title ?? 'Error'),
        content: SingleChildScrollView(
          child: SelectableText(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    ));
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Parse and format error message for user display
  static String formatErrorMessage(Object error) {
    final msg = error.toString();
    
    // Remove technical prefixes
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    if (msg.startsWith('UnsupportedError: ')) {
      return msg.substring(18);
    }
    if (msg.startsWith('FormatException: ')) {
      return msg.substring(17);
    }
    
    return msg;
  }

  /// Check if error is a network error
  static bool isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('host lookup') ||
        msg.contains('timeout');
  }

  /// Check if error is an authentication error
  static bool isAuthError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('unauthorized') ||
        msg.contains('authentication') ||
        msg.contains('401') ||
        msg.contains('403');
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(Object error) {
    if (isNetworkError(error)) {
      return 'Network error. Please check your internet connection.';
    }
    if (isAuthError(error)) {
      return 'Authentication failed. Please check your credentials.';
    }
    return formatErrorMessage(error);
  }
}

/// Extension to run async operations with error handling
extension SafeAsync<T> on Future<T> {
  /// Execute with error handling and optional callback
  Future<T?> safeExecute({
    void Function(T result)? onSuccess,
    void Function(Object error)? onError,
    void Function()? onComplete,
  }) async {
    try {
      final result = await this;
      onSuccess?.call(result);
      return result;
    } catch (e, stack) {
      Logger.app.error('SafeExecute error: $e', e, stack);
      onError?.call(e);
      return null;
    } finally {
      onComplete?.call();
    }
  }
}
