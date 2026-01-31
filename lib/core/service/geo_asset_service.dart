import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geo_asset_service.g.dart';

class GeoAssetSources {
  static const List<String> geoipUrls = [
    'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat',
    'https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat',
    'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat',
  ];

  static const List<String> geositeUrls = [
    'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat',
    'https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat',
    'https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat',
  ];
}

enum GeoAssetStatus {
  idle,
  checking,
  downloading,
  extracting,
  completed,
  failed,
}

class GeoDownloadProgress {
  const GeoDownloadProgress({
    required this.status,
    this.progress = 0,
    this.currentFile = '',
    this.error,
    this.sourceIndex = 0,
  });

  final GeoAssetStatus status;
  final double progress;
  final String currentFile;
  final String? error;
  final int sourceIndex;

  GeoDownloadProgress copyWith({
    GeoAssetStatus? status,
    double? progress,
    String? currentFile,
    String? error,
    int? sourceIndex,
  }) => GeoDownloadProgress(
    status: status ?? this.status,
    progress: progress ?? this.progress,
    currentFile: currentFile ?? this.currentFile,
    error: error,
    sourceIndex: sourceIndex ?? this.sourceIndex,
  );
}

@Riverpod(keepAlive: true)
GeoAssetService geoAssetService(Ref ref) => GeoAssetService();

class GeoAssetService {
  static const int _minGeoAssetBytes = 100 * 1024;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  GeoDownloadProgress _progress = const GeoDownloadProgress(
    status: GeoAssetStatus.idle,
  );
  GeoDownloadProgress get progress => _progress;

  void Function(GeoDownloadProgress)? onProgressChanged;

  void _updateProgress(GeoDownloadProgress p) {
    _progress = p;
    onProgressChanged?.call(p);
  }

  Future<String> getGeoAssetDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return File(Platform.resolvedExecutable).parent.path;
    }

    if (Platform.isIOS) {
      try {
        final paths = await const MethodChannel(
          'com.hiddify.app/platform',
        ).invokeMethod<Map<String, dynamic>>('get_paths');
        final base = paths?['base'];
        if (base is String && base.isNotEmpty) {
          return base;
        }
      } catch (_) {}

      final dir = await getLibraryDirectory();
      return dir.path;
    }

    if (Platform.isAndroid) {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }

    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  Future<bool> assetsExist() async {
    final dir = await getGeoAssetDirectory();
    final geoipFile = File('$dir/geoip.dat');
    final geositeFile = File('$dir/geosite.dat');
    if (!await geoipFile.exists() || !await geositeFile.exists()) {
      return false;
    }
    final geoipStat = await geoipFile.stat();
    final geositeStat = await geositeFile.stat();
    return geoipStat.size > _minGeoAssetBytes &&
        geositeStat.size > _minGeoAssetBytes;
  }

  Future<String> getGeoIpPath() async {
    final dir = await getGeoAssetDirectory();
    return '$dir/geoip.dat';
  }

  Future<String> getGeoSitePath() async {
    final dir = await getGeoAssetDirectory();
    return '$dir/geosite.dat';
  }

  Future<void> ensureAssetsExist({
    void Function(GeoDownloadProgress)? onProgress,
  }) async {
    onProgressChanged = onProgress;
    _updateProgress(const GeoDownloadProgress(status: GeoAssetStatus.checking));

    if (await assetsExist()) {
      _updateProgress(
        const GeoDownloadProgress(status: GeoAssetStatus.completed),
      );
      return;
    }
    final success = await downloadAssets();

    if (!success) {
      await _extractBundledAssets();
    }
  }

  Future<bool> downloadAssets() async {
    final dir = await getGeoAssetDirectory();
    _updateProgress(
      const GeoDownloadProgress(
        status: GeoAssetStatus.downloading,
        currentFile: 'geoip.dat',
      ),
    );

    var geoipSuccess = false;
    for (
      var i = 0;
      i < GeoAssetSources.geoipUrls.length && !geoipSuccess;
      i++
    ) {
      try {
        await _downloadWithRetry(
          GeoAssetSources.geoipUrls[i],
          '$dir/geoip.dat',
          onProgress: (received, total) {
            if (total > 0) {
              _updateProgress(
                GeoDownloadProgress(
                  status: GeoAssetStatus.downloading,
                  currentFile: 'geoip.dat',
                  progress: (received / total) * 0.5,
                  sourceIndex: i,
                ),
              );
            }
          },
        );
        geoipSuccess = true;
      } catch (e) {
        if (i == GeoAssetSources.geoipUrls.length - 1) {
          _updateProgress(
            GeoDownloadProgress(
              status: GeoAssetStatus.failed,
              error: 'Failed to download geoip.dat: $e',
            ),
          );
        }
      }
    }

    if (!geoipSuccess) return false;
    _updateProgress(
      const GeoDownloadProgress(
        status: GeoAssetStatus.downloading,
        currentFile: 'geosite.dat',
        progress: 0.5,
      ),
    );

    var geositeSuccess = false;
    for (
      var i = 0;
      i < GeoAssetSources.geositeUrls.length && !geositeSuccess;
      i++
    ) {
      try {
        await _downloadWithRetry(
          GeoAssetSources.geositeUrls[i],
          '$dir/geosite.dat',
          onProgress: (received, total) {
            if (total > 0) {
              _updateProgress(
                GeoDownloadProgress(
                  status: GeoAssetStatus.downloading,
                  currentFile: 'geosite.dat',
                  progress: 0.5 + (received / total) * 0.5,
                  sourceIndex: i,
                ),
              );
            }
          },
        );
        geositeSuccess = true;
      } catch (e) {
        if (i == GeoAssetSources.geositeUrls.length - 1) {
          _updateProgress(
            GeoDownloadProgress(
              status: GeoAssetStatus.failed,
              error: 'Failed to download geosite.dat: $e',
            ),
          );
        }
      }
    }

    if (geositeSuccess) {
      _updateProgress(
        const GeoDownloadProgress(
          status: GeoAssetStatus.completed,
          progress: 1,
        ),
      );
    }

    return geositeSuccess;
  }

  Future<void> _downloadWithRetry(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    int maxRetries = 3,
  }) async {
    var lastError = '';

    final saveFile = File(savePath);
    await saveFile.parent.create(recursive: true);

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final tempPath =
          '$savePath.${DateTime.now().microsecondsSinceEpoch}.tmp';
      try {
        Logger.geoAsset.info(
          'Downloading asset from $url (attempt ${attempt + 1}/$maxRetries)',
        );
        await _dio.download(
          url,
          tempPath,
          onReceiveProgress: onProgress,
          options: Options(
            followRedirects: true,
            maxRedirects: 5,
            headers: {'User-Agent': 'Hiddify/3.0'},
          ),
        );

        await _validateMinSize(tempPath);
        await _verifySha256IfAvailable(url, tempPath);
        await _replaceFileAtomic(fromPath: tempPath, toPath: savePath);

        Logger.geoAsset.info('Download successful: $savePath');
        return; 
      } on DioException catch (e) {
        lastError = e.message ?? e.toString();
        Logger.geoAsset.warning(
          'Download failed (attempt ${attempt + 1}): $lastError',
        );
        try {
          final tmp = File(tempPath);
          if (await tmp.exists()) await tmp.delete();
        } catch (_) {}
        if (attempt < maxRetries - 1) {
          await Future<void>.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      } catch (e) {
        lastError = e.toString();
        Logger.geoAsset.warning(
          'Download failed (attempt ${attempt + 1}): $lastError',
        );
        try {
          final tmp = File(tempPath);
          if (await tmp.exists()) await tmp.delete();
        } catch (_) {}
        if (attempt < maxRetries - 1) {
          await Future<void>.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
    }

    Logger.geoAsset.error(
      'Download failed after $maxRetries attempts: $lastError',
    );
    throw Exception('Download failed after $maxRetries attempts: $lastError');
  }

  Future<void> _validateMinSize(String filePath) async {
    final stat = await FileStat.stat(filePath);
    if (stat.size < _minGeoAssetBytes) {
      throw Exception(
        'Downloaded file is too small (${stat.size} bytes, expected >= $_minGeoAssetBytes)',
      );
    }
  }

  Future<String?> _fetchSha256ForUrl(String url) async {
    final candidates = <String>[
      '$url.sha256sum',
      '$url.sha256',
    ];
    for (final shaUrl in candidates) {
      try {
        final res = await _dio.get<String>(
          shaUrl,
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: true,
            maxRedirects: 5,
            headers: {'User-Agent': 'Hiddify/3.0'},
          ),
        );
        final text = res.data;
        if (text is! String || text.isEmpty) continue;
        final match = RegExp(
          r'\b[a-f0-9]{64}\b',
          caseSensitive: false,
        ).firstMatch(text);
        if (match != null) {
          return match.group(0);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _verifySha256IfAvailable(String url, String filePath) async {
    final expected = await _fetchSha256ForUrl(url);
    if (expected == null || expected.isEmpty) return;

    final digest = await sha256.bind(File(filePath).openRead()).first;
    final actual = digest.toString();
    if (actual.toLowerCase() != expected.toLowerCase()) {
      throw Exception(
        'SHA256 mismatch. Expected: $expected, actual: $actual',
      );
    }
  }

  Future<void> _replaceFileAtomic({
    required String fromPath,
    required String toPath,
  }) async {
    final from = File(fromPath);
    final to = File(toPath);
    await to.parent.create(recursive: true);

    final backup = File('$toPath.bak');
    var hasBackup = false;
    if (await backup.exists()) {
      try {
        await backup.delete();
      } catch (_) {}
    }

    if (await to.exists()) {
      try {
        await to.rename(backup.path);
        hasBackup = true;
      } catch (_) {
        try {
          await to.delete();
        } catch (_) {}
      }
    }

    try {
      await from.rename(to.path);
    } catch (_) {
      try {
        await from.copy(to.path);
        await from.delete();
      } catch (_) {
        if (hasBackup && await backup.exists()) {
          try {
            await backup.rename(to.path);
          } catch (_) {}
        }
        rethrow;
      }
    } finally {
      if (hasBackup && await backup.exists()) {
        try {
          await backup.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _writeBytesAtomic({
    required String path,
    required Uint8List bytes,
  }) async {
    final tempPath = '$path.${DateTime.now().microsecondsSinceEpoch}.tmp';
    final tmp = File(tempPath);
    await tmp.parent.create(recursive: true);
    await tmp.writeAsBytes(bytes, flush: true);
    await _validateMinSize(tempPath);
    await _replaceFileAtomic(fromPath: tempPath, toPath: path);
  }

  
  Future<void> _extractBundledAssets() async {
    Logger.geoAsset.info('Extracting bundled assets...');
    _updateProgress(
      const GeoDownloadProgress(
        status: GeoAssetStatus.extracting,
        currentFile: 'Extracting bundled assets...',
      ),
    );

    try {
      final dir = await getGeoAssetDirectory();
      await Directory(dir).create(recursive: true);

      final geoipPath = '$dir/geoip.dat';
      final geositePath = '$dir/geosite.dat';
      try {
        final geoipFile = File(geoipPath);
        if (!await geoipFile.exists() ||
            (await geoipFile.stat()).size < _minGeoAssetBytes) {
          final geoipData = await rootBundle.load('assets/geo/geoip.dat');
          await _writeBytesAtomic(
            path: geoipPath,
            bytes: geoipData.buffer.asUint8List(),
          );
        }
      } catch (_) {}

      try {
        final geositeFile = File(geositePath);
        if (!await geositeFile.exists() ||
            (await geositeFile.stat()).size < _minGeoAssetBytes) {
          final geositeData = await rootBundle.load('assets/geo/geosite.dat');
          await _writeBytesAtomic(
            path: geositePath,
            bytes: geositeData.buffer.asUint8List(),
          );
        }
      } catch (_) {}

      _updateProgress(
        const GeoDownloadProgress(status: GeoAssetStatus.completed),
      );
      Logger.geoAsset.info('Bundled assets extracted successfully');
    } catch (e) {
      Logger.geoAsset.error('Failed to extract bundled assets: $e');
      _updateProgress(
        GeoDownloadProgress(
          status: GeoAssetStatus.failed,
          error: 'Failed to extract bundled assets: $e',
        ),
      );
    }
  }

  
  Future<Map<String, dynamic>?> getAssetInfo(String assetName) async {
    final dir = await getGeoAssetDirectory();
    final file = File('$dir/$assetName');
    if (!await file.exists()) return null;
    final stat = await file.stat();
    return {'size': stat.size, 'modified': stat.modified, 'path': file.path};
  }

  
  Future<bool> isUpdateAvailable() async {
    final geositeInfo = await getAssetInfo('geosite.dat');
    if (geositeInfo == null) return true;

    final modified = geositeInfo['modified'] as DateTime;
    final age = DateTime.now().difference(modified);
    return age.inDays > 7;
  }

  
  Future<bool> updateAssets() => downloadAssets();

  
  Future<void> deleteAssets() async {
    final dir = await getGeoAssetDirectory();
    final geoipFile = File('$dir/geoip.dat');
    final geositeFile = File('$dir/geosite.dat');
    if (await geoipFile.exists()) await geoipFile.delete();
    if (await geositeFile.exists()) await geositeFile.delete();
  }

  
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
