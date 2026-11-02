import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/one_tap/mit_updates.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final ResponseBody Function(RequestOptions options) reply;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async => reply(options);
  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> release([String tag = 'mit-beta-1.6.0']) => {
  'draft': false, 'tag_name': tag, 'body': 'Изменения',
  'assets': [for (final name in ['mits-vpn.apk', 'mits-vpn-update.json'])
    {'name': name, 'browser_download_url': mitReleaseAsset(tag, name).toString()}],
};
Map<String, dynamic> manifest() => {'schema': 1, 'application_id': 'app.hiddify.com',
  'version': '1.6.0-beta', 'build_number': 50006, 'apk_size': 3, 'apk_sha256': 'a' * 64};

void main() {
  test('only a newer canonical release is offered', () {
    expect(parseMitUpdate(release(), manifest())!.build, 50006);
    expect(parseMitUpdate(release(), manifest(), currentBuild: 50006), isNull);
    expect(parseMitUpdate(release(), manifest(), currentBuild: 50007), isNull);
  });
  test('metadata rejects wrong identity, tag, version, hash and bounds', () {
    for (final entry in {'schema': 2, 'application_id': 'other.app', 'version': '1.6.0',
      'build_number': 2147483648, 'apk_size': mitMaxApkBytes + 1, 'apk_sha256': 'oops'}.entries) {
      expect(() => parseMitUpdate(release(), {...manifest(), entry.key: entry.value}), throwsA(isA<MitUpdateException>()));
    }
    expect(() => parseMitUpdate({...release(), 'draft': true}, manifest()), throwsA(isA<MitUpdateException>()));
    expect(() => parseMitUpdate(release('mit-beta-1.7.0'), manifest()), throwsA(isA<MitUpdateException>()));
    final spoof = {...release(), 'assets': [{'name': 'mits-vpn.apk', 'browser_download_url': 'https://evil.test/update.apk'}]};
    expect(() => parseMitUpdate(spoof, manifest()), throwsA(isA<MitUpdateException>()));
  });
  test('redirect trust excludes HTTP, credentials, ports and lookalike hosts', () {
    expect(mitAllowedUpdateUrl(Uri.parse('https://release-assets.githubusercontent.com/file?token=x')), true);
    for (final url in ['http://github.com/a', 'https://github.com.evil.test/a',
      'https://user:password@github.com/a', 'https://github.com:8443/a', 'https://github.com/a#b']) {
      expect(mitAllowedUpdateUrl(Uri.parse(url)), false);
    }
  });
  test('check finds canonical release and rejects an untrusted redirect', () async {
    final dio = Dio()..httpClientAdapter = _Adapter((o) => ResponseBody.fromString(
      jsonEncode(o.uri.host == 'api.github.com' ? [release()] : manifest()), 200));
    expect((await MitUpdateService(dio).check(CancelToken()))!.version, '1.6.0-beta');
    var calls = 0;
    dio.httpClientAdapter = _Adapter((o) { calls++; return ResponseBody.fromString('', 302,
      headers: {'location': ['https://evil.test/a']}); });
    await expectLater(MitUpdateService(dio).check(CancelToken()), throwsA(isA<MitUpdateException>()));
    expect(calls, 1);
  });
  test('download enforces actual bytes, removes partial files and respects cancellation', () async {
    final directory = await Directory.systemTemp.createTemp('mit-update-test');
    addTearDown(() => directory.delete(recursive: true));
    final candidate = parseMitUpdate(release(), manifest())!;
    final dio = Dio()..httpClientAdapter = _Adapter((_) => ResponseBody.fromBytes([1, 2, 3], 200));
    final service = MitUpdateService(dio);
    await service.download(candidate, directory, CancelToken(), (_, __) {});
    final apk = File('${directory.path}/mits-vpn-update.apk');
    expect(await apk.readAsBytes(), [1, 2, 3]);
    for (final bytes in [[1, 2], [1, 2, 3, 4]]) {
      dio.httpClientAdapter = _Adapter((_) => ResponseBody.fromBytes(bytes, 200));
      await expectLater(service.download(candidate, directory, CancelToken(), (_, __) {}), throwsA(isA<MitUpdateException>()));
      expect(await File('${directory.path}/mits-vpn-update.apk.part').exists(), false);
      expect(await apk.readAsBytes(), [1, 2, 3]);
    }
    final token = CancelToken()..cancel();
    await expectLater(service.download(candidate, directory, token, (_, __) {}), throwsA(isA<DioException>()));
    expect(await File('${directory.path}/mits-vpn-update.apk.part').exists(), false);
  });
}
