import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geo_asset_service.g.dart';

/// URLs for GeoIP and GeoSite data from v2fly releases
class GeoAssetUrls {
  static const String geoipUrl =
      'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat';
  static const String geositeUrl =
      'https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat';
}

/// Service for managing GeoIP and GeoSite assets
@Riverpod(keepAlive: true)
GeoAssetService geoAssetService(Ref ref) => GeoAssetService();

class GeoAssetService {
  final Dio _dio = Dio();

  /// Get the directory where geo assets should be stored
  Future<String> getGeoAssetDirectory() async {
    if (Platform.isWindows) {
      // For Windows, use executable directory
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return exeDir;
    } else if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } else {
      // Linux/macOS
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
  }

  /// Check if geo assets exist
  Future<bool> assetsExist() async {
    final dir = await getGeoAssetDirectory();
    final geoipFile = File('$dir/geoip.dat');
    final geositeFile = File('$dir/geosite.dat');
    // ignore: avoid_slow_async_io
    return await geoipFile.exists() && await geositeFile.exists();
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

  /// Download geo assets if they don't exist
  Future<void> ensureAssetsExist({void Function(double)? onProgress}) async {
    if (await assetsExist()) return;
    await downloadAssets(onProgress: onProgress);
  }

  /// Download or update geo assets
  Future<void> downloadAssets({void Function(double)? onProgress}) async {
    final dir = await getGeoAssetDirectory();

    // Download geoip.dat
    await _downloadFile(
      GeoAssetUrls.geoipUrl,
      '$dir/geoip.dat',
      onProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress((received / total) * 0.5); // 0-50%
        }
      },
    );

    // Download geosite.dat
    await _downloadFile(
      GeoAssetUrls.geositeUrl,
      '$dir/geosite.dat',
      onProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(0.5 + (received / total) * 0.5); // 50-100%
        }
      },
    );
  }

  Future<void> _downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
      options: Options(
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
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
    };
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
}
