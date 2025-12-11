import 'dart:convert';
import 'package:hiddify/features/config/model/config.dart';
import 'package:uuid/uuid.dart';

/// A utility class for extracting proxy configuration URLs from mixed text content.
class ConfigExtractor {
  static const _uuid = Uuid();

  /// Regular expression pattern to match proxy URLs
  static final RegExp _configPattern = RegExp(
    r'((?:vless|vmess|trojan|ss|ssr|hysteria2?|hy2|tuic|naive\+https|wg|wireguard):\/\/[^\s\n\r]+)',
    multiLine: true,
    caseSensitive: false,
  );

  /// Extracts all proxy configuration URLs from the given text.
  static List<Config> extractConfigs(String text, {String source = 'extracted'}) {
    if (text.isEmpty) return [];

    final configs = <Config>[];
    final matches = _configPattern.allMatches(text);

    for (final match in matches) {
      final configUrl = match.group(1);
      if (configUrl != null && configUrl.isNotEmpty) {
        final config = _parseConfigUrl(configUrl, source);
        if (config != null) {
          configs.add(config);
        }
      }
    }

    return configs;
  }

  /// Extracts unique proxy configuration URLs (removes duplicates based on content)
  static List<Config> extractUniqueConfigs(String text, {String source = 'extracted'}) {
    final configs = extractConfigs(text, source: source);
    final seen = <String>{};
    
    return configs.where((config) {
      if (seen.contains(config.content)) {
        return false;
      }
      seen.add(config.content);
      return true;
    }).toList();
  }

  /// Extracts only the raw configuration URLs as strings
  static List<String> extractConfigUrls(String text) {
    if (text.isEmpty) return [];
    
    final matches = _configPattern.allMatches(text);
    return matches
        .map((m) => m.group(1))
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// Checks if the given text contains any proxy configuration
  static bool containsConfig(String text) => _configPattern.hasMatch(text);

  /// Counts the number of configurations in the given text
  static int countConfigs(String text) => _configPattern.allMatches(text).length;

  /// Detects the protocol type from a configuration URL
  static String detectProtocol(String url) {
    final lowercaseUrl = url.toLowerCase();
    if (lowercaseUrl.startsWith('vless://')) return 'vless';
    if (lowercaseUrl.startsWith('vmess://')) return 'vmess';
    if (lowercaseUrl.startsWith('trojan://')) return 'trojan';
    if (lowercaseUrl.startsWith('ssr://')) return 'ssr';
    if (lowercaseUrl.startsWith('ss://')) return 'shadowsocks';
    if (lowercaseUrl.startsWith('hysteria2://') || lowercaseUrl.startsWith('hy2://')) return 'hysteria2';
    if (lowercaseUrl.startsWith('hysteria://')) return 'hysteria';
    if (lowercaseUrl.startsWith('tuic://')) return 'tuic';
    if (lowercaseUrl.startsWith('naive+https://')) return 'naive';
    if (lowercaseUrl.startsWith('wg://') || lowercaseUrl.startsWith('wireguard://')) return 'wireguard';
    return 'unknown';
  }

  /// Parses a single configuration URL into a [Config] object
  static Config? _parseConfigUrl(String url, String source) {
    final protocol = detectProtocol(url);
    if (protocol == 'unknown') return null;

    final name = _extractName(url, protocol);

    return Config(
      id: _uuid.v4(),
      name: name,
      content: url,
      type: protocol,
      source: source,
      addedAt: DateTime.now(),
    );
  }

  /// Extracts the name/remark from a configuration URL
  static String _extractName(String url, String protocol) {
    // VMess is base64 encoded, needs special handling
    if (protocol == 'vmess') {
      return _extractVmessName(url);
    }

    // For other protocols, name is usually in the fragment (#)
    try {
      final fragmentIndex = url.indexOf('#');
      if (fragmentIndex != -1 && fragmentIndex < url.length - 1) {
        final fragment = url.substring(fragmentIndex + 1);
        return Uri.decodeComponent(fragment);
      }
    } catch (_) {}

    // Default names based on protocol
    return _getDefaultName(protocol);
  }

  /// Extracts name from VMess base64 encoded URL
  static String _extractVmessName(String url) {
    try {
      // Remove vmess:// prefix
      final base64Part = url.substring(8);
      
      // Handle potential fragment after base64
      final fragmentIndex = base64Part.indexOf('#');
      if (fragmentIndex != -1) {
        // Fragment exists, use it as name
        return Uri.decodeComponent(base64Part.substring(fragmentIndex + 1));
      }

      // Try to decode base64 and extract ps (name) field
      // Add padding if necessary
      final padded = base64Part.padRight(base64Part.length + (4 - base64Part.length % 4) % 4, '=');
      
      final decoded = utf8.decode(base64.decode(padded));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      
      if (json.containsKey('ps')) {
        return json['ps'] as String;
      }
    } catch (_) {}
    
    return 'VMess Config';
  }

  /// Returns a default name based on protocol
  static String _getDefaultName(String protocol) {
    switch (protocol) {
      case 'vless':
        return 'VLESS Config';
      case 'vmess':
        return 'VMess Config';
      case 'trojan':
        return 'Trojan Config';
      case 'shadowsocks':
        return 'Shadowsocks Config';
      case 'ssr':
        return 'ShadowsocksR Config';
      case 'hysteria':
        return 'Hysteria Config';
      case 'hysteria2':
        return 'Hysteria2 Config';
      case 'tuic':
        return 'TUIC Config';
      case 'naive':
        return 'Naive Config';
      case 'wireguard':
        return 'WireGuard Config';
      default:
        return 'Config';
    }
  }

  /// Separates config URLs from non-config text
  static ({List<Config> configs, String remainingText}) separateConfigsFromText(
    String text, {
    String source = 'extracted',
  }) {
    final configs = extractConfigs(text, source: source);
    final cleanedText = text.replaceAll(_configPattern, '').trim();
    
    // Clean up extra whitespace
    final normalizedText = cleanedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
    
    return (configs: configs, remainingText: normalizedText);
  }
}
