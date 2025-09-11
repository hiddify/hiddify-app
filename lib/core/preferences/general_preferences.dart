import 'package:flutter/foundation.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
// import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'general_preferences.g.dart';

bool _debugIntroPage = false;

abstract class Preferences {
  static final introCompleted = PreferencesNotifier.create(
    "intro_completed",
    false,
    overrideValue: _debugIntroPage && kDebugMode ? false : null,
  );

  static final silentStart = PreferencesNotifier.create<bool, bool>(
    "silent_start",
    false,
  );

  static final disableMemoryLimit = PreferencesNotifier.create<bool, bool>(
    "disable_memory_limit",
    // disable memory limit on desktop by default
    PlatformUtils.isDesktop,
  );

  static final perAppProxyMode = PreferencesNotifier.create<PerAppProxyMode, String>(
    "per_app_proxy_mode",
    PerAppProxyMode.off,
    mapFrom: PerAppProxyMode.values.byName,
    mapTo: (value) => value.name,
  );

  static final markNewProfileActive = PreferencesNotifier.create<bool, bool>(
    "mark_new_profile_active",
    true,
  );

  static final dynamicNotification = PreferencesNotifier.create<bool, bool>(
    "dynamic_notification",
    true,
  );

  static final autoCheckIp = PreferencesNotifier.create<bool, bool>(
    "auto_check_ip",
    true,
  );

  static final startedByUser = PreferencesNotifier.create<bool, bool>(
    "started_by_user",
    false,
  );

  static final storeReviewedByUser = PreferencesNotifier.create<bool, bool>(
    "store_reviewed_by_user",
    false,
  );

  static final actionAtClose = PreferencesNotifier.create<ActionsAtClosing, String>(
    "action_at_close",
    ActionsAtClosing.ask,
    mapFrom: ActionsAtClosing.values.byName,
    mapTo: (value) => value.name,
  );
}

@Riverpod(keepAlive: true)
class DebugModeNotifier extends _$DebugModeNotifier {
  late final _pref = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "debug_mode",
    defaultValue: ref.read(environmentProvider) == Environment.dev,
  );

  @override
  bool build() => _pref.read();

  Future<void> update(bool value) {
    state = value;
    return _pref.write(value);
  }
}

@Riverpod(keepAlive: true)
class PerAppProxyList extends _$PerAppProxyList {
  late final _include = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "per_app_proxy_include_list",
    defaultValue: <String>[],
  );

  late final _exclude = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "per_app_proxy_exclude_list",
    defaultValue: <String>[],
  );

  @override
  List<String> build() => ref.watch(Preferences.perAppProxyMode) == PerAppProxyMode.include ? _include.read() : _exclude.read();

  Future<void> update(List<String> value) {
    state = value;
    if (ref.read(Preferences.perAppProxyMode) == PerAppProxyMode.include) {
      return _include.write(value);
    }
    return _exclude.write(value);
  }
}
