import 'package:hiddify/core/logger/logger.dart';

// NaïveProxy protocol parser
// NaïveProxy uses Chrome's network stack for traffic camouflage
class NaiveParser {
  // Parse Naive URI
  // Format: naive+https://username:password@host:port?params#name
  // Alternative: naive://username:password@host:port?params#name
  static Map<String, dynamic>? parse(String uri) {
    final isNaiveHttps = uri.startsWith('naive+https://');
    final isNaiveQuic = uri.startsWith('naive+quic://');
    final isNaivePlain = uri.startsWith('naive://');

    if (!isNaiveHttps && !isNaiveQuic && !isNaivePlain) return null;

    try {
      String scheme;
      String withoutScheme;
      
      if (isNaiveHttps) {
        scheme = 'https';
        withoutScheme = uri.substring(14);
      } else if (isNaiveQuic) {
        scheme = 'quic';
        withoutScheme = uri.substring(13);
      } else {
        scheme = 'https';
        withoutScheme = uri.substring(8);
      }

      final fragmentIndex = withoutScheme.indexOf('#');
      String mainPart;
      String? remark;

      if (fragmentIndex != -1) {
        mainPart = withoutScheme.substring(0, fragmentIndex);
        remark = Uri.decodeComponent(withoutScheme.substring(fragmentIndex + 1));
      } else {
        mainPart = withoutScheme;
      }

      final atIndex = mainPart.lastIndexOf('@');
      if (atIndex == -1) return null;

      final userInfo = mainPart.substring(0, atIndex);
      final rest = mainPart.substring(atIndex + 1);
      final colonIndex = userInfo.indexOf(':');
      String username;
      String password;

      if (colonIndex != -1) {
        username = Uri.decodeComponent(userInfo.substring(0, colonIndex));
        password = Uri.decodeComponent(userInfo.substring(colonIndex + 1));
      } else {
        username = Uri.decodeComponent(userInfo);
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
        host: host,
        port: port,
        username: username,
        password: password,
        scheme: scheme,
        sni: params['sni'] ?? '',
        insecure: params['insecure'] == '1' || params['allowInsecure'] == '1',
        remark: remark,
      );
    } catch (e) {
      Logger.naive.warning('Failed to parse NaïveProxy URI: $e');
      return null;
    }
  }

  static Map<String, dynamic> _buildConfig({
    required String host,
    required int port,
    required String username,
    required String password,
    required String scheme,
    required String sni,
    required bool insecure,
    String? remark,
  }) {
    final config = <String, dynamic>{
      'tag': 'proxy',
      '_protocol': 'naive',
      '_type': 'external',
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'scheme': scheme,
      'sni': sni.isNotEmpty ? sni : host,
      'insecure': insecure,
    };

    if (remark != null && remark.isNotEmpty) {
      config['_remark'] = remark;
    }

    return config;
  }

  // Validate Naive config and return error message if invalid
  static String? validate(Map<String, dynamic>? config) {
    if (config == null) return 'Failed to parse NaïveProxy config';
    
    final protocol = config['_protocol'] as String?;
    if (protocol != 'naive') {
      return 'Invalid NaïveProxy protocol type';
    }
    
    final host = config['host'] as String?;
    if (host == null || host.isEmpty) return 'Missing server address in NaïveProxy config';
    
    final port = config['port'] as int?;
    if (port == null || port <= 0 || port > 65535) return 'Invalid port in NaïveProxy config';
    
    final username = config['username'] as String?;
    if (username == null || username.isEmpty) return 'Missing username in NaïveProxy config';
    
    final password = config['password'] as String?;
    if (password == null || password.isEmpty) return 'Missing password in NaïveProxy config';
    
    return null; 
  }

  // Convert config back to URI
  static String toUri(Map<String, dynamic> config) {
    try {
      final host = config['host'] as String;
      final port = config['port'] as int;
      final username = config['username'] as String;
      final password = config['password'] as String;
      final scheme = config['scheme'] as String? ?? 'https';
      final sni = config['sni'] as String? ?? '';
      final insecure = config['insecure'] as bool? ?? false;
      final remark = config['_remark'] as String? ?? 'NaïveProxy';

      final params = <String, String>{};
      if (sni.isNotEmpty && sni != host) {
        params['sni'] = sni;
      }
      if (insecure) {
        params['insecure'] = '1';
      }

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final userPart = '${Uri.encodeComponent(username)}:${Uri.encodeComponent(password)}';
      final hostPart = '$host:$port';
      final schemePrefix = scheme == 'quic' ? 'naive+quic' : 'naive+https';

      var result = '$schemePrefix://$userPart@$hostPart';
      if (queryString.isNotEmpty) {
        result += '?$queryString';
      }
      return '$result#${Uri.encodeComponent(remark)}';
    } catch (e) {
      Logger.naive.warning('Failed to generate NaïveProxy URI: $e');
      return '';
    }
  }

  // Available Naive schemes
  static const List<String> availableSchemes = [
    'https',
    'quic',
  ];
}
