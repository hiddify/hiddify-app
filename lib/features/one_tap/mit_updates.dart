import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/one_tap/mit_release.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const mitUpdateRepository = 'Mit-ping/Mit-s';
const mitMaxApkBytes = 350 * 1024 * 1024;

class MitUpdateException implements Exception {
  const MitUpdateException();
  @override
  String toString() => 'Не удалось проверить или скачать обновление. Повторите позже.';
}

class MitUpdateCandidate {
  const MitUpdateCandidate({required this.version, required this.build, required this.notes,
    required this.apk, required this.sha256, required this.size});
  final String version, notes, sha256;
  final int build, size;
  final Uri apk;
}

Uri mitReleaseAsset(String tag, String name) => Uri.https('github.com', '/$mitUpdateRepository/releases/download/$tag/$name');

bool mitAllowedUpdateUrl(Uri uri) => uri.scheme == 'https' && uri.userInfo.isEmpty &&
    (!uri.hasPort || uri.port == 443) && uri.fragment.isEmpty && {
      'api.github.com', 'github.com', 'release-assets.githubusercontent.com',
      'objects.githubusercontent.com', 'github-cloud.s3.amazonaws.com',
    }.contains(uri.host);

MitUpdateCandidate? parseMitUpdate(Map release, Map manifest, {int currentBuild = MitRelease.buildNumber}) {
  final tag = release['tag_name']; final version = manifest['version'];
  final build = manifest['build_number']; final size = manifest['apk_size']; final hash = manifest['apk_sha256'];
  if (release['draft'] != false || tag is! String || version is! String ||
      !RegExp(r'^\d+\.\d+\.\d+-beta$').hasMatch(version) || tag != 'mit-beta-${version.replaceFirst('-beta', '')}' ||
      manifest['schema'] != 1 || manifest['application_id'] != 'app.hiddify.com' ||
      build is! int || build <= 0 || build > 2147483647 || size is! int || size <= 0 || size > mitMaxApkBytes ||
      hash is! String || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) throw const MitUpdateException();
  final assets = release['assets'];
  if (assets is! List || !assets.whereType<Map>().any((a) => a['name'] == 'mits-vpn.apk' &&
      a['browser_download_url'] == mitReleaseAsset(tag, 'mits-vpn.apk').toString())) throw const MitUpdateException();
  if (build <= currentBuild) return null;
  final notes = release['body'] is String ? release['body'] as String : '';
  return MitUpdateCandidate(version: version, build: build, size: size, sha256: hash.toLowerCase(),
    notes: notes.length > 8000 ? notes.substring(0, 8000) : notes, apk: mitReleaseAsset(tag, 'mits-vpn.apk'));
}

class MitUpdateService {
  MitUpdateService(this.dio);
  final Dio dio;
  Future<ResponseBody> _stream(Uri initialUrl, CancelToken token) async {
    var url = initialUrl;
    for (var redirects = 0; redirects <= 5; redirects++) {
      if (!mitAllowedUpdateUrl(url)) throw const MitUpdateException();
      final response = await dio.get<ResponseBody>(url.toString(), cancelToken: token,
        options: Options(responseType: ResponseType.stream, followRedirects: false,
          validateStatus: (code) => code != null && code >= 200 && code < 400,
          headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'MitsVPN/${MitRelease.buildName}'}));
      final body = response.data;
      if (body == null) throw const MitUpdateException();
      if (response.statusCode == 200) return body;
      await body.stream.listen(null).cancel();
      final location = response.headers.value('location');
      if (location == null) throw const MitUpdateException();
      url = url.resolve(location);
    }
    throw const MitUpdateException();
  }
  Future<dynamic> _json(Uri uri, CancelToken token) async {
    final body = await _stream(uri, token); final bytes = <int>[];
    await for (final chunk in body.stream) {
      if (bytes.length + chunk.length > 1024 * 1024) throw const MitUpdateException();
      bytes.addAll(chunk);
    }
    return jsonDecode(utf8.decode(bytes));
  }
  Future<MitUpdateCandidate?> check(CancelToken token) async {
    final data = await _json(Uri.https('api.github.com', '/repos/$mitUpdateRepository/releases', {'per_page': '20'}), token);
    if (data is! List) throw const MitUpdateException();
    MitUpdateCandidate? best;
    for (final release in data.whereType<Map>()) {
      final tag = release['tag_name'];
      if (release['draft'] != false || tag is! String || !RegExp(r'^mit-beta-\d+\.\d+\.\d+$').hasMatch(tag)) continue;
      final assets = release['assets'];
      if (assets is! List || !assets.whereType<Map>().any((a) => a['name'] == 'mits-vpn-update.json' &&
          a['browser_download_url'] == mitReleaseAsset(tag, 'mits-vpn-update.json').toString())) continue;
      final manifest = await _json(mitReleaseAsset(tag, 'mits-vpn-update.json'), token);
      if (manifest is! Map) throw const MitUpdateException();
      final candidate = parseMitUpdate(release, manifest);
      if (candidate != null && (best == null || candidate.build > best.build)) best = candidate;
    }
    return best;
  }
  Future<void> download(MitUpdateCandidate candidate, Directory directory, CancelToken token,
      void Function(int received, int total) progress) async {
    await directory.create(recursive: true);
    final part = File('${directory.path}/mits-vpn-update.apk.part');
    final output = File('${directory.path}/mits-vpn-update.apk');
    final sink = part.openWrite(); var size = 0;
    try {
      final body = await _stream(candidate.apk, token);
      await for (final bytes in body.stream) {
        if (token.isCancelled) throw token.cancelError!;
        size += bytes.length;
        if (size > candidate.size || size > mitMaxApkBytes) throw const MitUpdateException();
        sink.add(bytes); progress(size, candidate.size);
      }
      await sink.flush(); await sink.close();
      if (size != candidate.size) throw const MitUpdateException();
      if (token.isCancelled) throw token.cancelError!;
      await part.rename(output.path);
    } catch (_) {
      await sink.close();
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }
}

final mitUpdateServiceProvider = Provider<MitUpdateService>((ref) {
  final port = ref.watch(ConfigOptions.mixedPort);
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30), sendTimeout: const Duration(seconds: 15)));
  dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () => HttpClient()
    ..findProxy = (_) => port > 0 ? 'PROXY 127.0.0.1:$port; DIRECT' : 'DIRECT');
  ref.onDispose(() => dio.close(force: true));
  return MitUpdateService(dio);
});

class MitUpdatePlatform {
  static const channel = MethodChannel('com.hiddify.app/platform');
  Map<String, dynamic> _args(MitUpdateCandidate candidate) => {'sha256': candidate.sha256,
    'version': candidate.build, 'size': candidate.size};
  Future<Directory> directory() async => Directory((await channel.invokeMethod<String>('mit_update_directory'))!);
  Future<void> verify(MitUpdateCandidate candidate) async {
    if (await channel.invokeMethod<bool>('mit_verify_update', _args(candidate)) != true) throw const MitUpdateException();
  }
  Future<String> install(MitUpdateCandidate candidate) async =>
    await channel.invokeMethod<String>('mit_install_update', _args(candidate)) ?? 'failed';
  Future<void> openPermission() => channel.invokeMethod<void>('mit_update_permission');
}
final mitUpdatePlatformProvider = Provider<MitUpdatePlatform>((ref) => MitUpdatePlatform());
