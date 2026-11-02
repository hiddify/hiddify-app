import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Deterministic synthetic credentials and documentation-only endpoint.
String testWgKey(int offset) => base64.encode(List.generate(32, (i) => (i + offset) % 256));

String awgTestConfig({int version = 2}) => '''[Interface]
PrivateKey = ${testWgKey(1)}
Address = 10.8.0.2/32, fd42::2/128
DNS = 1.1.1.1, 2606:4700:4700::1111
MTU = 1280
Jc = 4
Jmin = 40
Jmax = 70
S1 = 15
S2 = 18
H1 = ${version >= 2 ? '1001-1009' : '1001'}
H2 = 2001
H3 = 3001
H4 = 4001
${version >= 2 ? 'S3 = 6\nS4 = 8\nI1 = <b 0x01020304>\n' : ''}${version >= 3 ? '''HeaderProtectionKey = ${List.filled(64, '1').join()}
ContentPaddingAddition = 0-16
RekeyAfterTime = 100-120
RekeyTimeout = 5-8
RejectAfterTime = 160-180
KeepaliveTimeout = 10-15
MaxHandshakeAttempts = 12-18
RandomTrailers = 1
DisableCookies = 0
''' : ''}[Peer]
PublicKey = ${testWgKey(65)}
PresharedKey = ${testWgKey(33)}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 192.0.2.10:51820
PersistentKeepalive = 25
''';

Map<String, dynamic> amneziaTestContainer(String config) => {
  'description': 'private-display-name',
  'hostName': 'private-administrative-host',
  'userName': '', 'password': '',
  'defaultContainer': 'amnezia-awg',
  'containers': [{
    'container': 'amnezia-awg',
    'awg': {'last_config': jsonEncode({'config': config})},
  }],
};

String amneziaTestLink(Map<String, dynamic> container, {bool compressed = true}) {
  final json = utf8.encode(jsonEncode(container));
  final prefix = ByteData(4)..setUint32(0, json.length);
  final bytes = compressed ? [...prefix.buffer.asUint8List(), ...zlib.encode(json)] : json;
  return 'vpn://${base64Url.encode(bytes).replaceAll('=', '')}';
}


Map<String, dynamic> amneziaStructuredContainer() {
  final root = amneziaTestContainer('');
  final awg = (root['containers'] as List).single['awg'] as Map;
  awg['Jc'] = '4'; awg['Jmin'] = '40'; awg['Jmax'] = '70';
  awg['S1'] = '15'; awg['S2'] = '18';
  awg['H1'] = '1001'; awg['H2'] = '2001'; awg['H3'] = '3001'; awg['H4'] = '4001';
  awg['last_config'] = jsonEncode({
    'client_priv_key': testWgKey(1), 'server_pub_key': testWgKey(65), 'psk_key': testWgKey(33),
    'client_ip': ['10.8.0.2/32', 'fd42::2/128'], 'allowed_ips': ['0.0.0.0/0', '::/0'],
    'hostName': '192.0.2.10', 'port': 51820, 'mtu': '1280', 'persistent_keep_alive': '25',
  });
  return root;
}

String awgOptionalEmptyConfig() => awgTestConfig().replaceFirst('[Peer]', 'I2 = \nI3 = \nI4 = \nI5 = \nHeaderProtectionKey = \n[Peer]');

String awgBase64HeaderConfig() => awgTestConfig(version: 3)
    .replaceFirst(List.filled(64, '1').join(), testWgKey(0))
    .replaceFirst('RandomTrailers = 1', 'RandomTrailers = on')
    .replaceFirst('DisableCookies = 0', 'DisableCookies = on');

// Reproduces the exported syntax that Alpha 1.2 rejected, using synthetic
// credentials, a documentation endpoint and a synthetic packet constant.
String awgAmneziaPlaceholderConfig() => awgBase64HeaderConfig()
    .replaceFirst('DNS = 1.1.1.1, 2606:4700:4700::1111', r'DNS = $PRIMARY_DNS, $SECONDARY_DNS')
    .replaceFirst('PersistentKeepalive = 25', 'PersistentKeepalive = 25-35')
    .replaceFirst('<b 0x01020304>', '<r 2><b 0x01020304>');
