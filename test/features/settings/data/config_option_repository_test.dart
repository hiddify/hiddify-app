import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';

void main() {
  group('ConfigOptionRepository.keepOwnDnsBehindExtraSecurity', () {
    Map<String, dynamic> own({String chain = 'off'}) => {
      'remote-dns-address': 'udp://9.9.9.9',
      'direct-dns-address': 'udp://1.1.1.1',
      'chain-status': chain,
    };

    Map<String, dynamic> merge(Map<String, dynamic> own, Map<String, dynamic> override) =>
        ConfigOptionRepository.keepOwnDnsBehindExtraSecurity(
          own,
          ProfileParser.applyProfileOverride({...own}, jsonEncode(override)),
        );

    test('a profile sets the remote DNS while the chain is off', () {
      final merged = merge(own(), {'remote-dns-address': 'https://dns.provider/dns-query'});
      expect(merged['remote-dns-address'], 'https://dns.provider/dns-query');
    });

    test("with extra security on in the settings, the user's own remote DNS stays", () {
      final merged = merge(own(chain: 'extra_security'), {
        'remote-dns-address': 'https://dns.provider/dns-query',
        'direct-dns-address': 'udp://8.8.8.8',
      });
      expect(merged['remote-dns-address'], 'udp://9.9.9.9');
      expect(merged['direct-dns-address'], 'udp://8.8.8.8', reason: 'only the remote DNS is held back');
    });

    test('a profile that turns extra security on does not set the remote DNS either', () {
      final merged = merge(own(), {
        'remote-dns-address': 'https://dns.provider/dns-query',
        'chain-status': 'extra_security',
      });
      expect(merged['chain-status'], 'extra_security');
      expect(merged['remote-dns-address'], 'udp://9.9.9.9');
    });

    test('a profile without a DNS of its own changes nothing', () {
      final merged = merge(own(chain: 'extra_security'), {'connection-test-url': 'https://example.com'});
      expect(merged['remote-dns-address'], 'udp://9.9.9.9');
      expect(merged['connection-test-url'], 'https://example.com');
    });
  });
}
