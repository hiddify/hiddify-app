import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

/// Service for downloading and managing TUN assets (wintun.dll, tun2socks.exe)
class TunAssetService {
  final Dio _dio = Dio();

  // Asset URLs
  static const _wintunUrl =
      'https://www.wintun.net/builds/wintun-0.14.1.zip';
  static const _wintunSha256 =
      '07c256185d6ee3652e09fa55c0b673e2624b565e02c4b9091c79ca7d2f24ef51';
  static const _tun2socksUrl =
      'https://github.com/xjasonlyu/tun2socks/releases/download/v2.6.0/tun2socks-windows-amd64.zip';
  static const _tun2socksSha256 =
      '1429e2e3b1ea09052da2c65e5005538b5730d63da37e304f4ad6fd2698a66695';

  Future<void> _verifySha256({
    required String filePath,
    required String expectedSha256,
    required String name,
  }) async {
    final digest = await sha256.bind(File(filePath).openRead()).first;
    final actual = digest.toString();
    if (actual.toLowerCase() != expectedSha256.toLowerCase()) {
      throw Exception(
        'SHA256 mismatch for $name. Expected: $expectedSha256, actual: $actual',
      );
    }
  }

  /// Get TUN assets directory
  Future<String> getTunAssetDirectory() async {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return exeDir;
    } else {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
  }

  /// Check if wintun.dll exists
  Future<bool> wintunExists() async {
    final dir = await getTunAssetDirectory();
    final file = File('$dir/wintun.dll');
    return file.existsSync();
  }

  /// Check if tun2socks.exe exists
  Future<bool> tun2socksExists() async {
    final dir = await getTunAssetDirectory();
    final file = File('$dir/tun2socks.exe');
    return file.existsSync();
  }

  /// Check if all TUN assets exist
  Future<bool> assetsExist() async {
    if (!Platform.isWindows) return false;
    return await wintunExists() && await tun2socksExists();
  }

  /// Download wintun.dll
  Future<void> downloadWintun({
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTunAssetDirectory();
    final zipPath = '$dir/wintun.zip';

    Logger.app.info('Downloading wintun...');

    try {
      await _dio.download(
        _wintunUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      await _verifySha256(
        filePath: zipPath,
        expectedSha256: _wintunSha256,
        name: 'wintun.zip',
      );

      // Extract wintun.dll from zip
      final zipFile = File(zipPath);
      try {
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          if (file.name.endsWith('amd64/wintun.dll')) {
            final data = file.content as List<int>;
            final outFile = File('$dir/wintun.dll');
            await outFile.writeAsBytes(data);
            Logger.app.info('wintun.dll extracted');
            return;
          }
        }

        throw Exception('wintun.dll not found in downloaded archive');
      } finally {
        // Cleanup zip
        try {
          if (await zipFile.exists()) await zipFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      Logger.app.error('Failed to download wintun: $e');
      try {
        final zipFile = File(zipPath);
        if (await zipFile.exists()) await zipFile.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Download tun2socks.exe
  Future<void> downloadTun2socks({
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTunAssetDirectory();
    final zipPath = '$dir/tun2socks.zip';

    Logger.app.info('Downloading tun2socks...');

    try {
      await _dio.download(
        _tun2socksUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      await _verifySha256(
        filePath: zipPath,
        expectedSha256: _tun2socksSha256,
        name: 'tun2socks.zip',
      );

      // Extract tun2socks.exe from zip
      final zipFile = File(zipPath);
      try {
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        ArchiveFile? extractedExe;
        for (final file in archive) {
          if (file.name.endsWith('/tun2socks.exe') || file.name == 'tun2socks.exe') {
            extractedExe = file;
            break;
          }
        }

        extractedExe ??= archive.where((f) => f.name.endsWith('.exe')).length == 1
            ? archive.firstWhere((f) => f.name.endsWith('.exe'))
            : null;

        if (extractedExe == null) {
          throw Exception('tun2socks.exe not found in downloaded archive');
        }

        final data = extractedExe.content as List<int>;
        final outFile = File('$dir/tun2socks.exe');
        await outFile.writeAsBytes(data);
        Logger.app.info('tun2socks.exe extracted');
      } finally {
        // Cleanup zip
        try {
          if (await zipFile.exists()) await zipFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      Logger.app.error('Failed to download tun2socks: $e');
      try {
        final zipFile = File(zipPath);
        if (await zipFile.exists()) await zipFile.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Download all TUN assets
  Future<void> ensureAssetsExist({
    void Function(double progress, String status)? onProgress,
  }) async {
    if (!Platform.isWindows) {
      Logger.app.warning('TUN assets only supported on Windows');
      return;
    }

    if (await assetsExist()) {
      Logger.app.debug('TUN assets already exist');
      return;
    }

    // Download wintun
    if (!await wintunExists()) {
      onProgress?.call(0, 'Downloading wintun.dll...');
      await downloadWintun(
        onProgress: (p) => onProgress?.call(p * 0.5, 'Downloading wintun.dll...'),
      );
    }

    // Download tun2socks
    if (!await tun2socksExists()) {
      onProgress?.call(0.5, 'Downloading tun2socks.exe...');
      await downloadTun2socks(
        onProgress: (p) => onProgress?.call(0.5 + p * 0.5, 'Downloading tun2socks.exe...'),
      );
    }

    onProgress?.call(1, 'TUN assets ready');
    Logger.app.info('TUN assets download complete');
  }

  /// Get path to tun2socks.exe
  Future<String> getTun2socksPath() async {
    final dir = await getTunAssetDirectory();
    return '$dir/tun2socks.exe';
  }

  /// Get path to wintun.dll
  Future<String> getWintunPath() async {
    final dir = await getTunAssetDirectory();
    return '$dir/wintun.dll';
  }

  /// Delete TUN assets
  Future<void> deleteAssets() async {
    final dir = await getTunAssetDirectory();
    
    final wintun = File('$dir/wintun.dll');
    if (await wintun.exists()) await wintun.delete();
    
    final tun2socks = File('$dir/tun2socks.exe');
    if (await tun2socks.exists()) await tun2socks.delete();
    
    Logger.app.info('TUN assets deleted');
  }
}
