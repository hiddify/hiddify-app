/// Trojan protocol parser for Xray-core
class TrojanParser {
  /// Parse Trojan URI to outbound config
  /// Format: trojan://password@host:port?params#name
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('trojan://')) return null;

    try {
      final withoutScheme = uri.substring(9);
      final fragmentIndex = withoutScheme.indexOf('#');

      String mainPart;
      String? remark;

      if (fragmentIndex != -1) {
        mainPart = withoutScheme.substring(0, fragmentIndex);
        remark = Uri.decodeComponent(withoutScheme.substring(fragmentIndex + 1));
      } else {
        mainPart = withoutScheme;
      }

      final atIndex = mainPart.indexOf('@');
      if (atIndex == -1) return null;

      final password = mainPart.substring(0, atIndex);
      final rest = mainPart.substring(atIndex + 1);

      final queryIndex = rest.indexOf('?');
      String hostPort;
      var params = <String, String>{};

      if (queryIndex != -1) {
        hostPort = rest.substring(0, queryIndex);
        final queryString = rest.substring(queryIndex + 1);
        params = Uri.splitQueryString(queryString);
      } else {
        hostPort = rest;
      }

      // Parse host and port
      String host;
      int port;

      if (hostPort.startsWith('[')) {
        // IPv6
        final closeBracket = hostPort.indexOf(']');
        host = hostPort.substring(1, closeBracket);
        final portPart = hostPort.substring(closeBracket + 1);
        port = portPart.startsWith(':') ? int.parse(portPart.substring(1)) : 443;
      } else {
        final colonIndex = hostPort.lastIndexOf(':');
        if (colonIndex != -1) {
          host = hostPort.substring(0, colonIndex);
          port = int.parse(hostPort.substring(colonIndex + 1));
        } else {
          host = hostPort;
          port = 443;
        }
      }

      return _buildOutbound(
        password: password,
        address: host,
        port: port,
        remark: remark,
        params: params,
      );
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _buildOutbound({
    required String password,
    required String address,
    required int port,
    required Map<String, String> params,
    String? remark,
  }) {
    final security = params['security'] ?? 'tls';
    final type = params['type'] ?? 'tcp';
    final sni = params['sni'] ?? params['serverName'] ?? '';
    final fp = params['fp'] ?? params['fingerprint'] ?? 'chrome';
    final alpn = params['alpn'] ?? '';
    final path = params['path'] ?? '/';
    final host = params['host'] ?? '';
    final serviceName = params['serviceName'] ?? '';
    final mode = params['mode'] ?? 'gun';
    final headerType = params['headerType'] ?? 'none';

    final outbound = <String, dynamic>{
      'tag': 'proxy',
      'protocol': 'trojan',
      'settings': {
        'servers': [
          {
            'address': address,
            'port': port,
            'password': password,
            'level': 0,
          },
        ],
      },
      'streamSettings': _buildStreamSettings(
        network: type,
        security: security,
        sni: sni.isNotEmpty ? sni : address,
        fingerprint: fp,
        alpn: alpn,
        path: path,
        host: host,
        serviceName: serviceName,
        mode: mode,
        headerType: headerType,
      ),
    };

    if (remark != null) {
      outbound['_remark'] = remark;
    }

    return outbound;
  }

  static Map<String, dynamic> _buildStreamSettings({
    required String network,
    required String security,
    required String sni,
    required String fingerprint,
    String? alpn,
    String? path,
    String? host,
    String? serviceName,
    String? mode,
    String? headerType,
  }) {
    final streamSettings = <String, dynamic>{
      'network': network == 'tcp' ? 'raw' : network,
      'security': security,
    };

    if (security == 'tls') {
      streamSettings['tlsSettings'] = {
        'serverName': sni,
        'fingerprint': fingerprint,
        'allowInsecure': false,
        if (alpn != null && alpn.isNotEmpty)
          'alpn': alpn.split(',').map((e) => e.trim()).toList(),
      };
    }

    if (security == 'reality') {
      const pbk = '';
      const sid = '';
      streamSettings['realitySettings'] = {
        'serverName': sni,
        'fingerprint': fingerprint,
        'publicKey': pbk,
        'shortId': sid,
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
          'serviceName': serviceName ?? '',
          'multiMode': mode == 'multi',
        };
      case 'http':
      case 'h2':
        streamSettings['httpSettings'] = {
          'path': path ?? '/',
          if (host != null && host.isNotEmpty) 'host': [host],
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
      final server = (settings['servers'] as List).first as Map<String, dynamic>;
      final streamSettings = outbound['streamSettings'] as Map<String, dynamic>;

      final password = server['password'] as String;
      final address = server['address'] as String;
      final port = server['port'] as int;

      final network = streamSettings['network'] as String? ?? 'tcp';
      final security = streamSettings['security'] as String? ?? 'tls';

      final params = <String, String>{
        'type': network == 'raw' ? 'tcp' : network,
        'security': security,
      };

      if (security == 'tls' && streamSettings['tlsSettings'] != null) {
        final tls = streamSettings['tlsSettings'] as Map<String, dynamic>;
        if (tls['serverName'] != null) params['sni'] = tls['serverName'] as String;
        if (tls['fingerprint'] != null) params['fp'] = tls['fingerprint'] as String;
        if (tls['alpn'] != null) params['alpn'] = (tls['alpn'] as List).join(',');
      }

      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final remark = outbound['_remark'] as String? ?? 'Trojan';

      return 'trojan://$password@$address:$port?$queryString#${Uri.encodeComponent(remark)}';
    } catch (e) {
      return '';
    }
  }
}
