import 'dart:io';

import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = appLogger('DiagnosticsSender');

final diagnosticsSenderProvider = Provider<DiagnosticsSender>((ref) => DiagnosticsSender());

/// Uploads the diagnostics zip to the developers' Sentry, as the attachment of one event.
///
/// The user asked for this report to be sent, so it goes even with analytics off: Sentry is
/// then started for this one event and closed again, and nothing else is reported.
class DiagnosticsSender {
  /// Whether a build can upload at all: one without a DSN (a debug or a local build) cannot.
  static bool get available => Sentry.isEnabled || Environment.sentryDSN.isNotEmpty;

  Future<bool> send(File zip, {String? crashName}) async {
    final temporary = !Sentry.isEnabled;
    if (temporary) {
      if (Environment.sentryDSN.isEmpty) {
        _log.warning('no Sentry DSN in this build, the report cannot be uploaded');
        return false;
      }
      await SentryFlutter.init((options) {
        options.dsn = Environment.sentryDSN;
        options.serverName = "";
        options.enableNativeCrashHandling = false;
        options.enableAutoSessionTracking = false;
        options.tracesSampleRate = 0;
      });
    }
    try {
      final name = zip.uri.pathSegments.last;
      final id = await Sentry.captureMessage(
        crashName == null ? 'diagnostics report' : 'crash report $crashName',
        level: crashName == null ? SentryLevel.info : SentryLevel.fatal,
        hint: Hint.withAttachment(
          SentryAttachment.fromUint8List(await zip.readAsBytes(), name, contentType: 'application/zip'),
        ),
        withScope: (scope) => scope.setTag('report', crashName == null ? 'diagnostics' : 'crash'),
      );
      _log.info('report $name sent to Sentry as $id');
      return id != const SentryId.empty();
    } catch (e, stack) {
      _log.warning('sending the report to Sentry failed: $e', e, stack);
      return false;
    } finally {
      if (temporary) await Sentry.close();
    }
  }
}
