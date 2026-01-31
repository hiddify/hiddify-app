import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class InboundSettings {
  static final socksPort = PreferencesNotifier.create<int, int>(
    'inbound_socks_port',
    2334,
  );

  static final socksListen = PreferencesNotifier.create<String, String>(
    'inbound_socks_listen',
    '127.0.0.1',
  );

  static final socksUdp = PreferencesNotifier.create<bool, bool>(
    'inbound_socks_udp',
    true,
  );

  static final socksAuth = PreferencesNotifier.create<String, String>(
    'inbound_socks_auth',
    'noauth',
  );

  static final httpPort = PreferencesNotifier.create<int, int>(
    'inbound_http_port',
    2335,
  );

  static final httpListen = PreferencesNotifier.create<String, String>(
    'inbound_http_listen',
    '127.0.0.1',
  );

  static final httpAllowTransparent = PreferencesNotifier.create<bool, bool>(
    'inbound_http_transparent',
    false,
  );

  static final sniffingEnabled = PreferencesNotifier.create<bool, bool>(
    'inbound_sniffing_enabled',
    true,
  );

  static final sniffingDestOverride =
      PreferencesNotifier.create<String, String>(
        'inbound_sniffing_dest_override',
        'http,tls',
      );

  static final sniffingRouteOnly = PreferencesNotifier.create<bool, bool>(
    'inbound_sniffing_route_only',
    false,
  );

  static final sniffingFakeDns = PreferencesNotifier.create<bool, bool>(
    'inbound_sniffing_fakedns',
    false,
  );

  static final sniffingExcludeDomains =
      PreferencesNotifier.create<String, String>(
        'inbound_sniffing_exclude',
        '',
      );

  static final tunName = PreferencesNotifier.create<String, String>(
    'inbound_tun_name',
    'tun0',
  );

  static final tunMtu = PreferencesNotifier.create<int, int>(
    'inbound_tun_mtu',
    9000,
  );

  static final tunStack = PreferencesNotifier.create<String, String>(
    'inbound_tun_stack',
    'mixed',
  );

  static const List<String> availableSniffingTypes = [
    'http',
    'tls',
    'quic',
    'fakedns',
    'fakedns+others',
  ];

  static const List<String> availableTunStacks = ['system', 'gvisor', 'mixed'];

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
      'settings': {'auth': auth, 'udp': udp},
    };

    if (sniffing != null) {
      config['sniffing'] = sniffing;
    }

    return config;
  }

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
      'settings': {'allowTransparent': allowTransparent},
    };

    if (sniffing != null) {
      config['sniffing'] = sniffing;
    }

    return config;
  }

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
