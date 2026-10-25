import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:ffi/ffi.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/gen/hiddify_core_generated_bindings.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/mtls_channel_cred.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello_service.pbgrpc.dart';
import 'package:hiddify/utils/custom_loggers.dart';

import 'package:path/path.dart' as p;

final _logger = infraLogger('HiddifyCoreFFI');
typedef StopFunc = Pointer<Utf8> Function();
typedef StopFuncDart = Pointer<Utf8> Function();

class CoreInterfaceDesktop extends CoreInterface with InfraLogger {
  CoreInterfaceDesktop({this.port = 17078});
  static final HiddifyCoreNativeLibrary _box = _gen();

  // Exposed for macOS/desktop mTLS smoke tests.
  static HiddifyCoreNativeLibrary get nativeLibrary => _box;

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

    _logger.debug('hiddify-core native libs path: "$fullPath"');
    final lib = DynamicLibrary.open(fullPath);
    return HiddifyCoreNativeLibrary(lib);
  }

  Future<bool> isMusl() async {
    try {
      final result = await Process.run('ldd', ['--version']);
      return result.stdout.toString().toLowerCase().contains('musl');
    } catch (_) {
      return false;
    }
  }

  final int port;
  static String generateRandomPassword(int length) {
    const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (_) => characters[random.nextInt(characters.length)]).join();
  }

  static final String secret = generateRandomPassword(100);
  static final _clientKey = CryptoUtils.generateRSAKeyPair();

  // Whether this process started its core. Another Hiddify instance can answer on the same port, and
  // using its core leaves every call refused once that instance quits.
  static bool _coreStarted = false;

  ClientChannel? _channel;
  ChannelCredentials _credentials = const ChannelCredentials.insecure();

  bool _isMtlsMode(int mode) => mode == 1 || mode == 2;

  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    final useMtls = _isMtlsMode(mode);
    final setupMode = useMtls ? SetupMode.GRPC_NORMAL.value : SetupMode.GRPC_NORMAL_INSECURE.value;

    try {
      if (!_coreStarted) throw StateError('core is not started yet');
      // Probe with current credentials once we have a channel path below.
    } catch (_) {
      final errPtr = _box.setup(
        directories.baseDir.path.toNativeUtf8().cast(),
        directories.workingDir.path.toNativeUtf8().cast(),
        directories.tempDir.path.toNativeUtf8().cast(),
        setupMode,
        '127.0.0.1:$port'.toNativeUtf8().cast(),
        secret.toNativeUtf8().cast(),
        0,
        debug ? 1 : 0,
      );
      final err = errPtr.cast<Utf8>().toDartString();
      if (err.isNotEmpty) {
        return err;
      }
      _coreStarted = true;
    }

    try {
      _credentials = useMtls ? _buildMtlsCredentials() : const ChannelCredentials.insecure();
    } catch (e, st) {
      loggy.error('mTLS credentials failed', e, st);
      return 'mTLS setup failed: $e';
    }

    final helloChannel = ClientChannel(
      '127.0.0.1',
      port: port,
      options: ChannelOptions(credentials: _credentials),
    );
    try {
      final res = await HelloClient(helloChannel).sayHello(HelloRequest(name: 'test'));
      loggy.info(res.toString());
    } catch (e, st) {
      loggy.error('gRPC hello failed', e, st);
      await helloChannel.shutdown();
      return 'gRPC hello failed: $e';
    } finally {
      unawaited(helloChannel.shutdown());
    }

    final previousChannel = _channel;
    _channel = ClientChannel(
      '127.0.0.1',
      port: port,
      options: ChannelOptions(credentials: _credentials),
    );
    bgClient = fgClient = CoreClient(_channel!);
    unawaited(previousChannel?.shutdown());

    return '';
  }

  ChannelCredentials _buildMtlsCredentials() {
    final serverPtr = _box.GetServerPublicKey();
    final serverPem = serverPtr.cast<Utf8>().toDartString();
    _box.freeString(serverPtr);
    if (serverPem.isEmpty || !serverPem.contains('BEGIN CERTIFICATE')) {
      throw StateError('empty gRPC server certificate');
    }

    final mtls = MTLSChannelCredentials(
      serverCertificatePem: Uint8List.fromList(utf8.encode(serverPem)),
      clientKey: _clientKey,
    );

    final clientPtr = mtls.clientCertificatePem.toNativeUtf8();
    try {
      final errPtr = _box.AddGrpcClientPublicKey(clientPtr.cast());
      final err = errPtr.cast<Utf8>().toDartString();
      _box.freeString(errPtr);
      if (err.isNotEmpty) {
        throw StateError('AddGrpcClientPublicKey: $err');
      }
    } finally {
      malloc.free(clientPtr);
    }
    return mtls;
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
