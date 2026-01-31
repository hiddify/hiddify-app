import 'dart:convert';

import 'package:hiddify/core/logger/logger.dart';

 // Shadowsocks protocol parser for Xray-core
 // Supports SS and SS2022
class ShadowsocksParser {
  static final _logger = Logger.shadowsocks;

  // Parse Shadowsocks URI to outbound config
  // Format 1: ss://base64(method:password)@host:port#name
  // Format 2: ss://base64(method:password@host:port)#name
  // Format 3: ss://method:password@host:port#name (SIP002)
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('ss://')) return null;

    try {
      final withoutScheme = uri.substring(5);
      final fragmentIndex = withoutScheme.indexOf('#');

      String mainPart;
      String? remark;

      if (fragmentIndex != -1) {
        mainPart = withoutScheme.substring(0, fragmentIndex);
        remark = Uri.decodeComponent(withoutScheme.substring(fragmentIndex + 1));
      } else {
        mainPart = withoutScheme;
      }

      String method;
      String password;
      String host;
      int port;
      String? plugin;
      Map<String, String>? pluginParams;
      final queryIndex = mainPart.indexOf('?');
      if (queryIndex != -1) {
        final queryString = mainPart.substring(queryIndex + 1);
        final params = Uri.splitQueryString(queryString);
        if (params.containsKey('plugin')) {
          final pluginStr = Uri.decodeComponent(params['plugin']!);
          final pluginParts = pluginStr.split(';');
          plugin = pluginParts.first;
          if (pluginParts.length > 1) {
            pluginParams = {};
            for (var i = 1; i < pluginParts.length; i++) {
              final pair = pluginParts[i].split('=');
              if (pair.length == 2) {
                pluginParams[pair[0]] = pair[1];
              }
            }
          }
        }
        
        mainPart = mainPart.substring(0, queryIndex);
      }
      if (mainPart.contains('@')) {
        final atIndex = mainPart.lastIndexOf('@');
        final userInfo = mainPart.substring(0, atIndex);
        final hostPort = mainPart.substring(atIndex + 1);
        final parsed = _parseHostPort(hostPort);
        host = parsed['host']!;
        port = int.parse(parsed['port']!);
        if (_isBase64(userInfo)) {
          final decoded = _decodeBase64(userInfo);
          final colonIndex = decoded.indexOf(':');
          if (colonIndex != -1) {
            method = decoded.substring(0, colonIndex);
            password = decoded.substring(colonIndex + 1);
          } else {
             method = 'chacha20-ietf-poly1305';
             password = decoded;
          }
        } else {
          final colonIndex = userInfo.indexOf(':');
          if (colonIndex != -1) {
            method = userInfo.substring(0, colonIndex);
            password = Uri.decodeComponent(userInfo.substring(colonIndex + 1));
          } else {
             return null;
          }
        }
      } else {
        final decoded = _decodeBase64(mainPart);
        final atIndex = decoded.lastIndexOf('@');
        if (atIndex == -1) return null;
        
        final userInfo = decoded.substring(0, atIndex);
        final hostPort = decoded.substring(atIndex + 1);

        final colonIndex = userInfo.indexOf(':');
        if (colonIndex != -1) {
          method = userInfo.substring(0, colonIndex);
          password = userInfo.substring(colonIndex + 1);
        } else {
           return null;
        }

        final parsed = _parseHostPort(hostPort);
        host = parsed['host']!;
        port = int.parse(parsed['port']!);
      }

      _logger.info('Parsed Shadowsocks URI: $uri');

      return _buildOutbound(
        method: method,
        password: password,
        address: host,
        port: port,
        remark: remark,
        plugin: plugin,
        pluginParams: pluginParams,
      );
    } catch (e) {
      _logger.warning('Failed to parse Shadowsocks URI: $e');
      return null;
    }
  }

  static bool _isBase64(String str) {
    try {
      final regex = RegExp(r'^[A-Za-z0-9+/=]+$');
      return regex.hasMatch(str) && !str.contains(':');
    } catch (_) {
      return false;
    }
  }

  static String _decodeBase64(String str) {
    final padded = str.padRight(str.length + (4 - str.length % 4) % 4, '=');
    return utf8.decode(base64.decode(padded));
  }

  static Map<String, String> _parseHostPort(String hostPort) {
    if (hostPort.startsWith('[')) {
      final closeBracket = hostPort.indexOf(']');
      final host = hostPort.substring(1, closeBracket);
      final portPart = hostPort.substring(closeBracket + 1);
      final port = portPart.startsWith(':') ? portPart.substring(1) : '443';
      return {'host': host, 'port': port};
    } else {
      final colonIndex = hostPort.lastIndexOf(':');
      if (colonIndex != -1) {
        return {
          'host': hostPort.substring(0, colonIndex),
          'port': hostPort.substring(colonIndex + 1),
        };
      }
      return {'host': hostPort, 'port': '443'};
    }
  }

  static Map<String, dynamic> _buildOutbound({
    required String method,
    required String password,
    required String address,
    required int port,
    String? remark,
    String? plugin,
    Map<String, String>? pluginParams,
  }) {
    final outbound = <String, dynamic>{
      'tag': 'proxy',
      'protocol': 'shadowsocks',
      'settings': {
        'servers': [
          {
            'address': address,
            'port': port,
            'method': method,
            'password': password,
            'level': 0,
          },
        ],
      },
      'streamSettings': {
        'network': 'raw',
        'security': 'none',
      },
    };

    if (plugin != null) {
       if (plugin == 'v2ray-plugin' || plugin == 'obfs-local') {
          outbound['plugin'] = plugin;
          outbound['plugin_opts'] = pluginParams;
       }
    }

    if (remark != null) {
      outbound['_remark'] = remark;
    }

    return outbound;
  }

  // Validate Shadowsocks config and return error message if invalid
  static String? validate(Map<String, dynamic>? config) {
    if (config == null) return 'Failed to parse Shadowsocks config';
    
    final settings = config['settings'] as Map<String, dynamic>?;
    if (settings == null) return 'Missing settings in Shadowsocks config';
    
    final servers = settings['servers'] as List?;
    if (servers == null || servers.isEmpty) return 'Missing servers in Shadowsocks config';
    
    final server = servers.first as Map<String, dynamic>?;
    if (server == null) return 'Invalid server in Shadowsocks config';
    
    final address = server['address'] as String?;
    if (address == null || address.isEmpty) return 'Missing server address in Shadowsocks config';
    
    final port = server['port'] as int?;
    if (port == null || port <= 0 || port > 65535) return 'Invalid port in Shadowsocks config';

    final method = server['method'] as String?;
    if (method == null || method.isEmpty) return 'Missing encryption method in Shadowsocks config';
    
    final password = server['password'] as String?;
    if (password == null || password.isEmpty) return 'Missing password in Shadowsocks config';
    
    return null; 
  }

  // Convert parsed config back to URI
  static String toUri(Map<String, dynamic> outbound) {
    try {
      final settings = outbound['settings'] as Map<String, dynamic>;
      final server = (settings['servers'] as List).first as Map<String, dynamic>;

      final method = server['method'] as String;
      final password = server['password'] as String;
      final address = server['address'] as String;
      final port = server['port'] as int;
      final remark = outbound['_remark'] as String? ?? 'SS';

      final userInfo = base64.encode(utf8.encode('$method:$password'));
      _logger.info('Generated Shadowsocks URI: ss://$userInfo@$address:$port#${Uri.encodeComponent(remark)}');
      return 'ss://$userInfo@$address:$port#${Uri.encodeComponent(remark)}';
    } catch (e) {
      _logger.warning('Failed to generate Shadowsocks URI: $e');
      return '';
    }
  }

  // Available Shadowsocks methods
  static const List<String> availableMethods = [
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
    'aes-128-gcm',
    'aes-256-gcm',
    'chacha20-ietf-poly1305',
    'xchacha20-ietf-poly1305',
    'aes-128-cfb',
    'aes-256-cfb',
    'chacha20',
    'chacha20-ietf',
    'rc4-md5',
  ];
}
