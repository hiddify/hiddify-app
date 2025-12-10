import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_selection_notifier.g.dart';

/// Notifier to manage selected location preference per profile
@riverpod
class LocationSelectionNotifier extends _$LocationSelectionNotifier with AppLogger {
  @override
  String? build() {
    // Watch active profile and load saved selection
    ref.listen(
      activeProfileProvider,
      (previous, next) {
        if (next case AsyncData(value: final profile?)) {
          _loadSelection(profile.id);
        } else {
          state = null;
        }
      },
    );

    // Load initial selection if profile exists
    Future.microtask(() {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile case AsyncData(value: final profile?)) {
        _loadSelection(profile.id);
      }
    });

    return null;
  }

  void _loadSelection(String profileId) {
    final prefs = ref.read(sharedPreferencesProvider).requireValue;
    final key = _getKey(profileId);
    final selectedTag = prefs.getString(key);
    if (selectedTag != null && selectedTag.isNotEmpty) {
      loggy.debug("loaded saved location selection for profile [$profileId]: [$selectedTag]");
      state = selectedTag;
    } else {
      state = null;
    }
  }

  /// Update selected location for current active profile
  Future<void> updateSelection(String? locationTag) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile case AsyncData(value: final profile?)) {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final key = _getKey(profile.id);

      if (locationTag == null || locationTag.isEmpty) {
        await prefs.remove(key);
        loggy.debug("cleared location selection for profile [${profile.id}]");
        state = null;
      } else {
        await prefs.setString(key, locationTag);
        loggy.debug("saved location selection for profile [${profile.id}]: [$locationTag]");
        state = locationTag;
      }
    } else {
      loggy.warning("cannot update location selection: no active profile");
    }
  }

  /// Get selected location tag for a specific profile
  Future<String?> getSelectionForProfile(String profileId) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final key = _getKey(profileId);
    return prefs.getString(key);
  }

  String _getKey(String profileId) => "selected_location_$profileId";
}

