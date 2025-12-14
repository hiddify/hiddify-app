import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/features/config/logic/config_parser.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/connection/logic/connection_notifier.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ping_service.g.dart';

// FFI types
typedef PingNative = Int32 Function(Pointer<Utf8> address, Int32 timeoutMs);
typedef PingDart = int Function(Pointer<Utf8> address, int timeoutMs);

typedef ProxyPingNative = Int32 Function(
  Pointer<Utf8> socksAddr,
  Pointer<Utf8> testUrl,
  Int32 timeoutMs,
);
typedef ProxyPingDart = int Function(
  Pointer<Utf8> socksAddr,
  Pointer<Utf8> testUrl,
  int timeoutMs,
);

typedef IsRunningNative = Int32 Function();
typedef IsRunningDart = int Function();

class PingService {
  static const _channel = MethodChannel('com.hiddify.app/method');
  static const String testUrl = 'https://connectivitycheck.gstatic.com/generate_204';
  static const int defaultTimeout = 5000; // 5 seconds

  late final DynamicLibrary? _lib;
  late final PingDart? _ping;
  late final ProxyPingDart? _proxyPing;
  late final IsRunningDart? _isRunning;

  PingService() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        _lib = _loadLibrary();
        _ping = _lib!.lookup<NativeFunction<PingNative>>('Ping').asFunction();
        _proxyPing = _lib!
            .lookup<NativeFunction<ProxyPingNative>>('ProxyPing')
            .asFunction();
        _isRunning =
            _lib!.lookup<NativeFunction<IsRunningNative>>('IsRunning').asFunction();
      } catch (e) {
        Logger.app.error('Failed to load ping functions from libcore: $e');
        _lib = null;
        _ping = null;
        _proxyPing = null;
        _isRunning = null;
      }
    } else {
      _lib = null;
      _ping = null;
      _proxyPing = null;
      _isRunning = null;
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('libcore.dll');
    if (Platform.isLinux) return DynamicLibrary.open('libcore.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libcore.dylib');
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  /// Direct ping to server (before connection)
  Future<int?> pingServer(String address, {int timeout = defaultTimeout}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<int>('ping', {
          'address': address,
          'timeout': timeout,
        });
        return result;
      } on PlatformException catch (e) {
        Logger.app.error('Ping failed: ${e.message}');
        return null;
      }
    } else {
      if (_ping == null) return null;

      final addressPtr = address.toNativeUtf8();
      try {
        final result = _ping!(addressPtr, timeout);
        return result >= 0 ? result : null;
      } finally {
        malloc.free(addressPtr);
      }
    }
  }

  /// Ping through SOCKS proxy (after connection)
  Future<int?> proxyPing({
    required String socksAddr,
    String url = testUrl,
    int timeout = defaultTimeout,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<int>('proxyPing', {
          'socksAddr': socksAddr,
          'testUrl': url,
          'timeout': timeout,
        });
        return result;
      } on PlatformException catch (e) {
        Logger.app.error('Proxy ping failed: ${e.message}');
        return null;
      }
    } else {
      if (_proxyPing == null) return null;

      final socksPtr = socksAddr.toNativeUtf8();
      final urlPtr = url.toNativeUtf8();
      try {
        final result = _proxyPing!(socksPtr, urlPtr, timeout);
        return result >= 0 ? result : null;
      } finally {
        malloc.free(socksPtr);
        malloc.free(urlPtr);
      }
    }
  }

  /// Check if core is running
  bool isRunning() {
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile, we rely on ConnectionStatus
      return false;
    }
    if (_isRunning == null) return false;
    return _isRunning!() == 1;
  }

  /// Test config before connection by pinging its server
  Future<int?> testConfig(Config config) async {
    final serverAddress = ConfigParser.extractServerAddress(config.content);
    if (serverAddress == null) {
      Logger.app.warning('Could not extract server address from config');
      return null;
    }
    return pingServer(serverAddress);
  }
}

@riverpod
PingService pingService(Ref ref) => PingService();

/// Real-time ping provider - updates every 3 seconds when connected
@riverpod
Stream<int?> realTimePing(Ref ref) async* {
  final connectionStatus = ref.watch(connectionProvider);
  final pingService = ref.watch(pingServiceProvider);
  final socksPort = ref.watch(InboundSettings.socksPort);

  if (connectionStatus != ConnectionStatus.connected) {
    yield null;
    return;
  }

  // Emit ping every 3 seconds while connected
  while (true) {
    final ping = await pingService.proxyPing(
      socksAddr: '127.0.0.1:$socksPort',
    );
    yield ping;
    await Future<void>.delayed(const Duration(seconds: 3));
    
    // Check if still connected
    if (ref.read(connectionProvider) != ConnectionStatus.connected) {
      yield null;
      return;
    }
  }
}

/// Ping a specific config (for testing before connection)
@riverpod
Future<int?> configPing(Ref ref, Config config) {
  final pingService = ref.watch(pingServiceProvider);
  return pingService.testConfig(config);
}
