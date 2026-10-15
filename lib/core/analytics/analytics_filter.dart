import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

FutureOr<SentryEvent?> sentryBeforeSend(SentryEvent event, Hint hint) async {
  if (!canSendEvent(event.throwable)) return null;
  return event.copyWith(
    user: SentryUser(email: "", username: "", ipAddress: "0.0.0.0"),
  );
}

FutureOr<SentryEvent?> safeSentryBeforeSend(SentryEvent event, Hint hint) {
  hint
    ..attachments.clear()
    ..screenshot = null
    ..viewHierarchy = null
    ..clear();

  final inputLevel = event.level ?? (event.throwable == null ? SentryLevel.info : SentryLevel.error);
  final (level, code) = _safeSentrySeverity(inputLevel);
  return SentryEvent(logger: 'safe_diagnostics', level: level, message: SentryMessage(code));
}

Breadcrumb? safeSentryBeforeBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
  hint
    ..attachments.clear()
    ..screenshot = null
    ..viewHierarchy = null
    ..clear();
  if (breadcrumb == null) return null;

  final (level, code) = _safeSentrySeverity(breadcrumb.level, prefix: 'safe_diagnostic.breadcrumb');
  return Breadcrumb(category: 'safe_diagnostics', type: 'default', level: level, message: code);
}

SentryTransaction? dropSentryTransaction(SentryTransaction transaction) => null;

bool dropSentryMetric(String key, {Map<String, String>? tags}) => false;

void installIosSafeSentryTransport(SentryFlutterOptions options) {
  final delegate = options.transport;
  if (delegate is IosSafeSentryTransport) return;
  options.transport = IosSafeSentryTransport(delegate, options.sdk, options.dsn);
}

class IosSafeSentryTransportIntegration implements Integration<SentryFlutterOptions> {
  @override
  void call(Hub hub, SentryFlutterOptions options) {
    installIosSafeSentryTransport(options);
  }

  @override
  Future<void> close() async {}
}

class IosSafeSentryTransport implements Transport {
  IosSafeSentryTransport(this._delegate, this._sdk, this._dsn);

  final Transport _delegate;
  final SdkVersion _sdk;
  final String? _dsn;

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    SentryEvent? event;
    for (final item in envelope.items) {
      final candidate = item.originalObject;
      if (item.header.type == 'event' && candidate is SentryEvent) {
        event = candidate;
        break;
      }
    }
    if (event == null) return const SentryId.empty();

    final safeEvent = await safeSentryBeforeSend(event, Hint());
    if (safeEvent == null) return const SentryId.empty();
    return _delegate.send(SentryEnvelope.fromEvent(safeEvent, _sdk, dsn: _dsn));
  }
}

/// iOS paths that cannot be proven to pass the Dart callbacks stay disabled.
void configureIosSafeSentryOptions(SentryFlutterOptions options) {
  options
    ..autoInitializeNativeSdk = false
    ..transport = SentryOptions().transport
    ..debug = false
    ..reportPackages = false
    ..sendClientReports = false
    ..enableNativeCrashHandling = false
    ..enableAutoSessionTracking = false
    ..enableWatchdogTerminationTracking = false
    ..enableAppHangTracking = false
    ..enableNdkScopeSync = false
    ..enableScopeSync = false
    ..enableAutoNativeBreadcrumbs = false
    ..enableAutoPerformanceTracing = false
    ..enableUserInteractionTracing = false
    ..enableTimeToFullDisplayTracing = false
    ..enableFramesTracking = false
    ..attachThreads = false
    ..attachScreenshot = false
    ..attachViewHierarchy = false
    ..sendDefaultPii = false
    ..maxRequestBodySize = MaxRequestBodySize.never
    ..maxResponseBodySize = MaxResponseBodySize.never
    ..tracesSampleRate = null
    ..tracesSampler = null
    ..profilesSampleRate = null
    ..beforeSend = safeSentryBeforeSend
    ..beforeSendFeedback = safeSentryBeforeSend
    ..beforeBreadcrumb = safeSentryBeforeBreadcrumb
    ..beforeSendTransaction = dropSentryTransaction
    ..beforeMetricCallback = dropSentryMetric;
  options.addIntegrationByIndex(0, IosSafeSentryTransportIntegration());
}

(SentryLevel, String) _safeSentrySeverity(SentryLevel? input, {String prefix = 'safe_diagnostic.sentry'}) {
  return switch (input) {
    SentryLevel.debug => (SentryLevel.debug, '$prefix.debug'),
    SentryLevel.info => (SentryLevel.info, '$prefix.info'),
    SentryLevel.warning => (SentryLevel.warning, '$prefix.warning'),
    SentryLevel.error || SentryLevel.fatal => (SentryLevel.error, '$prefix.error'),
    _ => (SentryLevel.info, '$prefix.info'),
  };
}

bool canSendEvent(dynamic throwable) {
  return switch (throwable) {
    UnexpectedFailure(:final error) => canSendEvent(error),
    DioException _ => false,
    SocketException _ => false,
    HttpException _ => false,
    HandshakeException _ => false,
    ExpectedFailure _ => false,
    ExpectedMeasuredFailure _ => false,
    _ => true,
  };
}

bool canLogEvent(dynamic throwable) => switch (throwable) {
  ExpectedMeasuredFailure _ => true,
  _ => canSendEvent(throwable),
};
