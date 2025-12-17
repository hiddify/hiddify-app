import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class DnsSettings {
  static final remoteDns = PreferencesNotifier.create<String, String>(
    'dns_remote',
    '8.8.8.8',
  );

  static final remoteDnsType = PreferencesNotifier.create<String, String>(
    'dns_remote_type',
    'doh',
  );

  static final directDns = PreferencesNotifier.create<String, String>(
    'dns_direct',
    '178.22.122.100',
  );

  static final directDnsType = PreferencesNotifier.create<String, String>(
    'dns_direct_type',
    'udp',
  );

  static final iranBackupDns = PreferencesNotifier.create<String, String>(
    'dns_iran_backup',
    '10.202.10.202',
  );

  static final enableDnsRouting = PreferencesNotifier.create<bool, bool>(
    'dns_routing_enabled',
    true,
  );

  static final queryStrategy = PreferencesNotifier.create<String, String>(
    'dns_query_strategy',
    'UseIP',
  );

  static final disableCache = PreferencesNotifier.create<bool, bool>(
    'dns_disable_cache',
    false,
  );

  static final disableFallback = PreferencesNotifier.create<bool, bool>(
    'dns_disable_fallback',
    false,
  );

  static final disableFallbackIfMatch = PreferencesNotifier.create<bool, bool>(
    'dns_disable_fallback_if_match',
    false,
  );

  static final clientIp = PreferencesNotifier.create<String, String>(
    'dns_client_ip',
    '',
  );

  static final dnsTag = PreferencesNotifier.create<String, String>(
    'dns_tag',
    'dns-out',
  );

  static final enableFakeDns = PreferencesNotifier.create<bool, bool>(
    'fakedns_enabled',
    false,
  );

  static final fakeDnsIpv4Pool = PreferencesNotifier.create<String, String>(
    'fakedns_ipv4_pool',
    '198.18.0.0/15',
  );

  static final fakeDnsIpv6Pool = PreferencesNotifier.create<String, String>(
    'fakedns_ipv6_pool',
    'fc00::/18',
  );

  static final fakeDnsPoolSize = PreferencesNotifier.create<int, int>(
    'fakedns_pool_size',
    65535,
  );

  static final customHosts = PreferencesNotifier.create<String, String>(
    'dns_custom_hosts',
    '',
  );

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

    final remoteFormatted = formatDnsAddress(remoteDnsAddr, remoteDnsType);
    servers.add({
      'address': remoteFormatted,
      'domains': ['geosite:geolocation-!cn'],
      'skipFallback': true,
    });

    final directFormatted = formatDnsAddress(directDnsAddr, directDnsType);
    servers.add({
      'address': directFormatted,
      'domains': [
        'domain:.ir',
        'domain:digikala.com',
        'domain:snapp.ir',
        'domain:divar.ir',
        'domain:shaparak.ir',
        'domain:saman.ir',
        'geosite:cn',
      ],
      'expectedIPs': ['geoip:ir', 'geoip:cn', 'geoip:private'],
      'skipFallback': false,
    });

    if (enableFakeDnsValue) {
      servers.insert(0, 'fakedns');
    }

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
