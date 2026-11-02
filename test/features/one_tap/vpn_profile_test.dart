import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/one_tap/vpn_profile.dart';

import 'fixtures/awg_fixture.dart';

Map<String, dynamic> endpoint(String text) => (jsonDecode(prepareVpnProfile(text).content)['endpoints'] as List).single as Map<String, dynamic>;

void main() {
  for (final version in [1, 2, 3]) {
    test('imports an Amnezia client vpn link and preserves AWG $version options', () {
      final prepared = prepareVpnProfile(amneziaTestLink(amneziaTestContainer(awgTestConfig(version: version))));
      final out = endpoint(amneziaTestLink(amneziaTestContainer(awgTestConfig(version: version))));
      expect(prepared.protocol, MitVpnProtocol.amneziaWg);
      expect(out['type'], 'awg');
      expect(out['private_key'], testWgKey(1));
      expect(out['address'], ['10.8.0.2/32', 'fd42::2/128']);
      final peer = (out['peers'] as List).single as Map;
      expect(peer['preshared_key'], testWgKey(33));
      expect(peer['allowed_ips'], ['0.0.0.0/0', '::/0']);
      expect(peer['persistent_keepalive_interval'], 25);
      expect(out['awg']['h1'], version >= 2 ? '1001-1009' : '1001');
      if (version >= 2) {
        expect(out['awg']['s3'], 6);
        expect(out['awg']['s4'], 8);
        expect(out['awg']['i1'], '<b 0x01020304>');
      }
      if (version >= 3) {
        expect(out['awg']['header_protection_key'], List.filled(64, '1').join());
        expect(out['awg']['rekey_after_time'], '100-120');
        expect(out['awg']['random_trailers'], true);
        expect(out['awg']['disable_cookies'], false);
      }
      expect(prepared.content, isNot(contains('private-display-name')));
      expect(prepared.content, isNot(contains('private-administrative-host')));
      expect(prepared.content, isNot(contains('containers')));
      expect(prepared.toString(), isNot(contains(testWgKey(1))));
      expect(jsonDecode(prepared.content).keys, ['endpoints']);
    });
  }

  test('imports Base64 header keys and on flags from conf, vpn links and files', () {
    final config = awgBase64HeaderConfig();
    final link = amneziaTestLink(amneziaTestContainer(config));
    final expectedHex = List.generate(32, (i) => i.toRadixString(16).padLeft(2, '0')).join();
    for (final input in [config, link, decodeVpnProfileBytes(utf8.encode(link)),
      decodeVpnProfileBytes(utf8.encode(config))]) {
      final awg = endpoint(input)['awg'] as Map;
      expect(awg['header_protection_key'], expectedHex);
      expect(awg['random_trailers'], true);
      expect(awg['disable_cookies'], true);
    }
  });

  test('normalizes Base64 header keys without losing leading or high bytes', () {
    final bytes = [0, 0, 255, 254, ...List.generate(28, (i) => i)];
    final expectedHex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    for (final encoded in [base64.encode(bytes), base64Url.encode(bytes),
      base64.encode(bytes).replaceAll('=', ''), base64Url.encode(bytes).replaceAll('=', ''),
      expectedHex, expectedHex.toUpperCase()]) {
      final config = awgTestConfig(version: 3).replaceFirst(List.filled(64, '1').join(), encoded);
      final actual = endpoint(config)['awg']['header_protection_key'] as String;
      expect(actual.toLowerCase(), expectedHex);
    }
  });

  test('inherits Base64 header keys and on/off flags from export metadata', () {
    final root = amneziaTestContainer(awgTestConfig());
    final awg = (root['containers'] as List).single['awg'] as Map;
    awg['HeaderProtectionKey'] = testWgKey(0);
    awg['RandomTrailers'] = 'on';
    awg['DisableCookies'] = 'off';
    final result = endpoint(amneziaTestLink(root))['awg'] as Map;
    expect(result['header_protection_key'], List.generate(32, (i) => i.toRadixString(16).padLeft(2, '0')).join());
    expect(result['random_trailers'], true);
    expect(result['disable_cookies'], false);
  });

  for (final entry in {'on': true, 'ON': true, 'true': true, 'True': true, '1': true,
    'off': false, 'OFF': false, 'false': false, 'False': false, '0': false}.entries) {
    test('accepts AWG boolean ${entry.key} for both flags', () {
      final config = awgTestConfig(version: 3)
          .replaceFirst('RandomTrailers = 1', 'RandomTrailers = ${entry.key}')
          .replaceFirst('DisableCookies = 0', 'DisableCookies = ${entry.key}');
      final awg = endpoint(config)['awg'] as Map;
      expect(awg['random_trailers'], entry.value);
      expect(awg['disable_cookies'], entry.value);
    });
  }

  for (final value in [base64.encode(List.filled(31, 1)), base64.encode(List.filled(33, 1)),
    '${testWgKey(0)}=', 'not-a-key', '${'a' * 63}g', '${'A' * 42}B=']) {
    test('rejects a malformed header key without exposing its value', () {
      final config = awgTestConfig(version: 3).replaceFirst(List.filled(64, '1').join(), value);
      try {
        prepareVpnProfile(config);
        fail('accepted invalid header key');
      } on VpnProfileException catch (error) {
        expect(error.message, contains('AWG-04'));
        expect(error.source, isNull);
        expect(error.toString(), isNot(contains(value)));
      }
    });
  }

  test('imports Amnezia DNS placeholders and keepalive range from links and files', () {
    final config = awgAmneziaPlaceholderConfig();
    final root = amneziaTestContainer(config);
    root['containers'][0]['container'] = 'amnezia-awg2';
    root['defaultContainer'] = 'amnezia-awg2';
    final link = amneziaTestLink(root);
    for (final text in [config, link, decodeVpnProfileBytes(utf8.encode(link)),
      decodeVpnProfileBytes(utf8.encode(jsonEncode(root))), decodeVpnProfileBytes(utf8.encode(config))]) {
      final out = endpoint(text);
      expect(out['peers'][0]['persistent_keepalive_interval'], 30);
      expect(out['awg']['random_trailers'], true);
      expect(out['awg']['disable_cookies'], true);
      expect(out['awg']['i1'], '<r 2><b 0x01020304>');
      expect(jsonEncode(out), isNot(contains(r'$PRIMARY_DNS')));
      expect(jsonEncode(out), isNot(contains(r'$SECONDARY_DNS')));
    }
  });

  test('normalizes structured Amnezia keepalive ranges', () {
    final root = amneziaStructuredContainer();
    final awg = root['containers'][0]['awg'] as Map;
    final client = jsonDecode(awg['last_config'] as String) as Map;
    client['persistent_keep_alive'] = '25-35';
    awg['last_config'] = jsonEncode(client);
    expect(endpoint(amneziaTestLink(root))['peers'][0]['persistent_keepalive_interval'], 30);
  });

  for (final entry in {'0': 0, '25': 25, '25-25': 25, '25-35': 30,
    '25-34': 29, '65535-65535': 65535}.entries) {
    test('normalizes keepalive ${entry.key} to a native uint16', () {
      final config = awgTestConfig().replaceFirst('PersistentKeepalive = 25', 'PersistentKeepalive = ${entry.key}');
      expect(endpoint(config)['peers'][0]['persistent_keepalive_interval'], entry.value);
    });
  }

  for (final value in ['35-25', '-1', '25-', '25-35-45', '1-65536', '65536', 'on']) {
    test('rejects malformed or out-of-bounds keepalive $value', () {
      final config = awgTestConfig().replaceFirst('PersistentKeepalive = 25', 'PersistentKeepalive = $value');
      expect(() => prepareVpnProfile(config), throwsA(isA<VpnProfileException>()));
    });
  }

  for (final value in [r'$PRIMARY_DNS', r'$SECONDARY_DNS', r'1.1.1.1, $SECONDARY_DNS']) {
    test('accepts known Amnezia DNS tokens $value', () {
      final config = awgTestConfig().replaceFirst('DNS = 1.1.1.1, 2606:4700:4700::1111', 'DNS = $value');
      expect(endpoint(config)['type'], 'awg');
    });
  }

  for (final value in [r'$UNKNOWN_DNS', r'$PRIMARY_DNS.evil', 'resolver.example.com', '1.1.1.999']) {
    test('rejects unsupported DNS values $value', () {
      final config = awgTestConfig().replaceFirst('DNS = 1.1.1.1, 2606:4700:4700::1111', 'DNS = $value');
      expect(() => prepareVpnProfile(config), throwsA(isA<VpnProfileException>()));
    });
  }

  test('accepts legacy uncompressed JSON, CRLF, BOM and comments', () {
    final config = '\uFEFF# Name = private-name\r\n${awgTestConfig().replaceAll('\n', '\r\n')}';
    expect(endpoint(config)['tag'], 'Mit-AWG');
    expect(endpoint(amneziaTestLink(amneziaTestContainer(awgTestConfig()), compressed: false))['type'], 'awg');
  });

  test('imports base64 conf and query style awg links with IPv6 endpoint', () {
    final conf = awgTestConfig().replaceFirst('192.0.2.10:51820', '[2001:db8::1]:51820');
    expect(endpoint('awg://${base64Url.encode(utf8.encode(conf))}')['peers'][0]['address'], '2001:db8::1');
    final query = Uri(scheme: 'awg', host: '2001:db8::1', port: 51820, queryParameters: {
      'pk': testWgKey(1), 'publickey': testWgKey(65), 'psk': testWgKey(33),
      'address': '10.8.0.2/32', 'allowedips': '0.0.0.0/0',
      'jc': '4', 'jmin': '40', 'jmax': '70', 's1': '15', 's2': '18',
      'h1': '1001', 'h2': '2001', 'h3': '3001', 'h4': '4001', 'keepalive': '25',
    }).toString();
    expect(endpoint(query)['awg']['s1'], 15);
    expect(endpoint(query)['peers'][0]['address'], '2001:db8::1');
    expect(() => prepareVpnProfile('$query&pk=duplicate'), throwsA(isA<VpnProfileException>()));
    expect(() => prepareVpnProfile('$query&detour=direct'), throwsA(isA<VpnProfileException>()));
  });

  test('imports old structured last_config without a native config string', () {
    final root = amneziaStructuredContainer();
    root['port'] = 22; // SSH port must not become the tunnel endpoint.
    final out = endpoint(amneziaTestLink(root));
    expect(out['private_key'], testWgKey(1));
    expect(out['peers'][0]['port'], 51820);
    expect(out['awg']['h1'], '1001');
    expect(out['awg']['s1'], 15);
    expect(out['peers'][0]['preshared_key'], testWgKey(33));
    final awg = (root['containers'] as List).single['awg'] as Map;
    final client = jsonDecode(awg['last_config'] as String) as Map;
    client['Jc'] = ''; // Old clients serialize an unset field as an empty string.
    awg['last_config'] = jsonEncode(client);
    expect(endpoint(amneziaTestLink(root))['awg']['jc'], 4);
  });

  test('accepts known empty optional fields and supplements obfuscation metadata', () {
    expect(endpoint(awgOptionalEmptyConfig())['awg']['i1'], '<b 0x01020304>');
    final root = amneziaTestContainer(awgTestConfig().replaceFirst('S3 = 6', 'S3 = '));
    final awg = (root['containers'] as List).single['awg'] as Map;
    awg['S3'] = '6'; awg['I2'] = '';
    expect(endpoint(amneziaTestLink(root))['awg']['s3'], 6);
    expect(() => prepareVpnProfile(awgTestConfig().replaceFirst('S3 = 6', 'UnknownOption = ')), throwsA(isA<VpnProfileException>()));
    expect(() => prepareVpnProfile(awgTestConfig().replaceFirst('S3 = 6', 'Jc = ')), throwsA(isA<VpnProfileException>()));
  });

  test('accepts an AWG connection export with a DNS container and explicit AWG selection', () {
    final root = amneziaTestContainer(awgTestConfig());
    (root['containers'] as List).add({'container': 'amnezia-dns', 'dns': {}});
    expect(endpoint(amneziaTestLink(root))['type'], 'awg');
    (root['containers'] as List).add({'container': 'amnezia-awg2', 'awg': {'last_config': jsonEncode({'config': awgTestConfig()})}});
    expect(endpoint(amneziaTestLink(root))['type'], 'awg'); // defaultContainer selects awg.
    root.remove('defaultContainer');
    expect(() => prepareVpnProfile(amneziaTestLink(root)), throwsA(isA<VpnProfileException>()));
  });

  test('decodes .vpn URL, JSON, Base64URL and Qt binary without exposing source', () {
    final root = amneziaStructuredContainer();
    final url = amneziaTestLink(root);
    final binary = base64Url.decode(base64Url.normalize(url.substring(6)));
    for (final data in [utf8.encode(url), utf8.encode(jsonEncode(root)), utf8.encode(url.substring(6)), binary]) {
      expect(endpoint(decodeVpnProfileBytes(data))['type'], 'awg');
    }
    try { prepareVpnProfile('vpn://bad'); fail('invalid key was accepted'); }
    on VpnProfileException catch (e) { expect(e.message, contains('AWG-01')); expect(e.source, isNull); }
    final noAwg = amneziaTestContainer(awgTestConfig()); noAwg['containers'] = [];
    expect(() => prepareVpnProfile(amneziaTestLink(noAwg)), throwsA(isA<VpnProfileException>().having((e) => e.message, 'safe diagnostic', contains('AWG-02'))));
  });

  test('supports wrapped share keys without merging multiple profiles', () {
    final link = amneziaTestLink(amneziaStructuredContainer());
    final wrapped = link.substring(0, 36) + '\n \u200B' + link.substring(36);
    expect(endpoint(wrapped)['type'], 'awg');
    expect(() => prepareVpnProfile('$link\n$link'), throwsA(isA<VpnProfileException>()));
  });

  test('still imports VLESS REALITY unchanged', () {
    final pbk = base64Url.encode(List.generate(32, (i) => i + 1)).replaceAll('=', '');
    final link = 'vless://00000000-0000-4000-8000-000000000001@example.com:443?security=reality&sni=example.com&fp=chrome&pbk=$pbk';
    final prepared = prepareVpnProfile(link);
    expect(prepared.protocol, MitVpnProtocol.reality);
    expect(prepared.content, link);
  });

  test('preserves bounded packet templates with random bytes, text, timestamp and QUIC decoy', () {
    const template = '<b 0x0102><r 32><rc 8><rd 8><t><dz 2><d><ds><qi example.com>';
    final config = awgTestConfig().replaceFirst('<b 0x01020304>', template);
    expect(endpoint(config)['awg']['i1'], template);
  });

  test('never accepts server administration, subscriptions or ambiguous containers', () {
    final admin = amneziaTestContainer(awgTestConfig())..['password'] = 'private-admin-password';
    expect(() => prepareVpnProfile(amneziaTestLink(admin)), throwsA(isA<VpnProfileException>().having((e) => e.message, 'safe explanation', contains('Поделиться подключением'))));
    final multi = amneziaTestContainer(awgTestConfig());
    (multi['containers'] as List).add((multi['containers'] as List).first);
    expect(() => prepareVpnProfile(amneziaTestLink(multi)), throwsA(isA<VpnProfileException>()));
    for (final input in ['https://example.com/profile', '{"endpoints":[]}', 'vpn://bad', 'vpn://${base64Url.encode(utf8.encode('{"api_key":"synthetic"}'))}']) {
      expect(() => prepareVpnProfile(input), throwsA(isA<VpnProfileException>()));
    }
  });

  test('bounds declared and actual decompression size and checks the Qt length', () {
    final prefix = ByteData(4)..setUint32(0, 32);
    final bomb = [...prefix.buffer.asUint8List(), ...zlib.encode(List.filled(maxVpnProfileBytes * 4, 65))];
    expect(() => prepareVpnProfile('vpn://${base64Url.encode(bomb)}'), throwsA(isA<VpnProfileException>()));
    final tooLarge = ByteData(4)..setUint32(0, maxVpnProfileBytes + 1);
    expect(() => prepareVpnProfile('vpn://${base64Url.encode([...tooLarge.buffer.asUint8List(), ...zlib.encode([1])])}'), throwsA(isA<VpnProfileException>()));
    final mismatch = [...prefix.buffer.asUint8List(), ...zlib.encode(utf8.encode('{}'))];
    expect(() => prepareVpnProfile('vpn://${base64Url.encode(mismatch)}'), throwsA(isA<VpnProfileException>()));
  });

  final invalid = <String, String Function(String)>{
    'missing private key': (s) => s.replaceFirst('PrivateKey = ${testWgKey(1)}', ''),
    'invalid public key': (s) => s.replaceFirst(testWgKey(65), 'invalid-public-key'),
    'duplicate private key': (s) => s.replaceFirst('MTU = 1280', 'PrivateKey = ${testWgKey(1)}'),
    'unknown obfuscation': (s) => s.replaceFirst('MTU = 1280', 'FutureObfuscation = 1'),
    'shell command': (s) => s.replaceFirst('MTU = 1280', 'PostUp = echo private-command'),
    'second peer': (s) => '$s\n[Peer]\nPublicKey = ${testWgKey(65)}',
    'second profile': (s) => '$s\n$s',
    'bad endpoint port': (s) => s.replaceFirst(':51820', ':65536'),
    'bad address': (s) => s.replaceFirst('10.8.0.2/32', '10.8.0.2/33'),
    'bad allowed IP': (s) => s.replaceFirst('0.0.0.0/0', 'example.com'),
    'malformed numeric': (s) => s.replaceFirst('Jc = 4', 'Jc = invalid'),
    'unbounded junk': (s) => s.replaceFirst('Jc = 4', 'Jc = 99999999'),
    'reversed junk range': (s) => s.replaceFirst('Jmax = 70', 'Jmax = 20'),
    'bad header range': (s) => s.replaceFirst('1001-1009', '1009-1001'),
    'bad header key': (s) => s.replaceFirst(List.filled(64, '1').join(), 'bad-key'),
    'bad boolean': (s) => s.replaceFirst('RandomTrailers = 1', 'RandomTrailers = invalid'),
    'negative template size': (s) => s.replaceFirst('<b 0x01020304>', '<r -1>'),
    'unbounded random packet': (s) => s.replaceFirst('<b 0x01020304>', '<r 999999999>'),
    'unbounded digit packet': (s) => s.replaceFirst('<b 0x01020304>', '<rd 999999999>'),
    'unbounded size field': (s) => s.replaceFirst('<b 0x01020304>', '<dz 999999999>'),
    'oversized complete packet': (s) => s.replaceFirst('<b 0x01020304>', '<r 40000><rc 40000>'),
    'invalid byte packet': (s) => s.replaceFirst('<b 0x01020304>', '<b 0x123>'),
    'unknown packet instruction': (s) => s.replaceFirst('<b 0x01020304>', '<unknown 4>'),
    'malformed packet instruction': (s) => s.replaceFirst('<b 0x01020304>', '<r 32'),
    'oversized input': (s) => 'x' * (maxVpnProfileBytes + 1),
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key} without showing credential or source', () {
      try {
        prepareVpnProfile(entry.value(awgTestConfig(version: 3)));
        fail('accepted invalid profile');
      } on VpnProfileException catch (error) {
        expect(error.source, isNull);
        expect(error.toString(), isNot(contains(testWgKey(1))));
        expect(error.toString(), isNot(contains('192.0.2.10')));
        expect(error.toString(), isNot(contains('private-command')));
      }
    });
  }
}
