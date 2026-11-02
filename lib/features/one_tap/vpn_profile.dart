import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hiddify/features/one_tap/reality_profile.dart';

const maxVpnProfileBytes = 64 * 1024;

enum MitVpnProtocol {
  reality('VLESS + REALITY', 'VPN'),
  amneziaWg('AmneziaWG', 'AmneziaWG');

  const MitVpnProtocol(this.label, this.profileName);
  final String label;
  final String profileName;
}

String mitProfileProtocolLabel(String? storedName) => storedName == MitVpnProtocol.amneziaWg.profileName
    ? MitVpnProtocol.amneziaWg.label
    : storedName == MitVpnProtocol.reality.profileName ? MitVpnProtocol.reality.label : 'VPN';

/// Only validated client credentials reach the repository. Input containers,
/// display names, server administration data and routing overrides never do.
class PreparedVpnProfile {
  const PreparedVpnProfile(this.protocol, this.content);
  final MitVpnProtocol protocol;
  final String content;

  @override
  String toString() => 'PreparedVpnProfile(${protocol.label})';
}

class VpnProfileException extends FormatException {
  const VpnProfileException(super.message);
}

const _invalid = VpnProfileException('Нужна ссылка VLESS + REALITY или клиентский профиль AmneziaWG.');
const _share = VpnProfileException('Не удалось распаковать ключ Amnezia (AWG-01). Скопируйте его целиком.');
const _container = VpnProfileException('В экспорте не найден однозначный профиль AmneziaWG (AWG-02). Выберите AWG при экспорте.');
const _client = VpnProfileException('В экспорте нет полной клиентской конфигурации AWG (AWG-03).');
const _parameters = VpnProfileException('Параметры профиля AWG не поддерживаются или повреждены (AWG-04).');
const _admin = VpnProfileException('Используйте ключ «Поделиться подключением» Amnezia, а не полный доступ к серверу.');
const _remote = VpnProfileException('Нужен готовый клиентский ключ AWG или файл .conf. Ключи доступа к сервису Amnezia пока не поддерживаются.');

PreparedVpnProfile prepareVpnProfile(String input) {
  try {
    if (input.length > maxVpnProfileBytes || utf8.encode(input).length > maxVpnProfileBytes) throw _invalid;
    var text = input.trim().replaceFirst(RegExp(r'^\uFEFF'), '').trim();
    if (text.startsWith('vless://')) {
      return PreparedVpnProfile(MitVpnProtocol.reality, validateRealityProfile(text));
    }
    if (text.startsWith('vpn://')) {
      text = _amneziaClientConfig(_sharePayload(text.substring(6)));
    } else if (text.startsWith('awg://')) {
      final payload = text.substring(6);
      if (RegExp(r'^[A-Za-z0-9+/_=-]+$').hasMatch(payload)) {
        text = utf8.decode(_decodeBase64(payload));
      } else {
        text = _awgLinkConfig(text);
      }
    }
    Map<String, dynamic> endpoint;
    try {
      endpoint = _awgEndpoint(text);
    } catch (_) {
      if (input.trim().startsWith('vpn://') || input.trim().startsWith('awg://') || text.contains('[Interface]')) throw _parameters;
      rethrow;
    }
    return PreparedVpnProfile(MitVpnProtocol.amneziaWg, jsonEncode({'endpoints': [endpoint]}));
  } on VpnProfileException {
    rethrow;
  } on FormatException {
    throw _invalid;
  } catch (_) {
    throw _invalid;
  }
}

List<int> _decodeBase64(String text) {
  if (text.length > maxVpnProfileBytes || !RegExp(r'^[A-Za-z0-9+/_-]+={0,2}$').hasMatch(text)) throw _invalid;
  final decoded = base64.decode(base64.normalize(text));
  if (decoded.length > maxVpnProfileBytes) throw _invalid;
  return decoded;
}

String _sharePayload(String value) => value.replaceAll(RegExp(r'[\s\u200B\uFEFF]'), '');

Map<String, dynamic> _unpackAmnezia(String payload) {
  final packed = _decodeBase64(payload);
  List<int> bytes;
  if (packed.isNotEmpty && packed.first == 0x7B) {
    // Older Amnezia exports may contain uncompressed JSON.
    bytes = packed;
  } else {
    if (packed.length < 6) throw _invalid;
    final expected = ByteData.sublistView(Uint8List.fromList(packed), 0, 4).getUint32(0);
    if (expected == 0 || expected > maxVpnProfileBytes) throw _invalid;
    final output = BytesBuilder(copy: false);
    // Bound actual inflated output as well as Qt's declared size. The sink
    // below checks every output chunk, before accumulating it in memory.
    final bounded = ZLibDecoder().startChunkedConversion(_BoundedBytes(output, expected));
    for (var offset = 4; offset < packed.length; offset += 128) {
      final end = offset + 128 < packed.length ? offset + 128 : packed.length;
      bounded.add(packed.sublist(offset, end));
    }
    bounded.close();
    bytes = output.takeBytes();
    if (bytes.length != expected) throw _invalid;
  }
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, dynamic>) throw _invalid;
  return decoded;
}

String _amneziaClientConfig(String payload) {
  final Map<String, dynamic> decoded;
  try {
    decoded = _unpackAmnezia(payload);
  } catch (_) {
    throw _share;
  }
  for (final key in ['userName', 'password']) {
    if (decoded[key] != null && decoded[key] != '') throw _admin;
  }
  if (decoded.containsKey('api_key') || decoded.containsKey('auth_data')) throw _remote;
  final containers = decoded['containers'];
  if (containers is! List) throw _container;
  final candidates = containers.whereType<Map>().where((c) => c['container'] is String &&
      RegExp(r'^amnezia-awg(?:[-_]?\w+)?$').hasMatch(c['container'] as String) && c['awg'] is Map).toList();
  if (candidates.length != 1) {
    final selected = candidates.where((c) => c['container'] == decoded['defaultContainer']).toList();
    if (selected.length != 1) throw _container;
    candidates..clear()..add(selected.single);
  }
  final awg = candidates.single['awg'] as Map;
  dynamic client = awg['last_config'];
  try {
    for (var depth = 0; depth < 2 && client is String; depth++) {
      if (client.trimLeft().startsWith('[Interface]')) return _mergeAwgFields(client, const {}, awg);
      client = jsonDecode(client);
    }
    if (client is! Map) throw _client;
    final native = client['config'];
    final config = native is String && native.trim().isNotEmpty ? native : _structuredAwgConfig(client, decoded);
    return _mergeAwgFields(config, client, awg);
  } on VpnProfileException {
    rethrow;
  } catch (_) {
    throw _client;
  }
}

String _scalar(dynamic value) {
  if (value == null) return '';
  if (value is! String && value is! int && value is! bool) throw _client;
  final text = '$value'.trim();
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(text)) throw _client;
  return text;
}

String _listValue(dynamic value) => value is List ? value.map(_scalar).where((s) => s.isNotEmpty).join(', ') : _scalar(value);

String _structuredAwgConfig(Map client, Map root) {
  final host = _scalar(client['hostName'] ?? root['hostName']);
  final port = _scalar(client['port']); // Never use root.port: that is an SSH port.
  final endpoint = host.contains(':') && !host.startsWith('[') ? '[$host]:$port' : '$host:$port';
  final local = <String, String>{
    'PrivateKey': _scalar(client['client_priv_key']),
    'Address': _listValue(client['client_ip']),
    'MTU': _scalar(client['mtu']),
  };
  final peer = <String, String>{
    'PublicKey': _scalar(client['server_pub_key']),
    'PresharedKey': _scalar(client['psk_key']),
    'AllowedIPs': _listValue(client['allowed_ips']),
    'PersistentKeepalive': _scalar(client['persistent_keep_alive']),
    'Endpoint': endpoint,
  };
  if (local['PrivateKey']!.isEmpty || local['Address']!.isEmpty || peer['PublicKey']!.isEmpty || host.isEmpty || port.isEmpty) throw _client;
  String lines(Map<String, String> values) => values.entries.where((e) => e.value.isNotEmpty).map((e) => '${e.key} = ${e.value}').join('\n');
  return '[Interface]\n${lines(local)}\n[Peer]\n${lines(peer)}';
}

String _mergeAwgFields(String config, Map client, Map server) {
  // Some old exports contain escaped newlines or keep obfuscation only in the
  // last_config/server fields. An explicit nonempty native value takes priority.
  var text = config.trim().replaceFirst(RegExp(r'^\uFEFF'), '');
  if (!text.contains('\n') && text.contains(r'\n')) text = text.replaceAll(r'\r\n', '\n').replaceAll(r'\n', '\n');
  final insert = <String>[];
  for (final field in _awgFields.entries) {
    var value = '';
    for (final raw in [client[field.key], client[field.value], server[field.key], server[field.value]]) {
      value = _scalar(raw);
      if (value.isNotEmpty) break;
    }
    if (value.isEmpty) continue;
    final pattern = RegExp('^[ \\t]*${RegExp.escape(field.key)}[ \\t]*=[^\\r\\n]*', multiLine: true);
    final existing = pattern.firstMatch(text);
    if (existing == null) {
      insert.add('${field.key} = $value');
    } else if (existing.group(0)!.split('=').skip(1).join('=').trim().isEmpty) {
      text = text.replaceFirstMapped(pattern, (_) => '${field.key} = $value');
    }
  }
  if (insert.isNotEmpty) {
    final header = RegExp(r'^[ \t]*\[Interface\][ \t]*\r?$', multiLine: true);
    if (!header.hasMatch(text)) throw _client;
    text = text.replaceFirstMapped(header, (_) => '[Interface]\n${insert.join('\n')}');
  }
  return text;
}

/// .vpn may be a share URL, Amnezia JSON, Base64URL or Qt-compressed bytes.
/// Conversion stays local; the resulting text still goes through the validator.
String decodeVpnProfileBytes(List<int> bytes) {
  if (bytes.isEmpty || bytes.length > maxVpnProfileBytes) throw _invalid;
  if (bytes.length >= 6 && bytes[4] == 0x78) {
    final expected = ByteData.sublistView(Uint8List.fromList(bytes), 0, 4).getUint32(0);
    if (expected > 0 && expected <= maxVpnProfileBytes) return 'vpn://${base64Url.encode(bytes)}';
  }
  String? original;
  try { original = utf8.decode(bytes); } on FormatException { /* Qt binary export. */ }
  if (original != null) {
    final text = original.trim();
    if (text.startsWith('{')) return 'vpn://${base64Url.encode(utf8.encode(text))}';
    final payload = _sharePayload(text);
    if (RegExp(r'^[A-Za-z0-9+/_-]+={0,2}$').hasMatch(payload)) return 'vpn://$payload';
    return original;
  }
  if (bytes.length < 6 || bytes[4] != 0x78) throw _share;
  return 'vpn://${base64Url.encode(bytes)}';
}

class _BoundedBytes extends ByteConversionSinkBase {
  _BoundedBytes(this.output, this.maximum);
  final BytesBuilder output;
  final int maximum;

  @override
  void add(List<int> chunk) {
    if (chunk.length > maximum - output.length) throw _invalid;
    output.add(chunk);
  }

  @override
  void close() {}
}

const _awgFields = {
  'Jc': 'jc', 'Jmin': 'jmin', 'Jmax': 'jmax',
  'S1': 's1', 'S2': 's2', 'S3': 's3', 'S4': 's4',
  'H1': 'h1', 'H2': 'h2', 'H3': 'h3', 'H4': 'h4',
  'I1': 'i1', 'I2': 'i2', 'I3': 'i3', 'I4': 'i4', 'I5': 'i5',
  'HeaderProtectionKey': 'header_protection_key',
  'ContentPaddingAddition': 'content_padding_addition',
  'RekeyAfterTime': 'rekey_after_time', 'RekeyTimeout': 'rekey_timeout',
  'RejectAfterTime': 'reject_after_time', 'KeepaliveTimeout': 'keepalive_timeout',
  'MaxHandshakeAttempts': 'max_handshake_attempts',
  'RandomTrailers': 'random_trailers', 'DisableCookies': 'disable_cookies',
};

Map<String, dynamic> _awgEndpoint(String text) {
  final sections = <String, Map<String, String>>{};
  Map<String, String>? current;
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) continue;
    if (line == '[Interface]' || line == '[Peer]') {
      if (sections.containsKey(line) || (line == '[Peer]' && !sections.containsKey('[Interface]'))) throw _invalid;
      current = sections[line] = {};
      continue;
    }
    final split = line.indexOf('=');
    if (current == null || split < 1) throw _invalid;
    final key = line.substring(0, split).trim();
    // Comments do not become part of keys or packet templates.
    final value = line.substring(split + 1).split(RegExp(r'\s[#;]')).first.trim();
    if (current.containsKey(key) || RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) throw _invalid;
    current[key] = value;
  }
  final local = sections['[Interface]'];
  final peer = sections['[Peer]'];
  if (sections.length != 2 || local == null || peer == null) throw _invalid;
  final interfaceFields = {'PrivateKey', 'Address', 'DNS', 'MTU', 'ListenPort', ..._awgFields.keys};
  const peerFields = {'PublicKey', 'PresharedKey', 'AllowedIPs', 'Endpoint', 'PersistentKeepalive'};
  if (local.keys.any((k) => !interfaceFields.contains(k)) || peer.keys.any((k) => !peerFields.contains(k))) throw _invalid;
  for (final key in ['PrivateKey', 'Address']) { if (local[key] == null || local[key]!.isEmpty) throw _invalid; }
  for (final key in ['PublicKey', 'Endpoint']) { if (peer[key] == null || peer[key]!.isEmpty) throw _invalid; }
  local.removeWhere((key, value) => value.isEmpty);
  peer.removeWhere((key, value) => value.isEmpty);
  final server = Uri.parse('udp://${peer['Endpoint'] ?? ''}');
  final host = _uriHost(server);
  if (server.host.isEmpty || !server.hasPort || server.userInfo.isNotEmpty || server.path.isNotEmpty ||
      server.hasQuery || server.hasFragment || !_validHost(host)) throw _invalid;
  final port = _number('${server.port}', 1, 65535);
  if (local['DNS'] case final dns?) {
    if (dns.split(',').any((s) => InternetAddress.tryParse(s.trim()) == null || s.contains('%'))) throw _invalid;
  }
  final awg = <String, dynamic>{};
  for (final entry in _awgFields.entries) {
    final value = local[entry.key];
    if (value == null) continue;
    if (entry.key.startsWith('I') && entry.key.length == 2) {
      _validatePacketTemplate(value);
      awg[entry.value] = value;
    } else if (entry.key == 'HeaderProtectionKey') {
      awg[entry.value] = _headerProtectionKey(value);
    } else if (entry.key == 'RandomTrailers' || entry.key == 'DisableCookies') {
      awg[entry.value] = switch (value.toLowerCase()) {
        'true' || '1' || 'on' => true,
        'false' || '0' || 'off' => false,
        _ => throw _invalid,
      };
    } else if (entry.key.startsWith('H') || entry.key.length > 4) {
      _range(value, entry.key == 'ContentPaddingAddition' ? 65507 : 0xFFFFFFFF);
      awg[entry.value] = value;
    } else {
      awg[entry.value] = _number(value, 0, entry.key == 'Jc' ? 128 : 65507);
    }
  }
  if (awg.isEmpty) throw _invalid;
  if ((awg['jmin'] as int? ?? 0) > (awg['jmax'] as int? ?? 0)) throw _invalid;
  return {
    'type': 'awg', 'tag': 'Mit-AWG',
    'private_key': _key(local['PrivateKey'] ?? ''),
    'address': _prefixes(local['Address'] ?? ''),
    'mtu': _number(local['MTU'] ?? '1280', 576, 9000),
    if (local['ListenPort'] case final listen?) 'listen_port': _number(listen, 0, 65535),
    'awg': awg,
    'peers': [{
      'address': host, 'port': port,
      'public_key': _key(peer['PublicKey'] ?? ''),
      if (peer['PresharedKey'] case final psk?) 'preshared_key': _key(psk, allowZero: true),
      'allowed_ips': _prefixes(peer['AllowedIPs'] ?? '0.0.0.0/0,::/0'),
      'persistent_keepalive_interval': _number(peer['PersistentKeepalive'] ?? '0', 0, 65535),
    }],
  };
}

void _validatePacketTemplate(String value) {
  if (value.length > 8192) throw _invalid;
  var offset = 0;
  var size = 0;
  for (final tag in RegExp(r'<([^<>]+)>').allMatches(value)) {
    if (value.substring(offset, tag.start).trim().isNotEmpty) throw _invalid;
    final parts = tag.group(1)!.trim().split(RegExp(r'\s+'));
    final name = parts.first;
    if (name == 'b' && parts.length == 2) {
      final hex = parts[1].replaceFirst(RegExp(r'^0x'), '');
      if (hex.isEmpty || hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) throw _invalid;
      size += hex.length ~/ 2;
    } else if ({'r', 'rc', 'rd', 'dz'}.contains(name) && parts.length == 2) {
      // Native builders accept an arbitrary signed int, then allocate/slice
      // using it during a handshake. Bound every part and the complete packet.
      size += _number(parts[1], 0, 65507);
    } else if ({'t', 'd', 'ds'}.contains(name) && parts.length == 1) {
      size += name == 't' ? 4 : 0; // I packets have no source data.
    } else if (name == 'qi' && parts.length == 2 && _validHost(parts[1])) {
      size += 1200;
    } else {
      throw _invalid;
    }
    if (size > 65507) throw _invalid;
    offset = tag.end;
  }
  if (offset == 0 || value.substring(offset).trim().isNotEmpty) throw _invalid;
}

String _headerProtectionKey(String text) {
  if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(text)) return text;
  // Amnezia exports this 32-byte key as Base64; the native AWG endpoint
  // expects hex. Reuse strict key validation before converting every byte.
  final bytes = base64.decode(_key(text, allowZero: true));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String _key(String text, {bool allowZero = false}) {
  if (!RegExp(r'^[A-Za-z0-9+/_-]{43}=?$').hasMatch(text)) throw _invalid;
  final bytes = _decodeBase64(text);
  if (bytes.length != 32 || (!allowZero && bytes.every((b) => b == 0))) throw _invalid;
  final canonical = base64.encode(bytes);
  if (base64.normalize(text) != canonical) throw _invalid;
  return canonical;
}

int _number(String text, int min, int max) {
  if (!RegExp(r'^[0-9]{1,10}$').hasMatch(text)) throw _invalid;
  final value = int.parse(text);
  if (value < min || value > max) throw _invalid;
  return value;
}

void _range(String value, int maximum) {
  final parts = value.split('-');
  if (parts.length > 2 || _number(parts.first, 0, maximum) > _number(parts.last, 0, maximum)) throw _invalid;
}

List<String> _prefixes(String value) {
  final result = <String>[];
  for (final raw in value.split(',')) {
    final parts = raw.trim().split('/');
    final ip = InternetAddress.tryParse(parts.first);
    if (ip == null || parts.length > 2 || parts.first.contains('%')) throw _invalid;
    final bits = ip.type == InternetAddressType.IPv4 ? 32 : 128;
    final prefix = parts.length == 2 ? _number(parts.last, 0, bits) : bits;
    result.add('${ip.address}/$prefix');
  }
  return result;
}

bool _validHost(String host) => !host.contains('%') && (InternetAddress.tryParse(host) != null ||
    (host.length <= 253 && host.split('.').every((label) => label.length <= 63 &&
      RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$').hasMatch(label))));

String _uriHost(Uri uri) => uri.host.startsWith('[') && uri.host.endsWith(']')
    ? uri.host.substring(1, uri.host.length - 1) : uri.host;

String _awgLinkConfig(String text) {
  if (RegExp(r'\s').hasMatch(text)) throw _invalid;
  final uri = Uri.parse(text);
  final host = _uriHost(uri);
  if (uri.scheme != 'awg' || !uri.hasPort || !_validHost(host) ||
      (uri.path.isNotEmpty && uri.path != '/')) throw _invalid;
  final aliases = <String, String>{
    'pk': 'PrivateKey', 'privatekey': 'PrivateKey',
    'publickey': 'PublicKey', 'peerpublickey': 'PublicKey', 'pub': 'PublicKey', 'peerpub': 'PublicKey', 'peerpk': 'PublicKey',
    'address': 'Address', 'ip': 'Address', 'localaddress': 'Address',
    'presharedkey': 'PresharedKey', 'psk': 'PresharedKey',
    'allowedips': 'AllowedIPs', 'keepalive': 'PersistentKeepalive', 'mtu': 'MTU', 'dns': 'DNS',
    for (final entry in _awgFields.entries) entry.key.toLowerCase(): entry.key,
    for (final entry in _awgFields.entries) entry.value: entry.key,
  };
  final values = <String, String>{};
  if (uri.userInfo.isNotEmpty) values['PrivateKey'] = Uri.decodeComponent(uri.userInfo);
  for (final entry in uri.queryParametersAll.entries) {
    final key = aliases[entry.key.toLowerCase()];
    if (key == null || entry.value.length != 1 || values.containsKey(key)) throw _invalid;
    final value = entry.value.single;
    if (RegExp(r'[\r\n\x00]').hasMatch(value)) throw _invalid;
    values[key] = value;
  }
  const peerFields = {'PublicKey', 'PresharedKey', 'AllowedIPs', 'PersistentKeepalive'};
  return '[Interface]\n${values.entries.where((e) => !peerFields.contains(e.key)).map((e) => '${e.key} = ${e.value}').join('\n')}\n'
      '[Peer]\nEndpoint = ${host.contains(':') ? '[$host]' : host}:${uri.port}\n'
      '${values.entries.where((e) => peerFields.contains(e.key)).map((e) => '${e.key} = ${e.value}').join('\n')}';
}
