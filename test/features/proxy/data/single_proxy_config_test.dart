import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/proxy/data/single_proxy_config.dart';

void main() {
  Map<String, dynamic> decode(String? json) => jsonDecode(json!) as Map<String, dynamic>;

  final generated = jsonEncode({
    'outbounds': [
      {
        'type': 'selector',
        'tag': 'select',
        'outbounds': ['a § 0', 'b § 1'],
      },
      {
        'type': 'vless',
        'tag': 'a § 0',
        'server': '1.2.3.4',
        'detour': 'direct-fragment §hide§',
        'domain_resolver': 'dns-direct',
      },
      {'type': 'trojan', 'tag': 'b § 1', 'server': '5.6.7.8', 'detour': 'a § 0'},
      {'type': 'direct', 'tag': 'direct-fragment §hide§'},
    ],
    'endpoints': [
      {'type': 'wireguard', 'tag': 'wg § 2', 'detour': 'a § 0'},
    ],
  });

  test('takes the proxy from the generated config, without what only the app knows', () {
    expect(decode(singleProxyConfig('a § 0', generated: generated)), {
      'outbounds': [
        {'type': 'vless', 'tag': 'a', 'server': '1.2.3.4'},
      ],
    });
  });

  test('keeps the proxies it dials through', () {
    expect(decode(singleProxyConfig('b § 1', generated: generated)), {
      'outbounds': [
        {'type': 'trojan', 'tag': 'b', 'server': '5.6.7.8', 'detour': 'a § 0'},
        {'type': 'vless', 'tag': 'a § 0', 'server': '1.2.3.4'},
      ],
    });
  });

  test('an endpoint stays an endpoint, its detour an outbound', () {
    final config = decode(singleProxyConfig('wg § 2', generated: generated));
    expect((config['endpoints'] as List).single, {'type': 'wireguard', 'tag': 'wg', 'detour': 'a § 0'});
    expect((config['outbounds'] as List).single, containsPair('tag', 'a § 0'));
  });

  test('takes the proxy from the saved profile by name first', () {
    final raw = jsonEncode({
      'outbounds': [
        {'type': 'vless', 'tag': 'a ', 'server': '9.9.9.9', 'server_port': 443},
      ],
    });
    expect(decode(singleProxyConfig('a § 0', raw: raw, generated: generated)), {
      'outbounds': [
        {'type': 'vless', 'tag': 'a', 'server': '9.9.9.9', 'server_port': 443},
      ],
    });
  });

  test('tells proxies of the same name apart by port, then by server', () {
    final raw = jsonEncode({
      'outbounds': [
        {'type': 'vmess', 'tag': 'dup', 'server': '1.1.1.1', 'server_port': 80},
        {'type': 'vmess', 'tag': 'dup', 'server': '2.2.2.2', 'server_port': 443},
        {'type': 'vmess', 'tag': 'dup', 'server': '3.3.3.3', 'server_port': 443},
      ],
    });
    String? server(String? json) =>
        json == null ? null : ((decode(json)['outbounds'] as List).single as Map)['server'] as String?;
    expect(server(singleProxyConfig('dup § 2', port: 80, raw: raw)), '1.1.1.1');
    expect(server(singleProxyConfig('dup § 2', host: '3.3.3.3', port: 443, raw: raw)), '3.3.3.3');
    // the core names the address, the profile a domain: still two of them
    expect(singleProxyConfig('dup § 2', host: 'example.com', port: 443, raw: raw), isNull);
  });

  test('the generated config counts only when the port agrees', () {
    final withPort = jsonEncode({
      'outbounds': [
        {'type': 'vless', 'tag': 'x § 3', 'server': '1.2.3.4', 'server_port': 443},
      ],
    });
    expect(singleProxyConfig('x § 3', port: 443, generated: withPort), isNotNull);
    expect(singleProxyConfig('x § 3', port: 8443, generated: withPort), isNull);
    expect(singleProxyConfig('missing', generated: generated), isNull);
    expect(singleProxyConfig('a', generated: 'not json'), isNull);
  });
}
