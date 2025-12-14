import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/features/connection/logic/connection_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_service.g.dart';

// FFI types for stats functions
typedef GetStatsNative = Int64 Function();
typedef GetStatsDart = int Function();

// FFI types for query stats (alternative method)
typedef QueryStatsNative = Pointer<Utf8> Function(Pointer<Utf8> pattern);
typedef QueryStatsDart = Pointer<Utf8> Function(Pointer<Utf8> pattern);

/// Traffic statistics data model
class TrafficStats {
  final int uploadBytes;
  final int downloadBytes;
  final int uploadSpeed; // bytes per second
  final int downloadSpeed; // bytes per second
  final int totalUpload; // cumulative
  final int totalDownload; // cumulative

  const TrafficStats({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.totalUpload,
    required this.totalDownload,
  });

  factory TrafficStats.zero() => const TrafficStats(
        uploadBytes: 0,
        downloadBytes: 0,
        uploadSpeed: 0,
        downloadSpeed: 0,
        totalUpload: 0,
        totalDownload: 0,
      );

  TrafficStats copyWith({
    int? uploadBytes,
    int? downloadBytes,
    int? uploadSpeed,
    int? downloadSpeed,
    int? totalUpload,
    int? totalDownload,
  }) =>
      TrafficStats(
        uploadBytes: uploadBytes ?? this.uploadBytes,
        downloadBytes: downloadBytes ?? this.downloadBytes,
        uploadSpeed: uploadSpeed ?? this.uploadSpeed,
        downloadSpeed: downloadSpeed ?? this.downloadSpeed,
        totalUpload: totalUpload ?? this.totalUpload,
        totalDownload: totalDownload ?? this.totalDownload,
      );

  @override
  String toString() =>
      'TrafficStats(upload: $uploadSpeed B/s, download: $downloadSpeed B/s, '
      'total: ↑$totalUpload ↓$totalDownload)';
}

/// Connection duration data model
class ConnectionDuration {
  final DateTime? connectedAt;
  final Duration duration;

  const ConnectionDuration({
    this.connectedAt,
    this.duration = Duration.zero,
  });

  factory ConnectionDuration.notConnected() => const ConnectionDuration();

  bool get isConnected => connectedAt != null;

  String get formatted {
    if (!isConnected) return '--:--:--';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  String toString() => 'ConnectionDuration($formatted)';
}

/// Stats service for getting traffic statistics from Xray core
class StatsService {
  static const _channel = MethodChannel('com.hiddify.app/method');
  static const _statsChannel = EventChannel(
    'com.hiddify.app/stats',
    JSONMethodCodec(),
  );

  late final DynamicLibrary? _lib;
  late final GetStatsDart? _getUplink;
  late final GetStatsDart? _getDownlink;

  // Track cumulative stats
  int _totalUpload = 0;
  int _totalDownload = 0;

  StatsService() {
    _initializeFFI();
  }

  void _initializeFFI() {
    if (Platform.isAndroid || Platform.isIOS) {
      _lib = null;
      _getUplink = null;
      _getDownlink = null;
      return;
    }

    try {
      _lib = _loadLibrary();
      _getUplink = _lib!
          .lookup<NativeFunction<GetStatsNative>>('GetUplink')
          .asFunction();
      _getDownlink = _lib!
          .lookup<NativeFunction<GetStatsNative>>('GetDownlink')
          .asFunction();
      Logger.app.debug('Stats FFI initialized successfully');
    } catch (e) {
      Logger.app.error('Failed to load stats functions from libcore: $e');
      _lib = null;
      _getUplink = null;
      _getDownlink = null;
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('libcore.dll');
    if (Platform.isLinux) return DynamicLibrary.open('libcore.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libcore.dylib');
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Stream<TrafficStats> mobileTrafficStatsStream() {
    DateTime? lastUpdate;
    int? lastTotalUpload;
    int? lastTotalDownload;
    var totalUpload = 0;
    var totalDownload = 0;

    return _statsChannel.receiveBroadcastStream().map((event) {
      try {
        if (event is! Map) return TrafficStats.zero();

        final now = DateTime.now();
        final hasTotals =
            event.containsKey('uplink-total') && event.containsKey('downlink-total');

        int uploadBytes;
        int downloadBytes;

        if (hasTotals) {
          final currentTotalUpload = _toInt(event['uplink-total']);
          final currentTotalDownload = _toInt(event['downlink-total']);

          if (lastTotalUpload != null && lastTotalDownload != null) {
            uploadBytes = currentTotalUpload - lastTotalUpload!;
            downloadBytes = currentTotalDownload - lastTotalDownload!;
            if (uploadBytes < 0) uploadBytes = 0;
            if (downloadBytes < 0) downloadBytes = 0;
          } else {
            uploadBytes = 0;
            downloadBytes = 0;
          }

          totalUpload = currentTotalUpload;
          totalDownload = currentTotalDownload;
        } else {
          uploadBytes = _toInt(event['uplink']);
          downloadBytes = _toInt(event['downlink']);
          totalUpload += uploadBytes;
          totalDownload += downloadBytes;
        }

        final elapsedMs =
            lastUpdate != null ? now.difference(lastUpdate!).inMilliseconds : 0;
        final uploadSpeed =
            elapsedMs > 0 ? ((uploadBytes * 1000) / elapsedMs).round() : 0;
        final downloadSpeed =
            elapsedMs > 0 ? ((downloadBytes * 1000) / elapsedMs).round() : 0;

        lastUpdate = now;
        lastTotalUpload = totalUpload;
        lastTotalDownload = totalDownload;

        return TrafficStats(
          uploadBytes: uploadBytes,
          downloadBytes: downloadBytes,
          uploadSpeed: uploadSpeed,
          downloadSpeed: downloadSpeed,
          totalUpload: totalUpload,
          totalDownload: totalDownload,
        );
      } catch (e) {
        Logger.app.error('Failed to parse mobile stats event: $e');
        return TrafficStats.zero();
      }
    });
  }

  /// Get uplink bytes since last call (resets counter in core)
  Future<int> getUplink() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _getMobileUplink();
    }
    if (_getUplink == null) return 0;
    try {
      return _getUplink!();
    } catch (e) {
      Logger.app.error('Error getting uplink stats: $e');
      return 0;
    }
  }

  /// Get downlink bytes since last call (resets counter in core)
  Future<int> getDownlink() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _getMobileDownlink();
    }
    if (_getDownlink == null) return 0;
    try {
      return _getDownlink!();
    } catch (e) {
      Logger.app.error('Error getting downlink stats: $e');
      return 0;
    }
  }

  /// Mobile platform implementation using MethodChannel
  Future<int> _getMobileUplink() async {
    try {
      final result = await _channel.invokeMethod<int>('getUplink');
      return result ?? 0;
    } on PlatformException catch (e) {
      Logger.app.error('Mobile getUplink failed: ${e.message}');
      return 0;
    } on MissingPluginException {
      // Method not implemented on this platform
      return 0;
    }
  }

  Future<int> _getMobileDownlink() async {
    try {
      final result = await _channel.invokeMethod<int>('getDownlink');
      return result ?? 0;
    } on PlatformException catch (e) {
      Logger.app.error('Mobile getDownlink failed: ${e.message}');
      return 0;
    } on MissingPluginException {
      // Method not implemented on this platform
      return 0;
    }
  }

  /// Get current traffic stats with speed calculation
  Future<TrafficStats> getStats() async {
    final upload = await getUplink();
    final download = await getDownlink();

    // Update cumulative totals
    _totalUpload += upload;
    _totalDownload += download;

    // Speed equals bytes received in this interval (1 second)
    return TrafficStats(
      uploadBytes: upload,
      downloadBytes: download,
      uploadSpeed: upload,
      downloadSpeed: download,
      totalUpload: _totalUpload,
      totalDownload: _totalDownload,
    );
  }

  /// Reset cumulative counters (call when disconnecting)
  void resetCounters() {
    _totalUpload = 0;
    _totalDownload = 0;
    Logger.app.debug('Stats counters reset');
  }
}

// Singleton instance
final _statsService = StatsService();

/// Provider for StatsService
@riverpod
StatsService statsService(Ref ref) => _statsService;

/// Provider for connection start time
@riverpod
class ConnectionStartTime extends _$ConnectionStartTime {
  @override
  DateTime? build() {
    // Listen to connection status changes
    ref.listen(connectionProvider, (previous, next) {
      if (next == ConnectionStatus.connected && previous != ConnectionStatus.connected) {
        // Just connected - set start time
        state = DateTime.now();
        Logger.app.info('Connection started at: $state');
      } else if (next != ConnectionStatus.connected && previous == ConnectionStatus.connected) {
        // Just disconnected - clear start time and reset stats
        state = null;
        _statsService.resetCounters();
        Logger.app.info('Connection ended, stats reset');
      }
    });
    return null;
  }

  DateTime? get connectedAt => state;
  set connectedAt(DateTime? time) => state = time;
  void clear() => state = null;
}

/// Provider for connection duration stream (updates every second)
@riverpod
Stream<ConnectionDuration> connectionDuration(Ref ref) async* {
  final connectionStatus = ref.watch(connectionProvider);
  
  if (connectionStatus != ConnectionStatus.connected) {
    yield ConnectionDuration.notConnected();
    return;
  }

  final startTime = ref.watch(connectionStartTimeProvider) ?? DateTime.now();
  
  // Emit duration every second while connected
  while (true) {
    final now = DateTime.now();
    final duration = now.difference(startTime);
    yield ConnectionDuration(
      connectedAt: startTime,
      duration: duration,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    
    // Check if still connected
    if (ref.read(connectionProvider) != ConnectionStatus.connected) {
      yield ConnectionDuration.notConnected();
      return;
    }
  }
}

/// Provider for traffic stats stream (updates every second)
@riverpod
Stream<TrafficStats> trafficStats(Ref ref) async* {
  final connectionStatus = ref.watch(connectionProvider);
  final statsService = ref.watch(statsServiceProvider);
  
  if (connectionStatus != ConnectionStatus.connected) {
    yield TrafficStats.zero();
    return;
  }

  if (Platform.isAndroid || Platform.isIOS) {
    yield* statsService.mobileTrafficStatsStream();
    return;
  }

  // Emit stats every second while connected
  while (true) {
    final stats = await statsService.getStats();
    yield stats;
    await Future<void>.delayed(const Duration(seconds: 1));
    
    // Check if still connected
    if (ref.read(connectionProvider) != ConnectionStatus.connected) {
      yield TrafficStats.zero();
      return;
    }
  }
}

/// Legacy provider for backward compatibility
/// Returns (uplink, downlink) tuple for speed in bytes/second
@riverpod
Stream<(int, int)> statsServiceStream(Ref ref) async* {
  final connectionStatus = ref.watch(connectionProvider);
  final statsService = ref.watch(statsServiceProvider);
  
  if (connectionStatus != ConnectionStatus.connected) {
    yield (0, 0);
    return;
  }

  if (Platform.isAndroid || Platform.isIOS) {
    yield* statsService
        .mobileTrafficStatsStream()
        .map((stats) => (stats.uploadSpeed, stats.downloadSpeed));
    return;
  }

  while (true) {
    final stats = await statsService.getStats();
    yield (stats.uploadSpeed, stats.downloadSpeed);
    await Future<void>.delayed(const Duration(seconds: 1));
    
    if (ref.read(connectionProvider) != ConnectionStatus.connected) {
      yield (0, 0);
      return;
    }
  }
}
