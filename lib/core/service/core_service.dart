import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/gen/libcore_bindings.dart';
import 'package:path_provider/path_provider.dart';

class CoreService {
  static const _channel = MethodChannel('com.hiddify.app/method');

  CoreService() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _initializeDesktop();
    }
  }

  void _initializeDesktop() {
    try {
      // eager load to verify symbols
      LibCore(_loadLibrary());
    } catch (e) {
      Logger.core.error('Failed to initialize LibCore: $e');
      rethrow;
    }
  }

  static DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('libcore.dll');
    if (Platform.isLinux) return DynamicLibrary.open('libcore.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libcore.dylib');
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  Future<String?> start(dynamic config) async {
    String jsonStr;
    if (config is String) {
      jsonStr = config;
    } else {
      jsonStr = jsonEncode(config);
    }

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/config.json');
        await file.writeAsString(jsonStr);

        await _channel.invokeMethod('start', {
          'path': file.path,
          'name': 'Hiddify',
        });
        return null;
      } on PlatformException catch (e) {
        return e.message;
      }
    } else {
      return Isolate.run(() {
        final lib = LibCore(_loadLibrary());
        final jsonPtr = jsonStr.toNativeUtf8();
        final resultPtr = lib.Start(jsonPtr.cast());
        calloc.free(jsonPtr);

        if (resultPtr != nullptr) {
          final error = resultPtr.cast<Utf8>().toDartString();
          lib.FreeCString(resultPtr);
          return error;
        }
        return null;
      });
    }
  }

  Future<void> stop() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _channel.invokeMethod('stop');
    } else {
      await Isolate.run(() {
        final lib = LibCore(_loadLibrary());
        lib.Stop();
      });
    }
  }
}
