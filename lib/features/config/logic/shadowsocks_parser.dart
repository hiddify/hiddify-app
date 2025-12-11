import 'dart:convert';

/// Shadowsocks protocol parser for Xray-core
/// Supports SS and SS2022
class ShadowsocksParser {
  /// Parse Shadowsocks URI to outbound config
  /// Format 1: ss://base64(method:password)@host:port#name
  /// Format 2: ss://base64(method:password@host:port)#name
  /// Format 3: ss://method:password@host:port#name (SIP002)
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

      // Try to detect format
      if (mainPart.contains('@')) {
        // SIP002 format or base64 with @
        final atIndex = mainPart.lastIndexOf('@');
        final userInfo = mainPart.substring(0, atIndex);
        final hostPort = mainPart.substring(atIndex + 1);

        // Parse host:port
        final parsed = _parseHostPort(hostPort);
        host = parsed['host']!;
        port = int.parse(parsed['port']!);

        // Check if userInfo is base64 encoded
        if (_isBase64(userInfo)) {
          final decoded = _decodeBase64(userInfo);
          final colonIndex = decoded.indexOf(':');
          method = decoded.substring(0, colonIndex);
          password = decoded.substring(colonIndex + 1);
        } else {
          // Plain format
          final colonIndex = userInfo.indexOf(':');
          method = userInfo.substring(0, colonIndex);
          password = Uri.decodeComponent(userInfo.substring(colonIndex + 1));
        }
      } else {
        // Fully base64 encoded
        final decoded = _decodeBase64(mainPart);
        final atIndex = decoded.lastIndexOf('@');
        final userInfo = decoded.substring(0, atIndex);
        final hostPort = decoded.substring(atIndex + 1);

        final colonIndex = userInfo.indexOf(':');
        method = userInfo.substring(0, colonIndex);
        password = userInfo.substring(colonIndex + 1);

        final parsed = _parseHostPort(hostPort);
        host = parsed['host']!;
        port = int.parse(parsed['port']!);
      }

      return _buildOutbound(
        method: method,
        password: password,
        address: host,
        port: port,
        remark: remark,
      );
    } catch (e) {
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
      // IPv6
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

    if (remark != null) {
      outbound['_remark'] = remark;
    }

    return outbound;
  }

  /// Convert parsed config back to URI
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
      return 'ss://$userInfo@$address:$port#${Uri.encodeComponent(remark)}';
    } catch (e) {
      return '';
    }
  }

  /// Available Shadowsocks methods
  static const List<String> availableMethods = [
    // AEAD 2022
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
    // AEAD
    'aes-128-gcm',
    'aes-256-gcm',
    'chacha20-ietf-poly1305',
    'xchacha20-ietf-poly1305',
    // Stream (legacy)
    'aes-128-cfb',
    'aes-256-cfb',
    'chacha20',
    'chacha20-ietf',
    'rc4-md5',
  ];
}
