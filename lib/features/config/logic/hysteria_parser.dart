/// Hysteria2 protocol parser
/// Note: Hysteria2 is not natively supported by Xray-core
/// This parser generates a compatible format for external handling
class HysteriaParser {
  /// Parse Hysteria2 URI
  /// Format: hysteria2://auth@host:port?params#name
  /// or: hy2://auth@host:port?params#name
  static Map<String, dynamic>? parse(String uri) {
    final isHy2 = uri.startsWith('hy2://') || uri.startsWith('hysteria2://');
    final isHy1 = uri.startsWith('hysteria://');

    if (!isHy2 && !isHy1) return null;

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

      final auth = Uri.decodeComponent(mainPart.substring(0, atIndex));
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

      return _buildConfig(
        auth: auth,
        address: host,
        port: port,
        remark: remark,
        params: params,
        isHy2: isHy2,
      );
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _buildConfig({
    required String auth,
    required String address,
    required int port,
    required Map<String, String> params,
    required bool isHy2,
    String? remark,
  }) {
    final sni = params['sni'] ?? params['peer'] ?? '';
    final insecure = params['insecure'] == '1' || params['allowInsecure'] == '1';
    final obfs = params['obfs'] ?? '';
    final obfsPassword = params['obfs-password'] ?? '';
    final upMbps = int.tryParse(params['up'] ?? params['upmbps'] ?? '') ?? 100;
    final downMbps = int.tryParse(params['down'] ?? params['downmbps'] ?? '') ?? 100;

    final config = <String, dynamic>{
      'tag': 'proxy',
      '_protocol': isHy2 ? 'hysteria2' : 'hysteria',
      '_type': 'external',
      'server': address,
      'port': port,
      'auth': auth,
      'sni': sni.isNotEmpty ? sni : address,
      'insecure': insecure,
      'up': upMbps,
      'down': downMbps,
    };

    if (obfs.isNotEmpty) {
      config['obfs'] = obfs;
      config['obfsPassword'] = obfsPassword;
    }

    if (remark != null) {
      config['_remark'] = remark;
    }

    return config;
  }

  /// Convert config back to URI
  static String toUri(Map<String, dynamic> config) {
    try {
      final protocol = config['_protocol'] as String? ?? 'hysteria2';
      final auth = config['auth'] as String;
      final server = config['server'] as String;
      final port = config['port'] as int;
      final sni = config['sni'] as String? ?? '';
      final insecure = config['insecure'] as bool? ?? false;
      final up = config['up'] as int? ?? 100;
      final down = config['down'] as int? ?? 100;
      final obfs = config['obfs'] as String? ?? '';
      final obfsPassword = config['obfsPassword'] as String? ?? '';
      final remark = config['_remark'] as String? ?? 'Hysteria2';

      final params = <String, String>{};

      if (sni.isNotEmpty) params['sni'] = sni;
      if (insecure) params['insecure'] = '1';
      params['up'] = up.toString();
      params['down'] = down.toString();
      if (obfs.isNotEmpty) {
        params['obfs'] = obfs;
        params['obfs-password'] = obfsPassword;
      }

      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final scheme = protocol == 'hysteria2' ? 'hy2' : 'hysteria';

      return '$scheme://${Uri.encodeComponent(auth)}@$server:$port?$queryString#${Uri.encodeComponent(remark)}';
    } catch (e) {
      return '';
    }
  }
}
