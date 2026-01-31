import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class TrafficSettings {
  static final connectionMode = PreferencesNotifier.create<String, String>(
    'traffic_connection_mode',
    'tun',
  );

  static final coreType = PreferencesNotifier.create<String, String>(
    'traffic_core_type',
    'xray',
  );

  static final splitTunnelEnabled = PreferencesNotifier.create<bool, bool>(
    'traffic_split_tunnel',
    false,
  );

  static final splitTunnelMode = PreferencesNotifier.create<String, String>(
    'traffic_split_tunnel_mode',
    'exclude',
  );

  static final directApps = PreferencesNotifier.create<String, String>(
    'traffic_direct_apps',
    '',
  );

  static final proxyApps = PreferencesNotifier.create<String, String>(
    'traffic_proxy_apps',
    '',
  );

  static final enableOnWifi = PreferencesNotifier.create<bool, bool>(
    'traffic_enable_wifi',
    true,
  );

  static final enableOnMobile = PreferencesNotifier.create<bool, bool>(
    'traffic_enable_mobile',
    true,
  );

  static final enableOnEthernet = PreferencesNotifier.create<bool, bool>(
    'traffic_enable_ethernet',
    true,
  );

  static final autoConnectTrustedWifi = PreferencesNotifier.create<bool, bool>(
    'traffic_auto_trusted_wifi',
    false,
  );

  static final trustedWifiSsids = PreferencesNotifier.create<String, String>(
    'traffic_trusted_wifi_ssids',
    '',
  );

  static final preferredProtocol = PreferencesNotifier.create<String, String>(
    'traffic_preferred_protocol',
    'auto',
  );

  static final enableProtocolFallback = PreferencesNotifier.create<bool, bool>(
    'traffic_protocol_fallback',
    true,
  );

  static final enableUdpRelay = PreferencesNotifier.create<bool, bool>(
    'traffic_udp_relay',
    true,
  );

  static final routingMode = PreferencesNotifier.create<String, String>(
    'traffic_routing_mode',
    'smart',
  );

  static final enableTrafficStats = PreferencesNotifier.create<bool, bool>(
    'traffic_enable_stats',
    true,
  );

  static final sessionTrafficLimit = PreferencesNotifier.create<int, int>(
    'traffic_session_limit',
    0,
  );

  static final speedLimit = PreferencesNotifier.create<int, int>(
    'traffic_speed_limit',
    0,
  );

  static final killSwitchEnabled = PreferencesNotifier.create<bool, bool>(
    'traffic_kill_switch',
    false,
  );

  static final killSwitchMode = PreferencesNotifier.create<String, String>(
    'traffic_kill_switch_mode',
    'all',
  );

  static final killSwitchAllowLan = PreferencesNotifier.create<bool, bool>(
    'traffic_kill_switch_allow_lan',
    true,
  );

  static final dnsMode = PreferencesNotifier.create<String, String>(
    'traffic_dns_mode',
    'auto',
  );

  static final customDnsServers = PreferencesNotifier.create<String, String>(
    'traffic_custom_dns',
    '',
  );

  static final blockDnsLeaks = PreferencesNotifier.create<bool, bool>(
    'traffic_block_dns_leaks',
    true,
  );

  static const List<String> availableConnectionModes = [
    'proxy',
    'system_proxy',
    'tun',
    'tun_service',
  ];

  static const List<String> availableCoreTypes = ['xray', 'singbox'];

  static const List<String> availableRoutingModes = ['all', 'smart', 'custom'];

  static const List<String> availableDnsModes = ['auto', 'doh', 'dot', 'plain'];

  static const List<String> availableProtocols = [
    'auto',
    'vless',
    'vmess',
    'trojan',
    'shadowsocks',
    'reality',
    'hysteria',
    'tuic',
    'wireguard',
  ];

  static String getConnectionModeDisplayName(String mode) {
    switch (mode) {
      case 'proxy':
        return 'Proxy Only';
      case 'system_proxy':
        return 'System Proxy';
      case 'tun':
        return 'VPN (TUN)';
      case 'tun_service':
        return 'VPN Service';
      default:
        return mode;
    }
  }

  static String getCoreTypeDisplayName(String core) {
    switch (core) {
      case 'xray':
        return 'Xray-core';
      case 'singbox':
        return 'Sing-box';
      default:
        return core;
    }
  }

  static List<String> parseList(String value) {
    if (value.isEmpty) return [];
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
