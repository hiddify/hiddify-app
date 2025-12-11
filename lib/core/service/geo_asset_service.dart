import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geo_asset_service.g.dart';

/// Multi-source URLs for GeoIP and GeoSite data
/// Ordered by priority - sources with IR support first
class GeoAssetSources {
  /// GeoIP sources (with IR support)
  static const List<String> geoipUrls = [
    // Loyalsoldier - has IR support ✅
    'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat',
    // chocolate4u - Iran optimized ✅
    'https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat',
    // v2fly original (fallback)
    'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat',
  ];

  /// GeoSite sources (with IR support)
  static const List<String> geositeUrls = [
    // Loyalsoldier - has IR support ✅
    'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat',
    // chocolate4u - Iran optimized ✅
    'https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat',
    // v2fly original (fallback, no IR)
    'https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat',
  ];
}

/// Download status for UI feedback
enum GeoAssetStatus {
  idle,
  checking,
  downloading,
  extracting,
  completed,
  failed,
}

/// Download progress info
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

/// Service for managing GeoIP and GeoSite assets with multi-source support
@Riverpod(keepAlive: true)
GeoAssetService geoAssetService(Ref ref) => GeoAssetService();

class GeoAssetService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(seconds: 30),
  ));

  /// Current download progress
  GeoDownloadProgress _progress = const GeoDownloadProgress(status: GeoAssetStatus.idle);
  GeoDownloadProgress get progress => _progress;

  /// Progress callback
  void Function(GeoDownloadProgress)? onProgressChanged;

  void _updateProgress(GeoDownloadProgress p) {
    _progress = p;
    onProgressChanged?.call(p);
  }

  /// Get the directory where geo assets should be stored
  Future<String> getGeoAssetDirectory() async {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return exeDir;
    } else if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } else {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
  }

  /// Check if geo assets exist and are valid
  Future<bool> assetsExist() async {
    final dir = await getGeoAssetDirectory();
    final geoipFile = File('$dir/geoip.dat');
    final geositeFile = File('$dir/geosite.dat');

    // ignore: avoid_slow_async_io
    if (!await geoipFile.exists() || !await geositeFile.exists()) {
      return false;
    }

    // Check minimum file size (corrupt files are usually small)
    // ignore: avoid_slow_async_io
    final geoipStat = await geoipFile.stat();
    // ignore: avoid_slow_async_io
    final geositeStat = await geositeFile.stat();

    // Minimum 100KB for valid files
    return geoipStat.size > 100 * 1024 && geositeStat.size > 100 * 1024;
  }

  /// Get GeoIP file path
  Future<String> getGeoIpPath() async {
    final dir = await getGeoAssetDirectory();
    return '$dir/geoip.dat';
  }

  /// Get GeoSite file path
  Future<String> getGeoSitePath() async {
    final dir = await getGeoAssetDirectory();
    return '$dir/geosite.dat';
  }

  /// Ensure assets exist - download if needed, use bundle as fallback
  Future<void> ensureAssetsExist({void Function(GeoDownloadProgress)? onProgress}) async {
    onProgressChanged = onProgress;
    _updateProgress(const GeoDownloadProgress(status: GeoAssetStatus.checking));

    if (await assetsExist()) {
      _updateProgress(const GeoDownloadProgress(status: GeoAssetStatus.completed));
      return;
    }

    // Try downloading from multiple sources
    final success = await downloadAssets();

    if (!success) {
      // Fallback: try to extract bundled assets
      await _extractBundledAssets();
    }
  }

  /// Download assets with multi-source retry
  Future<bool> downloadAssets() async {
    final dir = await getGeoAssetDirectory();

    // Download GeoIP
    _updateProgress(const GeoDownloadProgress(
      status: GeoAssetStatus.downloading,
      currentFile: 'geoip.dat',
      progress: 0,
    ));

    var geoipSuccess = false;
    for (var i = 0; i < GeoAssetSources.geoipUrls.length && !geoipSuccess; i++) {
      try {
        await _downloadWithRetry(
          GeoAssetSources.geoipUrls[i],
          '$dir/geoip.dat',
          onProgress: (received, total) {
            if (total > 0) {
              _updateProgress(GeoDownloadProgress(
                status: GeoAssetStatus.downloading,
                currentFile: 'geoip.dat',
                progress: (received / total) * 0.5,
                sourceIndex: i,
              ));
            }
          },
        );
        geoipSuccess = true;
      } catch (e) {
        // Try next source
        if (i == GeoAssetSources.geoipUrls.length - 1) {
          _updateProgress(GeoDownloadProgress(
            status: GeoAssetStatus.failed,
            error: 'Failed to download geoip.dat: $e',
          ));
        }
      }
    }

    if (!geoipSuccess) return false;

    // Download GeoSite
    _updateProgress(const GeoDownloadProgress(
      status: GeoAssetStatus.downloading,
      currentFile: 'geosite.dat',
      progress: 0.5,
    ));

    var geositeSuccess = false;
    for (var i = 0; i < GeoAssetSources.geositeUrls.length && !geositeSuccess; i++) {
      try {
        await _downloadWithRetry(
          GeoAssetSources.geositeUrls[i],
          '$dir/geosite.dat',
          onProgress: (received, total) {
            if (total > 0) {
              _updateProgress(GeoDownloadProgress(
                status: GeoAssetStatus.downloading,
                currentFile: 'geosite.dat',
                progress: 0.5 + (received / total) * 0.5,
                sourceIndex: i,
              ));
            }
          },
        );
        geositeSuccess = true;
      } catch (e) {
        if (i == GeoAssetSources.geositeUrls.length - 1) {
          _updateProgress(GeoDownloadProgress(
            status: GeoAssetStatus.failed,
            error: 'Failed to download geosite.dat: $e',
          ));
        }
      }
    }

    if (geositeSuccess) {
      _updateProgress(const GeoDownloadProgress(
        status: GeoAssetStatus.completed,
        progress: 1.0,
      ));
    }

    return geositeSuccess;
  }

  /// Download with retry logic
  Future<void> _downloadWithRetry(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    int maxRetries = 3,
  }) async {
    var lastError = '';

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _dio.download(
          url,
          savePath,
          onReceiveProgress: onProgress,
          options: Options(
            followRedirects: true,
            maxRedirects: 5,
            headers: {
              'User-Agent': 'Hiddify/3.0',
            },
          ),
        );
        return; // Success
      } on DioException catch (e) {
        lastError = e.message ?? e.toString();
        if (attempt < maxRetries - 1) {
          // Wait before retry with exponential backoff
          await Future<void>.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
    }

    throw Exception('Download failed after $maxRetries attempts: $lastError');
  }

  /// Extract bundled assets as fallback
  Future<void> _extractBundledAssets() async {
    _updateProgress(const GeoDownloadProgress(
      status: GeoAssetStatus.extracting,
      currentFile: 'Extracting bundled assets...',
    ));

    try {
      final dir = await getGeoAssetDirectory();

      // Try to load from Flutter assets
      try {
        final geoipData = await rootBundle.load('assets/geo/geoip.dat');
        await File('$dir/geoip.dat').writeAsBytes(
          geoipData.buffer.asUint8List(),
        );
      } catch (_) {
        // Bundle not available, create minimal placeholder
      }

      try {
        final geositeData = await rootBundle.load('assets/geo/geosite.dat');
        await File('$dir/geosite.dat').writeAsBytes(
          geositeData.buffer.asUint8List(),
        );
      } catch (_) {
        // Bundle not available
      }

      _updateProgress(const GeoDownloadProgress(status: GeoAssetStatus.completed));
    } catch (e) {
      _updateProgress(GeoDownloadProgress(
        status: GeoAssetStatus.failed,
        error: 'Failed to extract bundled assets: $e',
      ));
    }
  }

  /// Get file info (size and modification date)
  Future<Map<String, dynamic>?> getAssetInfo(String assetName) async {
    final dir = await getGeoAssetDirectory();
    final file = File('$dir/$assetName');

    // ignore: avoid_slow_async_io
    if (!await file.exists()) return null;

    // ignore: avoid_slow_async_io
    final stat = await file.stat();
    return {
      'size': stat.size,
      'modified': stat.modified,
      'path': file.path,
    };
  }

  /// Check if update is available (based on file age)
  Future<bool> isUpdateAvailable() async {
    final geositeInfo = await getAssetInfo('geosite.dat');
    if (geositeInfo == null) return true;

    final modified = geositeInfo['modified'] as DateTime;
    final age = DateTime.now().difference(modified);

    // Update if older than 7 days
    return age.inDays > 7;
  }

  /// Force update assets
  Future<bool> updateAssets() async {
    await deleteAssets();
    return downloadAssets();
  }

  /// Delete geo assets (for fresh download)
  Future<void> deleteAssets() async {
    final dir = await getGeoAssetDirectory();
    final geoipFile = File('$dir/geoip.dat');
    final geositeFile = File('$dir/geosite.dat');

    // ignore: avoid_slow_async_io
    if (await geoipFile.exists()) await geoipFile.delete();
    // ignore: avoid_slow_async_io
    if (await geositeFile.exists()) await geositeFile.delete();
  }

  /// Get human-readable file size
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
