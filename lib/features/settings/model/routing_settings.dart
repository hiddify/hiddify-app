import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class RoutingSettings {
  static final rulePreset = PreferencesNotifier.create<String, String>(
    'routing_preset',
    'bypass_iran',
  );

  static final domainStrategy = PreferencesNotifier.create<String, String>(
    'routing_domain_strategy',
    'AsIs',
  );

  static final domainMatcher = PreferencesNotifier.create<String, String>(
    'routing_domain_matcher',
    'hybrid',
  );

  static final bypassLan = PreferencesNotifier.create<bool, bool>(
    'routing_bypass_lan',
    true,
  );

  static final bypassIran = PreferencesNotifier.create<bool, bool>(
    'routing_bypass_iran',
    true,
  );

  static final bypassChina = PreferencesNotifier.create<bool, bool>(
    'routing_bypass_china',
    false,
  );

  static final blockAds = PreferencesNotifier.create<bool, bool>(
    'routing_block_ads',
    true,
  );

  static final blockPorn = PreferencesNotifier.create<bool, bool>(
    'routing_block_porn',
    true,
  );

  static final blockQuic = PreferencesNotifier.create<bool, bool>(
    'routing_block_quic',
    false,
  );

  static final blockMalware = PreferencesNotifier.create<bool, bool>(
    'routing_block_malware',
    true,
  );

  static final blockPhishing = PreferencesNotifier.create<bool, bool>(
    'routing_block_phishing',
    true,
  );

  static final blockCryptominers = PreferencesNotifier.create<bool, bool>(
    'routing_block_cryptominers',
    true,
  );

  static final blockBotnet = PreferencesNotifier.create<bool, bool>(
    'routing_block_botnet',
    true,
  );

  static final blockRansomware = PreferencesNotifier.create<bool, bool>(
    'routing_block_ransomware',
    true,
  );

  static final blockSpam = PreferencesNotifier.create<bool, bool>(
    'routing_block_spam',
    true,
  );

  static final blockTrackers = PreferencesNotifier.create<bool, bool>(
    'routing_block_trackers',
    true,
  );

  static final blockGambling = PreferencesNotifier.create<bool, bool>(
    'routing_block_gambling',
    false,
  );

  static final blockDating = PreferencesNotifier.create<bool, bool>(
    'routing_block_dating',
    false,
  );

  static final blockSocialMedia = PreferencesNotifier.create<bool, bool>(
    'routing_block_social_media',
    false,
  );

  static final sniffTlsForRouting = PreferencesNotifier.create<bool, bool>(
    'routing_sniff_tls',
    true,
  );

  static final directYoutube = PreferencesNotifier.create<bool, bool>(
    'routing_direct_youtube',
    false,
  );

  static final directNetflix = PreferencesNotifier.create<bool, bool>(
    'routing_direct_netflix',
    false,
  );

  static final customDirectDomains = PreferencesNotifier.create<String, String>(
    'routing_custom_direct_domains',
    '',
  );

  static final customProxyDomains = PreferencesNotifier.create<String, String>(
    'routing_custom_proxy_domains',
    '',
  );

  static final customBlockDomains = PreferencesNotifier.create<String, String>(
    'routing_custom_block_domains',
    '',
  );

  static final customDirectIps = PreferencesNotifier.create<String, String>(
    'routing_custom_direct_ips',
    '',
  );

  static final customProxyIps = PreferencesNotifier.create<String, String>(
    'routing_custom_proxy_ips',
    '',
  );

  static final customBlockIps = PreferencesNotifier.create<String, String>(
    'routing_custom_block_ips',
    '',
  );

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

  static List<String> parseCustomRules(String rules) {
    if (rules.isEmpty) return [];
    return rules
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.startsWith('#'))
        .toList();
  }

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
    bool blockCryptominersValue = true,
    bool blockBotnetValue = true,
    bool blockRansomwareValue = true,
    bool blockSpamValue = true,
    bool blockTrackersValue = true,
    bool blockGamblingValue = false,
    bool blockDatingValue = false,
    bool blockSocialMediaValue = false,
    List<String>? customDirectDomainsValue,
    List<String>? customProxyDomainsValue,
    List<String>? customBlockDomainsValue,
    List<String>? customDirectIpsValue,
    List<String>? customProxyIpsValue,
    List<String>? customBlockIpsValue,
    List<String>? blockedUdpPorts,
    List<String>? blockedTcpPorts,
  }) {
    final rules = <Map<String, dynamic>>[];

    if (blockMalwareValue || blockRansomwareValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'geosite:category-malware',
          'regexp:malware',
          'regexp:ransomware',
          'regexp:virus',
          'regexp:trojan',
          r'regexp:worm\.',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockPhishingValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'geosite:phishing',
          'regexp:phishing',
          'regexp:scam',
          'regexp:fake-login',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockCryptominersValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'geosite:category-cryptominers',
          'regexp:coinhive',
          'regexp:cryptoloot',
          'regexp:miner',
          r'regexp:mining\.js',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockBotnetValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'regexp:botnet',
          'regexp:c2server',
          'regexp:command-and-control',
          'regexp:zombie',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockSpamValue) {
      rules.add({
        'type': 'field',
        'domain': ['regexp:spam', 'regexp:spammer', 'regexp:bulk-mail'],
        'outboundTag': 'block',
      });
    }

    if (blockAdsValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'geosite:category-ads',
          'geosite:category-ads-all',
          'geosite:category-ads-ir',
          'regexp:doubleclick',
          'regexp:googlesyndication',
          'regexp:adservice',
          r'regexp:ads\.',
          r'regexp:\.ads\.',
          'regexp:adserver',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockTrackersValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'regexp:tracker',
          'regexp:tracking',
          'regexp:analytics',
          'regexp:telemetry',
          'regexp:beacon',
          'domain:google-analytics.com',
          'domain:mixpanel.com',
          'domain:segment.io',
          'domain:amplitude.com',
          'domain:hotjar.com',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockPornValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'geosite:category-porn',
          'geosite:nsfw',
          'regexp:porn',
          'regexp:xxx',
          'regexp:adult',
          r'regexp:sex\.',
          r'regexp:\.sex',
          'regexp:nsfw',
          'regexp:nude',
          'regexp:erotic',
          r'regexp:18\+',
          'regexp:xvideos',
          'regexp:pornhub',
          'regexp:xnxx',
          'regexp:xhamster',
          'regexp:redtube',
          'regexp:youporn',
          'regexp:brazzers',
          'regexp:chaturbate',
          'regexp:onlyfans',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockGamblingValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'geosite:category-gambling',
          'regexp:casino',
          'regexp:betting',
          'regexp:poker',
          'regexp:gambling',
          'regexp:slot-machine',
          'regexp:lottery',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockDatingValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'regexp:dating',
          'regexp:tinder',
          'regexp:bumble',
          r'regexp:match\.com',
          'regexp:okcupid',
        ],
        'outboundTag': 'block',
      });
    }

    if (blockSocialMediaValue) {
      rules.add({
        'type': 'field',
        'domain': [
          'domain:facebook.com',
          'domain:instagram.com',
          'domain:twitter.com',
          'domain:x.com',
          'domain:tiktok.com',
          'domain:snapchat.com',
          'domain:pinterest.com',
          'domain:linkedin.com',
          'domain:reddit.com',
          'domain:tumblr.com',
        ],
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

    if (blockedUdpPorts != null && blockedUdpPorts.isNotEmpty) {
      rules.add({
        'type': 'field',
        'port': blockedUdpPorts.join(','),
        'network': 'udp',
        'outboundTag': 'block',
      });
    }

    if (blockedTcpPorts != null && blockedTcpPorts.isNotEmpty) {
      rules.add({
        'type': 'field',
        'port': blockedTcpPorts.join(','),
        'network': 'tcp',
        'outboundTag': 'block',
      });
    }

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

    if (bypassLanValue) {
      rules.add({
        'type': 'field',
        'ip': ['geoip:private'],
        'outboundTag': 'direct',
      });
    }

    if (bypassIranValue) {
      rules.add({
        'type': 'field',
        'ip': ['geoip:ir'],
        'outboundTag': 'direct',
      });
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

    if (customDirectDomainsValue != null &&
        customDirectDomainsValue.isNotEmpty) {
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
