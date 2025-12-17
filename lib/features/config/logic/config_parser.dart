import 'dart:convert';

import 'package:hiddify/features/config/model/config.dart';
import 'package:uuid/uuid.dart';

class ConfigParser {
  static const _uuid = Uuid();

  static Config? parse(String content, {String source = 'manual'}) {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return null;

    var type = 'unknown';
    var name = 'Config';

    if (trimmedContent.startsWith('vless://')) {
      type = 'vless';
      name = _parseName(trimmedContent) ?? 'VLESS Config';
    } else if (trimmedContent.startsWith('vmess://')) {
      type = 'vmess';
      name = 'VMess Config';
    } else if (trimmedContent.startsWith('trojan://')) {
      type = 'trojan';
      name = _parseName(trimmedContent) ?? 'Trojan Config';
    } else if (trimmedContent.startsWith('ss://')) {
      type = 'shadowsocks';
      name = _parseName(trimmedContent) ?? 'SS Config';
    } else if (trimmedContent.startsWith('hy2://') ||
        trimmedContent.startsWith('hysteria2://') ||
        trimmedContent.startsWith('hysteria://')) {
      type = 'hysteria';
      name = _parseName(trimmedContent) ?? 'Hysteria Config';
    } else {
      if (trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) {
        type = 'json';
        name = 'Custom Config';
      }
    }

    if (type == 'unknown') return null;

    return Config(
      id: _uuid.v4(),
      name: name,
      content: trimmedContent,
      type: type,
      source: source,
      addedAt: DateTime.now(),
    );
  }

  static String? _parseName(String uri) {
    try {
      final fragmentIndex = uri.indexOf('#');
      if (fragmentIndex != -1) {
        return Uri.decodeComponent(uri.substring(fragmentIndex + 1));
      }
    } catch (_) {}
    return null;
  }

  // Extract server address (host =port) from config content
  static String? extractServerAddress(String content) {
    final trimmed = content.trim();

    try {
      if (trimmed.startsWith('vless://') ||
          trimmed.startsWith('trojan://') ||
          trimmed.startsWith('ss://') ||
          trimmed.startsWith('hy2://') ||
          trimmed.startsWith('hysteria2://') ||
          trimmed.startsWith('hysteria://')) {
        var uriPart = trimmed;
        final fragmentIndex = uriPart.indexOf('#');
        if (fragmentIndex != -1) {
          uriPart = uriPart.substring(0, fragmentIndex);
        }

        final uri = Uri.parse(uriPart);
        if (uri.host.isNotEmpty && uri.port > 0) {
          return '${uri.host}:${uri.port}';
        }
      }
      if (trimmed.startsWith('vmess://')) {
        final base64Part = trimmed.substring(8);
        var b64 = base64Part;
        final fragmentIndex = b64.indexOf('#');
        if (fragmentIndex != -1) {
          b64 = b64.substring(0, fragmentIndex);
        }
        final decoded = utf8.decode(base64.decode(base64.normalize(b64)));
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final host = json['add'] as String?;
        final port = json['port'];
        if (host != null && port != null) {
          return '$host:$port';
        }
      }
      if (trimmed.startsWith('socks://') || trimmed.startsWith('socks5://')) {
        final uri = Uri.parse(trimmed);
        if (uri.host.isNotEmpty && uri.port > 0) {
          return '${uri.host}:${uri.port}';
        }
      }
    } catch (_) {
      // Intentionally empty - return null on parse failure
    }

    return null;
  }
}
