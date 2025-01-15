import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/warp_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/add/model/free_profiles_model.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_notifier.g.dart';

@riverpod
class AddProfile extends _$AddProfile with AppLogger {
  @override
  AsyncValue<Unit?> build() {
    ref.disposeDelay(const Duration(minutes: 1));
    ref.onDispose(() {
      loggy.debug("disposing");
      _cancelToken?.cancel();
    });
    listenSelf(
      (previous, next) {
        final t = ref.read(translationsProvider).requireValue;
        final notification = ref.read(inAppNotificationControllerProvider);
        switch (next) {
          case AsyncData(value: final _?):
            notification.showSuccessToast(t.profile.save.successMsg);
          case AsyncError(:final error):
            if (error case ProfileInvalidUrlFailure()) {
              notification.showErrorToast(t.failure.profiles.invalidUrl);
            } else {
              notification.showErrorDialog(
                t.presentError(error, action: t.profile.add.failureMsg),
              );
            }
        }
      },
    );
    return const AsyncData(null);
  }

  ProfileRepository get _profilesRepo => ref.read(profileRepositoryProvider).requireValue;
  CancelToken? _cancelToken;

  Future<void> add(String rawInput) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    // await check4Warp(rawInput);
    state = await AsyncValue.guard(
      () async {
        final activeProfile = await ref.read(activeProfileProvider.future);
        final markAsActive = activeProfile == null || ref.read(Preferences.markNewProfileActive);
        final TaskEither<ProfileFailure, Unit> task;
        if (LinkParser.parse(rawInput) case (final link)?) {
          loggy.debug("adding profile, url: [${link.url}]");
          task = _profilesRepo.addByUrl(
            link.url,
            markAsActive: markAsActive,
            cancelToken: _cancelToken = CancelToken(),
          );
        } else if (LinkParser.protocol(rawInput) case (final parsed)?) {
          loggy.debug("adding profile, content");
          var name = parsed.name;
          var oldItem = await _profilesRepo.getByName(name);
          if (name == "Hiddify WARP" && oldItem != null) {
            _profilesRepo.deleteById(oldItem.id).run();
          }
          while (await _profilesRepo.getByName(name) != null) {
            name += '${randomInt(0, 9).run()}';
          }
          task = _profilesRepo.addByContent(
            parsed.content,
            name: name,
            markAsActive: markAsActive,
          );
        } else {
          loggy.debug("invalid content");
          throw const ProfileInvalidUrlFailure();
        }
        return task.match(
          (err) {
            loggy.warning("failed to add profile", err);
            throw err;
          },
          (_) {
            loggy.info(
              "successfully added profile, mark as active? [$markAsActive]",
            );
            return unit;
          },
        ).run();
      },
    );
  }

  Future<void> check4Warp(String rawInput) async {
    for (final line in rawInput.split("\n")) {
      if (line.toLowerCase().startsWith("warp://")) {
        final _prefs = ref.read(sharedPreferencesProvider).requireValue;
        final _warp = ref.read(warpOptionNotifierProvider.notifier);

        final consent = false && (_prefs.getBool(WarpOptionNotifier.warpConsentGiven) ?? false);

        final t = ref.read(translationsProvider).requireValue;
        final notification = ref.read(inAppNotificationControllerProvider);

        if (!consent) {
          final agreed = await showDialog<bool>(
            context: RootScaffold.stateKey.currentContext!,
            builder: (context) => const WarpLicenseAgreementModal(),
          );

          if (agreed ?? false) {
            await _prefs.setBool(WarpOptionNotifier.warpConsentGiven, true);
            final toast = notification.showInfoToast(t.profile.add.addingWarpMsg, duration: const Duration(milliseconds: 100));
            toast?.pause();
            await _warp.generateWarpConfig();
            toast?.start();
          } else {
            return;
          }
        }

        final accountId = _prefs.getString("warp2-account-id");
        final accessToken = _prefs.getString("warp2-access-token");
        final hasWarp2Config = accountId != null && accessToken != null;

        if (!hasWarp2Config || true) {
          final toast = notification.showInfoToast(t.profile.add.addingWarpMsg, duration: const Duration(milliseconds: 100));
          toast?.pause();
          await _warp.generateWarp2Config();
          toast?.start();
        }
      }
    }
  }
}

@riverpod
class UpdateProfile extends _$UpdateProfile with AppLogger {
  @override
  AsyncValue<Unit?> build(String id) {
    ref.disposeDelay(const Duration(minutes: 1));
    listenSelf(
      (previous, next) {
        final t = ref.read(translationsProvider).requireValue;
        final notification = ref.read(inAppNotificationControllerProvider);
        switch (next) {
          case AsyncData(value: final _?):
            notification.showSuccessToast(t.profile.update.successMsg);
          case AsyncError(:final error):
            notification.showErrorDialog(
              t.presentError(error, action: t.profile.update.failureMsg),
            );
        }
      },
    );
    return const AsyncData(null);
  }

  ProfileRepository get _profilesRepo => ref.read(profileRepositoryProvider).requireValue;

  Future<void> updateProfile(RemoteProfileEntity profile) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    state = await AsyncValue.guard(
      () async {
        return await _profilesRepo.updateSubscription(profile).match(
          (err) {
            loggy.warning("failed to update profile", err);
            throw err;
          },
          (_) async {
            loggy.info(
              'successfully updated profile, was active? [${profile.active}]',
            );

            await ref.read(activeProfileProvider.future).then((active) async {
              if (active != null && active.id == profile.id) {
                await ref.read(connectionNotifierProvider.notifier).reconnect(profile);
              }
            });
            return unit;
          },
        ).run();
      },
    );
  }
}

@riverpod
class FreeSwitch extends _$FreeSwitch {
  @override
  bool build() {
    return false;
  }

  Future<void> onChange(bool value) async => state = value;
}

@riverpod
class FreeProfiles extends _$FreeProfiles {
  @override
  Future<List<FreeProfile>> build() async {
    final httpCielt = ref.watch(httpClientProvider);
    final region = ref.watch(ConfigOptions.region);
    final res = await httpCielt.get('https://raw.githubusercontent.com/hiddify/hiddify-app/refs/heads/main/test.configs/free_configs');
    if (res.statusCode == 200) {
      final m = FreeProfilesModel.fromJson(jsonDecode(res.data.toString()) as Map<String, dynamic>);
      return m.profiles.where((e) => e.region.contains(region.name)).toList();
    }
    return <FreeProfile>[];
  }
}
