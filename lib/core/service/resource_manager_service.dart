import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hiddify/core/core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;

enum ResourceType {
  geoip,
  geosite,
  tunDriver,
  xrayCore,
  singboxCore,
  hysteriaCore,
  tuicCore,
  naiveCore,
  ssrCore,
  wintun,
  font,
  translation,
}

enum ResourceStatus {
  notDownloaded,
  downloading,
  downloaded,
  updateAvailable,
  error,
}

class ResourceInfo {
  const ResourceInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.localPath,
    required this.isRequired,
    this.size = 0,
    this.version = '',
    this.status = ResourceStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
  });

  final ResourceType type;
  final String name;
  final String description;
  final String downloadUrl;
  final String localPath;
  final bool isRequired;
  final int size;
  final String version;
  final ResourceStatus status;
  final double progress;
  final String? error;

  ResourceInfo copyWith({
    ResourceType? type,
    String? name,
    String? description,
    String? downloadUrl,
    String? localPath,
    bool? isRequired,
    int? size,
    String? version,
    ResourceStatus? status,
    double? progress,
    String? error,
  }) => ResourceInfo(
    type: type ?? this.type,
    name: name ?? this.name,
    description: description ?? this.description,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    localPath: localPath ?? this.localPath,
    isRequired: isRequired ?? this.isRequired,
    size: size ?? this.size,
    version: version ?? this.version,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    error: error,
  );

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ResourceManagerService {
  ResourceManagerService._();

  static final instance = ResourceManagerService._();

  static const int _minGeoAssetBytes = 100 * 1024;

  final _dio = Dio();
  final _resources = <ResourceType, ResourceInfo>{};
  final _statusController =
      StreamController<Map<ResourceType, ResourceInfo>>.broadcast();

  Stream<Map<ResourceType, ResourceInfo>> get resourcesStream =>
      _statusController.stream;
  Map<ResourceType, ResourceInfo> get resources => Map.unmodifiable(_resources);

  Future<void> initialize() async {
    await _detectUserRegion();
    await _initializeResources();
    await _checkExistingResources();
    Logger.system.info('ResourceManager initialized');
  }

  Future<String> _detectUserRegion() async {
    final locale = Platform.localeName;
    if (locale.contains('fa') || locale.contains('IR')) return 'ir';
    if (locale.contains('zh') || locale.contains('CN')) return 'cn';
    if (locale.contains('ru') || locale.contains('RU')) return 'ru';
    return 'global';
  }

  Future<void> _initializeResources() async {
    final geoAssetsDir = await GeoAssetService().getGeoAssetDirectory();
    await Directory(geoAssetsDir).create(recursive: true);

    final region = await _detectUserRegion();
    final geoSources = _getGeoSourcesForRegion(region);

    _resources[ResourceType.geoip] = ResourceInfo(
      type: ResourceType.geoip,
      name: 'GeoIP Database',
      description: 'IP geolocation database for routing',
      downloadUrl: geoSources['geoip']!,
      localPath: '$geoAssetsDir/geoip.dat',
      isRequired: true,
    );

    _resources[ResourceType.geosite] = ResourceInfo(
      type: ResourceType.geosite,
      name: 'GeoSite Database',
      description: 'Domain categorization database',
      downloadUrl: geoSources['geosite']!,
      localPath: '$geoAssetsDir/geosite.dat',
      isRequired: true,
    );

    if (Platform.isWindows) {
      _resources[ResourceType.wintun] = const ResourceInfo(
        type: ResourceType.wintun,
        name: 'WinTUN Driver',
        description: 'Windows TUN/TAP driver for VPN',
        downloadUrl: 'https://www.wintun.net/builds/wintun-0.14.1.zip',
        localPath: '',
        isRequired: true,
      );
    }

    _notifyListeners();
  }

  Map<String, String> _getGeoSourcesForRegion(String region) {
    switch (region) {
      case 'ir':
        return {
          'geoip':
              'https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geoip.dat',
          'geosite':
              'https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite.dat',
        };
      case 'cn':
        return {
          'geoip':
              'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat',
          'geosite':
              'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat',
        };
      default:
        return {
          'geoip':
              'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat',
          'geosite':
              'https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat',
        };
    }
  }

  Future<void> _checkExistingResources() async {
    for (final type in _resources.keys) {
      final resource = _resources[type]!;

      if (resource.localPath.isEmpty) {
        continue;
      }

      if (await FileSystemEntity.type(resource.localPath) !=
          FileSystemEntityType.notFound) {
        final stat = await FileStat.stat(resource.localPath);
        if ((type == ResourceType.geoip || type == ResourceType.geosite) &&
            stat.size < _minGeoAssetBytes) {
          _resources[type] = resource.copyWith(
            status: ResourceStatus.notDownloaded,
            size: stat.size,
          );
          continue;
        }
        _resources[type] = resource.copyWith(
          status: ResourceStatus.downloaded,
          size: stat.size,
        );
      } else {
        _resources[type] = resource.copyWith(
          status: ResourceStatus.notDownloaded,
        );
      }
    }
    _notifyListeners();
  }

  Future<bool> downloadResource(ResourceType type) async {
    final resource = _resources[type];
    if (resource == null) return false;
    if (resource.localPath.isEmpty) return false;

    String? tempPath;

    try {
      _resources[type] = resource.copyWith(
        status: ResourceStatus.downloading,
        progress: 0,
      );
      _notifyListeners();

      final dir = Directory(File(resource.localPath).parent.path);
      if (await FileSystemEntity.type(dir.path) ==
          FileSystemEntityType.notFound) {
        await dir.create(recursive: true);
      }

      final localTempPath =
          '${resource.localPath}.${DateTime.now().microsecondsSinceEpoch}.tmp';
      tempPath = localTempPath;

      await _dio.download(
        resource.downloadUrl,
        localTempPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _resources[type] = resource.copyWith(
              status: ResourceStatus.downloading,
              progress: received / total,
            );
            _notifyListeners();
          }
        },
      );

      if (type == ResourceType.geoip || type == ResourceType.geosite) {
        await _validateMinSize(localTempPath);
      }
      await _verifySha256IfAvailable(resource.downloadUrl, localTempPath);
      await _replaceFileAtomic(
        fromPath: localTempPath,
        toPath: resource.localPath,
      );

      final stat = await FileStat.stat(resource.localPath);

      _resources[type] = resource.copyWith(
        status: ResourceStatus.downloaded,
        size: stat.size,
        progress: 1,
      );
      _notifyListeners();

      Logger.system.info('Downloaded resource: ${resource.name}');
      return true;
    } catch (e) {
      if (tempPath != null) {
        try {
          final tmp = File(tempPath);
          if (await tmp.exists()) await tmp.delete();
        } catch (_) {}
      }
      _resources[type] = resource.copyWith(
        status: ResourceStatus.error,
        error: e.toString(),
      );
      _notifyListeners();
      Logger.system.error('Failed to download ${resource.name}: $e');
      return false;
    }
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
          options: Options(responseType: ResponseType.plain),
        );
        final text = res.data;
        if (text is! String || text.isEmpty) continue;
        final match =
            RegExp(r'\b[a-f0-9]{64}\b', caseSensitive: false).firstMatch(text);
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

  Future<void> downloadAllRequired() async {
    for (final entry in _resources.entries) {
      if (entry.value.isRequired &&
          entry.value.localPath.isNotEmpty &&
          entry.value.status != ResourceStatus.downloaded) {
        await downloadResource(entry.key);
      }
    }
  }

  Future<Map<ResourceType, bool>> checkForUpdates() async {
    final updates = <ResourceType, bool>{};

    for (final entry in _resources.entries) {
      if (entry.value.status == ResourceStatus.downloaded) {
        if (await FileSystemEntity.type(entry.value.localPath) !=
            FileSystemEntityType.notFound) {
          final stat = await FileStat.stat(entry.value.localPath);
          final age = DateTime.now().difference(stat.modified);
          updates[entry.key] = age.inDays > 7;
        }
      }
    }

    return updates;
  }

  Future<bool> deleteResource(ResourceType type) async {
    final resource = _resources[type];
    if (resource == null) return false;
    if (resource.localPath.isEmpty) return false;

    try {
      final file = File(resource.localPath);
      if (await FileSystemEntity.type(resource.localPath) !=
          FileSystemEntityType.notFound) {
        await file.delete();
      }

      _resources[type] = resource.copyWith(
        status: ResourceStatus.notDownloaded,
        size: 0,
      );
      _notifyListeners();

      Logger.system.info('Deleted resource: ${resource.name}');
      return true;
    } catch (e) {
      Logger.system.error('Failed to delete ${resource.name}: $e');
      return false;
    }
  }

  List<ResourceInfo> getMissingRequired() => _resources.values
      .where(
        (r) =>
            r.isRequired &&
            r.localPath.isNotEmpty &&
            r.status != ResourceStatus.downloaded,
      )
      .toList();

  bool get allRequiredAvailable => !_resources.values.any(
    (r) =>
        r.isRequired &&
        r.localPath.isNotEmpty &&
        r.status != ResourceStatus.downloaded,
  );

  void _notifyListeners() {
    _statusController.add(Map.unmodifiable(_resources));
  }

  void dispose() {
    unawaited(_statusController.close());
  }
}

final resourceManagerProvider = riverpod.Provider<ResourceManagerService>(
  (ref) => ResourceManagerService.instance,
);

final resourceStatusProvider =
    riverpod.StreamProvider<Map<ResourceType, ResourceInfo>>((ref) {
      final manager = ref.watch(resourceManagerProvider);
      return manager.resourcesStream;
    });

final missingResourcesProvider = riverpod.Provider<List<ResourceInfo>>((ref) {
  final manager = ref.watch(resourceManagerProvider);
  return manager.getMissingRequired();
});
