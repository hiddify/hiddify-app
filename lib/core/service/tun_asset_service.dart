import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:path_provider/path_provider.dart';

 // Service for downloading and managing TUN assets (wintun.dll, tun2socks.exe)
class TunAssetService {
  final Dio _dio = Dio();
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


  Future<String> getTunAssetDirectory() async {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final packagedWintun = File('$exeDir/wintun.dll');
      final packagedTun2socks = File('$exeDir/tun2socks.exe');
      if (packagedWintun.existsSync() && packagedTun2socks.existsSync()) {
        return exeDir;
      }

      final dir = await getApplicationSupportDirectory();
      final assetsDir = Directory('${dir.path}/tun');
      if (!assetsDir.existsSync()) {
        assetsDir.createSync(recursive: true);
      }
      return assetsDir.path;
    } else {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
  }


  Future<bool> wintunExists() async {
    final dir = await getTunAssetDirectory();
    final file = File('$dir/wintun.dll');
    return file.existsSync();
  }


  Future<bool> tun2socksExists() async {
    final dir = await getTunAssetDirectory();
    final file = File('$dir/tun2socks.exe');
    return file.existsSync();
  }


  Future<bool> assetsExist() async {
    if (!Platform.isWindows) return false;
    return await wintunExists() && await tun2socksExists();
  }


  Future<void> downloadWintun({
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTunAssetDirectory();
    final zipPath = '$dir/wintun.zip';

    Logger.tun.info('Downloading wintun...');

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
      final zipFile = File(zipPath);
      try {
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          if (file.name.endsWith('amd64/wintun.dll')) {
            final data = file.content as List<int>;
            final outFile = File('$dir/wintun.dll');
            await outFile.writeAsBytes(data);
            Logger.tun.info('wintun.dll extracted');
            return;
          }
        }

        throw Exception('wintun.dll not found in downloaded archive');
      } finally {
        try {
          if (await FileSystemEntity.type(zipFile.path) != FileSystemEntityType.notFound) await zipFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      Logger.tun.error('Failed to download wintun: $e');
      try {
        final zipFile = File(zipPath);
        if (await FileSystemEntity.type(zipFile.path) != FileSystemEntityType.notFound) await zipFile.delete();
      } catch (_) {}
      rethrow;
    }
  }


  Future<void> downloadTun2socks({
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTunAssetDirectory();
    final zipPath = '$dir/tun2socks.zip';

    Logger.tun.info('Downloading tun2socks...');

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
        Logger.tun.info('tun2socks.exe extracted');
      } finally {
        try {
          if (await FileSystemEntity.type(zipFile.path) != FileSystemEntityType.notFound) await zipFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      Logger.tun.error('Failed to download tun2socks: $e');
      try {
        final zipFile = File(zipPath);
        if (await FileSystemEntity.type(zipFile.path) != FileSystemEntityType.notFound) await zipFile.delete();
      } catch (_) {}
      rethrow;
    }
  }


  Future<void> ensureAssetsExist({
    void Function(double progress, String status)? onProgress,
  }) async {
    if (!Platform.isWindows) {
      Logger.tun.warning('TUN assets only supported on Windows');
      return;
    }

    if (await assetsExist()) {
      Logger.tun.debug('TUN assets already exist');
      return;
    }
    if (!await wintunExists()) {
      onProgress?.call(0, 'Downloading wintun.dll...');
      await downloadWintun(
        onProgress: (p) => onProgress?.call(p * 0.5, 'Downloading wintun.dll...'),
      );
    }
    if (!await tun2socksExists()) {
      onProgress?.call(0.5, 'Downloading tun2socks.exe...');
      await downloadTun2socks(
        onProgress: (p) => onProgress?.call(0.5 + p * 0.5, 'Downloading tun2socks.exe...'),
      );
    }

    onProgress?.call(1, 'TUN assets ready');
    Logger.tun.info('TUN assets download complete');
  }


  Future<String> getTun2socksPath() async {
    final dir = await getTunAssetDirectory();
    return '$dir/tun2socks.exe';
  }


  Future<String> getWintunPath() async {
    final dir = await getTunAssetDirectory();
    return '$dir/wintun.dll';
  }


  Future<void> deleteAssets() async {
    final dir = await getTunAssetDirectory();
    
    final wintun = File('$dir/wintun.dll');
    if (await FileSystemEntity.type(wintun.path) != FileSystemEntityType.notFound) await wintun.delete();
    
    final tun2socks = File('$dir/tun2socks.exe');
    if (await FileSystemEntity.type(tun2socks.path) != FileSystemEntityType.notFound) await tun2socks.delete();
    
    Logger.tun.info('TUN assets deleted');
  }
}
