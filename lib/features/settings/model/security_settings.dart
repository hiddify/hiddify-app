import 'package:hiddify/core/utils/preferences_utils.dart';



abstract class SecuritySettings {
  
  static final blockAdultContent = PreferencesNotifier.create<bool, bool>(
    'security_block_adult',
    true, 
  );

  
  static final blockGambling = PreferencesNotifier.create<bool, bool>(
    'security_block_gambling',
    false,
  );

  
  static final blockDating = PreferencesNotifier.create<bool, bool>(
    'security_block_dating',
    false,
  );

  
  static final blockSocialMedia = PreferencesNotifier.create<bool, bool>(
    'security_block_social_media',
    false,
  );

  
  static final blockVirus = PreferencesNotifier.create<bool, bool>(
    'security_block_virus',
    true, 
  );

  
  static final blockCryptominers = PreferencesNotifier.create<bool, bool>(
    'security_block_cryptominers',
    true,
  );

  
  static final blockRansomware = PreferencesNotifier.create<bool, bool>(
    'security_block_ransomware',
    true,
  );

  
  static final blockPhishing = PreferencesNotifier.create<bool, bool>(
    'security_block_phishing',
    true,
  );

  
  static final blockBotnet = PreferencesNotifier.create<bool, bool>(
    'security_block_botnet',
    true,
  );

  
  static final blockSpam = PreferencesNotifier.create<bool, bool>(
    'security_block_spam',
    true,
  );

  
  static final blockAds = PreferencesNotifier.create<bool, bool>(
    'security_block_ads',
    true,
  );

  
  static final blockTrackers = PreferencesNotifier.create<bool, bool>(
    'security_block_trackers',
    true,
  );

  
  static final blockAnalytics = PreferencesNotifier.create<bool, bool>(
    'security_block_analytics',
    false,
  );

  
  static final firewallEnabled = PreferencesNotifier.create<bool, bool>(
    'firewall_enabled',
    false, 
  );

  
  static final blockIncoming = PreferencesNotifier.create<bool, bool>(
    'firewall_block_incoming',
    true,
  );

  
  static final blockOutgoing = PreferencesNotifier.create<bool, bool>(
    'firewall_block_outgoing',
    false,
  );

  
  static final allowLan = PreferencesNotifier.create<bool, bool>(
    'firewall_allow_lan',
    true,
  );

  
  static final allowDhcp = PreferencesNotifier.create<bool, bool>(
    'firewall_allow_dhcp',
    true,
  );

  
  static final allowDns = PreferencesNotifier.create<bool, bool>(
    'firewall_allow_dns',
    true,
  );

  
  static final portFilterEnabled = PreferencesNotifier.create<bool, bool>(
    'firewall_port_filter',
    false,
  );

  
  static final blockUdp = PreferencesNotifier.create<bool, bool>(
    'firewall_block_udp',
    false,
  );

  
  static final blockTcp = PreferencesNotifier.create<bool, bool>(
    'firewall_block_tcp',
    false,
  );

  
  static final allowedUdpPorts = PreferencesNotifier.create<String, String>(
    'firewall_allowed_udp_ports',
    '53,67,68', 
  );

  
  static final allowedTcpPorts = PreferencesNotifier.create<String, String>(
    'firewall_allowed_tcp_ports',
    '53,80,443', 
  );

  
  static final blockedUdpPorts = PreferencesNotifier.create<String, String>(
    'firewall_blocked_udp_ports',
    '',
  );

  
  static final blockedTcpPorts = PreferencesNotifier.create<String, String>(
    'firewall_blocked_tcp_ports',
    '',
  );

  
  static final protectDdos = PreferencesNotifier.create<bool, bool>(
    'security_protect_ddos',
    true,
  );

  
  static final protectPortScan = PreferencesNotifier.create<bool, bool>(
    'security_protect_portscan',
    true,
  );

  
  static final protectIpSpoofing = PreferencesNotifier.create<bool, bool>(
    'security_protect_ipspoofing',
    true,
  );

  
  static final protectSynFlood = PreferencesNotifier.create<bool, bool>(
    'security_protect_synflood',
    true,
  );

  
  static final protectIcmpFlood = PreferencesNotifier.create<bool, bool>(
    'security_protect_icmpflood',
    true,
  );

  
  static final customBlockedDomains =
      PreferencesNotifier.create<String, String>(
        'security_custom_blocked_domains',
        '',
      );

  
  static final customBlockedIps = PreferencesNotifier.create<String, String>(
    'security_custom_blocked_ips',
    '',
  );

  
  static final customAllowedDomains =
      PreferencesNotifier.create<String, String>(
        'security_custom_allowed_domains',
        '',
      );

  
  static final customAllowedIps = PreferencesNotifier.create<String, String>(
    'security_custom_allowed_ips',
    '',
  );

  
  static final blockTorExitNodes = PreferencesNotifier.create<bool, bool>(
    'security_block_tor_exit',
    false,
  );

  
  static final blockOtherVpns = PreferencesNotifier.create<bool, bool>(
    'security_block_other_vpns',
    false,
  );

  
  static List<String> parsePorts(String ports) {
    if (ports.isEmpty) return [];
    return ports
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  
  static List<String> parseCustomRules(String rules) {
    if (rules.isEmpty) return [];
    return rules
        .split('\n')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();
  }

  
  static List<Map<String, dynamic>> generateSecurityRules({
    required bool blockAdultContentValue,
    required bool blockGamblingValue,
    required bool blockVirusValue,
    required bool blockCryptominersValue,
    required bool blockRansomwareValue,
    required bool blockPhishingValue,
    required bool blockBotnetValue,
    required bool blockSpamValue,
    required bool blockAdsValue,
    required bool blockTrackersValue,
    required bool blocKAnalyticsValue,
    required bool protectDdosValue,
    required bool protectPortScanValue,
    List<String>? customBlockedDomainsValue,
    List<String>? customBlockedIpsValue,
    List<String>? blockedUdpPortsValue,
    List<String>? blockedTcpPortsValue,
    bool blockTorExitValue = false,
  }) {
    final rules = <Map<String, dynamic>>[];

    if (blockAdultContentValue) {
      rules.add({
        'type': 'field',
        'domain': ['geoplugin.com', 'ip-api.com', 'ipinfo.io'],
      });
    }

    if (blockGamblingValue) {
      rules.add({
        'type': 'field',
        'domain': ['regexp:.*casino.*', 'regexp:.*poker.*', 'regexp:.*bet.*'],
      });
    }

    if (blockVirusValue || blockRansomwareValue) {
      rules.add({
        'type': 'field',
        'domain': ['malware-domain.com', 'virus-domain.com'],
      });
    }

    if (blockCryptominersValue) {
      rules.add({
        'type': 'field',
        'domain': ['regexp:.*pool.*', 'regexp:.*mine.*'],
      });
    }

    if (blockPhishingValue) {
      rules.add({
        'type': 'field',
        'domain': ['phishing-domain.com'],
      });
    }

    if (blockBotnetValue) {
      rules.add({
        'type': 'field',
        'domain': ['botnet-domain.com'],
      });
    }

    if (blockSpamValue) {
      rules.add({
        'type': 'field',
        'domain': ['spam-domain.com'],
      });
    }

    if (blockAdsValue) {
      rules.add({
        'type': 'field',
        'domain': ['doubleclick.net', 'googleadservices.com'],
      });
    }

    if (blockTrackersValue) {
      rules.add({
        'type': 'field',
        'domain': ['google-analytics.com', 'facebook.com'],
      });
    }

    if (blockTorExitValue) {
      rules.add({
        'type': 'field',
        'domain': [r'regexp:\.onion$', 'regexp:torproject'],
      });
    }

    if (blockedUdpPortsValue != null && blockedUdpPortsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'network': 'udp',
        'port': blockedUdpPortsValue,
      });
    }

    if (blockedTcpPortsValue != null && blockedTcpPortsValue.isNotEmpty) {
      rules.add({
        'type': 'field',
        'network': 'tcp',
        'port': blockedTcpPortsValue,
      });
    }

    if (customBlockedDomainsValue != null &&
        customBlockedDomainsValue.isNotEmpty) {
      rules.add({'type': 'field', 'domain': customBlockedDomainsValue});
    }

    if (customBlockedIpsValue != null && customBlockedIpsValue.isNotEmpty) {
      rules.add({'type': 'field', 'ip': customBlockedIpsValue});
    }

    return rules;
  }

  
  static Map<String, bool> getSecurityPreset(String level) {
    switch (level) {
      case 'off':
        return {
          'blockAdult': false,
          'blockGambling': false,
          'blockVirus': false,
          'blockAds': false,
          'blockTrackers': false,
        };
      case 'basic':
        return {
          'blockAdult': false,
          'blockGambling': false,
          'blockVirus': true,
          'blockAds': true,
          'blockTrackers': false,
        };
      case 'moderate':
        return {
          'blockAdult': true,
          'blockGambling': false,
          'blockVirus': true,
          'blockAds': true,
          'blockTrackers': true,
        };
      case 'strict':
        return {
          'blockAdult': true,
          'blockGambling': true,
          'blockVirus': true,
          'blockAds': true,
          'blockTrackers': true,
        };
      case 'paranoid':
        return {
          'blockAdult': true,
          'blockGambling': true,
          'blockVirus': true,
          'blockAds': true,
          'blockTrackers': true,
        };
      default:
        return {
          'blockAdult': false,
          'blockGambling': false,
          'blockVirus': true,
          'blockAds': true,
          'blockTrackers': false,
        };
    }
  }
}
