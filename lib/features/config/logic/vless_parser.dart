
import 'package:hiddify/core/logger/logger.dart';

 // VLESS protocol parser for Xray-core
 // Supports VLESS, VLESS+TLS, VLESS+REALITY, VLESS+XTLS
class VlessParser {
  // Parse VLESS URI to outbound config
  // Format: vless://uuid@host:port?params#name
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('vless://')) return null;

    try {
      final withoutScheme = uri.substring(8);
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

      final uuid = mainPart.substring(0, atIndex);
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
      String host;
      int port;
      
      if (hostPort.startsWith('[')) {
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
        uuid: uuid,
        address: host,
        port: port,
        remark: remark,
        params: params,
      );
    } catch (e) {
      Logger.vless.warning('Failed to parse VLESS URI: $e');
      return null;
    }
  }

  static Map<String, dynamic> _buildOutbound({
    required String uuid,
    required String address,
    required int port,
    required Map<String, String> params,
    String? remark,
  }) {
    final encryption = params['encryption'] ?? 'none';
    final flow = params['flow'] ?? '';
    final security = params['security'] ?? 'none';
    final type = params['type'] ?? 'tcp';
    final sni = params['sni'] ?? params['serverName'] ?? params['peer'] ?? '';
    final fp = params['fp'] ?? params['fingerprint'] ?? 'chrome';
    final alpn = params['alpn'] ?? '';
    final pbk = params['pbk'] ?? params['publicKey'] ?? params['public_key'] ?? '';
    final sid = params['sid'] ?? params['shortId'] ?? params['short_id'] ?? '';
    final spx = params['spx'] ?? params['spiderX'] ?? params['spider_x'] ?? '';
    final path = params['path'] ?? '/';
    final host = params['host'] ?? '';
    final serviceName = params['serviceName'] ?? '';
    final mode = params['mode'] ?? 'gun';
    final headerType = params['headerType'] ?? 'none';
    final seed = params['seed'] ?? '';

    final outbound = <String, dynamic>{
      'tag': 'proxy',
      'protocol': 'vless',
      'settings': {
        'vnext': [
          {
            'address': address,
            'port': port,
            'users': [
              {
                'id': uuid,
                'encryption': encryption,
                'flow': flow,
                'level': 0,
              },
            ],
          },
        ],
      },
      'streamSettings': _buildStreamSettings(
        network: type,
        security: security,
        sni: sni.isNotEmpty ? sni : address,
        fingerprint: fp,
        alpn: alpn,
        publicKey: pbk,
        shortId: sid,
        spiderX: spx,
        path: path,
        host: host,
        serviceName: serviceName,
        mode: mode,
        headerType: headerType,
        seed: seed,
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
    String? publicKey,
    String? shortId,
    String? spiderX,
    String? path,
    String? host,
    String? serviceName,
    String? mode,
    String? headerType,
    String? seed,
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
      streamSettings['realitySettings'] = {
        'serverName': sni,
        'fingerprint': fingerprint,
        'publicKey': publicKey ?? '',
        'shortId': shortId ?? '',
        if (spiderX != null && spiderX.isNotEmpty) 'spiderX': spiderX,
      };
    }
    switch (network) {
      case 'ws':
        streamSettings['wsSettings'] = {
          'path': path ?? '/',
          if (host != null && host.isNotEmpty)
            'headers': {'Host': host},
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
      case 'httpupgrade':
        streamSettings['httpupgradeSettings'] = {
          'path': path ?? '/',
          if (host != null && host.isNotEmpty) 'host': host,
        };
      case 'kcp':
        streamSettings['kcpSettings'] = {
          'header': {'type': headerType ?? 'none'},
          if (seed != null && seed.isNotEmpty) 'seed': seed,
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

  // Validate VLESS config and return error message if invalid
  static String? validate(Map<String, dynamic>? config) {
    if (config == null) return 'Failed to parse VLESS config';
    
    final settings = config['settings'] as Map<String, dynamic>?;
    if (settings == null) return 'Missing settings in VLESS config';
    
    final vnext = settings['vnext'] as List?;
    if (vnext == null || vnext.isEmpty) return 'Missing vnext in VLESS config';
    
    final server = vnext.first as Map<String, dynamic>?;
    if (server == null) return 'Invalid server in VLESS config';
    
    final address = server['address'] as String?;
    if (address == null || address.isEmpty) return 'Missing server address in VLESS config';
    
    final users = server['users'] as List?;
    if (users == null || users.isEmpty) return 'Missing users in VLESS config';
    
    final user = users.first as Map<String, dynamic>?;
    if (user == null) return 'Invalid user in VLESS config';
    
    final uuid = user['id'] as String?;
    if (uuid == null || uuid.isEmpty) return 'Missing UUID in VLESS config';
    try {
      if (!RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(uuid)) {
        return 'Invalid UUID format in VLESS config';
      }
    } catch (_) {}

    final port = server['port'] as int?;
    if (port == null || port < 1 || port > 65535) return 'Invalid port number in VLESS config';
    
    return null; 
  }

  // Convert parsed config back to URI
  static String toUri(Map<String, dynamic> outbound) {
    try {
      final settings = outbound['settings'] as Map<String, dynamic>;
      final vnext = (settings['vnext'] as List).first as Map<String, dynamic>;
      final user = (vnext['users'] as List).first as Map<String, dynamic>;
      final streamSettings = outbound['streamSettings'] as Map<String, dynamic>;

      final uuid = user['id'] as String;
      final address = vnext['address'] as String;
      final port = vnext['port'] as int;
      final encryption = user['encryption'] as String? ?? 'none';
      final flow = user['flow'] as String? ?? '';

      final network = streamSettings['network'] as String? ?? 'tcp';
      final security = streamSettings['security'] as String? ?? 'none';

      final params = <String, String>{
        'encryption': encryption,
        'type': network == 'raw' ? 'tcp' : network,
        'security': security,
      };

      if (flow.isNotEmpty) {
        params['flow'] = flow;
      }
      if (security == 'tls' && streamSettings['tlsSettings'] != null) {
        final tls = streamSettings['tlsSettings'] as Map<String, dynamic>;
        if (tls['serverName'] != null) params['sni'] = tls['serverName'] as String;
        if (tls['fingerprint'] != null) params['fp'] = tls['fingerprint'] as String;
        if (tls['alpn'] != null) params['alpn'] = (tls['alpn'] as List).join(',');
      }
      if (security == 'reality' && streamSettings['realitySettings'] != null) {
        final reality = streamSettings['realitySettings'] as Map<String, dynamic>;
        if (reality['serverName'] != null) params['sni'] = reality['serverName'] as String;
        if (reality['fingerprint'] != null) params['fp'] = reality['fingerprint'] as String;
        if (reality['publicKey'] != null) params['pbk'] = reality['publicKey'] as String;
        if (reality['shortId'] != null) params['sid'] = reality['shortId'] as String;
        if (reality['spiderX'] != null) params['spx'] = reality['spiderX'] as String;
      }

      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final remark = outbound['_remark'] as String? ?? 'VLESS';

      return 'vless://$uuid@$address:$port?$queryString#${Uri.encodeComponent(remark)}';
    } catch (e) {
      Logger.vless.warning('Failed to generate VLESS URI: $e');
      return '';
    }
  }
}
