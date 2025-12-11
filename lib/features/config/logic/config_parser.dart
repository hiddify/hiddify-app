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
      // vmess usually base64 encoded, need decode to get name, skipping for simple check
      name = 'VMess Config';
    } else if (trimmedContent.startsWith('trojan://')) {
      type = 'trojan';
      name = _parseName(trimmedContent) ?? 'Trojan Config';
    } else if (trimmedContent.startsWith('ss://')) {
      type = 'shadowsocks';
      name = _parseName(trimmedContent) ?? 'SS Config';
    } else {
      // Assuming it might be a JSON content or universal format?
      // Check for braces
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
}
