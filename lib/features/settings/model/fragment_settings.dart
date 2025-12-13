import 'package:hiddify/core/utils/preferences_utils.dart';

/// Fragment settings for bypassing censorship
/// Used in Freedom outbound for TLS fragmentation
abstract class FragmentSettings {
  // Fragment Enable
  static final enabled = PreferencesNotifier.create<bool, bool>(
    'fragment_enabled',
    false, // Default OFF
  );

  /// Fragment packets type: "tlshello" or "1-3" (TCP segments)
  /// tlshello is more effective for Iran DPI
  static final packets = PreferencesNotifier.create<String, String>(
    'fragment_packets',
    '1-1',
  );

  /// Fragment length range (e.g., "100-200")
  /// Optimal for Iran: 100-200 bytes
  static final length = PreferencesNotifier.create<String, String>(
    'fragment_length',
    '3-5',
  );

  /// Fragment interval in milliseconds (e.g., "10-20")
  /// Optimal for Iran: 10-20ms
  static final interval = PreferencesNotifier.create<String, String>(
    'fragment_interval',
    '3-8',
  );

  /// Maximum number of split fragments per packet
  static final maxSplit = PreferencesNotifier.create<String, String>(
    'fragment_max_split',
    '',
  );

  // ============ Noise Settings ============

  /// Enable UDP noise
  static final noiseEnabled = PreferencesNotifier.create<bool, bool>(
    'noise_enabled',
    false,
  );

  /// Noise type: "rand", "str", "base64"
  static final noiseType = PreferencesNotifier.create<String, String>(
    'noise_type',
    'rand',
  );

  /// Noise packet content
  /// For "rand": range like "10-20"
  /// For "str": plain string
  /// For "base64": base64 encoded string
  static final noisePacket = PreferencesNotifier.create<String, String>(
    'noise_packet',
    '10-20',
  );

  /// Noise delay in milliseconds (e.g., "10-16")
  static final noiseDelay = PreferencesNotifier.create<String, String>(
    'noise_delay',
    '10-16',
  );

  /// Noise apply to: "ip", "ipv4", "ipv6"
  static final noiseApplyTo = PreferencesNotifier.create<String, String>(
    'noise_apply_to',
    'ip',
  );

  /// Generate fragment config map for Xray-core
  static Map<String, dynamic>? generateFragmentConfig({
    required bool isEnabled,
    required String packetsType,
    required String lengthRange,
    required String intervalRange,
    String? maxSplitValue,
  }) {
    if (!isEnabled) return null;

    final config = <String, dynamic>{
      'packets': packetsType,
      'length': lengthRange,
      'interval': intervalRange,
    };

    if (maxSplitValue != null && maxSplitValue.isNotEmpty) {
      config['maxSplit'] = maxSplitValue;
    }

    return config;
  }

  /// Generate noises config array for Xray-core
  static List<Map<String, dynamic>>? generateNoisesConfig({
    required bool isEnabled,
    required String type,
    required String packet,
    required String delay,
    required String applyTo,
  }) {
    if (!isEnabled) return null;

    return [
      {
        'type': type,
        'packet': packet,
        'delay': delay,
        'applyTo': applyTo,
      },
    ];
  }
}
