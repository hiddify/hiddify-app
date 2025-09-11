import 'package:flutter/foundation.dart';
import 'package:hiddify/core/analytics/analytics_filter.dart';
import 'package:hiddify/core/analytics/analytics_logger.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'analytics_controller.g.dart';

const String enableAnalyticsPrefKey = "enable_analytics";

bool _testCrashReport = false;

@Riverpod(keepAlive: true)
class AnalyticsController extends _$AnalyticsController with AppLogger {
  @override
  Future<bool> build() async {
    return _preferences.getBool(enableAnalyticsPrefKey) ?? true;
  }

  SharedPreferences get _preferences => ref.read(sharedPreferencesProvider).requireValue;

  Future<void> enableAnalytics() async {
    if (state case AsyncData(value: final enabled)) {
      loggy.debug("enabling analytics");
      state = const AsyncLoading();
      if (!enabled) {
        await _preferences.setBool(enableAnalyticsPrefKey, true);
      }

      final env = ref.read(environmentProvider);
      final appInfo = await ref.read(appInfoProvider.future);
      final dsn = !kDebugMode || _testCrashReport ? Environment.sentryDSN : "";
      final sentryLogger = SentryLoggyIntegration();
      LoggerController.instance.addPrinter("analytics", sentryLogger);

      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.environment = env.name;
          options.dist = appInfo.release.name;
          options.debug = kDebugMode;
          options.enableNativeCrashHandling = true;
          options.enableNdkScopeSync = true;
          // options.attachScreenshot = true;
          options.serverName = "";
          options.attachThreads = true;
          options.tracesSampleRate = 0.20;
          options.enableUserInteractionTracing = true;
          options.addIntegration(sentryLogger);
          options.beforeSend = sentryBeforeSend;
        },
      );

      state = const AsyncData(true);
    }
  }

  Future<void> disableAnalytics() async {
    if (state case AsyncData()) {
      loggy.debug("disabling analytics");
      state = const AsyncLoading();
      await _preferences.setBool(enableAnalyticsPrefKey, false);
      await Sentry.close();
      LoggerController.instance.removePrinter("analytics");
      state = const AsyncData(false);
    }
  }
}
