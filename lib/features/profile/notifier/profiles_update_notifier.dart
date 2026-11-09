import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:meta/meta.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'profiles_update_notifier.g.dart';

typedef ProfileUpdateStatus = ({String name, bool success});

@Riverpod(keepAlive: true)
class ForegroundProfilesUpdateNotifier extends _$ForegroundProfilesUpdateNotifier with AppLogger {
  static const prefKey = "profiles_update_check";
  static const interval = Duration(minutes: 15);

  /// When each failing profile's update fell due, by id: until one succeeds.
  static const failingKey = "profiles_update_failing_since";

  /// A profile whose updates failed this long is no longer updated on its own; a manual update
  /// still runs, and one that succeeds starts over.
  static const giveUpAfter = Duration(days: 3);

  @override
  Stream<ProfileUpdateStatus?> build() {
    var cycleCount = 0;
    _scheduler = NeatPeriodicTaskScheduler(
      name: 'profiles update worker',
      interval: interval,
      timeout: const Duration(minutes: 5),
      task: () async {
        loggy.debug("cycle [${cycleCount++}]");
        await updateProfiles();
      },
    );

    ref.onDispose(() async {
      await _scheduler?.stop();
      _scheduler = null;
    });

    if (ref.watch(Preferences.introCompleted)) {
      loggy.debug("intro done, starting");
      _scheduler?.start();
    } else {
      loggy.debug("intro in process, skipping");
    }
    return const Stream.empty();
  }

  NeatPeriodicTaskScheduler? _scheduler;
  bool _forceNextRun = false;

  Future<void> trigger() async {
    loggy.debug("triggering update");
    _forceNextRun = true;
    await _scheduler?.trigger();
  }

  /// Whether a profile failing since [since] is no longer updated on its own at [now].
  static bool gaveUp(DateTime? since, DateTime now) => since != null && now.difference(since) >= giveUpAfter;

  /// When a failing profile's update fell due: its last success plus its update interval. A
  /// subscription that broke long ago (before an app update, or while the app was closed) gives up
  /// on its first failed run, not three days after it.
  @visibleForTesting
  static DateTime failingSince(DateTime lastSuccess, Duration? updateInterval) =>
      lastSuccess.add(updateInterval ?? Duration.zero);

  Map<String, DateTime> _failingSince() => readFailingSince(ref.read(sharedPreferencesProvider).requireValue);

  /// When each failing profile's update fell due, by id, as the last update run saved it.
  static Map<String, DateTime> readFailingSince(SharedPreferences prefs) {
    final raw = prefs.getString(failingKey);
    if (raw == null) return {};
    try {
      return {
        for (final MapEntry(:key, :value) in (jsonDecode(raw) as Map).cast<String, String>().entries)
          if (DateTime.tryParse(value) case final since?) key: since,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveFailing(Map<String, DateTime> failing) => ref
      .read(sharedPreferencesProvider)
      .requireValue
      .setString(failingKey, jsonEncode({for (final e in failing.entries) e.key: e.value.toIso8601String()}));

  @visibleForTesting
  Future<void> updateProfiles() async {
    var force = false;
    if (_forceNextRun) {
      force = true;
      _forceNextRun = false;
    }

    try {
      final previousRun = DateTime.tryParse(ref.read(sharedPreferencesProvider).requireValue.getString(prefKey) ?? "");

      if (!force && previousRun != null && previousRun.add(interval) > DateTime.now()) {
        loggy.debug("too soon! previous run: [$previousRun]");
        return;
      }
      loggy.debug("${force ? "[FORCED] " : ""}running, previous run: [$previousRun]");

      final remoteProfiles = await ref
          .read(profileRepositoryProvider)
          .requireValue
          .watchAll()
          .map(
            (event) => event.getOrElse((f) {
              loggy.error("error getting profiles", f);
              throw f;
            }).whereType<RemoteProfileEntity>(),
          )
          .first;

      final failing = _failingSince();
      final now = DateTime.now();
      // a profile updated since it began to fail works again (a manual update, say)
      failing.removeWhere(
        (id, since) =>
            remoteProfiles.none((p) => p.id == id) ||
            remoteProfiles.any((p) => p.id == id && p.lastUpdate.isAfter(since)),
      );
      final toUpdate = remoteProfiles.where((profile) {
        if (!force && gaveUp(failing[profile.id], now)) {
          loggy.debug("skipping profile [${profile.id}] update: failing since [${failing[profile.id]}]");
          return false;
        }
        final updateInterval = profile.options?.updateInterval;
        final shouldUpdate =
            force || updateInterval != null && updateInterval <= DateTime.now().difference(profile.lastUpdate);
        if (!shouldUpdate) {
          loggy.debug(
            "skipping profile [${profile.id}] update. last successful update: [${profile.lastUpdate}] - interval: [${profile.options?.updateInterval}]",
          );
        }
        return shouldUpdate;
      }).toList();

      var successCount = 0;
      final failedNames = <String>[];
      // Sequential on purpose: validation and the active-profile reconnect share
      // one native core that is not safe to call concurrently (it can hang).
      for (final profile in toUpdate) {
        await ref.read(updateProfileNotifierProvider(profile.id).notifier).updateProfile(profile, isBulk: true);
        if (ref.read(updateProfileNotifierProvider(profile.id)).hasError) {
          failedNames.add(profile.name);
          failing[profile.id] = failingSince(profile.lastUpdate, profile.options?.updateInterval);
        } else {
          successCount++;
          failing.remove(profile.id);
        }
      }
      await _saveFailing(failing);

      // Only a manual run (forced) reports; the periodic background run stays silent.
      if (force && (successCount > 0 || failedNames.isNotEmpty)) {
        final t = ref.read(translationsProvider).requireValue;
        final notification = ref.read(inAppNotificationControllerProvider);
        if (failedNames.isEmpty) {
          notification.showSuccessToast(t.pages.profiles.msg.update.bulkSuccess(count: successCount));
        } else {
          notification.showErrorToast(
            t.pages.profiles.msg.update.bulkPartial(
              success: successCount,
              failed: failedNames.length,
              names: failedNames.join(", "),
            ),
          );
        }
      }
    } finally {
      await ref.read(sharedPreferencesProvider).requireValue.setString(prefKey, DateTime.now().toIso8601String());
    }
  }
}
