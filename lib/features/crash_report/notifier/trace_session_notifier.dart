import 'dart:async';

import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = appLogger('TraceSession');

/// A short stretch of trace logging the user turns on from Report a problem, to catch the problem
/// in detail before sending it: the state is when it ends, or null when it is off.
///
/// The level it replaced and the end are kept in the preferences, so a session the app was closed
/// in still ends on the next start, and the user is never left on trace without knowing.
final traceSessionProvider = NotifierProvider<TraceSessionNotifier, DateTime?>(TraceSessionNotifier.new);

class TraceSessionNotifier extends Notifier<DateTime?> {
  static const duration = Duration(minutes: 10);

  static const _untilKey = 'trace-session-until';
  static const _levelBeforeKey = 'trace-session-level-before';

  Timer? _timer;

  @override
  DateTime? build() {
    ref.onDispose(() => _timer?.cancel());
    final until = DateTime.tryParse(_prefs.getString(_untilKey) ?? '');
    if (until == null) return null;
    if (!until.isAfter(DateTime.now())) {
      // ended while the app was closed: nothing to tell, the report can still be sent
      Future.microtask(() => _end(notify: false));
      return null;
    }
    _schedule(until);
    return until;
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider).requireValue;

  bool get active => state != null;

  /// Turns trace on for [duration]. A running core picks it up by reconnecting by itself
  /// (ConfigOptionNotifier), a stopped one on the next connect. The core is told the end too
  /// (ConfigOptions.singboxConfigOptions), and goes back by itself when the app is not running then.
  Future<void> start() async {
    final level = ref.read(ConfigOptions.logLevel);
    // a second start keeps the level from before the first
    if (state == null) await _prefs.setString(_levelBeforeKey, level.name);
    final until = DateTime.now().add(duration);
    await _prefs.setString(_untilKey, until.toIso8601String());
    _schedule(until);
    // the end first, then the level: the core's options change once, with both
    state = until;
    _log.info('trace logging on until $until (was ${level.name})');
    if (level != LogLevel.trace) await ref.read(ConfigOptions.logLevel.notifier).update(LogLevel.trace);
  }

  /// The level the session goes back to, while one runs.
  LogLevel? get levelBefore => LogLevel.values.asNameMap()[_prefs.getString(_levelBeforeKey) ?? ''];

  /// Ends it now: the report is made, or the user stopped it.
  Future<void> stop() => _end(notify: false);

  void _schedule(DateTime until) {
    _timer?.cancel();
    _timer = Timer(until.difference(DateTime.now()), () => _end(notify: true));
  }

  Future<void> _end({required bool notify}) async {
    _timer?.cancel();
    _timer = null;
    final before = levelBefore ?? LogLevel.warn;
    final wasActive = state != null;
    // the level first, then the end: the core's options change once, with both; a level the user
    // picked by hand meanwhile is theirs to keep
    if (ref.read(ConfigOptions.logLevel) == LogLevel.trace && before != LogLevel.trace) {
      await ref.read(ConfigOptions.logLevel.notifier).update(before);
    }
    await _prefs.remove(_untilKey);
    await _prefs.remove(_levelBeforeKey);
    state = null;
    _log.info('trace logging off, back to ${before.name}');
    if (notify && wasActive) {
      final t = ref.read(translationsProvider).valueOrNull;
      if (t != null) ref.read(inAppNotificationControllerProvider).showInfoToast(t.dialogs.crashReport.trace.ended);
    }
  }
}
