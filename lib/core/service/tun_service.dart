import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/service/tun_asset_service.dart';
import 'package:path_provider/path_provider.dart';

/// TUN service for managing tun2socks process
class TunService {
  Process? _process;
  final TunAssetService _assetService = TunAssetService();
  
  bool _isRunning = false;
  String? _lastError;

  /// Check if TUN is running
  bool get isRunning => _isRunning;
  
  /// Get last error
  String? get lastError => _lastError;

  /// TUN interface name
  static const String tunName = 'HiddifyTun';
  
  /// TUN MTU
  static const int tunMtu = 9000;

  static const String _pidFileName = 'tun2socks.pid';

  Future<File> _pidFile() async {
    final dir = await getApplicationSupportDirectory();
    final runDir = Directory('${dir.path}/run');
    if (!await runDir.exists()) {
      await runDir.create(recursive: true);
    }
    return File('${runDir.path}/$_pidFileName');
  }

  Future<({int pid, String? path})?> _readPidInfo() async {
    try {
      final file = await _pidFile();
      if (!await file.exists()) return null;
      final raw = (await file.readAsString()).trim();
      if (raw.isEmpty) return null;

      if (raw.startsWith('{')) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final pidVal = decoded['pid'];
          final pathVal = decoded['path'];
          final pid = pidVal is int
              ? pidVal
              : pidVal is String
                  ? int.tryParse(pidVal)
                  : null;
          final path = pathVal is String && pathVal.trim().isNotEmpty
              ? pathVal.trim()
              : null;
          if (pid != null && pid > 0) {
            return (pid: pid, path: path);
          }
        }
        return null;
      }

      final pid = int.tryParse(raw);
      if (pid != null && pid > 0) {
        return (pid: pid, path: null);
      }
      return null;
    } on Exception catch (e, stackTrace) {
      Logger.app.debug('Failed to read tun2socks pid file: $e', e, stackTrace);
      return null;
    }
  }

  Future<void> _writePid({required int pid, required String path}) async {
    try {
      final file = await _pidFile();
      await file.writeAsString(jsonEncode({'pid': pid, 'path': path}));
    } on Exception catch (e, stackTrace) {
      Logger.app.debug('Failed to write tun2socks pid file: $e', e, stackTrace);
    }
  }

  Future<void> _deletePid() async {
    try {
      final file = await _pidFile();
      if (await file.exists()) {
        await file.delete();
      }
    } on Exception catch (e, stackTrace) {
      Logger.app.debug('Failed to delete tun2socks pid file: $e', e, stackTrace);
    }
  }

  Future<bool> _matchesTun2socksProcess({
    required int pid,
    String? expectedPath,
  }) async {
    if (!Platform.isWindows) return false;

    final expected = expectedPath?.toLowerCase().trim();

    try {
      final ps = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          '(Get-Process -Id $pid -ErrorAction SilentlyContinue | Select-Object -Expand Path)',
        ],
        runInShell: false,
      );

      final stdout = ps.stdout;
      if (stdout is String) {
        final path = stdout.trim();
        if (path.isNotEmpty) {
          if (expected == null) {
            return path.toLowerCase().endsWith('\\tun2socks.exe');
          }
          return path.toLowerCase() == expected;
        }
      }
    } on Exception catch (e, stackTrace) {
      Logger.app.debug('Failed to query tun2socks process path: $e', e, stackTrace);
    }

    try {
      final tasklist = await Process.run(
        'tasklist',
        ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH'],
        runInShell: false,
      );

      final stdout = tasklist.stdout;
      if (stdout is String) {
        final line = stdout.trim();
        if (line.isEmpty || line.startsWith('INFO:')) return false;
        final firstQuote = line.indexOf('"');
        if (firstQuote == -1) return false;
        final secondQuote = line.indexOf('"', firstQuote + 1);
        if (secondQuote == -1) return false;
        final imageName = line.substring(firstQuote + 1, secondQuote);
        if (imageName.toLowerCase() != 'tun2socks.exe') return false;
        if (expected == null) return true;
        return expected.endsWith('\\tun2socks.exe');
      }
    } on Exception catch (e, stackTrace) {
      Logger.app.debug('Failed to query tun2socks process name: $e', e, stackTrace);
    }

    return false;
  }

  Future<void> _killOrphanIfAny() async {
    final info = await _readPidInfo();
    if (info == null) return;

    final matches =
        await _matchesTun2socksProcess(pid: info.pid, expectedPath: info.path);
    if (!matches) {
      await _deletePid();
      return;
    }

    try {
      final killed = Process.killPid(info.pid);
      if (killed) {
        Logger.app.warning('Killed orphan tun2socks process (pid: ${info.pid})');
      }
    } on Exception catch (e, stackTrace) {
      Logger.app.warning('Failed to kill orphan tun2socks (pid: ${info.pid}): $e', e, stackTrace);
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    final stillRunning =
        await _matchesTun2socksProcess(pid: info.pid, expectedPath: info.path);
    if (stillRunning) {
      Logger.app.warning(
        'Orphan tun2socks still running after kill attempt (pid: ${info.pid})',
      );
      return;
    }

    await _deletePid();
  }

  /// Start TUN with tun2socks
  /// [socksAddr] - SOCKS5 proxy address (e.g., "127.0.0.1:2334")
  Future<String?> start({
    required String socksAddr,
    String? tunName,
    int? mtu,
    String? logLevel,
  }) async {
    if (_isRunning) {
      Logger.app.warning('TUN already running');
      return null;
    }

    if (!Platform.isWindows) {
      _lastError = 'TUN only supported on Windows';
      return _lastError;
    }

    // Check assets
    if (!await _assetService.assetsExist()) {
      _lastError = 'TUN assets not found. Please download them first.';
      Logger.app.error(_lastError);
      return _lastError;
    }

    final tun2socksPath = await _assetService.getTun2socksPath();
    final deviceName = tunName ?? TunService.tunName;
    final deviceMtu = mtu ?? TunService.tunMtu;

    await _killOrphanIfAny();

    // Build tun2socks arguments
    final args = <String>[
      '-device', 'tun://$deviceName',
      '-proxy', 'socks5://$socksAddr',
      '-mtu', deviceMtu.toString(),
      '-tcp-sndbuf', '4m',
      '-tcp-rcvbuf', '4m',
    ];

    if (logLevel != null) {
      args.addAll(['-loglevel', logLevel]);
    }

    Logger.app.info('Starting TUN: $tun2socksPath ${args.join(' ')}');

    try {
      _process = await Process.start(
        tun2socksPath,
        args,
        mode: ProcessStartMode.normal,
        runInShell: false,
      );

      _isRunning = true;
      _lastError = null;

      await _writePid(pid: _process!.pid, path: tun2socksPath);

      // Listen to stdout
      _process!.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.trim().isNotEmpty) {
          Logger.app.debug('[tun2socks] $line');
        }
      });

      // Listen to stderr
      _process!.stderr
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.trim().isNotEmpty) {
          Logger.app.warning('[tun2socks] $line');
        }
      });

      // Handle process exit
      unawaited(_process!.exitCode.then((code) {
        Logger.app.info('tun2socks exited with code: $code');
        _isRunning = false;
        if (code != 0) {
          _lastError = 'tun2socks exited with code $code';
        }
        unawaited(_deletePid());
      }));

      // Wait a bit for process to start
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Check if still running
      if (!_isRunning) {
        // Check for common errors
        if (_lastError?.contains('Access is denied') ?? false) {
          _lastError = 'Administrator access required. Please run as Administrator.';
        } else if (_process != null && await _process!.exitCode != 0) {
           // If it failed immediately with non-zero code, it's often permissions or conflict
           _lastError = 'TUN failed to start (Code: ${await _process!.exitCode}).\nTry running as Administrator.';
        }
        return _lastError ?? 'TUN failed to start';
      }

      Logger.app.info('TUN started successfully');
      return null;
    } catch (e) {
      _lastError = 'Failed to start TUN: $e';
      Logger.app.error(_lastError);
      _isRunning = false;
      return _lastError;
    }
  }

  /// Stop TUN
  Future<void> stop() async {
    final pidInfo = await _readPidInfo();
    if (!_isRunning && _process == null && pidInfo == null) {
      Logger.app.debug('TUN not running');
      return;
    }

    Logger.app.info('Stopping TUN...');

    var shouldDeletePid = true;

    try {
      // Send SIGTERM on Unix, kill on Windows
      if (_process != null) {
        final process = _process!;
        process.kill();

        var timedOut = false;
        await process.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            timedOut = true;
            Logger.app.warning(
              'TUN did not exit gracefully, force killing...',
            );
            process.kill();
            return -1;
          },
        );

        if (timedOut) {
          final stillRunning = await _matchesTun2socksProcess(
            pid: process.pid,
            expectedPath: pidInfo?.path,
          );
          if (stillRunning) {
            shouldDeletePid = false;
            Logger.app.warning(
              'tun2socks still running after stop attempt (pid: ${process.pid})',
            );
          }
        }
      } else if (pidInfo != null) {
        final matches = await _matchesTun2socksProcess(
          pid: pidInfo.pid,
          expectedPath: pidInfo.path,
        );
        if (matches) {
          final killed = Process.killPid(pidInfo.pid);
          if (killed) {
            Logger.app.warning('Killed tun2socks by pid (${pidInfo.pid})');
          }

          await Future<void>.delayed(const Duration(milliseconds: 200));
          final stillRunning = await _matchesTun2socksProcess(
            pid: pidInfo.pid,
            expectedPath: pidInfo.path,
          );
          if (stillRunning) {
            shouldDeletePid = false;
            Logger.app.warning(
              'tun2socks still running after kill attempt (pid: ${pidInfo.pid})',
            );
          }
        }
      }
    } catch (e) {
      Logger.app.error('Error stopping TUN: $e');
    } finally {
      if (shouldDeletePid) {
        await _deletePid();
      }
    }

    _process = null;
    _isRunning = false;
    _lastError = null;

    Logger.app.info('TUN stopped');
  }

  /// Restart TUN
  Future<String?> restart({
    required String socksAddr,
    String? tunName,
    int? mtu,
    String? logLevel,
  }) async {
    await stop();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return start(
      socksAddr: socksAddr,
      tunName: tunName,
      mtu: mtu,
      logLevel: logLevel,
    );
  }

  /// Check if TUN assets are available
  Future<bool> isAvailable() async {
    if (!Platform.isWindows) return false;
    return _assetService.assetsExist();
  }

  /// Download TUN assets if needed
  Future<void> ensureAssets({
    void Function(double progress, String status)? onProgress,
  }) async {
    await _assetService.ensureAssetsExist(onProgress: onProgress);
  }
}
