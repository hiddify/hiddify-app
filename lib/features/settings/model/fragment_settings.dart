import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class FragmentSettings {
  static final enabled = PreferencesNotifier.create<bool, bool>(
    'fragment_enabled',
    false,
  );

  static final packets = PreferencesNotifier.create<String, String>(
    'fragment_packets',
    '1-1',
  );

  static final length = PreferencesNotifier.create<String, String>(
    'fragment_length',
    '3-5',
  );

  static final interval = PreferencesNotifier.create<String, String>(
    'fragment_interval',
    '3-8',
  );

  static final maxSplit = PreferencesNotifier.create<String, String>(
    'fragment_max_split',
    '',
  );

  static final noiseEnabled = PreferencesNotifier.create<bool, bool>(
    'noise_enabled',
    false,
  );

  static final noiseType = PreferencesNotifier.create<String, String>(
    'noise_type',
    'rand',
  );

  static final noisePacket = PreferencesNotifier.create<String, String>(
    'noise_packet',
    '10-20',
  );

  static final noiseDelay = PreferencesNotifier.create<String, String>(
    'noise_delay',
    '10-16',
  );

  static final noiseApplyTo = PreferencesNotifier.create<String, String>(
    'noise_apply_to',
    'ip',
  );

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

  static List<Map<String, dynamic>>? generateNoisesConfig({
    required bool isEnabled,
    required String type,
    required String packet,
    required String delay,
    required String applyTo,
  }) {
    if (!isEnabled) return null;

    return [
      {'type': type, 'packet': packet, 'delay': delay, 'applyTo': applyTo},
    ];
  }
}
