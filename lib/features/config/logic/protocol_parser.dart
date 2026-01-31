import 'package:hiddify/features/config/logic/hysteria_parser.dart';
import 'package:hiddify/features/config/logic/naive_parser.dart';
import 'package:hiddify/features/config/logic/shadowsocks_parser.dart';
import 'package:hiddify/features/config/logic/shadowsocksr_parser.dart';
import 'package:hiddify/features/config/logic/trojan_parser.dart';
import 'package:hiddify/features/config/logic/tuic_parser.dart';
import 'package:hiddify/features/config/logic/vless_parser.dart';
import 'package:hiddify/features/config/logic/vmess_parser.dart';
import 'package:hiddify/features/config/logic/wireguard_parser.dart';

 // Unified protocol parser for all supported protocols
class ProtocolParser {
  // Parse any supported protocol URI to outbound config
  static Map<String, dynamic>? parse(String uri) {
    final trimmed = uri.trim();

    if (trimmed.startsWith('vless://')) {
      return VlessParser.parse(trimmed);
    }

    if (trimmed.startsWith('vmess://')) {
      return VmessParser.parse(trimmed);
    }

    if (trimmed.startsWith('trojan://')) {
      return TrojanParser.parse(trimmed);
    }

    if (trimmed.startsWith('ss://')) {
      return ShadowsocksParser.parse(trimmed);
    }

    if (trimmed.startsWith('wg://') || trimmed.startsWith('wireguard://')) {
      return WireguardParser.parse(trimmed);
    }

    if (trimmed.startsWith('hy2://') ||
        trimmed.startsWith('hysteria2://') ||
        trimmed.startsWith('hysteria://')) {
      return HysteriaParser.parse(trimmed);
    }

    if (trimmed.startsWith('tuic://')) {
      return TuicParser.parse(trimmed);
    }
    if (trimmed.startsWith('ssr://')) {
      return ShadowsocksRParser.parse(trimmed);
    }
    if (trimmed.startsWith('naive+https://') ||
        trimmed.startsWith('naive+quic://') ||
        trimmed.startsWith('naive://')) {
      return NaiveParser.parse(trimmed);
    }
    if (trimmed.startsWith('socks://') || trimmed.startsWith('socks5://')) {
      return _parseSocksUri(trimmed);
    }

    return null;
  }

  // Parse SOCKS URI: socks://[user:pass@]host:port[#remark]
  static Map<String, dynamic>? _parseSocksUri(String uri) {
    try {
      final schemeEnd = uri.indexOf('://') + 3;
      final withoutScheme = uri.substring(schemeEnd);
      final fragmentIndex = withoutScheme.indexOf('#');

      String mainPart;
      String? remark;

      if (fragmentIndex != -1) {
        mainPart = withoutScheme.substring(0, fragmentIndex);
        remark = Uri.decodeComponent(withoutScheme.substring(fragmentIndex + 1));
      } else {
        mainPart = withoutScheme;
      }

      String host;
      int port;
      String? user;
      String? pass;

      final atIndex = mainPart.indexOf('@');
      String hostPort;
      
      if (atIndex != -1) {
        final userPass = mainPart.substring(0, atIndex);
        hostPort = mainPart.substring(atIndex + 1);
        final colonIndex = userPass.indexOf(':');
        if (colonIndex != -1) {
          user = Uri.decodeComponent(userPass.substring(0, colonIndex));
          pass = Uri.decodeComponent(userPass.substring(colonIndex + 1));
        } else {
          user = Uri.decodeComponent(userPass);
        }
      } else {
        hostPort = mainPart;
      }

      final colonIndex = hostPort.lastIndexOf(':');
      if (colonIndex != -1) {
        host = hostPort.substring(0, colonIndex);
        port = int.parse(hostPort.substring(colonIndex + 1));
      } else {
        host = hostPort;
        port = 1080;
      }

      final settings = <String, dynamic>{
        'servers': [
          {
            'address': host,
            'port': port,
            if (user != null) 'users': [{'user': user, 'pass': pass ?? ''}],
          },
        ],
      };

      return {
        'tag': 'proxy',
        'protocol': 'socks',
        'settings': settings,
        if (remark != null) '_remark': remark,
      };
    } catch (e) {
      return null;
    }
  }

  // Detect protocol type from URI
  static String detectProtocol(String uri) {
    final trimmed = uri.trim().toLowerCase();

    if (trimmed.startsWith('vless://')) return 'vless';
    if (trimmed.startsWith('vmess://')) return 'vmess';
    if (trimmed.startsWith('trojan://')) return 'trojan';
    if (trimmed.startsWith('ss://')) return 'shadowsocks';
    if (trimmed.startsWith('ssr://')) return 'shadowsocksr';
    if (trimmed.startsWith('wg://') || trimmed.startsWith('wireguard://')) return 'wireguard';
    if (trimmed.startsWith('hy2://') || trimmed.startsWith('hysteria2://')) return 'hysteria2';
    if (trimmed.startsWith('hysteria://')) return 'hysteria';
    if (trimmed.startsWith('tuic://')) return 'tuic';
    if (trimmed.startsWith('naive+https://') ||
        trimmed.startsWith('naive+quic://') ||
        trimmed.startsWith('naive://')) {
      return 'naive';
    }
    if (trimmed.startsWith('socks://') || trimmed.startsWith('socks5://')) return 'socks';

    return 'unknown';
  }

  // Check if protocol is natively supported by Xray-core
  static bool isNativeXrayProtocol(String protocol) => [
      'vless',
      'vmess',
      'trojan',
      'shadowsocks',
      'wireguard',
    ].contains(protocol);

  // Check if protocol requires external handler
  static bool isExternalProtocol(String protocol) => [
      'hysteria',
      'hysteria2',
      'tuic',
      'naive',
      'shadowsocksr',
    ].contains(protocol);

  // Extract remark/name from parsed config
  static String? extractRemark(Map<String, dynamic>? config) {
    if (config == null) return null;
    return config['_remark'] as String?;
  }

  // Get protocol from parsed config
  static String? extractProtocol(Map<String, dynamic>? config) {
    if (config == null) return null;
    if (config['_protocol'] != null) {
      return config['_protocol'] as String;
    }
    return config['protocol'] as String?;
  }

  // Convert parsed config back to URI
  static String toUri(Map<String, dynamic> config) {
    final protocol = extractProtocol(config);

    switch (protocol) {
      case 'vless':
        return VlessParser.toUri(config);
      case 'vmess':
        return VmessParser.toUri(config);
      case 'trojan':
        return TrojanParser.toUri(config);
      case 'shadowsocks':
        return ShadowsocksParser.toUri(config);
      case 'wireguard':
        return WireguardParser.toUri(config);
      case 'hysteria':
      case 'hysteria2':
        return HysteriaParser.toUri(config);
      case 'tuic':
        return TuicParser.toUri(config);
      case 'shadowsocksr':
        return ShadowsocksRParser.toUri(config);
      case 'naive':
        return NaiveParser.toUri(config);
      default:
        return '';
    }
  }
}
