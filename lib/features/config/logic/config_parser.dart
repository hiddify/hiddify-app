import 'package:uuid/uuid.dart';
import '../model/config.dart';

class ConfigParser {
  static const _uuid = Uuid();

  static Config? parse(String content, {String source = 'manual'}) {
    content = content.trim();
    if (content.isEmpty) return null;

    String type = 'unknown';
    String name = 'Config';

    if (content.startsWith('vless://')) {
      type = 'vless';
      name = _parseName(content) ?? 'VLESS Config';
    } else if (content.startsWith('vmess://')) {
      type = 'vmess';
      // vmess usually base64 encoded, need decode to get name, skipping for simple check
      name = 'VMess Config';
    } else if (content.startsWith('trojan://')) {
      type = 'trojan';
      name = _parseName(content) ?? 'Trojan Config';
    } else if (content.startsWith('ss://')) {
      type = 'shadowsocks';
      name = _parseName(content) ?? 'SS Config';
    } else {
      // Assuming it might be a JSON content or universal format?
      // Check for braces
      if (content.startsWith('{') && content.endsWith('}')) {
        type = 'json';
        name = 'Custom Config';
      }
    }

    if (type == 'unknown') return null;

    return Config(
      id: _uuid.v4(),
      name: name,
      content: content,
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
}
