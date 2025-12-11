import 'dart:convert';

/// VMess protocol parser for Xray-core
class VmessParser {
  /// Parse VMess URI to outbound config
  /// Format: vmess://base64_json or vmess://base64_json#name
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('vmess://')) return null;

    try {
      var base64Part = uri.substring(8);
      String? remark;

      // Check for fragment
      final fragmentIndex = base64Part.indexOf('#');
      if (fragmentIndex != -1) {
        remark = Uri.decodeComponent(base64Part.substring(fragmentIndex + 1));
        base64Part = base64Part.substring(0, fragmentIndex);
      }

      // Decode base64
      final padded = base64Part.padRight(
        base64Part.length + (4 - base64Part.length % 4) % 4,
        '=',
      );
      final decoded = utf8.decode(base64.decode(padded));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      return _buildOutbound(json, remark);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _buildOutbound(
    Map<String, dynamic> json,
    String? remarkOverride,
  ) {
    final uuid = json['id'] as String? ?? '';
    final address = json['add'] as String? ?? '';
    final port = _parseInt(json['port']) ?? 443;
    final alterId = _parseInt(json['aid']) ?? 0;
    final security = json['scy'] as String? ?? 'auto';
    final network = json['net'] as String? ?? 'tcp';
    final type = json['type'] as String? ?? 'none';
    final host = json['host'] as String? ?? '';
    final path = json['path'] as String? ?? '/';
    final tls = json['tls'] as String? ?? '';
    final sni = json['sni'] as String? ?? '';
    final alpn = json['alpn'] as String? ?? '';
    final fp = json['fp'] as String? ?? 'chrome';
    final remark = remarkOverride ?? json['ps'] as String? ?? 'VMess';

    final outbound = <String, dynamic>{
      'tag': 'proxy',
      'protocol': 'vmess',
      'settings': {
        'vnext': [
          {
            'address': address,
            'port': port,
            'users': [
              {
                'id': uuid,
                'alterId': alterId,
                'security': security,
                'level': 0,
              },
            ],
          },
        ],
      },
      'streamSettings': _buildStreamSettings(
        network: network,
        tls: tls,
        sni: sni.isNotEmpty ? sni : address,
        fingerprint: fp,
        alpn: alpn,
        path: path,
        host: host,
        headerType: type,
      ),
      '_remark': remark,
    };

    return outbound;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Map<String, dynamic> _buildStreamSettings({
    required String network,
    required String tls,
    required String sni,
    required String fingerprint,
    String? alpn,
    String? path,
    String? host,
    String? headerType,
  }) {
    final streamSettings = <String, dynamic>{
      'network': network == 'tcp' ? 'raw' : network,
      'security': tls == 'tls' ? 'tls' : 'none',
    };

    if (tls == 'tls') {
      streamSettings['tlsSettings'] = {
        'serverName': sni,
        'fingerprint': fingerprint,
        'allowInsecure': false,
        if (alpn != null && alpn.isNotEmpty)
          'alpn': alpn.split(',').map((e) => e.trim()).toList(),
      };
    }

    switch (network) {
      case 'ws':
        streamSettings['wsSettings'] = {
          'path': path ?? '/',
          if (host != null && host.isNotEmpty) 'headers': {'Host': host},
        };
      case 'grpc':
        streamSettings['grpcSettings'] = {
          'serviceName': path ?? '',
        };
      case 'http':
      case 'h2':
        streamSettings['httpSettings'] = {
          'path': path ?? '/',
          if (host != null && host.isNotEmpty) 'host': [host],
        };
      case 'kcp':
        streamSettings['kcpSettings'] = {
          'header': {'type': headerType ?? 'none'},
        };
      case 'quic':
        streamSettings['quicSettings'] = {
          'security': 'none',
          'header': {'type': headerType ?? 'none'},
        };
      case 'tcp':
      case 'raw':
        if (headerType == 'http') {
          streamSettings['rawSettings'] = {
            'header': {
              'type': 'http',
              'request': {
                'path': [path ?? '/'],
                'headers': {
                  'Host': [host ?? ''],
                },
              },
            },
          };
        }
    }

    return streamSettings;
  }

  /// Convert parsed config back to URI
  static String toUri(Map<String, dynamic> outbound) {
    try {
      final settings = outbound['settings'] as Map<String, dynamic>;
      final vnext = (settings['vnext'] as List).first as Map<String, dynamic>;
      final user = (vnext['users'] as List).first as Map<String, dynamic>;
      final streamSettings = outbound['streamSettings'] as Map<String, dynamic>;

      final json = <String, dynamic>{
        'v': '2',
        'ps': outbound['_remark'] ?? 'VMess',
        'add': vnext['address'],
        'port': vnext['port'].toString(),
        'id': user['id'],
        'aid': (user['alterId'] ?? 0).toString(),
        'scy': user['security'] ?? 'auto',
        'net': streamSettings['network'] == 'raw' ? 'tcp' : streamSettings['network'],
        'type': 'none',
        'host': '',
        'path': '',
        'tls': streamSettings['security'] == 'tls' ? 'tls' : '',
        'sni': '',
        'alpn': '',
        'fp': 'chrome',
      };

      // Extract TLS settings
      if (streamSettings['tlsSettings'] != null) {
        final tls = streamSettings['tlsSettings'] as Map<String, dynamic>;
        json['sni'] = tls['serverName'] ?? '';
        json['fp'] = tls['fingerprint'] ?? 'chrome';
        if (tls['alpn'] != null) {
          json['alpn'] = (tls['alpn'] as List).join(',');
        }
      }

      // Extract transport settings
      final network = streamSettings['network'] as String? ?? 'tcp';
      switch (network) {
        case 'ws':
          if (streamSettings['wsSettings'] != null) {
            final ws = streamSettings['wsSettings'] as Map<String, dynamic>;
            json['path'] = ws['path'] ?? '/';
            if (ws['headers'] != null) {
              json['host'] = (ws['headers'] as Map)['Host'] ?? '';
            }
          }
        case 'grpc':
          if (streamSettings['grpcSettings'] != null) {
            final grpc = streamSettings['grpcSettings'] as Map<String, dynamic>;
            json['path'] = grpc['serviceName'] ?? '';
          }
      }

      final jsonStr = jsonEncode(json);
      final base64Str = base64.encode(utf8.encode(jsonStr));
      return 'vmess://$base64Str';
    } catch (e) {
      return '';
    }
  }
}
