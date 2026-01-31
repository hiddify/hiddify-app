import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class PrivacySettings {
  static final enableAnalytics = PreferencesNotifier.create<bool, bool>(
    'privacy_analytics',
    false,
  );

  static final enableCrashReporting = PreferencesNotifier.create<bool, bool>(
    'privacy_crash_reporting',
    false,
  );

  static final enableLocalStats = PreferencesNotifier.create<bool, bool>(
    'privacy_local_stats',
    true,
  );

  static final blockWebRtcLeaks = PreferencesNotifier.create<bool, bool>(
    'privacy_block_webrtc',
    true,
  );

  static final blockIpv6Leaks = PreferencesNotifier.create<bool, bool>(
    'privacy_block_ipv6_leaks',
    true,
  );

  static final blockDnsLeaks = PreferencesNotifier.create<bool, bool>(
    'privacy_block_dns_leaks',
    true,
  );

  static final forceHttps = PreferencesNotifier.create<bool, bool>(
    'privacy_force_https',
    false,
  );

  static final enableDoh = PreferencesNotifier.create<bool, bool>(
    'privacy_enable_doh',
    true,
  );

  static final randomizeTlsFingerprint = PreferencesNotifier.create<bool, bool>(
    'privacy_random_tls_fp',
    false,
  );

  static final rotateConnection = PreferencesNotifier.create<bool, bool>(
    'privacy_rotate_connection',
    false,
  );

  static final rotationInterval = PreferencesNotifier.create<int, int>(
    'privacy_rotation_interval',
    60,
  );

  static final logRetentionDays = PreferencesNotifier.create<int, int>(
    'privacy_log_retention',
    7,
  );

  static final redactSensitiveData = PreferencesNotifier.create<bool, bool>(
    'privacy_redact_logs',
    true,
  );

  static final redactPatterns = PreferencesNotifier.create<String, String>(
    'privacy_redact_patterns',
    'password,token,key,secret,auth',
  );

  static final encryptLocalStorage = PreferencesNotifier.create<bool, bool>(
    'privacy_encrypt_storage',
    true,
  );

  static final clearDataOnExit = PreferencesNotifier.create<bool, bool>(
    'privacy_clear_on_exit',
    false,
  );

  static final autoClearLogs = PreferencesNotifier.create<bool, bool>(
    'privacy_auto_clear_logs',
    false,
  );

  static final stealthMode = PreferencesNotifier.create<bool, bool>(
    'privacy_stealth_mode',
    false,
  );

  static final obfuscationLevel = PreferencesNotifier.create<String, String>(
    'privacy_obfuscation',
    'none',
  );

  static final randomizePorts = PreferencesNotifier.create<bool, bool>(
    'privacy_random_ports',
    false,
  );

  static final hideFromRecents = PreferencesNotifier.create<bool, bool>(
    'privacy_hide_recents',
    false,
  );

  static final secureKeyboard = PreferencesNotifier.create<bool, bool>(
    'privacy_secure_keyboard',
    true,
  );

  static final blurInSwitcher = PreferencesNotifier.create<bool, bool>(
    'privacy_blur_switcher',
    false,
  );

  static final disableScreenshots = PreferencesNotifier.create<bool, bool>(
    'privacy_disable_screenshots',
    false,
  );

  static const List<String> availablePrivacyLevels = [
    'minimal',
    'balanced',
    'strict',
    'maximum',
  ];

  static Map<String, bool> getPrivacyPreset(String level) {
    switch (level) {
      case 'minimal':
        return {
          'blockWebRtc': false,
          'blockIpv6Leaks': false,
          'blockDnsLeaks': false,
          'redactLogs': false,
          'encryptStorage': false,
          'stealthMode': false,
        };
      case 'balanced':
        return {
          'blockWebRtc': true,
          'blockIpv6Leaks': true,
          'blockDnsLeaks': true,
          'redactLogs': true,
          'encryptStorage': true,
          'stealthMode': false,
        };
      case 'strict':
        return {
          'blockWebRtc': true,
          'blockIpv6Leaks': true,
          'blockDnsLeaks': true,
          'redactLogs': true,
          'encryptStorage': true,
          'stealthMode': true,
        };
      case 'maximum':
        return {
          'blockWebRtc': true,
          'blockIpv6Leaks': true,
          'blockDnsLeaks': true,
          'redactLogs': true,
          'encryptStorage': true,
          'stealthMode': true,
          'randomizePorts': true,
          'rotateConnection': true,
          'autoClearLogs': true,
        };
      default:
        return {
          'blockWebRtc': true,
          'blockIpv6Leaks': true,
          'blockDnsLeaks': true,
          'redactLogs': true,
          'encryptStorage': true,
          'stealthMode': false,
        };
    }
  }

  static List<String> parseRedactPatterns(String patterns) {
    if (patterns.isEmpty) return [];
    return patterns.split(',').map((e) => e.trim().toLowerCase()).toList();
  }
}
