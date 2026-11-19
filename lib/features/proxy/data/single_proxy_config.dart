import 'dart:convert';

/// A config that holds only one proxy, to share it or edit it as a profile of its own: the proxy,
/// and the proxies it dials through (its `detour`), so it still connects alone.
///
/// The proxy is the one the core runs as [tag], at [host] and [port] when it says (empty and 0
/// when not). It is looked up first in [raw], the profile as saved, by its name: the tag without
/// the core's numbering (`name § 3`), and among proxies of the same name by its port and server.
/// Then in [generated], the profile's generated config, by the exact tag, which matches the
/// running one unless the core renumbered it on a reload, so only when the port agrees. Returns
/// null when neither tells which proxy it is.
///
/// What only the running app knows is left out: a detour to one of the app's own hidden outbounds
/// (such as the TLS fragment one), and `domain_resolver`, which names a DNS server of the app.
String? singleProxyConfig(String tag, {String host = '', int port = 0, String? raw, String? generated}) {
  bool portAgrees(Map<String, dynamic> item) => port == 0 || item['server_port'] == null || item['server_port'] == port;
  bool hostAgrees(Map<String, dynamic> item) => host.isEmpty || item['server'] == null || item['server'] == host;

  if (_decode(raw) case final config?) {
    final name = baseTag(tag);
    var matches = _items(config).where((item) => baseTag('${item['tag']}') == name).toList();
    if (matches.length > 1) matches = matches.where(portAgrees).toList();
    if (matches.length > 1) matches = matches.where(hostAgrees).toList();
    if (matches.length == 1) return _extract(config, matches.single);
  }
  if (_decode(generated) case final config?) {
    final match = _items(config).where((item) => item['tag'] == tag).firstOrNull;
    if (match != null && portAgrees(match)) return _extract(config, match);
  }
  return null;
}

/// [tag] without the core's numbering of duplicate names (`name § 3`).
String baseTag(String tag) => tag.split(' § ').first.trim();

/// Tags of the app's own outbounds, which no shared config has.
bool isHiddenTag(String tag) => tag.contains('§hide§');

const _sections = ['outbounds', 'endpoints'];

Map<String, dynamic>? _decode(String? content) {
  if (content == null || content.isEmpty) return null;
  try {
    final decoded = jsonDecode(content);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

Iterable<Map<String, dynamic>> _items(Map<String, dynamic> config) sync* {
  for (final section in _sections) {
    if (config[section] case final List<dynamic> list) yield* list.whereType<Map<String, dynamic>>();
  }
}

String _extract(Map<String, dynamic> config, Map<String, dynamic> proxy) {
  final byTag = {for (final item in _items(config)) '${item['tag']}': item};

  // the proxy, then each proxy it dials through, once
  final picked = <String, Map<String, dynamic>>{};
  Map<String, dynamic>? next = proxy;
  while (next != null && !picked.containsKey('${next['tag']}')) {
    final item = Map<String, dynamic>.of(next)..remove('domain_resolver');
    picked['${next['tag']}'] = item;
    final detour = item['detour'];
    next = detour is String && !isHiddenTag(detour) ? byTag[detour] : null;
    if (next == null) item.remove('detour');
  }

  final endpointTags = {
    if (config['endpoints'] case final List<dynamic> list)
      for (final item in list.whereType<Map<String, dynamic>>()) '${item['tag']}',
  };
  final outbounds = <Map<String, dynamic>>[];
  final endpoints = <Map<String, dynamic>>[];
  for (final MapEntry(key: tag, value: item) in picked.entries) {
    (endpointTags.contains(tag) ? endpoints : outbounds).add(item);
  }
  // the proxy shows under its own name, not the core's numbered one
  picked.values.first['tag'] = baseTag(picked.keys.first);
  return const JsonEncoder.withIndent(
    '  ',
  ).convert({if (outbounds.isNotEmpty) 'outbounds': outbounds, if (endpoints.isNotEmpty) 'endpoints': endpoints});
}
