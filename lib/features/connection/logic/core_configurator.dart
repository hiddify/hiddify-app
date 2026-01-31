import 'dart:convert';

import 'package:hiddify/features/config/logic/protocol_parser.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/settings/model/dns_settings.dart';
import 'package:hiddify/features/settings/model/fragment_settings.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:hiddify/features/settings/model/mux_settings.dart';
import 'package:hiddify/features/settings/model/routing_settings.dart';
import 'package:hiddify/features/settings/model/sockopt_settings.dart';

class CoreConfigurator {
  static String generateConfig({
    required Config activeConfig,
    required String coreMode,
    required String logLevel,
    required bool enableLogging,
    required String accessLogPath,
    required String errorLogPath,
    required int socksPort,
    required int httpPort,
    required String domainStrategy,
    required bool allowInsecure,
    required String fingerPrint,
    required bool enableMux,
    required int muxConcurrency,
    required String remoteDns,
    required bool bypassLan,
    required bool bypassIran,
    String? alpn,
    bool muxPadding = true,
    int? xudpConcurrency,
    String? xudpProxyUDP443,
    String remoteDnsType = 'doh',
    String? directDns,
    String directDnsType = 'udp',
    String? dnsQueryStrategy,
    bool enableFakeDns = false,
    bool enableDnsRouting = true,
    bool dnsDisableCache = false,
    bool dnsDisableFallback = false,
    String? dnsClientIp,
    String? fakeDnsIpv4Pool,
    String? fakeDnsIpv6Pool,
    int? fakeDnsPoolSize,
    Map<String, dynamic>? dnsHosts,
    String socksListen = '127.0.0.1',
    bool socksUdp = true,
    String socksAuth = 'noauth',
    String httpListen = '127.0.0.1',
    bool httpAllowTransparent = false,
    bool enableSniffing = true,
    String? sniffingDestOverride,
    bool sniffingRouteOnly = false,
    bool sniffingFakeDns = false,
    List<String>? sniffingExcludeDomains,
    bool bypassChina = false,
    bool blockAds = false,
    bool blockPorn = true,
    bool blockQuic = false,
    bool blockMalware = true,
    bool blockPhishing = true,
    bool directYoutube = false,
    bool directNetflix = false,
    bool blockCryptominers = true,
    bool blockBotnet = true,
    bool blockRansomware = true,
    bool blockSpam = true,
    bool blockTrackers = true,
    bool blockGambling = false,
    bool blockDating = false,
    bool blockSocialMedia = false,
    List<String>? customDirectDomains,
    List<String>? customProxyDomains,
    List<String>? customBlockDomains,
    List<String>? customDirectIps,
    List<String>? customProxyIps,
    List<String>? customBlockIps,
    List<String>? blockedUdpPorts,
    List<String>? blockedTcpPorts,
    bool enableFragment = true,
    String? fragmentPackets,
    String? fragmentLength,
    String? fragmentInterval,
    bool enableNoise = false,
    String? noiseType,
    String? noisePacket,
    String? noiseDelay,
    bool tcpFastOpen = false,
    String? tcpCongestion,
    int? tcpKeepAliveInterval,
    int? tcpKeepAliveIdle,
    int? tcpUserTimeout,
    bool tcpNoDelay = false,
    int? tcpMaxSeg,
    int? tcpWindowClamp,
    bool tcpMptcp = false,
    String? sockoptTproxy,
    String? sockoptDomainStrategy,
  }) {
    final inbounds = <Map<String, dynamic>>[];
    final outbounds = <Map<String, dynamic>>[];
    final routingRules = <Map<String, dynamic>>[];

    final sniffingConfig = InboundSettings.generateSniffingConfig(
      enabled: enableSniffing,
      destOverride: sniffingDestOverride ?? 'http,tls',
      routeOnly: sniffingRouteOnly,
      excludeDomains: sniffingExcludeDomains,
    );

    inbounds.add(
      InboundSettings.generateSocksInbound(
        port: socksPort,
        listen: socksListen,
        udp: socksUdp,
        auth: socksAuth,
        tag: 'socks_in',
        sniffing: sniffingConfig,
      ),
    );
    inbounds.add(
      InboundSettings.generateHttpInbound(
        port: httpPort,
        listen: httpListen,
        allowTransparent: httpAllowTransparent,
        tag: 'http_in',
        sniffing: sniffingConfig,
      ),
    );

    Map<String, dynamic>? proxyOutbound;

    final content = activeConfig.content.trim();
    if (content.startsWith('{')) {
      try {
        final parsed = jsonDecode(content);
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('outbounds') && parsed['outbounds'] is List) {
            final parsedOutbounds = List<Map<String, dynamic>>.from(
              parsed['outbounds'] as List,
            );
            if (parsedOutbounds.isNotEmpty) {
              proxyOutbound = parsedOutbounds.first;
            }
          } else if (parsed.containsKey('protocol')) {
            proxyOutbound = parsed;
          }
        }
      } catch (_) {}
    } else {
      proxyOutbound = ProtocolParser.parse(content);
    }

    proxyOutbound ??= {
      'tag': 'proxy',
      'protocol': 'freedom',
      'settings': <String, dynamic>{},
    };

    proxyOutbound['tag'] = 'proxy';

    _applyOutboundSettings(
      outbound: proxyOutbound,
      allowInsecure: allowInsecure,
      fingerPrint: fingerPrint,
      alpn: alpn,
      enableMux: enableMux,
      muxConcurrency: muxConcurrency,
      muxPadding: muxPadding,
      xudpConcurrency: xudpConcurrency,
      xudpProxyUDP443: xudpProxyUDP443,
      tcpFastOpen: tcpFastOpen,
      tcpCongestion: tcpCongestion,
      tcpKeepAliveInterval: tcpKeepAliveInterval,
      tcpKeepAliveIdle: tcpKeepAliveIdle,
      tcpUserTimeout: tcpUserTimeout,
      tcpNoDelay: tcpNoDelay,
      tcpMaxSeg: tcpMaxSeg,
      tcpWindowClamp: tcpWindowClamp,
      tcpMptcp: tcpMptcp,
      sockoptTproxy: sockoptTproxy,
      sockoptDomainStrategy: sockoptDomainStrategy,
    );

    outbounds.add(proxyOutbound);

    final freedomStrategy = _convertToFreedomStrategy(domainStrategy);
    final directOutbound = <String, dynamic>{
      'tag': 'direct',
      'protocol': 'freedom',
      'settings': <String, dynamic>{'domainStrategy': freedomStrategy},
    };

    if (enableFragment) {
      final fragmentConfig = FragmentSettings.generateFragmentConfig(
        isEnabled: true,
        packetsType: fragmentPackets ?? 'tlshello',
        lengthRange: fragmentLength ?? '100-200',
        intervalRange: fragmentInterval ?? '10-20',
      );
      if (fragmentConfig != null) {
        (directOutbound['settings'] as Map<String, dynamic>)['fragment'] =
            fragmentConfig;
      }
    }

    if (enableNoise) {
      final noisesConfig = FragmentSettings.generateNoisesConfig(
        isEnabled: true,
        type: noiseType ?? 'rand',
        packet: noisePacket ?? '10-20',
        delay: noiseDelay ?? '10-16',
        applyTo: 'ip',
      );
      if (noisesConfig != null) {
        (directOutbound['settings'] as Map<String, dynamic>)['noises'] =
            noisesConfig;
      }
    }

    outbounds.add(directOutbound);

    if (enableFragment) {
      final fragmentOutbound = <String, dynamic>{
        'tag': 'fragment',
        'protocol': 'freedom',
        'settings': <String, dynamic>{
          'domainStrategy': freedomStrategy,
          'fragment': {
            'packets': fragmentPackets ?? 'tlshello',
            'length': fragmentLength ?? '100-200',
            'interval': fragmentInterval ?? '10-20',
          },
        },
      };
      if (enableNoise) {
        (fragmentOutbound['settings'] as Map<String, dynamic>)['noises'] = [
          {
            'type': noiseType ?? 'rand',
            'packet': noisePacket ?? '10-20',
            'delay': noiseDelay ?? '10-16',
          },
        ];
      }
      outbounds.add(fragmentOutbound);
    }

    outbounds.add({
      'tag': 'block',
      'protocol': 'blackhole',
      'settings': {
        'response': {'type': 'http'},
      },
    });

    outbounds.add({'tag': 'dns-out', 'protocol': 'dns'});

    if (enableDnsRouting) {
      routingRules.add({
        'type': 'field',
        'inboundTag': ['socks_in', 'http_in', 'tun_in'],
        'port': 53,
        'outboundTag': 'dns-out',
      });
    }

    final generatedRules = RoutingSettings.generateRoutingRules(
      bypassLanValue: bypassLan,
      bypassIranValue: bypassIran,
      bypassChinaValue: bypassChina,
      blockAdsValue: blockAds,
      blockPornValue: blockPorn,
      blockQuicValue: blockQuic,
      blockMalwareValue: blockMalware,
      blockPhishingValue: blockPhishing,
      directYoutubeValue: directYoutube,
      directNetflixValue: directNetflix,
      blockCryptominersValue: blockCryptominers,
      blockBotnetValue: blockBotnet,
      blockRansomwareValue: blockRansomware,
      blockSpamValue: blockSpam,
      blockTrackersValue: blockTrackers,
      blockGamblingValue: blockGambling,
      blockDatingValue: blockDating,
      blockSocialMediaValue: blockSocialMedia,
      customDirectDomainsValue: customDirectDomains,
      customProxyDomainsValue: customProxyDomains,
      customBlockDomainsValue: customBlockDomains,
      customDirectIpsValue: customDirectIps,
      customProxyIpsValue: customProxyIps,
      customBlockIpsValue: customBlockIps,
      blockedUdpPorts: blockedUdpPorts,
      blockedTcpPorts: blockedTcpPorts,
    );
    routingRules.addAll(generatedRules);

    final dnsConfig = DnsSettings.generateDnsConfig(
      remoteDnsAddr: remoteDns,
      remoteDnsType: remoteDnsType,
      directDnsAddr: directDns ?? '1.1.1.1',
      directDnsType: directDnsType,
      queryStrategyValue: dnsQueryStrategy ?? 'UseIP',
      disableCacheValue: dnsDisableCache,
      disableFallbackValue: dnsDisableFallback,
      enableFakeDnsValue: enableFakeDns,
      clientIpValue: dnsClientIp,
      hosts: dnsHosts,
    );

    List<Map<String, dynamic>>? fakeDnsConfig;
    if (enableFakeDns) {
      fakeDnsConfig = DnsSettings.generateFakeDnsConfig(
        isEnabled: true,
        ipv4Pool: fakeDnsIpv4Pool ?? '198.18.0.0/15',
        ipv6Pool: fakeDnsIpv6Pool ?? 'fc00::/18',
        poolSize: fakeDnsPoolSize ?? 65535,
        queryStrategyValue: dnsQueryStrategy ?? 'UseIP',
      );
    }

    final finalConfig = <String, dynamic>{
      'log': {
        'loglevel': enableLogging ? logLevel : 'none',
        if (enableLogging && accessLogPath.isNotEmpty) 'access': accessLogPath,
        if (enableLogging && errorLogPath.isNotEmpty) 'error': errorLogPath,
      },
      'dns': dnsConfig,
      'api': {
        'tag': 'api',
        'services': ['StatsService'],
      },
      'stats': <String, dynamic>{},
      'inbounds': [
        ...inbounds,
        {
          'tag': 'api',
          'port': 10085,
          'listen': '127.0.0.1',
          'protocol': 'dokodemo-door',
          'settings': {'address': '127.0.0.1'},
        },
      ],
      'outbounds': outbounds,
      'routing': {
        'domainStrategy': domainStrategy,
        'domainMatcher': 'hybrid',
        'rules': [
          ...routingRules,
          {
            'type': 'field',
            'inboundTag': ['api'],
            'outboundTag': 'api',
          },
        ],
      },
      'policy': {
        'levels': {
          '0': {
            'handshake': 4,
            'connIdle': 300,
            'uplinkOnly': 1,
            'downlinkOnly': 1,
            'bufferSize': 10240,
            'statsUserUplink': true,
            'statsUserDownlink': true,
          },
        },
        'system': {
          'statsInboundUplink': true,
          'statsInboundDownlink': true,
          'statsOutboundUplink': true,
          'statsOutboundDownlink': true,
        },
      },
    };

    if (fakeDnsConfig != null) {
      finalConfig['fakedns'] = fakeDnsConfig;
    }

    return jsonEncode(finalConfig);
  }

  static void _applyOutboundSettings({
    required Map<String, dynamic> outbound,
    required bool allowInsecure,
    required String fingerPrint,
    required bool enableMux,
    required int muxConcurrency,
    String? alpn,
    bool muxPadding = true,
    int? xudpConcurrency,
    String? xudpProxyUDP443,
    bool tcpFastOpen = false,
    String? tcpCongestion,
    int? tcpKeepAliveInterval,
    int? tcpKeepAliveIdle,
    int? tcpUserTimeout,
    bool tcpNoDelay = false,
    int? tcpMaxSeg,
    int? tcpWindowClamp,
    bool tcpMptcp = false,
    String? sockoptTproxy,
    String? sockoptDomainStrategy,
  }) {
    final streamSettings =
        outbound['streamSettings'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    outbound['streamSettings'] = streamSettings;

    final security = streamSettings['security'] as String? ?? 'none';

    if (security == 'tls') {
      final tlsSettings =
          streamSettings['tlsSettings'] as Map<String, dynamic>? ??
          <String, dynamic>{};
      streamSettings['tlsSettings'] = tlsSettings;

      if (allowInsecure) {
        tlsSettings['allowInsecure'] = true;
      }
      if (fingerPrint.isNotEmpty) {
        tlsSettings['fingerprint'] = fingerPrint;
      }
      if (alpn != null && alpn.isNotEmpty) {
        tlsSettings['alpn'] = alpn.split(',').map((e) => e.trim()).toList();
      }
    }

    if (security == 'reality') {
      final realitySettings =
          streamSettings['realitySettings'] as Map<String, dynamic>? ??
          <String, dynamic>{};
      streamSettings['realitySettings'] = realitySettings;

      if (fingerPrint.isNotEmpty) {
        realitySettings['fingerprint'] = fingerPrint;
      }
    }

    final sockopt = SockoptSettings.generateSockoptConfig(
      tcpFastOpenValue: tcpFastOpen,
      tcpCongestionValue: tcpCongestion,
      tcpKeepAliveIntervalValue: tcpKeepAliveInterval,
      tcpKeepAliveIdleValue: tcpKeepAliveIdle,
      tcpUserTimeoutValue: tcpUserTimeout,
      tcpNoDelayValue: tcpNoDelay,
      tcpMaxSegValue: tcpMaxSeg,
      tcpWindowClampValue: tcpWindowClamp,
      tcpMptcpValue: tcpMptcp,
      tproxyValue: sockoptTproxy,
      domainStrategyValue: sockoptDomainStrategy,
    );
    if (sockopt != null) {
      streamSettings['sockopt'] = sockopt;
    }

    if (enableMux) {
      final muxConfig = MuxSettings.generateMuxConfig(
        isEnabled: true,
        concurrencyValue: muxConcurrency,
        paddingValue: muxPadding,
        xudpConcurrencyValue: xudpConcurrency,
        xudpProxyUDP443Value: xudpProxyUDP443,
      );
      if (muxConfig != null) {
        outbound['mux'] = muxConfig;
      }
    }
  }

  static String generateConfigFromPreferences({
    required Config activeConfig,
    required Map<String, dynamic> preferences,
  }) => generateConfig(
    activeConfig: activeConfig,
    coreMode: preferences['coreMode'] as String? ?? 'proxy',
    logLevel: preferences['logLevel'] as String? ?? 'warning',
    enableLogging: preferences['enableLogging'] as bool? ?? false,
    accessLogPath: preferences['accessLogPath'] as String? ?? '',
    errorLogPath: preferences['errorLogPath'] as String? ?? '',
    socksPort: preferences['socksPort'] as int? ?? 2334,
    httpPort: preferences['httpPort'] as int? ?? 2335,
    domainStrategy: preferences['domainStrategy'] as String? ?? 'IPIfNonMatch',
    allowInsecure: preferences['allowInsecure'] as bool? ?? false,
    fingerPrint: preferences['fingerPrint'] as String? ?? 'chrome',
    alpn: preferences['alpn'] as String?,
    enableMux: preferences['enableMux'] as bool? ?? false,
    muxConcurrency: preferences['muxConcurrency'] as int? ?? 8,
    muxPadding: preferences['muxPadding'] as bool? ?? true,
    xudpConcurrency: preferences['xudpConcurrency'] as int?,
    xudpProxyUDP443: preferences['xudpProxyUDP443'] as String?,
    remoteDns: preferences['remoteDns'] as String? ?? '8.8.8.8',
    directDns: preferences['directDns'] as String?,
    dnsQueryStrategy: preferences['dnsQueryStrategy'] as String?,
    enableFakeDns: preferences['enableFakeDns'] as bool? ?? false,
    bypassLan: preferences['bypassLan'] as bool? ?? true,
    bypassIran: preferences['bypassIran'] as bool? ?? true,
    bypassChina: preferences['bypassChina'] as bool? ?? false,
    blockAds: preferences['blockAds'] as bool? ?? false,
    blockQuic: preferences['blockQuic'] as bool? ?? false,
    enableFragment: preferences['enableFragment'] as bool? ?? false,
    fragmentPackets: preferences['fragmentPackets'] as String?,
    fragmentLength: preferences['fragmentLength'] as String?,
    fragmentInterval: preferences['fragmentInterval'] as String?,
    enableSniffing: preferences['enableSniffing'] as bool? ?? true,
    sniffingDestOverride: preferences['sniffingDestOverride'] as String?,
    tcpFastOpen: preferences['tcpFastOpen'] as bool? ?? false,
    tcpCongestion: preferences['tcpCongestion'] as String?,
    customDirectDomains: preferences['customDirectDomains'] as List<String>?,
    customProxyDomains: preferences['customProxyDomains'] as List<String>?,
    customBlockDomains: preferences['customBlockDomains'] as List<String>?,
  );

  static String _convertToFreedomStrategy(String routingStrategy) {
    switch (routingStrategy) {
      case 'IPIfNonMatch':
      case 'IPOnDemand':
        return 'UseIP';
      case 'AsIs':
      default:
        return 'AsIs';
    }
  }
}
