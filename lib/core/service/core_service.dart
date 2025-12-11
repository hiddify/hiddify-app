import 'dart:convert';
import 'dart:ffi'; // For FFI
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

typedef StartFunc = Pointer<Utf8> Function(Pointer<Utf8> configJson);
typedef Start = Pointer<Utf8> Function(Pointer<Utf8> configJson);

typedef StopFunc = Void Function();
typedef Stop = void Function();

class CoreService {
  late DynamicLibrary _lib;
  late Start _start;
  late Stop _stop;

  static const _channel = MethodChannel('com.hiddify.app/method');

  CoreService() {
    if (!Platform.isAndroid && !Platform.isIOS) {
       _lib = _loadLibrary();
       try {
         _start = _lib.lookup<NativeFunction<StartFunc>>('Start').asFunction();
         _stop = _lib.lookup<NativeFunction<StopFunc>>('Stop').asFunction();
       } catch (e) {
         // ignore: avoid_print
         print('Failed to lookup symbols: $e');
         rethrow;
       }
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('libcore.dll');
    if (Platform.isLinux) return DynamicLibrary.open('libcore.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libcore.dylib');
    // Android/iOS libraries are loaded by the OS/Native wrapper
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
      // Desktop FFI
      final jsonPtr = jsonStr.toNativeUtf8();
      final resultPtr = _start(jsonPtr);
      malloc.free(jsonPtr);

      if (resultPtr != nullptr) {
        final error = resultPtr.toDartString();
        return error;
      }
      return null;
    }
  }

  Future<void> stop() async {
    if (Platform.isAndroid || Platform.isIOS) {
       await _channel.invokeMethod('stop');
    } else {
       _stop();
    }
  }
}
