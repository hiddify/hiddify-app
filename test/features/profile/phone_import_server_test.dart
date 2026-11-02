import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart';

const _text = (
  lang: 'en',
  rtl: false,
  title: 'Send <to> TV',
  intro: 'Four steps',
  network: (title: 'Same Wi-Fi', body: 'Join it'),
  copy: (title: 'Copy', body: 'Copy the link'),
  paste: (title: 'Paste', body: 'Paste it'),
  confirm: (title: 'Confirm', body: 'Press Import'),
  label: 'Link',
  hint: 'Paste',
  send: 'Send',
  sentTitle: 'Sent to TV',
  sent: 'Press Import on the TV',
  empty: 'Paste a link first',
  footer: 'Local only',
);

void main() {
  late PhoneImportServer server;
  late HttpClient client;

  setUp(() async {
    server = await PhoneImportServer.start(InternetAddress.loopbackIPv4, _text);
    client = HttpClient()..autoUncompress = false;
  });

  tearDown(() async {
    client.close(force: true);
    await server.close();
  });

  Future<HttpClientResponse> send(String method, Uri uri, {String? body, String? host, String? type}) async {
    final request = await client.openUrl(method, uri);
    request.followRedirects = false;
    if (host != null) request.headers.host = host;
    if (body != null) {
      request.headers.contentType = ContentType.parse(type ?? 'application/x-www-form-urlencoded');
      request.write(body);
    }
    return request.close();
  }

  String form(String link) => 'link=${Uri.encodeQueryComponent(link)}';

  test('the address carries a 6 digit code, new on each start', () async {
    final codes = {server.url.path};
    for (var i = 0; i < 3; i++) {
      final other = await PhoneImportServer.start(InternetAddress.loopbackIPv4, _text);
      codes.add(other.url.path);
      await other.close();
    }
    expect(server.url.path, matches(RegExp(r'^/\d{6}$')));
    expect(codes.length, greaterThan(1));
  });

  test('too many wrong codes lock the page for everyone, the right code too', () async {
    // a browser's own icon request is no guess
    expect((await send('GET', server.url.replace(path: '/favicon.ico'))).statusCode, HttpStatus.notFound);
    for (var i = 0; i < PhoneImportServer.maxMisses - 1; i++) {
      expect((await send('GET', server.url.replace(path: '/guess$i'))).statusCode, HttpStatus.notFound);
    }
    expect(server.isLocked, isFalse);
    expect((await send('GET', server.url)).statusCode, HttpStatus.ok);

    // a request naming another host counts as a wrong try too
    expect((await send('GET', server.url, host: 'evil.example')).statusCode, HttpStatus.notFound);
    await server.whenLocked;
    expect((await send('GET', server.url)).statusCode, HttpStatus.notFound);
    expect((await send('POST', server.url, body: form('link'))).statusCode, HttpStatus.notFound);
  });

  test('serves the page, escaped and locked down, only at the secret path', () async {
    final page = await send('GET', server.url);
    expect(page.statusCode, HttpStatus.ok);
    final html = await utf8.decodeStream(page);
    expect(html, contains('Send &lt;to&gt; TV'));
    expect(html, isNot(contains('<script')));
    expect(page.headers.value('content-security-policy'), contains("default-src 'none'"));
    expect(page.headers.value('cache-control'), 'no-store');

    final root = server.url.replace(path: '/');
    expect((await send('GET', root)).statusCode, HttpStatus.notFound);
    final wrong = server.url.replace(path: '${server.url.path.substring(0, server.url.path.length - 1)}x');
    expect((await send('GET', wrong)).statusCode, HttpStatus.notFound);
  });

  test('refuses a request naming another host', () async {
    final response = await send('GET', server.url, host: 'evil.example');
    expect(response.statusCode, HttpStatus.notFound);
  });

  test('offers what the phone sends, then sends it back to the page', () async {
    final received = server.entries.first;
    final response = await send('POST', server.url, body: form('  https://example.com/sub?token=a&b=c  '));
    expect(response.statusCode, HttpStatus.seeOther);
    expect(response.headers.value('location'), '${server.url.path}?sent');
    final entry = await received;
    expect(entry.text, 'https://example.com/sub?token=a&b=c');
    expect(entry.from.isLoopback, isTrue);

    final page = await utf8.decodeStream(await send('GET', server.url.replace(query: 'sent')));
    expect(page, contains('Sent'));
  });

  test('refuses an empty text, another content type, and too much text', () async {
    final empty = await send('POST', server.url, body: form('   '));
    expect(empty.statusCode, HttpStatus.badRequest);
    expect(await utf8.decodeStream(empty), contains('Paste a link first'));

    final json = await send('POST', server.url, body: '{"link":"x"}', type: 'application/json');
    expect(json.statusCode, HttpStatus.unsupportedMediaType);

    final large = await send('POST', server.url, body: form('a' * (PhoneImportServer.maxText + 1)));
    expect(large.statusCode, HttpStatus.requestEntityTooLarge);
  });

  test('stops taking texts while too many wait on the TV', () async {
    for (var i = 0; i < PhoneImportServer.maxPending; i++) {
      expect((await send('POST', server.url, body: form('link $i'))).statusCode, HttpStatus.seeOther);
    }
    expect((await send('POST', server.url, body: form('one more'))).statusCode, HttpStatus.tooManyRequests);
    server.handled();
    expect((await send('POST', server.url, body: form('one more'))).statusCode, HttpStatus.seeOther);
  });

  test('only local networks count as local', () {
    bool local(String ip) => isLocalNetwork(InternetAddress(ip));
    for (final ip in ['10.1.2.3', '172.16.0.1', '172.31.255.1', '192.168.1.20', '169.254.1.1', '127.0.0.1']) {
      expect(local(ip), isTrue, reason: ip);
    }
    for (final ip in ['fe80::1', 'fd12:3456::1', '::ffff:192.168.1.20']) {
      expect(local(ip), isTrue, reason: ip);
    }
    for (final ip in ['8.8.8.8', '172.32.0.1', '100.64.0.1', '2001:4860::8888', '::ffff:8.8.8.8']) {
      expect(local(ip), isFalse, reason: ip);
    }
  });
}
