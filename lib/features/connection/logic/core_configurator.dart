import 'dart:convert';

import 'package:hiddify/features/config/logic/protocol_parser.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/settings/model/dns_settings.dart';
import 'package:hiddify/features/settings/model/fragment_settings.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:hiddify/features/settings/model/mux_settings.dart';
import 'package:hiddify/features/settings/model/routing_settings.dart';
import 'package:hiddify/features/settings/model/sockopt_settings.dart';

/// Full Xray-core configuration generator
/// Supports all Xray-core features including Fragment, REALITY, MUX, advanced DNS, etc.
class CoreConfigurator {
  /// Generate complete Xray-core configuration
  static String generateConfig({
    // Required params first
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
    // Optional params after
    String? alpn,
    bool muxPadding = true,
    int? xudpConcurrency,
    String? xudpProxyUDP443,
    String? directDns,
    String? dnsQueryStrategy,
    bool enableFakeDns = false,
    bool bypassChina = false,
    bool blockAds = false,
    bool blockQuic = false,
    bool enableFragment = true,
    String? fragmentPackets,
    String? fragmentLength,
    String? fragmentInterval,
    bool enableNoise = false,
    String? noiseType,
    String? noisePacket,
    String? noiseDelay,
    bool enableSniffing = true,
    String? sniffingDestOverride,
    bool tcpFastOpen = false,
    String? tcpCongestion,
    bool blockMalware = true,
    bool blockPhishing = true,
    List<String>? customDirectDomains,
    List<String>? customProxyDomains,
    List<String>? customBlockDomains,
  }) {
    final inbounds = <Map<String, dynamic>>[];
    final outbounds = <Map<String, dynamic>>[];
    final routingRules = <Map<String, dynamic>>[];

    // ============ SNIFFING CONFIG ============
    final sniffingConfig = InboundSettings.generateSniffingConfig(
      enabled: enableSniffing,
      destOverride: sniffingDestOverride ?? 'http,tls',
    );

    // ============ INBOUNDS ============
    // Always add SOCKS and HTTP inbounds (needed for tun2socks in VPN mode too)
    inbounds.add(InboundSettings.generateSocksInbound(
      port: socksPort,
      listen: '127.0.0.1',
      udp: true,
      tag: 'socks_in',
      sniffing: sniffingConfig,
    ),);
    inbounds.add(InboundSettings.generateHttpInbound(
      port: httpPort,
      listen: '127.0.0.1',
      tag: 'http_in',
      sniffing: sniffingConfig,
    ),);

    // ============ PARSE PROXY OUTBOUND ============
    Map<String, dynamic>? proxyOutbound;

    final content = activeConfig.content.trim();
    if (content.startsWith('{')) {
      // JSON config
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
      } catch (_) {
        // Will use fallback
      }
    } else {
      // URI format - parse using protocol parsers
      proxyOutbound = ProtocolParser.parse(content);
    }

    // Fallback if parsing failed
    proxyOutbound ??= {
      'tag': 'proxy',
      'protocol': 'freedom',
      'settings': <String, dynamic>{},
    };

    // External protocols (Hysteria, TUIC) are now handled by ConnectionNotifier
    // which starts the external process and chains via SOCKS

    // Ensure tag is set
    proxyOutbound['tag'] = 'proxy';

    // ============ APPLY SETTINGS TO PROXY OUTBOUND ============
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
    );

    outbounds.add(proxyOutbound);

    // ============ DIRECT OUTBOUND (with Fragment + Noise support) ============
    // Note: freedom outbound only supports: AsIs, UseIP, UseIPv4, UseIPv6
    // IPIfNonMatch/IPOnDemand are only for routing, not for outbound
    final freedomStrategy = _convertToFreedomStrategy(domainStrategy);
    final directOutbound = <String, dynamic>{
      'tag': 'direct',
      'protocol': 'freedom',
      'settings': <String, dynamic>{
        'domainStrategy': freedomStrategy,
      },
    };

    // Add Fragment settings if enabled (GFW-knocker feature)
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

    // Add Noise settings if enabled (GFW-knocker feature)
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

    // ============ FRAGMENT OUTBOUND (for proxy chain) ============
    // This allows Fragment to be applied to proxy traffic
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

    // ============ BLOCK OUTBOUND ============
    outbounds.add({
      'tag': 'block',
      'protocol': 'blackhole',
      'settings': {'response': {'type': 'http'}},
    });

    // ============ DNS OUTBOUND ============
    outbounds.add({
      'tag': 'dns-out',
      'protocol': 'dns',
    });

    // ============ ROUTING RULES ============
    // DNS routing
    routingRules.add({
      'type': 'field',
      'inboundTag': ['socks_in', 'http_in', 'tun_in'],
      'port': 53,
      'outboundTag': 'dns-out',
    });

    // Custom and preset routing rules
    final generatedRules = RoutingSettings.generateRoutingRules(
      bypassLanValue: bypassLan,
      bypassIranValue: bypassIran,
      bypassChinaValue: bypassChina,
      blockAdsValue: blockAds,
      blockPornValue: false,
      blockQuicValue: blockQuic,
      directYoutubeValue: false,
      directNetflixValue: false,
      customDirectDomainsValue: customDirectDomains,
      customProxyDomainsValue: customProxyDomains,
      customBlockDomainsValue: customBlockDomains,
    );
    routingRules.addAll(generatedRules);

    // ============ DNS CONFIG ============
    final dnsConfig = DnsSettings.generateDnsConfig(
      remoteDnsAddr: remoteDns,
      remoteDnsType: _detectDnsType(remoteDns),
      directDnsAddr: directDns ?? '1.1.1.1',
      directDnsType: 'udp',
      queryStrategyValue: dnsQueryStrategy ?? 'UseIP',
      disableCacheValue: false,
      disableFallbackValue: false,
      enableFakeDnsValue: enableFakeDns,
    );

    // ============ FAKEDNS CONFIG ============
    List<Map<String, dynamic>>? fakeDnsConfig;
    if (enableFakeDns) {
      fakeDnsConfig = DnsSettings.generateFakeDnsConfig(
        isEnabled: true,
        ipv4Pool: '198.18.0.0/15',
        ipv6Pool: 'fc00::/18',
        poolSize: 65535,
        queryStrategyValue: dnsQueryStrategy ?? 'UseIP',
      );
    }

    // ============ FINAL CONFIG ============
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
          'settings': {
            'address': '127.0.0.1',
          },
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
          }
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
      'stats': <String, dynamic>{},
    };

    // Add FakeDNS if enabled
    if (fakeDnsConfig != null) {
      finalConfig['fakedns'] = fakeDnsConfig;
    }

    return jsonEncode(finalConfig);
  }

  /// Apply settings to proxy outbound
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
  }) {
    // Get or create streamSettings
    final streamSettings =
        outbound['streamSettings'] as Map<String, dynamic>? ?? <String, dynamic>{};
    outbound['streamSettings'] = streamSettings;

    final security = streamSettings['security'] as String? ?? 'none';

    // Apply TLS settings
    if (security == 'tls') {
      final tlsSettings =
          streamSettings['tlsSettings'] as Map<String, dynamic>? ?? <String, dynamic>{};
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

    // Apply REALITY settings fingerprint
    if (security == 'reality') {
      final realitySettings =
          streamSettings['realitySettings'] as Map<String, dynamic>? ?? <String, dynamic>{};
      streamSettings['realitySettings'] = realitySettings;

      if (fingerPrint.isNotEmpty) {
        realitySettings['fingerprint'] = fingerPrint;
      }
    }

    // Apply Sockopt settings
    final sockopt = SockoptSettings.generateSockoptConfig(
      tcpFastOpenValue: tcpFastOpen,
      tcpCongestionValue: tcpCongestion,
    );
    if (sockopt != null) {
      streamSettings['sockopt'] = sockopt;
    }

    // Apply MUX settings
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

  /// Detect DNS type from address
  static String _detectDnsType(String address) {
    if (address.startsWith('https://') ||
        address.startsWith('https+local://')) {
      return 'doh';
    }
    if (address.startsWith('tcp://') || address.startsWith('tcp+local://')) {
      return 'tcp';
    }
    if (address.startsWith('quic+local://')) {
      return 'doq';
    }
    return 'udp';
  }

  /// Generate config with all settings from preferences
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

  /// Convert routing domain strategy to freedom outbound strategy
  /// Freedom outbound only supports: AsIs, UseIP, UseIPv4, UseIPv6
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
