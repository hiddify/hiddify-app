import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';

const _appAgent = 'HiddifyNext/9.9.9 (android) like ClashMeta v2ray sing-box';

void main() {
  late HttpServer server;
  late String base;
  late List<String?> seen;

  setUp(() async {
    seen = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    unawaited(
      server.forEach((request) {
        seen.add(request.headers.value(HttpHeaders.userAgentHeader));
        if (request.uri.path == '/redirect') {
          request.response
            ..statusCode = HttpStatus.found
            ..headers.set(HttpHeaders.locationHeader, '/final');
        } else {
          request.response.write('ok');
        }
        request.response.close();
      }),
    );
  });

  tearDown(() => server.close(force: true));

  DioHttpClient client() => DioHttpClient(timeout: const Duration(seconds: 5), userAgent: _appAgent, debug: false);

  test('a request without a user agent of its own carries the app one', () async {
    await client().get('$base/plain');

    expect(seen, [_appAgent]);
  });

  test('a user agent given for the request is the one sent', () async {
    await client().get('$base/plain', userAgent: 'HiddifyNextX/9.9.9');

    expect(seen, ['HiddifyNextX/9.9.9']);
  });

  test('a redirect is followed with the same user agent', () async {
    await client().get('$base/redirect');

    expect(seen, [_appAgent, _appAgent]);
  });

  test('a download carries it too', () async {
    final file = File('${Directory.systemTemp.path}/ua_download_${DateTime.now().microsecondsSinceEpoch}');
    addTearDown(() => file.existsSync() ? file.deleteSync() : null);

    await client().download('$base/plain', file.path);

    expect(seen, [_appAgent]);
  });

  test('the user agent of dart:io is never sent, whatever asks for it', () async {
    await client().get('$base/plain', userAgent: 'Dart/3.10 (dart:io)');
    await client().get('$base/plain', userAgent: '');

    expect(seen, [_appAgent, _appAgent]);
    expect(seen.where((agent) => agent?.startsWith('Dart') ?? true), isEmpty);
  });
}
