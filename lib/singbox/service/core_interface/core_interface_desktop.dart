import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/gen/hiddify_core_generated_bindings.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/service/core_interface/core_interface.dart';
import 'package:loggy/loggy.dart';
import 'package:path/path.dart' as p;

final _logger = Loggy('FFISingboxService');

class CoreInterfaceDesktop extends CoreInterface {
  static final HiddifyCoreNativeLibrary _box = _gen();
  static HiddifyCoreNativeLibrary _gen() {
    String fullPath = "";
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      fullPath = "hiddify-core";
    }
    if (Platform.isWindows) {
      fullPath = p.join(fullPath, "hiddify-core.dll");
    } else if (Platform.isMacOS) {
      fullPath = p.join(fullPath, "hiddify-core.dylib");
    } else {
      fullPath = p.join(fullPath, "hiddify-core.so");
    }

    _logger.debug('singbox native libs path: "$fullPath"');
    final lib = DynamicLibrary.open(fullPath);
    return HiddifyCoreNativeLibrary(lib);
  }

  final port = 17078;
  static String generateRandomPassword(int length) {
    const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (_) => characters[random.nextInt(characters.length)]).join();
  }

  static final String secret = generateRandomPassword(100);

  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    // Generate a random password for the grpc service
    final errPtr2 = _box.stop();
    // final err = errPtr.cast<Utf8>().toDartString();

    final errPtr = _box.setup(
      directories.baseDir.path.toNativeUtf8().cast(),
      directories.workingDir.path.toNativeUtf8().cast(),
      directories.tempDir.path.toNativeUtf8().cast(),
      3,
      "127.0.0.1:$port".toNativeUtf8().cast(),
      secret.toNativeUtf8().cast(),
      0,
      debug ? 1 : 0,
    );
    final err = errPtr.cast<Utf8>().toDartString();

    if (err.isNotEmpty) {
      return err;
    }

    bgClient = fgClient = CoreClient(
      ClientChannel(
        'localhost',
        port: port,
        options: ChannelOptions(
          credentials: ChannelCredentials.secure(
            password: secret,
            onBadCertificate: (certificate, host) => true,
          ),
        ),
      ),
    );

    return "";
  }

  @override
  Future<bool> start(String path, String name) async {
    return false;
  }

  @override
  Future<bool> restart(String path, String name) async {
    return false;
  }

  @override
  Future<bool> stop() async {
    return false;
  }
}
