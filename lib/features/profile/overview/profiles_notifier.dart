import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profiles_notifier.g.dart';

@riverpod
class ProfilesSortNotifier extends _$ProfilesSortNotifier with AppLogger {
  @override
  ({ProfilesSort by, SortMode mode}) build() => ref.watch(Preferences.profilesSort);

  void changeSort(ProfilesSort sortBy) {
    ref.read(Preferences.profilesSort.notifier).update((
      by: sortBy,
      mode: switch (sortBy) {
        ProfilesSort.name => SortMode.ascending, // A → Z
        ProfilesSort.lastUpdate => SortMode.descending, // newest first
      },
    ));
  }

  void toggleMode() {
    final current = ref.read(Preferences.profilesSort);
    ref.read(Preferences.profilesSort.notifier).update((
      by: current.by,
      mode: current.mode == SortMode.ascending ? SortMode.descending : SortMode.ascending,
    ));
  }
}

/// Why a subscription counts as inactive, most telling first.
enum InactiveReason { expired, noTraffic, updateFailing }

/// A subscription that no longer works, and since when, if known.
typedef InactiveProfile = ({RemoteProfileEntity profile, InactiveReason reason, DateTime? since});

/// The subscriptions in [profiles] that no longer work at [now]: expired, out of traffic, or
/// failing to update long enough that they are no longer updated on their own ([failingSince]
/// as the update run saves it). Local profiles never expire, so they are never listed.
List<InactiveProfile> findInactiveProfiles(
  Iterable<ProfileEntity> profiles,
  Map<String, DateTime> failingSince,
  DateTime now,
) {
  return [
    for (final profile in profiles.whereType<RemoteProfileEntity>())
      if (profile.subInfo case final info? when !info.expire.isAfter(now))
        (profile: profile, reason: InactiveReason.expired, since: info.expire)
      else if (profile.subInfo case final info? when info.consumption >= info.total)
        (profile: profile, reason: InactiveReason.noTraffic, since: null)
      else if (failingSince[profile.id] case final since?
          when ForegroundProfilesUpdateNotifier.gaveUp(since, now) && !profile.lastUpdate.isAfter(since))
        (profile: profile, reason: InactiveReason.updateFailing, since: since),
  ];
}

@riverpod
class ProfilesNotifier extends _$ProfilesNotifier with AppLogger {
  @override
  Stream<List<ProfileEntity>> build() {
    final sort = ref.watch(profilesSortNotifierProvider);
    return _profilesRepo.watchAll(sort: sort.by, sortMode: sort.mode).map((event) => event.getOrElse((l) => throw l));
  }

  ProfileRepository get _profilesRepo => ref.read(profileRepositoryProvider).requireValue;

  Future<Unit> selectActiveProfile(String id) async {
    loggy.debug('changing active profile to: [$id]');
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    return _profilesRepo.setAsActive(id).getOrElse((err) {
      loggy.warning('failed to set [$id] as active profile', err);
      throw err;
    }).run();
  }

  Future<void> togglePin(ProfileEntity profile) async {
    loggy.debug('toggling pin for profile: [${profile.id}] -> ${!profile.pinned}');
    await _profilesRepo.setPinned(profile.id, !profile.pinned).getOrElse((err) {
      loggy.warning('failed to toggle pin for [${profile.id}]', err);
      throw err;
    }).run();
  }

  /// The subscriptions that no longer work, to offer removing them.
  Future<List<InactiveProfile>> findInactive() async {
    final profiles = await _profilesRepo.watchAll().first.then((e) => e.getOrElse((l) => throw l));
    final failing = ForegroundProfilesUpdateNotifier.readFailingSince(ref.read(sharedPreferencesProvider).requireValue);
    return findInactiveProfiles(profiles, failing, DateTime.now());
  }

  Future<void> deleteProfile(ProfileEntity profile) async {
    await _delete(profile);
    final t = ref.read(translationsProvider).requireValue;
    ref.read(inAppNotificationControllerProvider).showSuccessToast(t.pages.profiles.msg.delete.success);
  }

  /// Deletes [profiles] with one toast at the end. The active one goes last: deleting it makes
  /// another profile active, which must not be one still to be deleted.
  Future<void> deleteProfiles(List<ProfileEntity> profiles) async {
    final ordered = [...profiles.where((p) => !p.active), ...profiles.where((p) => p.active)];
    var deleted = 0;
    for (final profile in ordered) {
      try {
        await _delete(profile);
        deleted++;
      } catch (_) {
        // logged in _delete; the rest are still deleted
      }
    }
    final t = ref.read(translationsProvider).requireValue;
    final notification = ref.read(inAppNotificationControllerProvider);
    if (deleted == ordered.length) {
      notification.showSuccessToast(t.pages.profiles.msg.delete.bulkSuccess(count: deleted));
    } else {
      notification.showErrorToast(t.pages.profiles.msg.delete.bulkPartial(deleted: deleted, total: ordered.length));
    }
  }

  Future<void> _delete(ProfileEntity profile) async {
    loggy.debug('deleting profile: ${profile.name}');

    if (profile.active) await ref.read(connectionNotifierProvider.notifier).abortConnection();
    await _profilesRepo
        .deleteById(profile.id, profile.active)
        .match(
          (err) {
            loggy.warning('failed to delete profile', err);
            throw err;
          },
          (_) async {
            loggy.info('successfully deleted profile, was active? [${profile.active}]');

            final activePrfile = await ref.read(activeProfileProvider.future);
            if (profile.id == ref.read(ConfigOptions.extraSecurityProfileId)) {
              ref.read(ConfigOptions.extraSecurityProfileId.notifier).update(activePrfile?.id);
            }
            if (profile.id == ref.read(ConfigOptions.unblockerProfileId)) {
              ref.read(ConfigOptions.unblockerProfileId.notifier).update(activePrfile?.id);
            }

            return unit;
          },
        )
        .run();
  }

  /// The configuration JSON [profile] runs with, to share it.
  Future<String> generateConfig(ProfileEntity profile) => _profilesRepo.generateConfig(profile.id).getOrElse((err) {
    loggy.warning('error generating config', err);
    throw err;
  }).run();
}
