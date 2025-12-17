import 'package:hiddify/core/logger/logger.dart';

 // TUIC protocol parser
 // Note: TUIC is not natively supported by Xray-core
 // This parser generates a compatible format for external handling
class TuicParser {
  // Parse TUIC URI
  // Format: tuic://uuid:password@host:port?params#name
  static Map<String, dynamic>? parse(String uri) {
    if (!uri.startsWith('tuic://')) return null;

    try {
      final withoutScheme = uri.substring(7);
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

      final userInfo = mainPart.substring(0, atIndex);
      final rest = mainPart.substring(atIndex + 1);
      final colonIndex = userInfo.indexOf(':');
      String uuid;
      String password;

      if (colonIndex != -1) {
        uuid = userInfo.substring(0, colonIndex);
        password = userInfo.substring(colonIndex + 1);
      } else {
        uuid = userInfo;
        password = '';
      }

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
        final colonIdx = hostPort.lastIndexOf(':');
        if (colonIdx != -1) {
          host = hostPort.substring(0, colonIdx);
          port = int.parse(hostPort.substring(colonIdx + 1));
        } else {
          host = hostPort;
          port = 443;
        }
      }

      return _buildConfig(
        uuid: uuid,
        password: password,
        address: host,
        port: port,
        remark: remark,
        params: params,
      );
    } catch (e) {
      Logger.tuic.warning('Failed to parse TUIC URI: $e');
      return null;
    }
  }

  static Map<String, dynamic> _buildConfig({
    required String uuid,
    required String password,
    required String address,
    required int port,
    required Map<String, String> params,
    String? remark,
  }) {
    final sni = params['sni'] ?? '';
    final alpn = params['alpn'] ?? 'h3';
    final congestionControl = params['congestion_control'] ?? params['cc'] ?? 'bbr';
    final udpRelayMode = params['udp_relay_mode'] ?? 'native';
    final disableSni = params['disable_sni'] == '1';
    final allowInsecure = params['allowInsecure'] == '1' || params['insecure'] == '1';

    final config = <String, dynamic>{
      'tag': 'proxy',
      '_protocol': 'tuic',
      '_type': 'external',
      'server': address,
      'port': port,
      'uuid': uuid,
      'password': password,
      'sni': sni.isNotEmpty ? sni : address,
      'alpn': alpn.split(',').map((e) => e.trim()).toList(),
      'congestionControl': congestionControl,
      'udpRelayMode': udpRelayMode,
      'disableSni': disableSni,
      'allowInsecure': allowInsecure,
    };

    if (remark != null) {
      config['_remark'] = remark;
    }

    return config;
  }

  // Validate TUIC config and return error message if invalid
  static String? validate(Map<String, dynamic>? config) {
    if (config == null) return 'Failed to parse TUIC config';
    
    final protocol = config['_protocol'] as String?;
    if (protocol != 'tuic') {
      return 'Invalid TUIC protocol type';
    }
    
    final server = config['server'] as String?;
    if (server == null || server.isEmpty) return 'Missing server address in TUIC config';
    
    final port = config['port'] as int?;
    if (port == null || port <= 0 || port > 65535) return 'Invalid port in TUIC config';
    
    final uuid = config['uuid'] as String?;
    if (uuid == null || uuid.isEmpty) return 'Missing UUID in TUIC config';
    
    return null; 
  }

  // Convert config back to URI
  static String toUri(Map<String, dynamic> config) {
    try {
      final uuid = config['uuid'] as String;
      final password = config['password'] as String? ?? '';
      final server = config['server'] as String;
      final port = config['port'] as int;
      final sni = config['sni'] as String? ?? '';
      final alpn = config['alpn'] as List?;
      final cc = config['congestionControl'] as String? ?? 'bbr';
      final udpMode = config['udpRelayMode'] as String? ?? 'native';
      final allowInsecure = config['allowInsecure'] as bool? ?? false;
      final remark = config['_remark'] as String? ?? 'TUIC';

      final params = <String, String>{};

      if (sni.isNotEmpty) params['sni'] = sni;
      if (alpn != null) params['alpn'] = alpn.join(',');
      params['congestion_control'] = cc;
      params['udp_relay_mode'] = udpMode;
      if (allowInsecure) params['allowInsecure'] = '1';

      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      return 'tuic://$uuid:$password@$server:$port?$queryString#${Uri.encodeComponent(remark)}';
    } catch (e) {
      Logger.tuic.warning('Failed to generate TUIC URI: $e');
      return '';
    }
  }
}
