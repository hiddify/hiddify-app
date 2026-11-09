import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/features/app_update/data/github_release_parser.dart';
import 'package:hiddify/features/app_update/model/install_kind.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/notifier/app_updater.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

const _payload = 'trusted update';
const _sha256 = '3e815a6f9d8c44b0c2fc5d26f77545bb0d4378f1693d3dc425e654261f8780fc';

String _assetName(InstallKind kind) =>
    kind == InstallKind.androidApk ? 'Hiddify-Android-arm64.apk' : 'Hiddify-Linux-x64-AppImage.AppImage';

RemoteVersionEntity _release(InstallKind kind, Object? digest, {int size = 14}) => GithubReleaseParser.parse({
  'tag_name': 'v9.9.9',
  'html_url': 'https://github.com/hiddify/hiddify-app/releases/tag/v9.9.9',
  'published_at': '2026-11-01T00:00:00Z',
  'assets': [
    {
      'name': _assetName(kind),
      'browser_download_url': 'https://example.invalid/${_assetName(kind)}',
      'size': size,
      'digest': digest,
    },
  ],
})!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('com.hiddify.app/platform');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory temporary;
  late PathProviderPlatform originalPaths;
  late _DownloadClient client;
  late List<String> installations;
  late List<AppUpdaterState> states;
  ProviderContainer? container;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('hiddify-update-digest-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(temporary.path);
    client = _DownloadClient();
    installations = [];
    states = [];
    messenger.setMockMethodCallHandler(platform, (call) async {
      if (call.method == 'supported_abis') return ['arm64-v8a'];
      if (call.method == 'install_apk') {
        final path = call.arguments as String;
        installations.add(await File(path).readAsString());
        return 'started';
      }
      throw StateError('Unexpected platform method: ${call.method}');
    });
  });

  tearDown(() async {
    container?.dispose();
    container = null;
    messenger.setMockMethodCallHandler(platform, null);
    PathProviderPlatform.instance = originalPaths;
    await temporary.delete(recursive: true);
  });

  AppUpdater updater(InstallKind kind) {
    container = ProviderContainer(
      overrides: [installKindProvider.overrideWithValue(kind), httpClientProvider.overrideWithValue(client)],
    );
    container!.listen(appUpdaterProvider, (_, next) => states.add(next));
    return container!.read(appUpdaterProvider.notifier);
  }

  for (final kind in [InstallKind.androidApk, InstallKind.linuxAppImage]) {
    group('$kind', () {
      test('a same-size modified payload is rejected before installation', () async {
        client.payload = 'altered update';
        expect(utf8.encode(client.payload).length, utf8.encode(_payload).length);
        await updater(kind).update(_release(kind, 'sha256:$_sha256'));

        expect(container!.read(appUpdaterProvider), isA<AppUpdaterFailed>());
        expect(states.whereType<AppUpdaterInstalling>(), isEmpty);
        expect(installations, isEmpty);
        expect(client.downloads, 1);
        expect(File('${temporary.path}/updates/${_assetName(kind)}').existsSync(), isFalse);
      });

      for (final digest in <Object?>[null, '', 'md5:$_sha256', 'sha256:abc', 'sha256:${'z' * 64}', 42]) {
        test('missing or invalid digest ($digest) fails before downloading', () async {
          await updater(kind).update(_release(kind, digest));

          expect(container!.read(appUpdaterProvider), isA<AppUpdaterFailed>());
          expect(states.whereType<AppUpdaterInstalling>(), isEmpty);
          expect(installations, isEmpty);
          expect(client.downloads, 0);
        });
      }
    });
  }

  for (final size in [0, 14]) {
    test('a verified Android payload reaches the installer with declared size $size', () async {
      await updater(InstallKind.androidApk).update(_release(InstallKind.androidApk, 'sha256:$_sha256', size: size));

      expect(container!.read(appUpdaterProvider), isNot(isA<AppUpdaterFailed>()));
      expect(installations, [_payload]);
      expect(client.downloads, 1);
    });
  }

  test('uppercase SHA-256 hexadecimal is accepted', () async {
    await updater(InstallKind.androidApk).update(_release(InstallKind.androidApk, 'sha256:${_sha256.toUpperCase()}'));
    expect(installations, [_payload]);
  });

  test('a valid digest does not bypass a declared-size mismatch', () async {
    await updater(InstallKind.androidApk).update(_release(InstallKind.androidApk, 'sha256:$_sha256', size: 15));
    expect(container!.read(appUpdaterProvider), isA<AppUpdaterFailed>());
    expect(states.whereType<AppUpdaterInstalling>(), isEmpty);
    expect(installations, isEmpty);
  });

  test('asset identity includes the release digest', () {
    final original = _release(InstallKind.androidApk, 'sha256:$_sha256').assets.single;
    final changed = _release(InstallKind.androidApk, 'sha256:${'0' * 64}').assets.single;
    expect(original, isNot(changed));
    expect(original, _release(InstallKind.androidApk, 'sha256:$_sha256').assets.single);
  });
}

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

class _DownloadClient extends DioHttpClient {
  _DownloadClient() : super(timeout: const Duration(seconds: 1), userAgent: 'regression-test', debug: false);
  String payload = _payload;
  int downloads = 0;

  @override
  Future<Response> download(
    String url,
    String path, {
    CancelToken? cancelToken,
    String? userAgent,
    ({String username, String password})? credentials,
    bool proxyOnly = false,
    ProgressCallback? onReceiveProgress,
  }) async {
    downloads++;
    final bytes = utf8.encode(payload);
    await File(path).writeAsBytes(bytes);
    onReceiveProgress?.call(bytes.length, bytes.length);
    return Response(requestOptions: RequestOptions(path: url), statusCode: 200);
  }
}
