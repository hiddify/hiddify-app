import 'package:hiddify/core/utils/preferences_utils.dart';

/// Routing settings for Xray-core traffic routing
abstract class RoutingSettings {
  // ============ Basic Routing ============

  /// Routing rule preset: global, bypass_iran, bypass_lan, bypass_china, custom
  static final rulePreset = PreferencesNotifier.create<String, String>(
    'routing_preset',
    'bypass_iran',
  );

  /// Domain strategy: AsIs, IPIfNonMatch, IPOnDemand
  static final domainStrategy = PreferencesNotifier.create<String, String>(
    'routing_domain_strategy',
    'IPIfNonMatch',
  );

  /// Domain matcher: hybrid, linear
  static final domainMatcher = PreferencesNotifier.create<String, String>(
    'routing_domain_matcher',
    'hybrid',
  );

  // ============ Bypass Options ============

  /// Bypass LAN addresses 
  /// Bypass LAN traffic
  static final bypassLan = PreferencesNotifier.create<bool, bool>(
    'routing_bypass_lan',
    true,
  );

  /// Bypass Iran domains/IPs - 
  static final bypassIran = PreferencesNotifier.create<bool, bool>(
    'routing_bypass_iran',
    true, //  Default ON for Iran users
  );

  /// Bypass China domains/IPs
  static final bypassChina = PreferencesNotifier.create<bool, bool>(
    'routing_bypass_china',
    false,
  );

  // ============ Block Options ============

  /// Block ads - 
  static final blockAds = PreferencesNotifier.create<bool, bool>(
    'routing_block_ads',
    true, //  Default ON - block Iranian/global ads
  );

  /// Block porn sites
  static final blockPorn = PreferencesNotifier.create<bool, bool>(
    'routing_block_porn',
    false,
  );

  /// Block QUIC protocol (force TLS for better XTLS) - 
  static final blockQuic = PreferencesNotifier.create<bool, bool>(
    'routing_block_quic',
    false, //  Default OFF - allow QUIC/UDP
  );

  /// Block malware domains
  static final blockMalware = PreferencesNotifier.create<bool, bool>(
    'routing_block_malware',
    true, //  Default ON - security
  );

  /// Block phishing domains
  static final blockPhishing = PreferencesNotifier.create<bool, bool>(
    'routing_block_phishing',
    true, //  Default ON - security
  );

  /// Sniff TLS for routing (improve accuracy)
  static final sniffTlsForRouting = PreferencesNotifier.create<bool, bool>(
    'routing_sniff_tls',
    true, //  Default ON
  );

  // ============ Special Routes ============

  /// Direct YouTube
  static final directYoutube = PreferencesNotifier.create<bool, bool>(
    'routing_direct_youtube',
    false,
  );

  /// Direct Netflix
  static final directNetflix = PreferencesNotifier.create<bool, bool>(
    'routing_direct_netflix',
    false,
  );

  // ============ Custom Rules ============

  /// Custom direct domains (one per line)
  static final customDirectDomains = PreferencesNotifier.create<String, String>(
    'routing_custom_direct_domains',
    '',
  );

  /// Custom proxy domains (one per line)
  static final customProxyDomains = PreferencesNotifier.create<String, String>(
    'routing_custom_proxy_domains',
    '',
  );

  /// Custom block domains (one per line)
  static final customBlockDomains = PreferencesNotifier.create<String, String>(
    'routing_custom_block_domains',
    '',
  );

  /// Custom direct IPs (CIDR format, one per line)
  static final customDirectIps = PreferencesNotifier.create<String, String>(
    'routing_custom_direct_ips',
    '',
  );

  /// Custom proxy IPs (CIDR format, one per line)
  static final customProxyIps = PreferencesNotifier.create<String, String>(
    'routing_custom_proxy_ips',
    '',
  );

  /// Custom block IPs (CIDR format, one per line)
  static final customBlockIps = PreferencesNotifier.create<String, String>(
    'routing_custom_block_ips',
    '',
  );

  // ============ Available Options ============

  static const List<String> availablePresets = [
    'global',
    'bypass_iran',
    'bypass_lan',
    'bypass_china',
    'custom',
  ];

  static const List<String> availableDomainStrategies = [
    'AsIs',
    'IPIfNonMatch',
    'IPOnDemand',
  ];

  /// Parse custom rules string to list
  static List<String> parseCustomRules(String rules) {
    if (rules.isEmpty) return [];
    return rules
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.startsWith('#'))
        .toList();
  }

  /// Generate routing rules for Xray-core
  static List<Map<String, dynamic>> generateRoutingRules({
    required bool bypassLanValue,
    required bool bypassIranValue,
    required bool bypassChinaValue,
    required bool blockAdsValue,
    required bool blockPornValue,
    required bool blockQuicValue,
    required bool blockMalwareValue,
    required bool blockPhishingValue,
    required bool directYoutubeValue,
    required bool directNetflixValue,
    List<String>? customDirectDomainsValue,
    List<String>? customProxyDomainsValue,
    List<String>? customBlockDomainsValue,
    List<String>? customDirectIpsValue,
    List<String>? customProxyIpsValue,
    List<String>? customBlockIpsValue,
  }) {
    final rules = <Map<String, dynamic>>[];

    // Block rules first
    if (blockAdsValue) {
      rules.add({
        'type': 'field',
        'domain': ['geosite:category-ads', 'geosite:category-ads-all'],
        'outboundTag': 'block',
      });
    }

    if (blockPornValue) {
      rules.add({
        'type': 'field',
        'domain': ['geosite:category-porn'],
        'outboundTag': 'block',
      });
    }

    if (blockQuicValue) {
      rules.add({
        'type': 'field',
        'port': '443',
        'network': 'udp',
        'outboundTag': 'block',
      });
    }

    // Custom block rules
    if (customBlockDomainsValue != null && customBlockDomainsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'domain': customBlockDomainsValue,
        'outboundTag': 'block',
      });
    }

    if (customBlockIpsValue != null && customBlockIpsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'ip': customBlockIpsValue,
        'outboundTag': 'block',
      });
    }

    // Direct rules
    if (bypassLanValue) {
      rules.add({
        'type': 'field',
        'ip': ['geoip:private'],
        'outboundTag': 'direct',
      });
    }

    if (bypassIranValue) {
      // Iran IPs - geoip:ir available in most geoip.dat files
      rules.add({
        'type': 'field',
        'ip': ['geoip:ir'],
        'outboundTag': 'direct',
      });
      // Iran domains - using .ir suffix as reliable fallback
      rules.add({
        'type': 'field',
        'domain': [
          r'regexp:\.ir$',
          'domain:digikala.com',
          'domain:snapp.ir',
          'domain:divar.ir',
          'domain:shaparak.ir',
          'domain:saman.ir',
          'domain:aparat.com',
          'domain:filimo.com',
          'domain:namava.ir',
          'domain:telewebion.com',
        ],
        'outboundTag': 'direct',
      });
    }

    if (bypassChinaValue) {
      rules.add({
        'type': 'field',
        'ip': ['geoip:cn'],
        'outboundTag': 'direct',
      });
      rules.add({
        'type': 'field',
        'domain': ['geosite:cn', 'geosite:geolocation-cn'],
        'outboundTag': 'direct',
      });
    }

    // Special direct routes
    if (directYoutubeValue) {
      rules.add({
        'type': 'field',
        'domain': ['geosite:youtube'],
        'outboundTag': 'direct',
      });
    }

    if (directNetflixValue) {
      rules.add({
        'type': 'field',
        'domain': ['geosite:netflix'],
        'outboundTag': 'direct',
      });
    }

    // Custom direct rules
    if (customDirectDomainsValue != null && customDirectDomainsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'domain': customDirectDomainsValue,
        'outboundTag': 'direct',
      });
    }

    if (customDirectIpsValue != null && customDirectIpsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'ip': customDirectIpsValue,
        'outboundTag': 'direct',
      });
    }

    // Custom proxy rules
    if (customProxyDomainsValue != null && customProxyDomainsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'domain': customProxyDomainsValue,
        'outboundTag': 'proxy',
      });
    }

    if (customProxyIpsValue != null && customProxyIpsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'ip': customProxyIpsValue,
        'outboundTag': 'proxy',
      });
    }

    return rules;
  }
}
