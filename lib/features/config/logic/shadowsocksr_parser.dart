import 'dart:convert';

import 'package:hiddify/core/logger/logger.dart';

 // ShadowsocksR (SSR) protocol parser
 // SSR uses a custom URI format with base64 encoding
class ShadowsocksRParser {
  // Parse SSR URI
  // Format: ssr://base64(host:port:protocol:method:obfs:base64(password)/?params)
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('ssr://')) return null;

    try {
      final encoded = uri.substring(6);
      var decoded = encoded.replaceAll('-', '+').replaceAll('_', '/');
      final padding = decoded.length % 4;
      if (padding > 0) {
        decoded += '=' * (4 - padding);
      }
      
      final decodedBytes = base64Decode(decoded);
      final decodedStr = utf8.decode(decodedBytes);
      final paramsIndex = decodedStr.indexOf('/?');
      String mainPart;
      var params = <String, String>{};
      
      if (paramsIndex != -1) {
        mainPart = decodedStr.substring(0, paramsIndex);
        final queryString = decodedStr.substring(paramsIndex + 2);
        params = Uri.splitQueryString(queryString);
      } else {
        mainPart = decodedStr;
      }
      
      final parts = mainPart.split(':');
      if (parts.length < 6) return null;
      
      final host = parts[0];
      final port = int.parse(parts[1]);
      final protocol = parts[2];
      final method = parts[3];
      final obfs = parts[4];
      final passwordBase64 = parts[5];
      final password = _decodeBase64Safe(passwordBase64);
      final protocolParam = params.containsKey('protoparam') 
          ? _decodeBase64Safe(params['protoparam']!) 
          : '';
      final obfsParam = params.containsKey('obfsparam') 
          ? _decodeBase64Safe(params['obfsparam']!) 
          : '';
      final remark = params.containsKey('remarks') 
          ? _decodeBase64Safe(params['remarks']!) 
          : null;
      final group = params.containsKey('group') 
          ? _decodeBase64Safe(params['group']!) 
          : null;

      return _buildConfig(
        server: host,
        port: port,
        password: password,
        method: method,
        protocol: protocol,
        protocolParam: protocolParam,
        obfs: obfs,
        obfsParam: obfsParam,
        remark: remark,
        group: group,
      );
    } catch (e) {
      Logger.ssr.warning('Failed to parse SSR URI: $e');
      return null;
    }
  }

  static String _decodeBase64Safe(String input) {
    try {
      var decoded = input.replaceAll('-', '+').replaceAll('_', '/');
      final padding = decoded.length % 4;
      if (padding > 0) {
        decoded += '=' * (4 - padding);
      }
      return utf8.decode(base64Decode(decoded));
    } catch (_) {
      return input;
    }
  }

  static String _encodeBase64Safe(String input) => base64Encode(utf8.encode(input))
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');

  static Map<String, dynamic> _buildConfig({
    required String server,
    required int port,
    required String password,
    required String method,
    required String protocol,
    required String protocolParam,
    required String obfs,
    required String obfsParam,
    String? remark,
    String? group,
  }) {
    final config = <String, dynamic>{
      'tag': 'proxy',
      '_protocol': 'shadowsocksr',
      '_type': 'external',
      'server': server,
      'port': port,
      'password': password,
      'method': method,
      'protocol': protocol,
      'protocolParam': protocolParam,
      'obfs': obfs,
      'obfsParam': obfsParam,
    };

    if (remark != null && remark.isNotEmpty) {
      config['_remark'] = remark;
    }

    if (group != null && group.isNotEmpty) {
      config['_group'] = group;
    }

    return config;
  }

  // Validate SSR config and return error message if invalid
  static String? validate(Map<String, dynamic>? config) {
    if (config == null) return 'Failed to parse SSR config';
    
    final protocol = config['_protocol'] as String?;
    if (protocol != 'shadowsocksr') {
      return 'Invalid SSR protocol type';
    }
    
    final server = config['server'] as String?;
    if (server == null || server.isEmpty) return 'Missing server address in SSR config';
    
    final port = config['port'] as int?;
    if (port == null || port <= 0 || port > 65535) return 'Invalid port in SSR config';
    
    final password = config['password'] as String?;
    if (password == null || password.isEmpty) return 'Missing password in SSR config';
    
    final method = config['method'] as String?;
    if (method == null || method.isEmpty) return 'Missing encryption method in SSR config';
    final supportedMethods = [
      'none', 'table', 'rc4', 'rc4-md5', 'rc4-md5-6',
      'aes-128-cfb', 'aes-192-cfb', 'aes-256-cfb',
      'aes-128-ctr', 'aes-192-ctr', 'aes-256-ctr',
      'bf-cfb', 'camellia-128-cfb', 'camellia-192-cfb', 'camellia-256-cfb',
      'cast5-cfb', 'des-cfb', 'idea-cfb', 'seed-cfb',
      'salsa20', 'chacha20', 'chacha20-ietf',
    ];
    
    if (!supportedMethods.contains(method.toLowerCase())) {
      return 'Unsupported encryption method: $method';
    }
    
    return null; 
  }

  // Convert config back to URI
  static String toUri(Map<String, dynamic> config) {
    try {
      final server = config['server'] as String;
      final port = config['port'] as int;
      final password = config['password'] as String;
      final method = config['method'] as String;
      final protocol = config['protocol'] as String? ?? 'origin';
      final protocolParam = config['protocolParam'] as String? ?? '';
      final obfs = config['obfs'] as String? ?? 'plain';
      final obfsParam = config['obfsParam'] as String? ?? '';
      final remark = config['_remark'] as String? ?? 'SSR';
      final group = config['_group'] as String? ?? '';
      final passwordB64 = _encodeBase64Safe(password);
      final mainPart = '$server:$port:$protocol:$method:$obfs:$passwordB64';
      final params = <String>[];
      if (protocolParam.isNotEmpty) {
        params.add('protoparam=${_encodeBase64Safe(protocolParam)}');
      }
      if (obfsParam.isNotEmpty) {
        params.add('obfsparam=${_encodeBase64Safe(obfsParam)}');
      }
      if (remark.isNotEmpty) {
        params.add('remarks=${_encodeBase64Safe(remark)}');
      }
      if (group.isNotEmpty) {
        params.add('group=${_encodeBase64Safe(group)}');
      }

      var fullStr = mainPart;
      if (params.isNotEmpty) {
        fullStr += '/?${params.join('&')}';
      }

      return 'ssr://${_encodeBase64Safe(fullStr)}';
    } catch (e) {
      Logger.ssr.warning('Failed to generate SSR URI: $e');
      return '';
    }
  }

  // Available SSR protocols
  static const List<String> availableProtocols = [
    'origin',
    'verify_deflate',
    'auth_sha1_v4',
    'auth_aes128_md5',
    'auth_aes128_sha1',
    'auth_chain_a',
    'auth_chain_b',
    'auth_chain_c',
    'auth_chain_d',
    'auth_chain_e',
    'auth_chain_f',
  ];

  // Available SSR obfuscations
  static const List<String> availableObfs = [
    'plain',
    'http_simple',
    'http_post',
    'random_head',
    'tls1.2_ticket_auth',
    'tls1.2_ticket_fastauth',
  ];

  // Available SSR encryption methods
  static const List<String> availableMethods = [
    'none',
    'table',
    'rc4',
    'rc4-md5',
    'rc4-md5-6',
    'aes-128-cfb',
    'aes-192-cfb',
    'aes-256-cfb',
    'aes-128-ctr',
    'aes-192-ctr',
    'aes-256-ctr',
    'bf-cfb',
    'camellia-128-cfb',
    'camellia-192-cfb',
    'camellia-256-cfb',
    'salsa20',
    'chacha20',
    'chacha20-ietf',
  ];
}
