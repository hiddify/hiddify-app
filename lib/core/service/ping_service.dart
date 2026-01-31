import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/features/config/logic/config_parser.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/connection/logic/connection_notifier.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:hiddify/gen/libcore_bindings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ping_service.g.dart';

class PingService {
  static const _channel = MethodChannel('com.hiddify.app/method');
  static const String testUrl =
      'https://connectivitycheck.gstatic.com/generate_204';
  static const int defaultTimeout = 5000; 

  PingService();

  static DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('libcore.dll');
    if (Platform.isLinux) return DynamicLibrary.open('libcore.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libcore.dylib');
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  Future<int?> pingServer(
    String address, {
    int timeout = defaultTimeout,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<int>('ping', {
          'address': address,
          'timeout': timeout,
        });
        return result;
      } on PlatformException catch (e) {
        Logger.connection.error('Ping failed: ${e.message}');
        return null;
      }
    } else {
      return Isolate.run(() {
        final lib = LibCore(_loadLibrary());
        final addressPtr = address.toNativeUtf8();
        try {
          final result = lib.Ping(addressPtr.cast(), timeout);
          return result >= 0 ? result : null;
        } finally {
          calloc.free(addressPtr);
        }
      });
    }
  }

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
        Logger.connection.error('Proxy ping failed: ${e.message}');
        return null;
      }
    } else {
      return Isolate.run(() {
        final lib = LibCore(_loadLibrary());
        final socksPtr = socksAddr.toNativeUtf8();
        final urlPtr = url.toNativeUtf8();
        try {
          final result = lib.ProxyPing(socksPtr.cast(), urlPtr.cast(), timeout);
          return result >= 0 ? result : null;
        } finally {
          calloc.free(socksPtr);
          calloc.free(urlPtr);
        }
      });
    }
  }

  bool isRunning() {
    if (Platform.isAndroid || Platform.isIOS) {
      return false;
    }
    try {
      final lib = LibCore(_loadLibrary());
      return lib.IsRunning() == 1;
    } catch (_) {
      return false;
    }
  }

  Future<int?> testConfig(Config config) async {
    final serverAddress = ConfigParser.extractServerAddress(config.content);
    if (serverAddress == null) {
      Logger.connection.warning('Could not extract server address from config');
      return null;
    }
    return pingServer(serverAddress);
  }
}

@riverpod
PingService pingService(Ref ref) => PingService();

@riverpod
Stream<int?> realTimePing(Ref ref) async* {
  final connectionStatus = ref.watch(connectionProvider);
  final pingService = ref.watch(pingServiceProvider);
  final socksPort = ref.watch(InboundSettings.socksPort);

  if (connectionStatus != ConnectionStatus.connected) {
    yield null;
    return;
  }
  while (true) {
    final ping = await pingService.proxyPing(socksAddr: '127.0.0.1:$socksPort');
    yield ping;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (ref.read(connectionProvider) != ConnectionStatus.connected) {
      yield null;
      return;
    }
  }
}

@riverpod
Future<int?> configPing(Ref ref, Config config) {
  final pingService = ref.watch(pingServiceProvider);
  return pingService.testConfig(config);
}
