import 'package:hiddify/core/logger/logger.dart';






class WireguardParser {
  
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('wg://') && !uri.startsWith('wireguard://')) {
      return null;
    }

    try {
      final schemeEnd = uri.indexOf('://') + 3;
      final withoutScheme = uri.substring(schemeEnd);
      final fragmentIndex = withoutScheme.indexOf('#');

      String mainPart;
      String? remark;

      if (fragmentIndex != -1) {
        mainPart = withoutScheme.substring(0, fragmentIndex);
        remark = Uri.decodeComponent(
          withoutScheme.substring(fragmentIndex + 1),
        );
      } else {
        mainPart = withoutScheme;
      }
      if (mainPart.contains('endpoint=') || mainPart.contains('privateKey=')) {
        return _parseAlternativeFormat(mainPart, remark);
      }

      final atIndex = mainPart.indexOf('@');
      if (atIndex == -1) {
        return _parseAlternativeFormat(mainPart, remark);
      }

      final privateKey = Uri.decodeComponent(mainPart.substring(0, atIndex));
      if (privateKey.isEmpty) return null;

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
      final (host, port) = _parseHostPort(hostPort);
      if (host.isEmpty) return null;

      return _buildOutbound(
        privateKey: privateKey,
        address: host,
        port: port,
        remark: remark,
        params: params,
      );
    } catch (e) {
      return null;
    }
  }

  
  static Map<String, dynamic>? _parseAlternativeFormat(
    String content,
    String? remark,
  ) {
    try {
      final params = Uri.splitQueryString(content);

      final privateKey =
          params['privateKey'] ??
          params['private_key'] ??
          params['secretKey'] ??
          '';
      if (privateKey.isEmpty) return null;

      final endpoint = params['endpoint'] ?? params['server'] ?? '';
      if (endpoint.isEmpty) return null;

      final (host, port) = _parseHostPort(endpoint);
      if (host.isEmpty) return null;

      return _buildOutbound(
        privateKey: privateKey,
        address: host,
        port: port,
        remark: remark,
        params: params,
      );
    } catch (e) {
      return null;
    }
  }

  
  static (String host, int port) _parseHostPort(String hostPort) {
    if (hostPort.isEmpty) return ('', 51820);

    String host;
    var port = 51820;

    if (hostPort.startsWith('[')) {
      final closeBracket = hostPort.indexOf(']');
      if (closeBracket == -1) return ('', 51820);
      host = hostPort.substring(1, closeBracket);
      final portPart = hostPort.substring(closeBracket + 1);
      if (portPart.startsWith(':') && portPart.length > 1) {
        port = int.tryParse(portPart.substring(1)) ?? 51820;
      }
    } else {
      final colonIndex = hostPort.lastIndexOf(':');
      if (colonIndex != -1) {
        host = hostPort.substring(0, colonIndex);
        port = int.tryParse(hostPort.substring(colonIndex + 1)) ?? 51820;
      } else {
        host = hostPort;
      }
    }

    return (host, port);
  }

  static Map<String, dynamic> _buildOutbound({
    required String privateKey,
    required String address,
    required int port,
    required Map<String, String> params,
    String? remark,
  }) {
    final publicKey =
        params['publicKey'] ??
        params['pk'] ??
        params['public_key'] ??
        params['peer_public_key'] ??
        '';
    final localAddress =
        params['address'] ??
        params['local'] ??
        params['local_address'] ??
        params['ip'] ??
        '';
    final mtu = int.tryParse(params['mtu'] ?? '') ?? 1420;
    final reserved = params['reserved'] ?? params['clientId'] ?? '';
    final workers = int.tryParse(params['workers'] ?? '') ?? 2;
    final presharedKey =
        params['presharedKey'] ?? params['presharedkey'] ?? params['psk'] ?? '';
    final keepAlive =
        int.tryParse(params['keepAlive'] ?? params['keepalive'] ?? '') ?? 0;
    final noise = params['wnoise'] ?? params['noise'] ?? '';
    final noiseDelay = params['wnoisedelay'] ?? params['noisedelay'] ?? '';
    final noiseCount = params['wnoisecount'] ?? params['noisecount'] ?? '';
    final payloadSize = params['wpayloadsize'] ?? params['payloadsize'] ?? '';
    final addresses = <String>[];
    if (localAddress.isNotEmpty) {
      for (final addr in localAddress.split(',')) {
        var trimmed = addr.trim();
        if (!trimmed.contains('/')) {
          trimmed = trimmed.contains(':') ? '$trimmed/128' : '$trimmed/32';
        }
        addresses.add(trimmed);
      }
    }
    if (privateKey.isEmpty || address.isEmpty) {
      return <String, dynamic>{
        '_error': 'Missing required fields: privateKey or server address',
      };
    }

    final outbound = <String, dynamic>{
      'tag': 'proxy',
      'protocol': 'wireguard',
      'settings': {
        'secretKey': privateKey,
        'address': addresses.isNotEmpty ? addresses : ['10.0.0.2/32'],
        'peers': [
          {
            'endpoint': '$address:$port',
            'publicKey': publicKey,
            if (presharedKey.isNotEmpty) 'presharedKey': presharedKey,
            if (keepAlive > 0) 'keepAlive': keepAlive,
          },
        ],
        'mtu': mtu,
        'workers': workers,
        if (noise.isNotEmpty) 'noise': noise,
        if (noiseDelay.isNotEmpty) 'noiseDelay': noiseDelay,
        if (noiseCount.isNotEmpty) 'noiseCount': noiseCount,
        if (payloadSize.isNotEmpty) 'payloadSize': payloadSize,
      },
    };
    if (reserved.isNotEmpty) {
      List<int>? reservedList;
      if (reserved.contains(',')) {
        reservedList = reserved
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .toList();
      } else if (reserved.length >= 4) {
        try {
          reservedList = reserved.codeUnits.take(3).toList();
        } catch (_) {}
      }

      if (reservedList != null && reservedList.length >= 3) {
        (outbound['settings'] as Map)['reserved'] = reservedList
            .take(3)
            .toList();
      }
    }

    if (remark != null) {
      outbound['_remark'] = remark;
    }

    return outbound;
  }

  
  static String? validate(Map<String, dynamic>? config) {
    if (config == null) return 'Failed to parse WireGuard config';
    if (config.containsKey('_error')) return config['_error'] as String;

    final settings = config['settings'] as Map<String, dynamic>?;
    if (settings == null) return 'Missing settings in WireGuard config';

    final secretKey = settings['secretKey'] as String?;
    if (secretKey == null || secretKey.isEmpty) {
      return 'Missing privateKey in WireGuard config';
    }

    final peers = settings['peers'] as List?;
    if (peers == null || peers.isEmpty) {
      return 'Missing peers in WireGuard config';
    }

    final peer = peers.first as Map<String, dynamic>?;
    if (peer == null) return 'Invalid peer in WireGuard config';

    final endpoint = peer['endpoint'] as String?;
    if (endpoint == null || endpoint.isEmpty || endpoint == ':51820') {
      return 'Missing or invalid endpoint in WireGuard config';
    }

    final publicKey = peer['publicKey'] as String?;
    if (publicKey == null || publicKey.isEmpty) {
      return 'Missing publicKey in WireGuard config';
    }

    return null; 
  }

  
  static String toUri(Map<String, dynamic> outbound) {
    try {
      final settings = outbound['settings'] as Map<String, dynamic>;
      final privateKey = settings['secretKey'] as String;
      final peers = settings['peers'] as List;
      final peer = peers.first as Map<String, dynamic>;
      final endpoint = peer['endpoint'] as String;
      final publicKey = peer['publicKey'] as String;
      final presharedKey = peer['presharedKey'] as String? ?? '';
      final keepAlive = peer['keepAlive'] as int? ?? 0;

      final addresses = settings['address'] as List?;
      final mtu = settings['mtu'] as int? ?? 1420;
      final reserved = settings['reserved'] as List?;

      final noise = settings['noise'] as String? ?? '';
      final noiseDelay = settings['noiseDelay'] as String? ?? '';
      final noiseCount = settings['noiseCount'] as String? ?? '';
      final payloadSize = settings['payloadSize'] as String? ?? '';

      final params = <String, String>{'publicKey': publicKey};

      if (presharedKey.isNotEmpty) params['presharedKey'] = presharedKey;
      if (keepAlive > 0) params['keepAlive'] = keepAlive.toString();

      if (addresses != null && addresses.isNotEmpty) {
        params['address'] = addresses.join(',');
      }

      params['mtu'] = mtu.toString();

      if (reserved != null && reserved.length == 3) {
        params['reserved'] = reserved.join(',');
      }

      if (noise.isNotEmpty) params['wnoise'] = noise;
      if (noiseDelay.isNotEmpty) params['wnoisedelay'] = noiseDelay;
      if (noiseCount.isNotEmpty) params['wnoisecount'] = noiseCount;
      if (payloadSize.isNotEmpty) params['wpayloadsize'] = payloadSize;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final remark = outbound['_remark'] as String? ?? 'WireGuard';

      Logger.wireguard.warning('Generated WireGuard URI');
      return 'wg://${Uri.encodeComponent(privateKey)}@$endpoint?$queryString#${Uri.encodeComponent(remark)}';
    } catch (e) {
      Logger.wireguard.warning('Failed to generate WireGuard URI: $e');
      return '';
    }
  }
}
