import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/model/config_option_failure.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:loggy/loggy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'warp_option_notifier.g.dart';

@riverpod
class WarpOptionNotifier extends _$WarpOptionNotifier with AppLogger {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider).requireValue;

  @override
  AsyncValue<String> build() {
    bool hasWarpConfig = false;
    try {
      final accountId = _prefs.getString(WarpConst.warpAccountId);
      final accessToken = _prefs.getString(WarpConst.warpAccessToken);
      hasWarpConfig = accountId != null && accessToken != null;
    } catch (e) {
      loggy.warning(e);
    }

    return hasWarpConfig ? const AsyncValue.data("") : AsyncError(const MissingWarpConfigFailure(), StackTrace.current);
  }

  Future<void> genWarps({bool showToast = true}) async {
    if (state is AsyncLoading) return;
    state = const AsyncLoading();
    final t = ref.read(translationsProvider).requireValue;
    final warpLog = await _genWarpConfig();
    final warpLog2 = await _genWarp2Config();
    if (warpLog != null && warpLog2 != null) {
      loggy.log(LogLevel.info, 'generated warp log : $warpLog');
      loggy.log(LogLevel.info, 'generated warp2 log : $warpLog2');
      if (showToast) {
        ref
            .read(inAppNotificationControllerProvider)
            .showSuccessToast('${t.pages.settings.warp.configGenerated} $warpLog');
      }
      state = AsyncValue.data(warpLog);
    } else {
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.pages.settings.warp.missingConfig);
      state = AsyncError(const MissingWarpConfigFailure(), StackTrace.current);
    }
  }

  Future<String?> _genWarpConfig() async {
    final result = await AsyncValue.guard(() async {
      final warp = await ref
          .read(hiddifyCoreServiceProvider)
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

    state = result;
    return result.value;
  }

  Future<String?> _genWarp2Config() async {
    final result = await AsyncValue.guard(() async {
      final warp = await ref
          .read(hiddifyCoreServiceProvider)
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

    return result.value;
  }
}

@riverpod
class WarpLicenseNotifier extends _$WarpLicenseNotifier with AppLogger {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider).requireValue;

  @override
  bool build() {
    final consent = _prefs.getBool(WarpConst.warpConsentGiven) ?? false;
    return consent;
  }

  Future<void> agree() async {
    await _prefs.setBool(WarpConst.warpConsentGiven, true);
    await ref.read(warpOptionNotifierProvider.notifier).genWarps(showToast: false);
    state = true;
  }
}
