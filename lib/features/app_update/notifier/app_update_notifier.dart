import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/app_update/data/app_update_data_providers.dart';
import 'package:hiddify/features/app_update/model/app_update_failure.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/notifier/app_update_state.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

part 'app_update_notifier.g.dart';

/// The store's own update prompt, where a store lookup works: Google Play, and the App Store on
/// iOS. Null elsewhere: outside a store the app checks its releases itself (AppUpdateNotifier),
/// the Mac App Store and the Microsoft Store update their apps on their own, and a Mac App Store
/// lookup by bundle id would find the iOS app, which has the same one.
@riverpod
Upgrader? upgrader(Ref ref) {
  final release = ref.watch(appInfoProvider).requireValue.release;
  final store = switch (release) {
    Release.googlePlay when PlatformUtils.isAndroid => UpgraderPlayStore(),
    Release.appStore when PlatformUtils.isIOS => UpgraderAppStore(),
    _ => null,
  };
  if (store == null) return null;
  return Upgrader(
    storeController: UpgraderStoreController(onAndroid: () => store, oniOS: () => store),
    messages: UpgraderMessages(code: ref.watch(localePreferencesProvider).languageCode),
  );
}

@Riverpod(keepAlive: true)
class AppUpdateNotifier extends _$AppUpdateNotifier with AppLogger {
  @override
  AppUpdateState build() => const AppUpdateState.initial();

  PreferencesEntry<String?, dynamic> get _ignoreReleasePref => PreferencesEntry(
    preferences: ref.read(sharedPreferencesProvider).requireValue,
    key: 'ignored_release_version',
    defaultValue: null,
  );

  Future<AppUpdateState> check() async {
    loggy.debug("checking for update");
    state = const AppUpdateState.checking();
    final appInfo = ref.read(appInfoProvider).requireValue;
    if (!appInfo.release.allowCustomUpdateChecker) {
      loggy.debug("custom update checkers are not allowed for [${appInfo.release.name}] release");
      return state = const AppUpdateState.disabled();
    }
    return ref
        .read(appUpdateRepositoryProvider)
        .getLatestVersion()
        .match(
          (err) {
            loggy.warning("failed to get latest version", err);
            return state = AppUpdateState.error(err);
          },
          (remote) {
            try {
              final latestVersion = Version.parse(remote.version);
              final currentVersion = Version.parse(appInfo.version);
              if (latestVersion > currentVersion) {
                if (remote.version == _ignoreReleasePref.read()) {
                  loggy.debug("ignored release [${remote.version}]");
                  return state = AppUpdateStateIgnored(remote);
                }
                loggy.debug("new version available: $remote");
                return state = AppUpdateState.available(remote);
              }
              loggy.info("already using latest version[$currentVersion], remote: [${remote.version}]");
              return state = const AppUpdateState.notAvailable();
            } catch (error, stackTrace) {
              loggy.warning("error parsing versions", error, stackTrace);
              return state = AppUpdateState.error(AppUpdateFailure.unexpected(error, stackTrace));
            }
          },
        )
        .run();
  }

  PreferencesEntry<int, dynamic> get _lastCheckPref => PreferencesEntry(
    preferences: ref.read(sharedPreferencesProvider).requireValue,
    key: 'last_update_check',
    defaultValue: 0,
  );

  /// Outside a store, at most once a day: the release this copy can update to, when there is one
  /// the user did not ignore.
  Future<RemoteVersionEntity?> checkOnStart() async {
    if (!ref.read(appInfoProvider).requireValue.release.allowCustomUpdateChecker) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastCheckPref.read() < const Duration(days: 1).inMilliseconds) return null;
    await _lastCheckPref.write(now);
    return switch (await check()) {
      AppUpdateStateAvailable(:final versionInfo) => versionInfo,
      _ => null,
    };
  }

  Future<void> ignoreRelease(RemoteVersionEntity version) async {
    loggy.debug("ignoring release [${version.version}]");
    await _ignoreReleasePref.write(version.version);
    state = AppUpdateStateIgnored(version);
  }
}
