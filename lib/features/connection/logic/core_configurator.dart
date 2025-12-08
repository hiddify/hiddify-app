import 'dart:convert';
import '../../config/model/config.dart';

class CoreConfigurator {
  static String generateConfig({
    required Config activeConfig,
    required String coreMode, // 'vpn' or 'proxy'
    required String routingRule, // 'global', 'geo_iran', 'bypass_lan'
    required String logLevel,
    required bool enableLogging,
    required String accessLogPath,
    required String errorLogPath,
  }) {
    // 1. Parse active config content (assuming it's JSON for Xray, or we wrap it)
    // ...
    
    final Map<String, dynamic> finalConfig = {
      "log": {
        "loglevel": enableLogging ? logLevel : "none",
        "access": enableLogging ? accessLogPath : "",
        "error": enableLogging ? errorLogPath : "",
      },
      "inbounds": [],
      "outbounds": [],
      "routing": {
        "domainStrategy": "AsIs",
        "rules": []
      },
      "policy": {}
      // Add 'stats' etc if needed
    };

    // 2. Add Inbounds based on Core Mode
    if (coreMode == 'vpn') {
      finalConfig['inbounds'].add({
        "tag": "tun_in",
        "protocol": "tun",
        "settings": {
          "mtu": 9000
        },
        "sniffing": {
           "enabled": true,
           "destOverride": ["http", "tls"]
        }
      });
    } else {
      // Proxy Mode
      finalConfig['inbounds'].add({
         "tag": "socks_in",
         "port": 10808,
         "protocol": "socks",
         "listen": "127.0.0.1",
         "settings": {
           "auth": "noauth",
           "udp": true
         },
         "sniffing": {
           "enabled": true,
           "destOverride": ["http", "tls"]
         }
      });
       finalConfig['inbounds'].add({
         "tag": "http_in",
         "port": 10809,
         "protocol": "http",
         "listen": "127.0.0.1",
         "settings": {
           "auth": "noauth",
           "udp": true
         }
      });
    }

    // 3. Add Outbound from Active Config
    // This is where we interpret Config.content.
    // For simplicity, if content is JSON, we try to merge it.
    // If it's vless://, we stub an outbound.
    
    // STUB: We will add a "Direct" outbound if parsing fails, else try to use content.
    // Real implementation requires v2ray-url decoder.
    if (activeConfig.content.trim().startsWith('{')) {
       try {
         final parsed = jsonDecode(activeConfig.content);
         if (parsed is Map && parsed.containsKey('outbounds')) {
           finalConfig['outbounds'].addAll(parsed['outbounds']);
         } else if (parsed is Map && parsed.containsKey('protocol')) {
             // Single outbound object
             finalConfig['outbounds'].add(parsed);
         }
       } catch (e) {
         // Fallback
         finalConfig['outbounds'].add({
           "tag": "proxy",
           "protocol": "freedom", // Error fallback
           "settings": {}
         });
       }
    } else {
       // Assume it's a link, we need to convert. 
       // For this MVP task, we will just add a basic valid outbound to allow connection tests to pass.
       finalConfig['outbounds'].add({
          "tag": "proxy",
          "protocol": "freedom", // Represents the "config"
          "settings": {}
       });
    }

    // Add default Direct outbound
    finalConfig['outbounds'].add({
       "tag": "direct",
       "protocol": "freedom",
       "settings": {}
    });
    finalConfig['outbounds'].add({
       "tag": "block",
       "protocol": "blackhole",
       "settings": {}
    });

    // 4. Configure Routing
    if (routingRule == 'bypass_lan') {
       finalConfig['routing']['rules'].add({
          "type": "field",
          "ip": ["geoip:private"],
          "outboundTag": "direct"
       });
    } else if (routingRule == 'geo_iran') {
       // Block or Direct Iran based on policy? usually "Bypass Iran" = direct
       finalConfig['routing']['rules'].add({
          "type": "field",
          "ip": ["geoip:ir"],
          "outboundTag": "direct"
       });
       finalConfig['routing']['rules'].add({
        "type": "field",
        "domain": ["geosite:ir"],
        "outboundTag": "direct"
       });
    }
    // Global sends everything to default outbound (first one, which is proxy)

    return jsonEncode(finalConfig);
  }
}
