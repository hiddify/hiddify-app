import 'dart:convert';
import 'dart:isolate';

import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/details/profile_details_state.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_details_notifier.g.dart';

@riverpod
class ProfileDetailsNotifier extends _$ProfileDetailsNotifier with AppLogger {
  ProfileRepository get _profilesRepo => ref.read(profileRepositoryProvider).requireValue;

  /// The config while it loads; save waits for it.
  late Future<EditableConfig> _config;

  @override
  Future<ProfileDetailsState> build(String id) async {
    final prof = (await _profilesRepo.getById(id).run()).match((l) => throw l, (prof) {
      if (prof == null) {
        loggy.warning('profile with id: [$id] does not exist');
        throw const ProfileNotFoundFailure();
      }
      return prof;
    });
    // The page opens at once with the profile; only the editor waits for the config.
    var disposed = false;
    ref.onDispose(() => disposed = true);
    final config = _config = _loadConfig(id);
    void show(AsyncValue<EditableConfig> config) {
      if (disposed) return;
      if (state case AsyncData(value: final ProfileDetailsState data)) {
        state = AsyncData(data.copyWith(config: config));
      }
    }

    config.then((config) => show(AsyncData(config)), onError: (Object e, StackTrace st) => show(AsyncError(e, st)));
    return ProfileDetailsState(
      loadingState: const AsyncData(null),
      profile: prof,
      config: const AsyncLoading(),
      isDetailsChanged: false,
    );
  }

  Future<EditableConfig> _loadConfig(String id) async {
    String content;
    try {
      content = (await _profilesRepo.generateConfig(id).run()).match(
        (l) => throw Exception('Failed to generate config: $l'),
        (content) => content,
      );
    } catch (e, st) {
      loggy.error('Error generating config for profile $id', e, st);
      content = await _profilesRepo.getRawConfig(id).run().then((e) => e.getOrElse((f) => ""));
    }
    // decoding and encoding a large config takes long: off the UI thread
    return Isolate.run(() => _editableConfig(content));
  }

  Future<T?> doAsync<T>(Future<T> Function() operation) async {
    if (state case AsyncData(value: final ProfileDetailsState data)) {
      state = AsyncData(data.copyWith(loadingState: const AsyncLoading()));
      final T? result = await operation();
      state = AsyncData(data.copyWith(loadingState: const AsyncData(null)));
      return result;
    }
    return null;
  }

  void setUserOverride(UserOverride userOverride) {
    if (state case AsyncData(value: final ProfileDetailsState data)) {
      state = AsyncData(
        data.copyWith(profile: data.profile.copyWith(userOverride: userOverride), isDetailsChanged: true),
      );
    }
  }

  void setContent(String configContent) {
    if (state case AsyncData(value: final ProfileDetailsState data)) {
      final isJson = data.config.valueOrNull?.isJson ?? false;
      state = AsyncData(
        data.copyWith(config: AsyncData((text: configContent, isJson: isJson)), isDetailsChanged: true),
      );
    }
  }

  Future<bool> save() async {
    bool success = false;
    if (state case AsyncData(:final value)) {
      if (value.loadingState case AsyncLoading()) return false;

      success =
          await doAsync<bool>(() async {
            final t = await ref.read(translationsProvider.future);
            // a rename saved before the config loaded waits for it, so the config is never lost
            final config = value.config.valueOrNull ?? await _config;
            return (await _profilesRepo.offlineUpdate(value.profile, config.text).run()).match(
              (l) async {
                await ref
                    .read(dialogNotifierProvider.notifier)
                    .showCustomAlertFromErr(
                      t.presentError(l, action: t.pages.profiles.msg.update.failureNamed(name: value.profile.name)),
                    );
                return false;
              },
              (r) {
                ref.read(inAppNotificationControllerProvider).showSuccessToast(t.pages.profiles.msg.update.success);
                return true;
              },
            );
          }) ??
          false;
    }
    return success;
  }
}

/// The outbounds and endpoints of a generated config, the part the user edits; content that is
/// not such JSON as it is.
EditableConfig _editableConfig(String content) {
  try {
    final jsonObject = jsonDecode(content);
    final List<Map<String, dynamic>> outbounds = [];
    if (jsonObject is Map<String, dynamic> && jsonObject['outbounds'] is List) {
      for (final outbound in jsonObject['outbounds'] as List<dynamic>) {
        if (outbound is Map<String, dynamic> &&
            outbound['type'] != null &&
            !['selector', 'urltest', 'dns', 'block'].contains(outbound['type']) &&
            !['direct', 'bypass', 'direct-fragment'].contains(outbound['tag'])) {
          outbounds.add(outbound);
        }
      }
    }
    // ignore: avoid_dynamic_calls
    final endpoints = jsonObject['endpoints'] as List? ?? [];
    return (text: '{"outbounds": ${json.encode(outbounds)},"endpoints":${json.encode(endpoints)} }', isJson: true);
  } catch (_) {
    return (text: content, isJson: false);
  }
}
