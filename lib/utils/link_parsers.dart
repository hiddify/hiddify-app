import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/singbox/model/singbox_proxy_type.dart';
import 'package:hiddify/utils/validators.dart';

typedef ProfileLink = ({String url, String name});

abstract class LinkParser {
  static String generateSubShareLink(String url, [String? name]) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final modifiedUri = Uri(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      query: uri.query,
      fragment: name ?? uri.fragment,
    );
    // return 'hiddify://import/$modifiedUri';
    return '$modifiedUri';
  }

  // protocols schemas
  static const protocols = {'clash', 'clashmeta', 'sing-box', 'hiddify'};

  static ProfileLink? parse(String link) {
    if (link.trim().isEmpty) return null;
    return simple(link) ?? deep(link);
  }

  static ProfileLink? simple(String link) {
    if (!isUrl(link)) return null;
    final uri = Uri.parse(link.trim());
    return (
      url: uri.toString(),
      name: uri.queryParameters['name'] ?? '',
    );
  }

  static ({String content, String name})? protocol(String content) {
    final normalContent = safeDecodeBase64(content);
    final lines = normalContent.split('\n');
    String? name;
    for (final line in lines) {
      final uri = Uri.tryParse(line);
      if (uri == null) continue;
      final fragment = uri.hasFragment ? Uri.decodeComponent(uri.fragment.split("&&detour")[0]) : null;
      name ??= switch (uri.scheme) {
        'ss' => fragment ?? ProxyType.shadowsocks.label,
        'ssconf' => fragment ?? ProxyType.shadowsocks.label,
        'vmess' => ProxyType.vmess.label,
        'vless' => fragment ?? ProxyType.vless.label,
        'trojan' => fragment ?? ProxyType.trojan.label,
        'tuic' => fragment ?? ProxyType.tuic.label,
        'hy2' || 'hysteria2' => fragment ?? ProxyType.hysteria2.label,
        'hy' || 'hysteria' => fragment ?? ProxyType.hysteria.label,
        'ssh' => fragment ?? ProxyType.ssh.label,
        'wg' => fragment ?? ProxyType.wireguard.label,
        'warp' => fragment ?? ProxyType.warp.label,
        _ => null,
      };
    }
    final headers = ProfileRepositoryImpl.parseHeadersFromContent(content);
    final subinfo = ProfileParser.parse("", headers);

    if (subinfo.name.isNotNullOrEmpty && subinfo.name != "Remote Profile") {
      name = subinfo.name;
    }

    return (content: normalContent, name: name ?? ProxyType.unknown.label);
  }

  static ProfileLink? deep(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    final queryParams = uri.queryParameters;
    switch (uri.scheme) {
      case 'clash' || 'clashmeta' when uri.authority == 'install-config':
        if (uri.authority != 'install-config' || !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      case 'sing-box':
        if (uri.authority != 'import-remote-profile' || !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      case 'hiddify':
        if (uri.authority == "import") {
          return (url: uri.path.substring(1) + (uri.hasQuery ? "?${uri.query}" : ""), name: uri.fragment);
        }
        //for backward compatibility
        if ((uri.authority != 'install-config' && uri.authority != 'install-sub') || !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      default:
        return null;
    }
  }
}

String safeDecodeBase64(String str) {
  try {
    return utf8.decode(base64Decode(str));
  } catch (e) {
    return str;
  }
}
