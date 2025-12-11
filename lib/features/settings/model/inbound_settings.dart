import 'package:hiddify/core/utils/preferences_utils.dart';

/// Inbound settings for Xray-core local proxy server
abstract class InboundSettings {
  // ============ SOCKS Inbound ============

  /// SOCKS5 proxy port
  static final socksPort = PreferencesNotifier.create<int, int>(
    'inbound_socks_port',
    2334,
  );

  /// SOCKS5 listen address
  static final socksListen = PreferencesNotifier.create<String, String>(
    'inbound_socks_listen',
    '127.0.0.1',
  );

  /// Enable SOCKS5 UDP
  static final socksUdp = PreferencesNotifier.create<bool, bool>(
    'inbound_socks_udp',
    true,
  );

  /// SOCKS5 authentication
  static final socksAuth = PreferencesNotifier.create<String, String>(
    'inbound_socks_auth',
    'noauth',
  );

  // ============ HTTP Inbound ============

  /// HTTP proxy port
  static final httpPort = PreferencesNotifier.create<int, int>(
    'inbound_http_port',
    2335,
  );

  /// HTTP listen address
  static final httpListen = PreferencesNotifier.create<String, String>(
    'inbound_http_listen',
    '127.0.0.1',
  );

  /// Allow HTTP CONNECT (for HTTPS tunneling)
  static final httpAllowTransparent = PreferencesNotifier.create<bool, bool>(
    'inbound_http_transparent',
    false,
  );

  // ============ Sniffing Settings ============

  /// Enable protocol sniffing
  static final sniffingEnabled = PreferencesNotifier.create<bool, bool>(
    'inbound_sniffing_enabled',
    true,
  );

  /// Sniffing destination override (comma-separated)
  static final sniffingDestOverride = PreferencesNotifier.create<String, String>(
    'inbound_sniffing_dest_override',
    'http,tls',
  );

  /// Route traffic only if destination matches sniffed domain
  static final sniffingRouteOnly = PreferencesNotifier.create<bool, bool>(
    'inbound_sniffing_route_only',
    false,
  );

  /// Enable FakeDNS in sniffing
  static final sniffingFakeDns = PreferencesNotifier.create<bool, bool>(
    'inbound_sniffing_fakedns',
    false,
  );

  /// Exclude domains from sniffing
  static final sniffingExcludeDomains = PreferencesNotifier.create<String, String>(
    'inbound_sniffing_exclude',
    '',
  );

  // ============ TUN/VPN Settings ============

  /// TUN device name
  static final tunName = PreferencesNotifier.create<String, String>(
    'inbound_tun_name',
    'tun0',
  );

  /// TUN MTU
  static final tunMtu = PreferencesNotifier.create<int, int>(
    'inbound_tun_mtu',
    9000,
  );

  /// TUN stack: system, gvisor, mixed
  static final tunStack = PreferencesNotifier.create<String, String>(
    'inbound_tun_stack',
    'mixed',
  );

  // ============ Available Options ============

  static const List<String> availableSniffingTypes = [
    'http',
    'tls',
    'quic',
    'fakedns',
    'fakedns+others',
  ];

  static const List<String> availableTunStacks = [
    'system',
    'gvisor',
    'mixed',
  ];

  /// Generate SOCKS inbound config
  static Map<String, dynamic> generateSocksInbound({
    required int port,
    required String listen,
    required bool udp,
    String auth = 'noauth',
    String? tag,
    Map<String, dynamic>? sniffing,
  }) {
    final config = <String, dynamic>{
      'tag': tag ?? 'socks_in',
      'port': port,
      'protocol': 'socks',
      'listen': listen,
      'settings': {
        'auth': auth,
        'udp': udp,
      },
    };

    if (sniffing != null) {
      config['sniffing'] = sniffing;
    }

    return config;
  }

  /// Generate HTTP inbound config
  static Map<String, dynamic> generateHttpInbound({
    required int port,
    required String listen,
    bool allowTransparent = false,
    String? tag,
    Map<String, dynamic>? sniffing,
  }) {
    final config = <String, dynamic>{
      'tag': tag ?? 'http_in',
      'port': port,
      'protocol': 'http',
      'listen': listen,
      'settings': {
        'allowTransparent': allowTransparent,
      },
    };

    if (sniffing != null) {
      config['sniffing'] = sniffing;
    }

    return config;
  }

  /// Generate dokodemo-door inbound for TUN/VPN mode
  static Map<String, dynamic> generateDokodemoDoorInbound({
    required int port,
    String listen = '127.0.0.1',
    String? tag,
    Map<String, dynamic>? sniffing,
  }) {
    final config = <String, dynamic>{
      'tag': tag ?? 'tun_in',
      'port': port,
      'protocol': 'dokodemo-door',
      'listen': listen,
      'settings': {
        'address': '127.0.0.1',
        'port': 0,
        'network': 'tcp,udp',
        'followRedirect': true,
      },
    };

    if (sniffing != null) {
      config['sniffing'] = sniffing;
    }

    return config;
  }

  /// Generate sniffing config
  static Map<String, dynamic> generateSniffingConfig({
    required bool enabled,
    required String destOverride,
    bool routeOnly = false,
    bool metadataOnly = false,
    List<String>? excludeDomains,
  }) {
    final destList = destOverride.split(',').map((e) => e.trim()).toList();

    final config = <String, dynamic>{
      'enabled': enabled,
      'destOverride': destList,
      'routeOnly': routeOnly,
      'metadataOnly': metadataOnly,
    };

    if (excludeDomains != null && excludeDomains.isNotEmpty) {
      config['domainsExcluded'] = excludeDomains;
    }

    return config;
  }
}
