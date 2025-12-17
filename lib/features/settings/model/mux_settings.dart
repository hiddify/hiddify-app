import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class MuxSettings {
  static final enabled = PreferencesNotifier.create<bool, bool>(
    'mux_enabled',
    true,
  );

  static final concurrency = PreferencesNotifier.create<int, int>(
    'mux_concurrency',
    8,
  );

  static final xudpConcurrency = PreferencesNotifier.create<int, int>(
    'mux_xudp_concurrency',
    16,
  );

  static final xudpProxyUDP443 = PreferencesNotifier.create<String, String>(
    'mux_xudp_proxy_udp443',
    'reject',
  );

  static final padding = PreferencesNotifier.create<bool, bool>(
    'mux_padding',
    false,
  );

  static final brutalEnabled = PreferencesNotifier.create<bool, bool>(
    'mux_brutal_enabled',
    false,
  );

  static final brutalUpMbps = PreferencesNotifier.create<int, int>(
    'mux_brutal_up_mbps',
    100,
  );

  static final brutalDownMbps = PreferencesNotifier.create<int, int>(
    'mux_brutal_down_mbps',
    100,
  );

  static final onlyFor = PreferencesNotifier.create<String, String>(
    'mux_only_for',
    '',
  );

  static const List<int> availableConcurrency = [1, 2, 4, 8, 16, 32, 64, 128];

  static const List<String> availableXudpProxyUDP443 = [
    'reject',
    'allow',
    'skip',
  ];

  static Map<String, dynamic>? generateMuxConfig({
    required bool isEnabled,
    required int concurrencyValue,
    int? xudpConcurrencyValue,
    String? xudpProxyUDP443Value,
    bool paddingValue = true,
  }) {
    if (!isEnabled) return null;

    final config = <String, dynamic>{
      'enabled': true,
      'concurrency': concurrencyValue,
      'padding': paddingValue,
    };

    if (xudpConcurrencyValue != null && xudpConcurrencyValue > 0) {
      config['xudpConcurrency'] = xudpConcurrencyValue;
    }

    if (xudpProxyUDP443Value != null && xudpProxyUDP443Value.isNotEmpty) {
      config['xudpProxyUDP443'] = xudpProxyUDP443Value;
    }

    return config;
  }
}
