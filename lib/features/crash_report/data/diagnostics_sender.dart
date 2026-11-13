import 'dart:async';
import 'dart:io';

import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/app_info_entity.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = appLogger('DiagnosticsSender');

final diagnosticsSenderProvider = Provider<DiagnosticsSender>(
  (ref) => DiagnosticsSender(appInfo: () => ref.read(appInfoProvider).value),
);

/// Uploads the diagnostics zip to the developers' Sentry, as the attachment of one event.
///
/// The upload goes over HTTP from Dart on every platform, with a client of its own, so the
/// answer is Sentry's own: the app's Sentry, when analytics is on, hands events on Android, iOS
/// and macOS to the native SDK, which only queues them and uploads later, and a rate limit (429),
/// an offline phone or a dropped attachment would still read as sent. A client of its own also
/// means the report goes with analytics off, and nothing else is reported with it.
class DiagnosticsSender {
  DiagnosticsSender({required AppInfoEntity? Function() appInfo}) : _appInfo = appInfo;

  final AppInfoEntity? Function() _appInfo;

  /// Whether a build can upload at all: one without a DSN (a debug or a local build) cannot.
  static bool get available => Environment.sentryDSN.isNotEmpty;

  /// Sentry's own limit for one attachment; a larger one is left out of the event without a word,
  /// so such a report is not sent at all and the user is pointed at email or Telegram instead.
  static const maxSize = 20 * 1024 * 1024;

  /// Long enough for a large zip on a slow line, short enough that a hung connection still ends
  /// with the user told to try another way.
  static const _timeout = Duration(minutes: 3);

  /// Whether Sentry took the report: false on a rate limit, any other answer than 200, no
  /// connection, a timeout, or a zip too large to attach.
  Future<bool> send(File zip, {String? crashName}) async {
    if (!available) {
      _log.warning('no Sentry DSN in this build, the report cannot be uploaded');
      return false;
    }
    final name = zip.uri.pathSegments.last;
    final SentryClient client;
    try {
      final size = await zip.length();
      if (size > maxSize) {
        _log.warning('report $name is $size bytes, over the $maxSize Sentry takes, not sent');
        return false;
      }
      client = SentryClient(_options());
    } catch (e, stack) {
      _log.warning('preparing the report for Sentry failed: $e', e, stack);
      return false;
    }
    try {
      final info = _appInfo();
      final id = await client
          .captureEvent(
            SentryEvent(
              message: SentryMessage(crashName == null ? 'diagnostics report' : 'crash report $crashName'),
              level: crashName == null ? SentryLevel.info : SentryLevel.fatal,
              tags: {
                'report': crashName == null ? 'diagnostics' : 'crash',
                if (info != null) ...{
                  'os': info.operatingSystem,
                  'os.version': info.operatingSystemVersion,
                  'app.release': info.release.name,
                  'app.environment': info.environment.name,
                },
              },
            ),
            hint: Hint.withAttachment(
              SentryAttachment.fromUint8List(await zip.readAsBytes(), name, contentType: 'application/zip'),
            ),
          )
          .timeout(_timeout);
      if (id == const SentryId.empty()) {
        // the transport answers an empty id for a rate limit (429), any other status than 200 and
        // a report the rate limiter held back
        _log.warning('Sentry did not take report $name');
        return false;
      }
      _log.info('report $name sent to Sentry as $id');
      return true;
    } on TimeoutException {
      _log.warning('sending report $name to Sentry timed out after $_timeout');
      return false;
    } catch (e, stack) {
      _log.warning('sending report $name to Sentry failed: $e', e, stack);
      return false;
    } finally {
      client.close();
    }
  }

  SentryOptions _options() {
    final info = _appInfo();
    return SentryOptions(dsn: Environment.sentryDSN)
      ..serverName = ""
      ..sendClientReports = false
      ..release = info == null ? null : 'hiddify@${info.version}+${info.buildNumber}'
      ..dist = info?.buildNumber;
  }
}
