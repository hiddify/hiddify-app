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

part 'profiles_update_notifier.g.dart';

typedef ProfileUpdateStatus = ({String name, bool success});

@Riverpod(keepAlive: true)
class ForegroundProfilesUpdateNotifier extends _$ForegroundProfilesUpdateNotifier with AppLogger {
  static const prefKey = "profiles_update_check";
  static const interval = Duration(minutes: 15);

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
              loggy.error("error getting profiles");
              throw f;
            }).whereType<RemoteProfileEntity>(),
          )
          .first;

      final toUpdate = remoteProfiles.where((profile) {
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
        } else {
          successCount++;
        }
      }

      if (successCount > 0 || failedNames.isNotEmpty) {
        final t = ref.read(translationsProvider).requireValue;
        final notification = ref.read(inAppNotificationControllerProvider);
        if (failedNames.isEmpty) {
          notification.showSuccessToast(t.pages.profiles.msg.update.bulkSuccess(count: successCount));
        } else {
          // Longer duration so the user has time to read the failed names.
          final seconds = failedNames.length >= 5 ? 15 : 5 + failedNames.length * 2;
          notification.showErrorToast(
            t.pages.profiles.msg.update.bulkPartial(
              success: successCount,
              failed: failedNames.length,
              names: failedNames.join(", "),
            ),
            duration: Duration(seconds: seconds),
          );
        }
      }
    } finally {
      await ref.read(sharedPreferencesProvider).requireValue.setString(prefKey, DateTime.now().toIso8601String());
    }
  }
}
