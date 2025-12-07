import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class CorePreferences {
  static final bindAddress = PreferencesNotifier.create<String, String>(
    "core_bind_address",
    "127.0.0.1:8086",
  );

  static final endpoint = PreferencesNotifier.create<String, String>(
    "core_endpoint",
    "",
  );

  static final licenseKey = PreferencesNotifier.create<String, String>(
    "core_license_key",
    "",
  );

  static final dns = PreferencesNotifier.create<String, String>(
    "core_dns",
    "1.1.1.1",
  );

  static final verboseLogging = PreferencesNotifier.create<bool, bool>(
    "core_verbose_logging",
    false,
  );

  static final goolMode = PreferencesNotifier.create<bool, bool>(
    "core_gool_mode",
    false,
  );

  static final masqueMode = PreferencesNotifier.create<bool, bool>(
    "core_masque_mode",
    false,
  );

  static final masqueAutoFallback = PreferencesNotifier.create<bool, bool>(
    "core_masque_auto_fallback",
    false,
  );
  
  static final masquePreferred = PreferencesNotifier.create<bool, bool>(
    "core_masque_preferred",
    false,
  );

  static final masqueNoise = PreferencesNotifier.create<bool, bool>(
    "core_masque_noise",
    false,
  );

  static final masqueNoisePreset = PreferencesNotifier.create<String, String>(
    "core_masque_noise_preset",
    "medium",
  );

  static final psiphonEnabled = PreferencesNotifier.create<bool, bool>(
    "core_psiphon_enabled",
    false,
  );

  static final psiphonCountry = PreferencesNotifier.create<String, String>(
    "core_psiphon_country",
    "AT",
  );

  static final proxyAddress = PreferencesNotifier.create<String, String>(
    "core_proxy_address",
    "",
  );
  
  static final scanEnabled = PreferencesNotifier.create<bool, bool>(
    "core_scan_enabled",
    false,
  );

  static final scanRtt = PreferencesNotifier.create<int, int>(
    "core_scan_rtt",
    1000,
  );
}
