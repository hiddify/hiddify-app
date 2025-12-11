import 'dart:convert';
import 'package:hiddify/features/config/model/config.dart';

class CoreConfigurator {
  static String generateConfig({
    required Config activeConfig,
    required String coreMode, // 'vpn' or 'proxy'
    required String routingRule, // 'global', 'geo_iran', 'bypass_lan'
    required String logLevel,
    required bool enableLogging,
    required String accessLogPath,
    required String errorLogPath,
    required int socksPort,
    required int httpPort,
    required bool enableMux,
    required int muxConcurrency,
    required String domainStrategy,
    required bool allowInsecure,
    required String remoteDns,
    required String fingerPrint,
  }) {
    final dnsServers = <String>[remoteDns, 'localhost'];
    final inbounds = <Map<String, dynamic>>[];
    final outbounds = <Map<String, dynamic>>[];
    final routingRules = <Map<String, dynamic>>[];

    // 2. Add Inbounds based on Core Mode
    if (coreMode == 'vpn') {
      // VPN mode uses dokodemo-door for transparent proxying on supported platforms
      // The actual TUN/TAP interface is managed by the native VPN service
      inbounds.add({
        'tag': 'tun_in',
        'port': 12345,
        'protocol': 'dokodemo-door',
        'listen': '127.0.0.1',
        'settings': {
          'address': '127.0.0.1',
          'port': 0,
          'network': 'tcp,udp',
          'followRedirect': true,
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls'],
        },
      });
    } else {
      // Proxy Mode
      inbounds.add({
        'tag': 'socks_in',
        'port': socksPort,
        'protocol': 'socks',
        'listen': '127.0.0.1',
        'settings': {
          'auth': 'noauth',
          'udp': true,
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls'],
        },
      });
      inbounds.add({
        'tag': 'http_in',
        'port': httpPort,
        'protocol': 'http',
        'listen': '127.0.0.1',
        'settings': {
          'auth': 'noauth',
          'udp': true,
        },
      });
    }

    // 3. Add Outbound from Active Config
    if (activeConfig.content.trim().startsWith('{')) {
      try {
        final parsed = jsonDecode(activeConfig.content);
        if (parsed is Map<String, dynamic>) {
           if (parsed.containsKey('outbounds') && parsed['outbounds'] is List) {
             outbounds.addAll(List<Map<String, dynamic>>.from(parsed['outbounds'] as List));
           } else if (parsed.containsKey('protocol')) {
             outbounds.add(parsed);
           }
        }
      } catch (e) {
        // Fallback
        outbounds.add({
          'tag': 'proxy',
          'protocol': 'freedom',
          'settings': <String, dynamic>{},
        });
      }
    } else {
      // Stub for link formats
      outbounds.add({
        'tag': 'proxy',
        'protocol': 'freedom',
        'settings': <String, dynamic>{},
      });
    }

    // Apply Mux and Insecure settings to the first outbound (proxy)
    if (outbounds.isNotEmpty) {
      final proxyOutbound = outbounds[0];
      
      var streamSettings = proxyOutbound['streamSettings'] as Map<String, dynamic>?;
      if (streamSettings == null) {
        streamSettings = <String, dynamic>{};
        proxyOutbound['streamSettings'] = streamSettings;
      }

      if (allowInsecure || fingerPrint.isNotEmpty) {
        if (streamSettings['security'] == 'tls') {
          var tlsSettings = streamSettings['tlsSettings'] as Map<String, dynamic>?;
          if (tlsSettings == null) {
            tlsSettings = <String, dynamic>{};
            streamSettings['tlsSettings'] = tlsSettings;
          }

          if (allowInsecure) {
            tlsSettings['allowInsecure'] = true;
          }
          if (fingerPrint.isNotEmpty) {
            tlsSettings['fingerprint'] = fingerPrint;
          }
        }
      }

      if (enableMux) {
        proxyOutbound['mux'] = {
          'enabled': true,
          'concurrency': muxConcurrency,
        };
      }
    }

    // Add default Direct outbound
    outbounds.add({
      'tag': 'direct',
      'protocol': 'freedom',
      'settings': <String, dynamic>{},
    });
    outbounds.add({
      'tag': 'block',
      'protocol': 'blackhole',
      'settings': <String, dynamic>{},
    });

    // 4. Configure Routing
    if (routingRule == 'bypass_lan') {
      routingRules.add({
        'type': 'field',
        'ip': ['geoip:private'],
        'outboundTag': 'direct',
      });
    } else if (routingRule == 'geo_iran') {
      routingRules.add({
        'type': 'field',
        'ip': ['geoip:ir'],
        'outboundTag': 'direct',
      });
      routingRules.add({
        'type': 'field',
        'domain': ['geosite:ir'],
        'outboundTag': 'direct',
      });
    }

    final finalConfig = {
      'log': {
        'loglevel': enableLogging ? logLevel : 'none',
        'access': enableLogging ? accessLogPath : '',
        'error': enableLogging ? errorLogPath : '',
      },
      'dns': {
        'servers': dnsServers,
      },
      'inbounds': inbounds,
      'outbounds': outbounds,
      'routing': {
        'domainStrategy': domainStrategy,
        'rules': routingRules,
      },
      'policy': <String, dynamic>{},
    };

    return jsonEncode(finalConfig);
  }
}
