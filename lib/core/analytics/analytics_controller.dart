import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hiddify/core/analytics/analytics_filter.dart';
import 'package:hiddify/core/analytics/analytics_logger.dart';
import 'package:hiddify/core/analytics/telemetry_delivery_provider.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';
import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/remote_diagnostic_subscription.dart';
import 'package:hiddify/features/diagnostics/remote_ios_ping_subscription.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'analytics_controller.g.dart';

const String enableAnalyticsPrefKey = "enable_analytics";

@Riverpod(keepAlive: true)
class AnalyticsController extends _$AnalyticsController with AppLogger {
  BetterStackLogPrinter? _remote;
  RemoteDiagnosticSubscription? _journalSubscription;
  RemoteIosPingSubscription? _pingSubscription;
  StreamSubscription<TelemetryDeliveryStatus>? _deliverySubscription;
  TelemetryDeliveryMonitor? _deliveryMonitor;
  int? _lastPingSequence;

  void _publishDelivery(TelemetryDeliveryStatus status) {
    _deliveryMonitor?.update(status);
  }

  @override
  Future<bool> build() async {
    _deliveryMonitor = ref.read(telemetryDeliveryMonitorProvider);
    ref.onDispose(() {
      unawaited(_stopRemote());
    });
    return _preferences.getBool(enableAnalyticsPrefKey) ?? Environment.telemetryBeta;
  }

  SharedPreferences get _preferences => ref.read(sharedPreferencesProvider).requireValue;

  Future<void> _stopRemote({bool clearPending = false}) async {
    _pingSubscription?.dispose();
    _pingSubscription = null;
    _journalSubscription?.dispose();
    _journalSubscription = null;
    final remote = _remote;
    _remote = null;
    await _deliverySubscription?.cancel();
    _deliverySubscription = null;
    _publishDelivery(const TelemetryDeliveryStatus.disabled());
    if (remote != null) await remote.dispose(clearPending: clearPending);
    if (clearPending) await _preferences.remove(BetterStackLogPrinter.preferenceKey);
  }

  Future<void> enableAnalytics() async {
    if (state case AsyncData(value: final enabled)) {
      state = const AsyncLoading();
      if (!enabled) await _preferences.setBool(enableAnalyticsPrefKey, true);
      await _stopRemote();
      final preferences = _preferences;
      final budget = TelemetryBudget(
        read: () => preferences.getString(TelemetryBudget.preferenceKey),
        write: (value) => preferences.setString(TelemetryBudget.preferenceKey, value),
      );
      final sentryLogger = SentryLoggyIntegration();
      LoggerController.instance.removePrinter("analytics");
      LoggerController.instance.addPrinter("analytics", sentryLogger);

      await SentryFlutter.init((options) {
        options.dsn = kDebugMode ? "" : Environment.sentryDSN;
        options.debug = false;
        options.serverName = "";
        options.tracesSampleRate = 0;
        options.enableUserInteractionTracing = false;
        options.addIntegration(sentryLogger);
        options.beforeSend = sentryBeforeSend;
        if (!kIsWeb && Platform.isIOS) configureIosSafeSentryOptions(options);
        final filter = options.beforeSend;
        options.beforeSend = (event, hint) async {
          final safe = filter == null ? event : await filter(event, hint);
          if (safe == null || !await budget.reserveException()) return null;
          return safe;
        };
      });

      if (!kDebugMode && !kIsWeb && Platform.isIOS && Environment.telemetryBeta) {
        final endpoint = Uri.tryParse(Environment.betterStackLogsURL);
        if (endpoint != null && isBetterStackLogsEndpoint(endpoint) && Environment.betterStackSourceToken.isNotEmpty) {
          final metadata = ref.read(safeDiagnosticMetadataProvider);
          final remote = BetterStackLogPrinter(
            endpoint: endpoint,
            token: Environment.betterStackSourceToken,
            budget: budget,
            sessionId: const Uuid().v4(),
            version: metadata.version,
            buildNumber: metadata.buildNumber,
            readOutbox: () => preferences.getString(BetterStackLogPrinter.preferenceKey),
            writeOutbox: (value) => preferences.setString(BetterStackLogPrinter.preferenceKey, value),
          );
          _remote = remote;
          _deliverySubscription = remote.deliveryStatuses.listen(_publishDelivery);
          _publishDelivery(remote.deliveryStatus);
          _journalSubscription = RemoteDiagnosticSubscription(ref.read(safeDiagnosticJournalProvider), remote);
          final trace = ref.read(iosPingTraceProvider);
          final events = trace.snapshot.events;
          final cursor = enabled ? (_lastPingSequence ?? 0) : (events.isEmpty ? 0 : events.last.sequence);
          _lastPingSequence = cursor;
          _pingSubscription = RemoteIosPingSubscription(
            trace,
            remote,
            afterSequence: cursor,
            onSequence: (sequence) => _lastPingSequence = sequence,
          );
        }
      }
      state = const AsyncData(true);
    }
  }

  /// A server acknowledgement remains separate from visibility in Better Stack search.
  Future<TelemetryTestResult> sendTestEvent() async {
    final remote = _remote;
    if (remote == null) return const TelemetryTestResult(outcome: TelemetryTestOutcome.disabled);
    return remote.sendTestEvent();
  }

  Future<void> disableAnalytics() async {
    if (state case AsyncData()) {
      state = const AsyncLoading();
      await _stopRemote(clearPending: true);
      await _preferences.setBool(enableAnalyticsPrefKey, false);
      LoggerController.instance.removePrinter("analytics");
      await Sentry.close();
      state = const AsyncData(false);
    }
  }
}
