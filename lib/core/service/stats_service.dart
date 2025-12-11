import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/features/connection/logic/connection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// FFI types
typedef GetStatsNative = Int64 Function();
typedef GetStatsDart = int Function();

class StatsService {
  static const _channel = MethodChannel('com.hiddify.app/method');

  late final DynamicLibrary? _lib;
  late final GetStatsDart? _getUplink;
  late final GetStatsDart? _getDownlink;

  StatsService() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        _lib = _loadLibrary();
        _getUplink = _lib!
            .lookup<NativeFunction<GetStatsNative>>('GetUplink')
            .asFunction();
        _getDownlink = _lib!
            .lookup<NativeFunction<GetStatsNative>>('GetDownlink')
            .asFunction();
      } catch (e) {
        Logger.app.error('Failed to load stats functions from libcore: $e');
        _lib = null;
        _getUplink = null;
        _getDownlink = null;
      }
    } else {
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

  /// Get uplink bytes (resets counter)
  int getUplink() {
    if (Platform.isAndroid || Platform.isIOS) {
      return 0; // TODO: implement for mobile
    }
    if (_getUplink == null) return 0;
    return _getUplink!();
  }

  /// Get downlink bytes (resets counter)
  int getDownlink() {
    if (Platform.isAndroid || Platform.isIOS) {
      return 0; // TODO: implement for mobile
    }
    if (_getDownlink == null) return 0;
    return _getDownlink!();
  }
}

final _statsService = StatsService();

final statsServiceProvider = StreamProvider.autoDispose<(int uplink, int downlink)>((ref) {
  final connectionStatus = ref.watch(connectionProvider);
  
  if (connectionStatus != ConnectionStatus.connected) {
    // Not connected, return zeros
    return Stream.value((0, 0));
  }

  // While connected, emit stats every second
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final uplink = _statsService.getUplink();
    final downlink = _statsService.getDownlink();
    return (uplink, downlink);
  });
});
