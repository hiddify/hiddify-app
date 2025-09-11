import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/model/config_option_failure.dart';
import 'package:hiddify/singbox/service/singbox_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'warp_option_notifier.freezed.dart';
part 'warp_option_notifier.g.dart';

@Riverpod(keepAlive: true)
class WarpOptionNotifier extends _$WarpOptionNotifier with AppLogger {
  @override
  WarpOptions build() {
    final consent = _prefs.getBool(warpConsentGiven) ?? false;
    bool hasWarpConfig = false;
    try {
      final accountId = _prefs.getString("warp-account-id");
      final accessToken = _prefs.getString("warp-access-token");
      hasWarpConfig = accountId != null && accessToken != null;
    } catch (e) {
      loggy.warning(e);
    }

    return WarpOptions(
      consentGiven: consent,
      configGeneration: hasWarpConfig ? const AsyncValue.data("") : AsyncError(const MissingWarpConfigFailure(), StackTrace.current),
    );
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider).requireValue;

  Future<void> agree() async {
    await ref.read(sharedPreferencesProvider).requireValue.setBool(warpConsentGiven, true);
    state = state.copyWith(consentGiven: true);
    await generateWarpConfig();
  }

  Future<void> generateWarpConfig() async {
    if (state.configGeneration.isLoading) return;
    state = state.copyWith(configGeneration: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      final warp = await ref
          .read(singboxServiceProvider)
          .generateWarpConfig(
            licenseKey: ref.read(ConfigOptions.warpLicenseKey),
            previousAccountId: ref.read(ConfigOptions.warpAccountId),
            previousAccessToken: ref.read(ConfigOptions.warpAccessToken),
          )
          .getOrElse((l) => throw l)
          .run();

      await ref.read(ConfigOptions.warpAccountId.notifier).update(warp.accountId);
      await ref.read(ConfigOptions.warpAccessToken.notifier).update(warp.accessToken);
      await ref.read(ConfigOptions.warpWireguardConfig.notifier).update(warp.wireguardConfig);
      return warp.log;
    });

    state = state.copyWith(configGeneration: result);
  }

  Future<void> generateWarp2Config() async {
    if (state.configGeneration.isLoading) return;
    state = state.copyWith(configGeneration: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      final warp = await ref
          .read(singboxServiceProvider)
          .generateWarpConfig(
            licenseKey: ref.read(ConfigOptions.warpLicenseKey),
            previousAccountId: ref.read(ConfigOptions.warp2AccountId),
            previousAccessToken: ref.read(ConfigOptions.warp2AccessToken),
          )
          .getOrElse((l) => throw l)
          .run();

      await ref.read(ConfigOptions.warp2AccountId.notifier).update(warp.accountId);
      await ref.read(ConfigOptions.warp2AccessToken.notifier).update(warp.accessToken);
      await ref.read(ConfigOptions.warp2WireguardConfig.notifier).update(warp.wireguardConfig);
      return warp.log;
    });

    state = state.copyWith(configGeneration: result);
  }

  static const warpConsentGiven = "warp_consent_given";
}

@freezed
sealed class WarpOptions with _$WarpOptions {
  const factory WarpOptions({
    required bool consentGiven,
    required AsyncValue<String> configGeneration,
  }) = _WarpOptions;
}
