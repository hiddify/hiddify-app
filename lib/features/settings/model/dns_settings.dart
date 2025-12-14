import 'package:hiddify/core/utils/preferences_utils.dart';

/// DNS settings for Xray-core built-in DNS server
abstract class DnsSettings {
  // ============ Remote DNS ============

  /// Remote DNS server address
  /// Formats: "8.8.8.8", "tcp://8.8.8.8", "https://dns.google/dns-query"
  static final remoteDns = PreferencesNotifier.create<String, String>(
    'dns_remote',
    '8.8.8.8',
  );

  /// Remote DNS type: "udp", "tcp", "doh", "doh_local", "doq"
  static final remoteDnsType = PreferencesNotifier.create<String, String>(
    'dns_remote_type',
    'doh',
  );

  // ============ Direct/Local DNS ============

  /// Direct DNS server (used for direct/Iran traffic)
  /// Shecan DNS optimized for Iran
  static final directDns = PreferencesNotifier.create<String, String>(
    'dns_direct',
    '178.22.122.100', // Shecan DNS for Iran
  );

  /// Direct DNS type
  static final directDnsType = PreferencesNotifier.create<String, String>(
    'dns_direct_type',
    'udp',
  );

  /// Backup DNS for Iran (403.online)
  static final iranBackupDns = PreferencesNotifier.create<String, String>(
    'dns_iran_backup',
    '10.202.10.202', // 403.online DNS
  );

  // ============ DNS Options ============

  /// Enable DNS routing
  static final enableDnsRouting = PreferencesNotifier.create<bool, bool>(
    'dns_routing_enabled',
    true,
  );

  /// Query strategy: "UseIP", "UseIPv4", "UseIPv6"
  static final queryStrategy = PreferencesNotifier.create<String, String>(
    'dns_query_strategy',
    'UseIP',
  );

  /// Disable DNS cache
  static final disableCache = PreferencesNotifier.create<bool, bool>(
    'dns_disable_cache',
    false,
  );

  /// Disable DNS fallback
  static final disableFallback = PreferencesNotifier.create<bool, bool>(
    'dns_disable_fallback',
    false,
  );

  /// Disable fallback if match
  static final disableFallbackIfMatch = PreferencesNotifier.create<bool, bool>(
    'dns_disable_fallback_if_match',
    false,
  );

  /// Client IP for ECS (EDNS Client Subnet)
  static final clientIp = PreferencesNotifier.create<String, String>(
    'dns_client_ip',
    '',
  );

  /// DNS tag for routing
  static final dnsTag = PreferencesNotifier.create<String, String>(
    'dns_tag',
    'dns-out',
  );

  // ============ FakeDNS ============

  /// Enable FakeDNS
  static final enableFakeDns = PreferencesNotifier.create<bool, bool>(
    'fakedns_enabled',
    false,
  );

  /// FakeDNS IPv4 pool
  static final fakeDnsIpv4Pool = PreferencesNotifier.create<String, String>(
    'fakedns_ipv4_pool',
    '198.18.0.0/15',
  );

  /// FakeDNS IPv6 pool
  static final fakeDnsIpv6Pool = PreferencesNotifier.create<String, String>(
    'fakedns_ipv6_pool',
    'fc00::/18',
  );

  /// FakeDNS pool size
  static final fakeDnsPoolSize = PreferencesNotifier.create<int, int>(
    'fakedns_pool_size',
    65535,
  );

  // ============ Static Hosts ============

  /// Custom hosts mapping (JSON format)
  static final customHosts = PreferencesNotifier.create<String, String>(
    'dns_custom_hosts',
    '',
  );

  /// Format DNS address based on type
  static String formatDnsAddress(String address, String type) {
    switch (type) {
      case 'tcp':
        return 'tcp://$address';
      case 'doh':
        if (address.startsWith('https://')) return address;
        return 'https://$address/dns-query';
      case 'doh_local':
        if (address.startsWith('https+local://')) return address;
        return 'https+local://$address/dns-query';
      case 'doq':
        if (address.startsWith('quic+local://')) return address;
        return 'quic+local://$address';
      case 'udp':
      default:
        return address;
    }
  }

  /// Generate DNS config for Xray-core
  static Map<String, dynamic> generateDnsConfig({
    required String remoteDnsAddr,
    required String remoteDnsType,
    required String directDnsAddr,
    required String directDnsType,
    required String queryStrategyValue,
    required bool disableCacheValue,
    required bool disableFallbackValue,
    String? clientIpValue,
    String? tagValue,
    Map<String, dynamic>? hosts,
    bool enableFakeDnsValue = false,
  }) {
    final servers = <dynamic>[];

    // Remote DNS for proxy domains
    final remoteFormatted = formatDnsAddress(remoteDnsAddr, remoteDnsType);
    servers.add({
      'address': remoteFormatted,
      'domains': ['geosite:geolocation-!cn'],
      'skipFallback': true,
    });

    // Direct DNS for local domains (Iran + China)
    // Using domain suffixes as fallback if geosite:ir not available
    final directFormatted = formatDnsAddress(directDnsAddr, directDnsType);
    servers.add({
      'address': directFormatted,
      'domains': [
        // Iran domains - direct suffixes as fallback
        'domain:.ir',
        'domain:digikala.com',
        'domain:snapp.ir',
        'domain:divar.ir',
        'domain:shaparak.ir',
        'domain:saman.ir',
        // China domains
        'geosite:cn',
      ],
      'expectedIPs': ['geoip:cn', 'geoip:private'],
      'skipFallback': false,
    });

    // FakeDNS if enabled
    if (enableFakeDnsValue) {
      servers.insert(0, 'fakedns');
    }

    // Fallback to localhost
    servers.add('localhost');

    final config = <String, dynamic>{
      'servers': servers,
      'queryStrategy': queryStrategyValue,
      'disableCache': disableCacheValue,
      'disableFallback': disableFallbackValue,
    };

    if (clientIpValue != null && clientIpValue.isNotEmpty) {
      config['clientIp'] = clientIpValue;
    }

    if (tagValue != null && tagValue.isNotEmpty) {
      config['tag'] = tagValue;
    }

    if (hosts != null && hosts.isNotEmpty) {
      config['hosts'] = hosts;
    }

    return config;
  }

  /// Generate FakeDNS config for Xray-core
  static List<Map<String, dynamic>>? generateFakeDnsConfig({
    required bool isEnabled,
    required String ipv4Pool,
    required String ipv6Pool,
    required int poolSize,
    required String queryStrategyValue,
  }) {
    if (!isEnabled) return null;

    if (queryStrategyValue == 'UseIPv4') {
      return [
        {'ipPool': ipv4Pool, 'poolSize': poolSize},
      ];
    } else if (queryStrategyValue == 'UseIPv6') {
      return [
        {'ipPool': ipv6Pool, 'poolSize': poolSize},
      ];
    } else {
      return [
        {'ipPool': ipv4Pool, 'poolSize': poolSize ~/ 2},
        {'ipPool': ipv6Pool, 'poolSize': poolSize ~/ 2},
      ];
    }
  }
}
