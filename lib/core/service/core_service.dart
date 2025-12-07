import 'dart:ffi';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'dart:io';

typedef StartFunc = Pointer<Utf8> Function(Pointer<Utf8> configJson);
typedef Start = Pointer<Utf8> Function(Pointer<Utf8> configJson);

typedef StopFunc = Void Function();
typedef Stop = void Function();

class CoreService {
  late DynamicLibrary _lib;
  late Start _start;
  late Stop _stop;

  VWarpService() {
    _lib = _loadLibrary();
    try {
      _start = _lib.lookup<NativeFunction<StartFunc>>('Start').asFunction();
      _stop = _lib.lookup<NativeFunction<StopFunc>>('Stop').asFunction();
    } catch (e) {
      print('Failed to lookup symbols: $e');
      rethrow;
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('libcore.dll');
    if (Platform.isLinux) return DynamicLibrary.open('libcore.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libcore.dylib');
    if (Platform.isAndroid) return DynamicLibrary.open('libcore.so');
    if (Platform.isIOS) return DynamicLibrary.process(); // Usually invalid for dylib but if static linked
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  String? start(Map<String, dynamic> config) {
    final jsonStr = jsonEncode(config);
    final jsonPtr = jsonStr.toNativeUtf8();
    final resultPtr = _start(jsonPtr);
    malloc.free(jsonPtr);

    if (resultPtr != nullptr) {
      final error = resultPtr.toDartString();
      // TODO: Free resultPtr if possible using a Go exported Free, otherwise small leak on error.
      return error;
    }
    return null;
  }

  void stop() {
    _stop();
  }
}
