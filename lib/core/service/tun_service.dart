import 'dart:async';
import 'dart:io';

import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/service/tun_asset_service.dart';

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
      Logger.app.error(_lastError!);
      return _lastError;
    }

    final tun2socksPath = await _assetService.getTun2socksPath();
    final deviceName = tunName ?? TunService.tunName;
    final deviceMtu = mtu ?? TunService.tunMtu;

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

      // Listen to stdout
      _process!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        Logger.app.debug('[tun2socks] $data');
      });

      // Listen to stderr
      _process!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        Logger.app.warning('[tun2socks] $data');
      });

      // Handle process exit
      unawaited(_process!.exitCode.then((code) {
        Logger.app.info('tun2socks exited with code: $code');
        _isRunning = false;
        if (code != 0) {
          _lastError = 'tun2socks exited with code $code';
        }
      }));

      // Wait a bit for process to start
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Check if still running
      if (!_isRunning) {
        // Check for common errors
        if (_lastError?.contains('Access is denied') ?? false) {
          _lastError = 'Administrator access required. Please run as Administrator.';
        }
        return _lastError ?? 'TUN failed to start';
      }

      Logger.app.info('TUN started successfully');
      return null;
    } catch (e) {
      _lastError = 'Failed to start TUN: $e';
      Logger.app.error(_lastError!);
      _isRunning = false;
      return _lastError;
    }
  }

  /// Stop TUN
  Future<void> stop() async {
    if (!_isRunning || _process == null) {
      Logger.app.debug('TUN not running');
      return;
    }

    Logger.app.info('Stopping TUN...');

    try {
      // Send SIGTERM on Unix, kill on Windows
      _process!.kill();
      
      // Wait for process to exit
      await _process!.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Logger.app.warning('TUN did not exit gracefully, force killing...');
          _process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (e) {
      Logger.app.error('Error stopping TUN: $e');
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
