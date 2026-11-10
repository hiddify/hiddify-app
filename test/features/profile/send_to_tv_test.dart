import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart';
import 'package:hiddify/features/profile/add/phone_import/send_to_tv.dart';

const _step = (title: 't', body: 'b');
const PhoneImportPageText _text = (
  lang: 'en',
  rtl: false,
  title: 'title',
  intro: 'intro',
  network: _step,
  copy: _step,
  paste: _step,
  confirm: _step,
  label: 'label',
  hint: 'hint',
  send: 'send',
  sentTitle: 'sentTitle',
  sent: 'sent',
  empty: 'empty',
  footer: 'footer',
);

void main() {
  group('parseTvImportCode', () {
    test('takes the code a TV shows', () {
      expect(parseTvImportCode('http://192.168.1.20:41234/123456'), isNotNull);
      expect(parseTvImportCode(' http://10.0.0.5:8080/000000\n'), isNotNull);
      expect(parseTvImportCode('http://[fd00::1]:8080/123456'), isNotNull);
    });

    test('refuses any other code', () {
      for (final code in [
        'vless://uuid@1.2.3.4:443',
        'https://example.com/sub',
        'http://8.8.8.8:80/123456', // not a local network
        'http://tv.local:8080/123456', // a name, not an address
        'http://192.168.1.20/123456', // no port
        'http://192.168.1.20:8080/12345',
        'http://192.168.1.20:8080/1234567',
        'http://192.168.1.20:8080/abcdef',
        'http://192.168.1.20:8080/123456?x=1',
        'http://u:p@192.168.1.20:8080/123456',
        'https://192.168.1.20:8080/123456',
      ]) {
        expect(parseTvImportCode(code), isNull, reason: code);
      }
    });
  });

  group('sendLinkToTv', () {
    late PhoneImportServer server;
    setUp(() async => server = await PhoneImportServer.start(InternetAddress.loopbackIPv4, _text));
    tearDown(() => server.close());

    test('the TV receives the link', () async {
      final received = server.entries.first;
      const link = 'https://sub.example.com/abc?name=My Sub#Mine';
      expect(await sendLinkToTv(server.url.toString(), link), SendToTvResult.sent);
      expect((await received).text, link);
    });

    test('a wrong code is never sent', () async {
      expect(await sendLinkToTv('https://example.com', 'x'), SendToTvResult.notTvCode);
    });

    test('a code the TV no longer serves is reported as expired', () async {
      final stale = server.url.replace(path: server.url.path == '/000000' ? '/111111' : '/000000');
      expect(await sendLinkToTv(stale.toString(), 'x'), SendToTvResult.expired);
    });

    test('a TV that is gone is unreachable', () async {
      final url = server.url;
      await server.close();
      expect(await sendLinkToTv(url.toString(), 'x'), SendToTvResult.unreachable);
      server = await PhoneImportServer.start(InternetAddress.loopbackIPv4, _text);
    });
  });
}
