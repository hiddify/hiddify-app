import 'package:hiddify/core/utils/preferences_utils.dart';











abstract class CorePreferences {
  
  static final configContent = PreferencesNotifier.create<String, String>(
    'core_config_content',
    '',
  );

  
  static final assetPath = PreferencesNotifier.create<String, String>(
    'core_asset_path',
    '',
  );

  
  static final coreMode = PreferencesNotifier.create<String, String>(
    'core_mode',
    'proxy',
  );

  
  static final enableLogging = PreferencesNotifier.create<bool, bool>(
    'enable_logging',
    false,
  );

  
  static final logLevel = PreferencesNotifier.create<String, String>(
    'log_level',
    'warning',
  );

  
  static const List<String> availableCoreModes = ['proxy', 'vpn'];

  
  static const List<String> availableLogLevels = [
    'none',
    'error',
    'warning',
    'info',
    'debug',
  ];
}
