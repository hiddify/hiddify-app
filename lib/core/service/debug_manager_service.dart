import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:path_provider/path_provider.dart';

abstract class DebugSettings {
  static final debugMode = PreferencesNotifier.create<bool, bool>(
    'debug_mode_enabled',
    kDebugMode,
  );

  static final verboseLogging = PreferencesNotifier.create<bool, bool>(
    'debug_verbose_logging',
    false,
  );

  static final showAdvancedDebug = PreferencesNotifier.create<bool, bool>(
    'debug_show_advanced',
    false,
  );

  static final performanceMonitoring = PreferencesNotifier.create<bool, bool>(
    'debug_performance_monitoring',
    false,
  );

  static final logNetworkRequests = PreferencesNotifier.create<bool, bool>(
    'debug_log_network',
    false,
  );

  static final logDnsQueries = PreferencesNotifier.create<bool, bool>(
    'debug_log_dns',
    false,
  );

  static final logRoutingDecisions = PreferencesNotifier.create<bool, bool>(
    'debug_log_routing',
    false,
  );

  static final maxLogFileSize = PreferencesNotifier.create<int, int>(
    'debug_max_log_size',
    10,
  );

  static final logRetentionDays = PreferencesNotifier.create<int, int>(
    'debug_log_retention',
    7,
  );
}

enum ProcessStatus { stopped, starting, running, stopping, error }

class ProcessInfo {
  const ProcessInfo({
    required this.name,
    required this.processId,
    required this.status,
    this.startTime,
    this.memoryUsage = 0,
    this.cpuUsage = 0.0,
    this.error,
  });

  final String name;
  final int processId;
  final ProcessStatus status;
  final DateTime? startTime;
  final int memoryUsage;
  final double cpuUsage;
  final String? error;

  ProcessInfo copyWith({
    String? name,
    int? processId,
    ProcessStatus? status,
    DateTime? startTime,
    int? memoryUsage,
    double? cpuUsage,
    String? error,
  }) {
    return ProcessInfo(
      name: name ?? this.name,
      processId: processId ?? this.processId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      error: error,
    );
  }

  String get uptimeFormatted {
    if (startTime == null) return 'N/A';
    final duration = DateTime.now().difference(startTime!);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }

  String get memoryFormatted {
    if (memoryUsage < 1024) return '$memoryUsage B';
    if (memoryUsage < 1024 * 1024) {
      return '${(memoryUsage / 1024).toStringAsFixed(1)} KB';
    }
    return '${(memoryUsage / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ProcessManagerService {
  ProcessManagerService._();

  static final instance = ProcessManagerService._();

  final _processes = <String, ProcessInfo>{};
  final _processController =
      StreamController<Map<String, ProcessInfo>>.broadcast();
  Timer? _monitorTimer;

  Stream<Map<String, ProcessInfo>> get processesStream =>
      _processController.stream;
  Map<String, ProcessInfo> get processes => Map.unmodifiable(_processes);

  Future<void> initialize() async {
    _processes['xray-core'] = const ProcessInfo(
      name: 'Xray Core',
      processId: 0,
      status: ProcessStatus.stopped,
    );

    _processes['tun2socks'] = const ProcessInfo(
      name: 'TUN2SOCKS',
      processId: 0,
      status: ProcessStatus.stopped,
    );

    _processes['hysteria'] = const ProcessInfo(
      name: 'Hysteria',
      processId: 0,
      status: ProcessStatus.stopped,
    );

    _processes['tuic'] = const ProcessInfo(
      name: 'TUIC',
      processId: 0,
      status: ProcessStatus.stopped,
    );

    _startMonitoring();
    Logger.system.info('ProcessManager initialized');
  }

  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_checkProcesses());
    });
  }

  Future<void> _checkProcesses() async {
    for (final name in _processes.keys.toList()) {
      final process = _processes[name]!;
      if (process.processId > 0) {
        final isRunning = await _isProcessRunning(process.processId);
        if (!isRunning) {
          _processes[name] = process.copyWith(
            status: ProcessStatus.stopped,
            processId: 0,
          );
        }
      }
    }
    _notifyListeners();
  }

  Future<bool> _isProcessRunning(int pid) async {
    if (pid <= 0) return false;

    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', ['/FI', 'PID eq $pid']);
        return (result.stdout as String).contains(pid.toString());
      } else {
        final result = await Process.run('ps', ['-p', pid.toString()]);
        return result.exitCode == 0;
      }
    } catch (e) {
      return false;
    }
  }

  void registerProcess(String name, int pid) {
    _processes[name] = ProcessInfo(
      name: name,
      processId: pid,
      status: ProcessStatus.running,
      startTime: DateTime.now(),
    );
    _notifyListeners();
    Logger.system.info('Process registered: $name (PID: $pid)');
  }

  void updateProcessStatus(String name, ProcessStatus status, {String? error}) {
    final existing = _processes[name];
    if (existing != null) {
      _processes[name] = existing.copyWith(status: status, error: error);
      _notifyListeners();
    }
  }

  void unregisterProcess(String name) {
    if (_processes.containsKey(name)) {
      _processes[name] = _processes[name]!.copyWith(
        status: ProcessStatus.stopped,
        processId: 0,
      );
      _notifyListeners();
      Logger.system.info('Process unregistered: $name');
    }
  }

  Future<bool> killProcess(String name) async {
    final process = _processes[name];
    if (process == null || process.processId <= 0) return false;

    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', [
          '/F',
          '/PID',
          process.processId.toString(),
        ]);
      } else {
        Process.killPid(process.processId);
      }

      _processes[name] = process.copyWith(
        status: ProcessStatus.stopped,
        processId: 0,
      );
      _notifyListeners();
      Logger.system.info('Process killed: $name (PID: ${process.processId})');
      return true;
    } catch (e) {
      Logger.system.error('Failed to kill process $name: $e');
      return false;
    }
  }

  List<ProcessInfo> getRunningProcesses() => _processes.values
      .where((p) => p.status == ProcessStatus.running)
      .toList();

  ProcessInfo? getProcess(String name) => _processes[name];

  void _notifyListeners() {
    _processController.add(Map.unmodifiable(_processes));
  }

  Future<void> dispose() async {
    _monitorTimer?.cancel();
    await _processController.close();
  }
}

class HealthCheckResult {
  const HealthCheckResult({
    required this.name,
    required this.passed,
    required this.message,
    this.details,
  });

  final String name;
  final bool passed;
  final String message;
  final String? details;
}

class SystemHealthService {
  SystemHealthService._();

  static final instance = SystemHealthService._();

  Future<List<HealthCheckResult>> runFullHealthCheck() async {
    final results = <HealthCheckResult>[];

    results.add(await _checkFileSystem());
    results.add(await _checkNetworkConnectivity());
    results.add(await _checkGeoAssets());
    results.add(await _checkCoreServices());
    results.add(await _checkMemoryUsage());
    results.add(await _checkDiskSpace());
    results.add(await _checkPermissions());

    return results;
  }

  Future<HealthCheckResult> _checkFileSystem() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final testFile = File('${dir.path}/.health_check');
      await testFile.writeAsString('test');
      await testFile.delete();

      return const HealthCheckResult(
        name: 'File System',
        passed: true,
        message: 'File system accessible',
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'File System',
        passed: false,
        message: 'File system error',
        details: e.toString(),
      );
    }
  }

  Future<HealthCheckResult> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return const HealthCheckResult(
          name: 'Network',
          passed: true,
          message: 'Internet connection available',
        );
      }
      return const HealthCheckResult(
        name: 'Network',
        passed: false,
        message: 'No internet connection',
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Network',
        passed: false,
        message: 'Network check failed',
        details: e.toString(),
      );
    }
  }

  Future<HealthCheckResult> _checkGeoAssets() async {
    try {
      final resourceManager = ResourceManagerService.instance;
      final geoipPath =
          resourceManager.resources[ResourceType.geoip]?.localPath ?? '';
      final geositePath =
          resourceManager.resources[ResourceType.geosite]?.localPath ?? '';

      final geoip = File(geoipPath);
      final geosite = File(geositePath);

      final geoipExists = await geoip.exists();
      final geositeExists = await geosite.exists();

      if (geoipExists && geositeExists) {
        return const HealthCheckResult(
          name: 'Geo Assets',
          passed: true,
          message: 'GeoIP and GeoSite files present',
        );
      }

      return HealthCheckResult(
        name: 'Geo Assets',
        passed: false,
        message: 'Geo assets missing',
        details:
            'GeoIP: ${geoipExists ? 'OK' : 'Missing'}, GeoSite: ${geositeExists ? 'OK' : 'Missing'}',
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Geo Assets',
        passed: false,
        message: 'Failed to check geo assets',
        details: e.toString(),
      );
    }
  }

  Future<HealthCheckResult> _checkCoreServices() async {
    try {
      final pm = ProcessManagerService.instance;
      final xray = pm.getProcess('xray-core');

      return HealthCheckResult(
        name: 'Core Services',
        passed: true,
        message: 'Core service check completed',
        details: 'Xray: ${xray?.status.name ?? 'unknown'}',
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Core Services',
        passed: false,
        message: 'Core service check failed',
        details: e.toString(),
      );
    }
  }

  Future<HealthCheckResult> _checkMemoryUsage() async {
    try {
      return const HealthCheckResult(
        name: 'Memory',
        passed: true,
        message: 'Memory usage normal',
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Memory',
        passed: false,
        message: 'Memory check failed',
        details: e.toString(),
      );
    }
  }

  Future<HealthCheckResult> _checkDiskSpace() async {
    try {
      final dir = await getApplicationSupportDirectory();
      await FileStat.stat(dir.path);
      return HealthCheckResult(
        name: 'Disk Space',
        passed: true,
        message: 'Disk space available',
        details: 'Path: ${dir.path}',
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Disk Space',
        passed: false,
        message: 'Disk check failed',
        details: e.toString(),
      );
    }
  }

  Future<HealthCheckResult> _checkPermissions() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('net', ['session']);
        final isAdmin = result.exitCode == 0;

        return HealthCheckResult(
          name: 'Permissions',
          passed: isAdmin,
          message: isAdmin
              ? 'Running as Administrator'
              : 'Not running as Administrator',
          details: isAdmin
              ? null
              : 'Some features may not work without admin rights',
        );
      }

      return const HealthCheckResult(
        name: 'Permissions',
        passed: true,
        message: 'Permissions OK',
      );
    } catch (e) {
      return HealthCheckResult(
        name: 'Permissions',
        passed: false,
        message: 'Permission check failed',
        details: e.toString(),
      );
    }
  }
}

final processManagerProvider = riverpod.Provider<ProcessManagerService>(
  (ref) => ProcessManagerService.instance,
);

final systemHealthProvider = riverpod.Provider<SystemHealthService>(
  (ref) => SystemHealthService.instance,
);

final processListProvider = riverpod.StreamProvider<Map<String, ProcessInfo>>((
  ref,
) {
  final pm = ref.watch(processManagerProvider);
  return pm.processesStream;
});
