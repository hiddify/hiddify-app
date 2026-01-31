import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class ResourcePreferences {
  static final autoUpdateResources = PreferencesNotifier.create<bool, bool>(
    'auto_update_resources',
    true,
  );

  static final useBetaVersions = PreferencesNotifier.create<bool, bool>(
    'use_beta_versions',
    false,
  );

  static final updateFrequency = PreferencesNotifier.create<String, String>(
    'resource_update_frequency',
    'weekly',
  );

  static final region = PreferencesNotifier.create<String, String>(
    'user_region',
    'global',
  );
}
