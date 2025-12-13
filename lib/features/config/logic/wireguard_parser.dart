/// WireGuard protocol parser for Xray-core
class WireguardParser {
  /// Parse WireGuard URI to outbound config
  /// Format: wg://privateKey@host:port?publicKey=xxx&address=xxx&mtu=xxx#name
  /// or: wireguard://privateKey@host:port?...
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('wg://') && !uri.startsWith('wireguard://')) return null;

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

      final atIndex = mainPart.indexOf('@');
      if (atIndex == -1) return null;

      final privateKey = Uri.decodeComponent(mainPart.substring(0, atIndex));
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
        final closeBracket = hostPort.indexOf(']');
        host = hostPort.substring(1, closeBracket);
        final portPart = hostPort.substring(closeBracket + 1);
        port = portPart.startsWith(':') ? int.parse(portPart.substring(1)) : 51820;
      } else {
        final colonIndex = hostPort.lastIndexOf(':');
        if (colonIndex != -1) {
          host = hostPort.substring(0, colonIndex);
          port = int.parse(hostPort.substring(colonIndex + 1));
        } else {
          host = hostPort;
          port = 51820;
        }
      }

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

  static Map<String, dynamic> _buildOutbound({
    required String privateKey,
    required String address,
    required int port,
    required Map<String, String> params,
    String? remark,
  }) {
    final publicKey = params['publicKey'] ?? params['pk'] ?? '';
    final localAddress = params['address'] ?? params['local'] ?? '';
    final mtu = int.tryParse(params['mtu'] ?? '') ?? 1420;
    final reserved = params['reserved'] ?? '';
    final workers = int.tryParse(params['workers'] ?? '') ?? 2;

    // Parse local addresses
    final addresses = <String>[];
    if (localAddress.isNotEmpty) {
      addresses.addAll(localAddress.split(',').map((e) => e.trim()));
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
          },
        ],
        'mtu': mtu,
        'workers': workers,
      },
    };

    // Parse reserved bytes
    if (reserved.isNotEmpty) {
      final reservedList = reserved.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (reservedList.length == 3) {
        (outbound['settings'] as Map)['reserved'] = reservedList;
      }
    }

    if (remark != null) {
      outbound['_remark'] = remark;
    }

    return outbound;
  }

  /// Convert parsed config back to URI
  static String toUri(Map<String, dynamic> outbound) {
    try {
      final settings = outbound['settings'] as Map<String, dynamic>;
      final privateKey = settings['secretKey'] as String;
      final peers = settings['peers'] as List;
      final peer = peers.first as Map<String, dynamic>;
      final endpoint = peer['endpoint'] as String;
      final publicKey = peer['publicKey'] as String;
      final addresses = settings['address'] as List?;
      final mtu = settings['mtu'] as int? ?? 1420;
      final reserved = settings['reserved'] as List?;

      final params = <String, String>{
        'publicKey': publicKey,
      };

      if (addresses != null && addresses.isNotEmpty) {
        params['address'] = addresses.join(',');
      }

      params['mtu'] = mtu.toString();

      if (reserved != null && reserved.length == 3) {
        params['reserved'] = reserved.join(',');
      }

      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final remark = outbound['_remark'] as String? ?? 'WireGuard';

      return 'wg://${Uri.encodeComponent(privateKey)}@$endpoint?$queryString#${Uri.encodeComponent(remark)}';
    } catch (e) {
      return '';
    }
  }
}
