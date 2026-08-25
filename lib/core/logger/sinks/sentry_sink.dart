import 'dart:async';

import 'package:hiddify/utils/sentry_utils.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Adapted from https://github.com/getsentry/sentry-dart/tree/main/logging
//
// This used to be a loggy printer held in LoggerController's map. It is now a
// plain listener on the root stream, attached when the user turns analytics on
// and cancelled when they turn it off.

/// Records at or above this become a breadcrumb — the trail Sentry shows
/// leading up to a crash.
const _minBreadcrumbLevel = Level.INFO;

/// Records at or above this become a reported event of their own.
const _minEventLevel = Level.SEVERE;

StreamSubscription<LogRecord>? _sub;

bool get sentryEnabled => _sub != null;

/// Starts forwarding to Sentry. Safe to call twice.
void logEnableSentry() {
  _sub ??= Logger.root.onRecord.listen(_toSentry);
}

/// Stops forwarding. The records still reach every other sink.
void logDisableSentry() {
  _sub?.cancel();
  _sub = null;
}

/// Kept so SentryFlutter.init can register it as an integration, which is what
/// makes the SDK aware of us.
class SentryLogIntegration implements Integration<SentryOptions> {
  @override
  void call(Hub hub, SentryOptions options) {
    options.sdk.addIntegration('LoggingIntegration');
  }

  @override
  Future<void> close() async {}
}

Future<void> _toSentry(LogRecord record) async {
  if (!canLogEvent(record.error)) return;

  if (record.level >= _minEventLevel) {
    await Sentry.captureEvent(
      record.toSentryEvent(),
      stackTrace: record.stackTrace,
    );
  }

  if (record.level >= _minBreadcrumbLevel) {
    await Sentry.addBreadcrumb(record.toBreadcrumb());
  }
}

extension LogRecordX on LogRecord {
  Breadcrumb toBreadcrumb() {
    return Breadcrumb(
      category: 'log',
      type: 'debug',
      timestamp: time.toUtc(),
      level: level.toSentryLevel(),
      message: message,
      data: <String, Object>{
        if (object != null) 'LogRecord.object': object!,
        if (error != null) 'LogRecord.error': error!,
        if (stackTrace != null) 'LogRecord.stackTrace': stackTrace!,
        'LogRecord.loggerName': loggerName,
        'LogRecord.sequenceNumber': sequenceNumber,
      },
    );
  }

  SentryEvent toSentryEvent() {
    return SentryEvent(
      timestamp: time.toUtc(),
      logger: loggerName,
      level: level.toSentryLevel(),
      message: SentryMessage(message),
      throwable: error,
      // ignore: deprecated_member_use
      extra: <String, Object>{
        if (object != null) 'LogRecord.object': object!,
        'LogRecord.sequenceNumber': sequenceNumber,
      },
    );
  }
}

extension LevelX on Level {
  /// Six levels map onto Sentry's five; FINEST and FINE both mean debug.
  SentryLevel? toSentryLevel() => switch (this) {
    Level.FINEST || Level.FINER || Level.FINE => SentryLevel.debug,
    Level.CONFIG || Level.INFO => SentryLevel.info,
    Level.WARNING => SentryLevel.warning,
    Level.SEVERE => SentryLevel.error,
    Level.SHOUT => SentryLevel.fatal,
    _ => null,
  };
}
