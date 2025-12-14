import 'package:hiddify/core/utils/preferences_utils.dart';

/// MUX settings for Xray-core connection multiplexing
/// Optimized defaults for Iran anti-censorship
abstract class MuxSettings {
  /// Enable MUX - 🇮🇷 Recommended for Iran
  static final enabled = PreferencesNotifier.create<bool, bool>(
    'mux_enabled',
    true, // 🇮🇷 Default ON for better anti-DPI
  );

  /// MUX concurrency (number of connections to multiplex)
  /// Lower values = more stable, Higher = faster but may trigger DPI
  static final concurrency = PreferencesNotifier.create<int, int>(
    'mux_concurrency',
    8, // 🇮🇷 Optimal for Iran
  );

  /// XUDP concurrency for UDP connections
  static final xudpConcurrency = PreferencesNotifier.create<int, int>(
    'mux_xudp_concurrency',
    16, // 🇮🇷 Higher for better UDP performance
  );

  /// Proxy UDP traffic on port 443 (for QUIC)
  /// reject = block QUIC (recommended for XTLS)
  static final xudpProxyUDP443 = PreferencesNotifier.create<String, String>(
    'mux_xudp_proxy_udp443',
    'reject', // 🇮🇷 Block QUIC for better XTLS
  );

  /// Enable MUX padding - 🇮🇷 Essential for anti-DPI
  static final padding = PreferencesNotifier.create<bool, bool>(
    'mux_padding',
    false,
  );

  /// Enable brutal mode for aggressive MUX
  static final brutalEnabled = PreferencesNotifier.create<bool, bool>(
    'mux_brutal_enabled',
    false,
  );

  /// Brutal mode upload speed (Mbps)
  static final brutalUpMbps = PreferencesNotifier.create<int, int>(
    'mux_brutal_up_mbps',
    100,
  );

  /// Brutal mode download speed (Mbps)
  static final brutalDownMbps = PreferencesNotifier.create<int, int>(
    'mux_brutal_down_mbps',
    100,
  );

  /// Only use MUX for specific protocols
  static final onlyFor = PreferencesNotifier.create<String, String>(
    'mux_only_for',
    '',
  );

  // ============ Available Options ============

  static const List<int> availableConcurrency = [1, 2, 4, 8, 16, 32, 64, 128];

  static const List<String> availableXudpProxyUDP443 = [
    'reject',
    'allow',
    'skip',
  ];

  /// Generate MUX config for Xray-core
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
