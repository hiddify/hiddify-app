import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/proxy/model/ip_info_entity.dart';

void main() {
  group('IpInfo.fromIpApiJson', () {
    test('parses custom ipapi-compatible payload', () {
      final info = IpInfo.fromIpApiJson({
        'ip': '1.2.3.4',
        'city': 'Paris',
        'region': 'Ile-de-France',
        'region_code': 'IDF',
        'country_name': 'France',
        'country_code': 'FR',
        'continent_code': 'EU',
        'latitude': 48.85,
        'longitude': 2.35,
        'timezone': 'Europe/Paris',
        'utc_offset': '+0200',
        'currency': 'EUR',
        'currency_name': 'Euro',
        'languages': 'fr-FR,en-US',
        'asn': 'AS1234',
        'org': 'cloudflare',
      });
      expect(info.ip, '1.2.3.4');
      expect(info.countryCode, 'FR');
      expect(info.city, 'Paris');
      expect(info.region, 'Ile-de-France');
      expect(info.timezone, 'Europe/Paris');
      expect(info.asn, 'AS1234');
      expect(info.org, 'cloudflare');
    });

    test('accepts missing optional fields and normalizes asn', () {
      final info = IpInfo.fromIpApiJson({
        'ip': '8.8.8.8',
        'country_code': 'us',
        'asn': 15169,
      });
      expect(info.countryCode, 'US');
      expect(info.asn, 'AS15169');
      expect(info.city, isNull);
      expect(info.org, isNull);
    });

    test('rejects payload without ip/country', () {
      expect(() => IpInfo.fromIpApiJson({'city': 'x'}), throwsFormatException);
    });
  });

  group('IpInfo.fromIpwhoIsJson', () {
    test('reads connection and nested timezone', () {
      final info = IpInfo.fromIpwhoIsJson({
        'success': true,
        'ip': '1.1.1.1',
        'country_code': 'AU',
        'region': 'Queensland',
        'city': 'South Brisbane',
        'connection': {'asn': 13335, 'org': 'Cloudflare, Inc.'},
        'timezone': {'id': 'Australia/Brisbane'},
      });
      expect(info.asn, 'AS13335');
      expect(info.org, 'Cloudflare, Inc.');
      expect(info.timezone, 'Australia/Brisbane');
    });
  });

  group('IpInfo.fromIpInfoIoJson', () {
    test('splits AS+org and does not require trailing slash URL shape', () {
      final info = IpInfo.fromIpInfoIoJson({
        'ip': '8.8.8.8',
        'country': 'US',
        'timezone': 'America/Los_Angeles',
        'org': 'AS15169 Google LLC',
      });
      expect(info.countryCode, 'US');
      expect(info.asn, 'AS15169');
      expect(info.org, 'Google LLC');
    });
  });

  group('IpInfo.parseFlexible', () {
    test('falls through to ifconfig.co shape', () {
      final info = IpInfo.parseFlexible({
        'ip': '9.9.9.9',
        'country_iso': 'DE',
        'time_zone': 'Europe/Berlin',
        'asn': 'AS42',
        'asn_org': 'Test Org',
      });
      expect(info.countryCode, 'DE');
      expect(info.org, 'Test Org');
      expect(info.timezone, 'Europe/Berlin');
    });
  });
}
