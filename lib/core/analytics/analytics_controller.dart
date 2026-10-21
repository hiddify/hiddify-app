import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hiddify/core/analytics/analytics_filter.dart';
import 'package:hiddify/core/analytics/analytics_logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/core/observability/telemetry_budget.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/remote_diagnostic_subscription.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
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
  _TelemetryLifecycle? _lifecycle;

  @override
  Future<bool> build() async {
    ref.onDispose(_stopRemote);
    return _preferences.getBool(enableAnalyticsPrefKey) ?? Environment.telemetryBeta;
  }

  SharedPreferences get _preferences => ref.read(sharedPreferencesProvider).requireValue;

  void _stopRemote() {
    final observer = _lifecycle;
    if (observer != null) WidgetsBinding.instance.removeObserver(observer);
    _lifecycle = null;
    _journalSubscription?.dispose();
    _journalSubscription = null;
    final remote = _remote;
    _remote = null;
    if (remote != null) unawaited(remote.dispose());
  }

  Future<void> enableAnalytics() async {
    if (state case AsyncData(value: final enabled)) {
      state = const AsyncLoading();
      if (!enabled) await _preferences.setBool(enableAnalyticsPrefKey, true);
      _stopRemote();
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
          );
          _remote = remote;
          _journalSubscription = RemoteDiagnosticSubscription(ref.read(safeDiagnosticJournalProvider), remote);
          _lifecycle = _TelemetryLifecycle(remote);
          WidgetsBinding.instance.addObserver(_lifecycle!);
        }
      }
      state = const AsyncData(true);
    }
  }

  /// Queuing is not a delivery acknowledgement; verify ingestion in Better Stack.
  bool sendTestEvent() {
    final remote = _remote;
    if (remote == null || !remote.addTestEvent()) return false;
    unawaited(remote.flush());
    return true;
  }

  Future<void> disableAnalytics() async {
    if (state case AsyncData()) {
      state = const AsyncLoading();
      _stopRemote();
      await _preferences.setBool(enableAnalyticsPrefKey, false);
      LoggerController.instance.removePrinter("analytics");
      await Sentry.close();
      state = const AsyncData(false);
    }
  }
}

class _TelemetryLifecycle extends WidgetsBindingObserver {
  _TelemetryLifecycle(this.remote);
  final BetterStackLogPrinter remote;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(remote.flush());
  }
}
