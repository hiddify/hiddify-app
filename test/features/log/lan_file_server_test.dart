import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/log/data/lan_file_server.dart';

void main() {
  late Directory dir;
  late File file;
  late LanFileServer server;
  final client = HttpClient();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lan_file_server');
    file = File('${dir.path}/diagnostics.zip')..writeAsBytesSync(List.generate(100000, (i) => i % 256));
    server = await LanFileServer.start(InternetAddress.loopbackIPv4, file);
  });

  tearDown(() async {
    await server.close();
    await dir.delete(recursive: true);
  });

  Future<HttpClientResponse> get(Uri uri) async => (await client.getUrl(uri)).close();

  test('serves the file at its secret address, as a download', () async {
    final downloaded = server.downloads.first;
    final response = await get(server.url);
    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.value('content-disposition'), 'attachment; filename="diagnostics.zip"');
    final bytes = await response.fold<List<int>>([], (all, chunk) => all..addAll(chunk));
    expect(bytes, file.readAsBytesSync());
    expect((await downloaded).isLoopback, isTrue);
  });

  test('anything but the secret address is not found', () async {
    final url = server.url;
    for (final path in ['/', '/diagnostics.zip', '/wrong/diagnostics.zip']) {
      final response = await get(url.replace(path: path));
      expect(response.statusCode, HttpStatus.notFound, reason: path);
      await response.drain<void>();
    }
  });

  test('a request naming another host is not served', () async {
    final request = await client.getUrl(server.url);
    request.headers.host = 'attacker.example';
    final response = await request.close();
    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });
}
