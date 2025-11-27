import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/config_option/notifier/warp_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
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
    return const AsyncData(null);
  }

  ProfileRepository get _profilesRepo =>
      ref.read(profileRepositoryProvider).requireValue;
  CancelToken? _cancelToken;

  Future<void> add(String rawInput) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    // await check4Warp(rawInput);
    state = await AsyncValue.guard(() async {
      final activeProfile = await ref.read(activeProfileProvider.future);
      final markAsActive =
          activeProfile == null || ref.read(Preferences.markNewProfileActive);
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
        final oldItem = await _profilesRepo.getByName(name);
        if (name == "Hiddify WARP" && oldItem != null) {
          _profilesRepo.deleteById(oldItem.id).run();
        }
        var candidate = name;
        while (await _profilesRepo.getByName(candidate) != null) {
          final sb = StringBuffer(candidate)..write(randomInt(0, 9).run());
          candidate = sb.toString();
        }
        name = candidate;
        task = _profilesRepo.addByContent(
          parsed.content,
          name: name,
          markAsActive: markAsActive,
        );
      } else {
        loggy.debug("invalid content");
        throw const ProfileInvalidUrlFailure();
      }
      return task
          .match(
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
          )
          .run();
    });
  }

  Future<void> check4Warp(String rawInput) async {
    for (final line in rawInput.split("\n")) {
      if (line.toLowerCase().startsWith("warp://")) {
        final prefs = ref.read(sharedPreferencesProvider).requireValue;
        final warp = ref.read(warpOptionProvider.notifier);

        final consent =
            prefs.getBool(WarpOptionNotifier.warpConsentGiven) ?? false;

        final t = ref.read(translationsProvider);
        final notification = ref.read(inAppNotificationControllerProvider);

        if (!consent) {
          final agreed = await showDialog<bool>(
            context: RootScaffold.stateKey.currentContext!,
            builder: (context) => const WarpLicenseAgreementModal(),
          );

          if (agreed ?? false) {
            await prefs.setBool(WarpOptionNotifier.warpConsentGiven, true);
            final toast = notification.showInfoToast(
              t.profile.add.addingWarpMsg,
              duration: const Duration(milliseconds: 100),
            );
            toast?.pause();
            await warp.generateWarpConfig();
            toast?.start();
          } else {
            return;
          }
        }

        final accountId = prefs.getString("warp2-account-id");
        final accessToken = prefs.getString("warp2-access-token");
        final hasWarp2Config = accountId != null && accessToken != null;

        if (!hasWarp2Config) {
          final toast = notification.showInfoToast(
            t.profile.add.addingWarpMsg,
            duration: const Duration(milliseconds: 100),
          );
          toast?.pause();
          await warp.generateWarp2Config();
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
    return const AsyncData(null);
  }

  ProfileRepository get _profilesRepo =>
      ref.read(profileRepositoryProvider).requireValue;

  Future<void> updateProfile(RemoteProfileEntity profile) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    state = await AsyncValue.guard(() async {
      return await _profilesRepo
          .updateSubscription(profile)
          .match(
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
                  await ref
                      .read(connectionProvider.notifier)
                      .reconnect(profile);
                }
              });
              return unit;
            },
          )
          .run();
    });
  }
}
