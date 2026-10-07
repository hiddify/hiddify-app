import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

bool _debugIntroPage = false;

abstract class Preferences {
  static final introCompleted = PreferencesNotifier.create(
    "intro_completed",
    false,
    overrideValue: _debugIntroPage && kDebugMode ? false : null,
  );

  // Null means that auto selection has not been performed yet.
  static final autoAppsSelectionRegion = PreferencesNotifier.create<Region?, String?>(
    "auto_apps_selection_region",
    null,
    mapFrom: (value) => value == null || value.isEmpty ? null : Region.values.byName(value),
    mapTo: (value) => value == null ? '' : value.name,
  );

  static final autoAppsSelectionLastUpdate = PreferencesNotifier.create<DateTime?, String?>(
    "auto_apps_selection_last_update",
    null,
    mapFrom: (value) => value == null ? null : DateTime.tryParse(value),
    mapTo: (value) => value?.toIso8601String(),
  );

  // Set when the user turns auto selection off by hand. Until then it comes on by itself when App-based routing
  // is turned on.
  static final autoAppsSelectionOffByUser = PreferencesNotifier.create<bool, bool>(
    "auto_apps_selection_off_by_user",
    false,
  );

  static final includeApps = PreferencesNotifier.create<List<String>, List<String>>(
    "per_app_proxy_include_list",
    <String>[],
  );

  static final excludeApps = PreferencesNotifier.create<List<String>, List<String>>(
    "per_app_proxy_exclude_list",
    <String>[],
  );

  static final windowMaximized = PreferencesNotifier.create<bool, bool>("window_maximized", false);

  static final windowPosition = PreferencesNotifier.create<Offset?, String?>(
    "window_position",
    null,
    mapFrom: (value) {
      if (value == null) return null;
      final list = value.split(',').map((e) => double.tryParse(e)).toList();
      return Offset(list[0]!, list[1]!);
    },
    mapTo: (value) {
      if (value == null) return null;
      return "${value.dx},${value.dy}";
    },
  );

  static final windowSize = PreferencesNotifier.create<Size, String>(
    "window_size",
    defaultWindowSize,
    mapFrom: (value) {
      final list = value.split(',').map((e) => double.tryParse(e)).toList();
      return Size(list[0]!, list[1]!);
    },
    mapTo: (value) => "${value.width},${value.height}",
  );

  static final silentStart = PreferencesNotifier.create<bool, bool>("silent_start", false);

  static final disableMemoryLimit = PreferencesNotifier.create<bool, bool>(
    "disable_memory_limit",
    // disable memory limit on desktop by default
    PlatformUtils.isDesktop,
  );

  static final perAppProxyEnabled = PreferencesNotifier.create<bool, bool>("per_app_proxy_enabled", false);

  // Kept while App-based routing is off, for when it is turned on again.
  static final perAppProxyMode = PreferencesNotifier.create<AppProxyMode, String>(
    "per_app_proxy_mode",
    AppProxyMode.exclude,
    mapFrom: AppProxyMode.values.byName,
    mapTo: (value) => value.name,
  );

  // The mode in use, or null while App-based routing is off.
  static final perAppProxyModeInUse = Provider<AppProxyMode?>(
    (ref) => ref.watch(perAppProxyEnabled) ? ref.watch(perAppProxyMode) : null,
  );

  static final markNewProfileActive = PreferencesNotifier.create<bool, bool>("mark_new_profile_active", true);

  static final dynamicNotification = PreferencesNotifier.create<bool, bool>("dynamic_notification", true);

  static final autoCheckIp = PreferencesNotifier.create<bool, bool>("auto_check_ip", true);

  static final startedByUser = PreferencesNotifier.create<bool, bool>("started_by_user", false);

  static final storeReviewedByUser = PreferencesNotifier.create<bool, bool>("store_reviewed_by_user", false);

  static final actionAtClose = PreferencesNotifier.create<ActionsAtClosing, String>(
    "action_at_close",
    ActionsAtClosing.ask,
    mapFrom: ActionsAtClosing.values.byName,
    mapTo: (value) => value.name,
  );

  static final warpConsentGiven = PreferencesNotifier.create<bool, bool>("warp-consent-given", false);

  static final psiphonConsentGiven = PreferencesNotifier.create<bool, bool>("psiphon-consent-given", false);

  /// How many records the in-memory log ring keeps. Saved, so a size picked
  /// once while chasing a bug is still there on the next run.
  static final logBufferSize = PreferencesNotifier.create<int, int>("log-buffer-size", 1000);

  static final profilesSort = PreferencesNotifier.create<({ProfilesSort by, SortMode mode}), String>(
    "profiles_sort",
    (by: ProfilesSort.lastUpdate, mode: SortMode.descending),
    mapFrom: (value) {
      final parts = value.split(":");
      return (by: ProfilesSort.values.byName(parts.first), mode: SortMode.values.byName(parts.last));
    },
    mapTo: (value) => "${value.by.name}:${value.mode.name}",
  );
}
