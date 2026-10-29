import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/gen/hiddify_core_generated_bindings.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/grpc_client_identity.dart';
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

  /// Resolved before the core is set up: the setup changes the working directory of the process,
  /// and a relative path would no longer find the library after that.
  static final String _path = Platform.environment.containsKey('FLUTTER_TEST')
      ? File(_libraryPath()).absolute.path
      : _libraryPath();

  static HiddifyCoreNativeLibrary _gen() {
    _logger.debug('hiddify-core native libs path: "$_path"');
    return _open(_path);
  }

  static String _libraryPath() {
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

    return fullPath;
  }

  /// Opens the library; the same loaded library answers in every isolate.
  static HiddifyCoreNativeLibrary _open(String path) => HiddifyCoreNativeLibrary(DynamicLibrary.open(path));

  /// The Go setup blocks until the core has loaded its data and started its server, so it runs in
  /// an isolate of its own: the UI isolate must not wait for it.
  static Future<String> _setupNative(
    String libraryPath,
    String baseDir,
    String workingDir,
    String tempDir,
    int mode,
    String listen,
    String secret,
    bool debug,
  ) {
    return Isolate.run(() {
      final errPtr = _open(libraryPath).setup(
        baseDir.toNativeUtf8().cast(),
        workingDir.toNativeUtf8().cast(),
        tempDir.toNativeUtf8().cast(),
        mode,
        listen.toNativeUtf8().cast(),
        secret.toNativeUtf8().cast(),
        0,
        debug ? 1 : 0,
      );
      return errPtr.cast<Utf8>().toDartString();
    });
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
  // Made once per launch, in an isolate: RSA key generation is too slow for the UI isolate.
  static GrpcClientIdentity? _clientIdentity;

  // Whether this process started its core. Another Hiddify instance can answer on the same port, and
  // using its core leaves every call refused once that instance quits.
  static bool _coreStarted = false;

  ClientChannel? _channel;
  ChannelCredentials _credentials = const ChannelCredentials.insecure();

  bool _isMtlsMode(int mode) => mode == 1 || mode == 2;

  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    final useMtls = _isMtlsMode(mode);
    // load the library here first: the setup below changes the working directory of the process
    _logger.debug('hiddify-core loaded (${_box.hashCode})');
    final setupMode = useMtls ? SetupMode.GRPC_NORMAL.value : SetupMode.GRPC_NORMAL_INSECURE.value;

    try {
      if (!_coreStarted) throw StateError('core is not started yet');
      // Probe with current credentials once we have a channel path below.
    } catch (_) {
      final err = await _setupNative(
        _path,
        directories.baseDir.path,
        directories.workingDir.path,
        directories.tempDir.path,
        setupMode,
        '127.0.0.1:$port',
        secret,
        debug,
      );
      if (err.isNotEmpty) {
        return err;
      }
      _coreStarted = true;
    }

    try {
      if (useMtls) _clientIdentity ??= await Isolate.run(GrpcClientIdentity.generate);
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

    final identity = _clientIdentity!;
    final mtls = MTLSChannelCredentials.fromPem(
      serverCertificatePem: Uint8List.fromList(utf8.encode(serverPem)),
      clientCertificatePem: identity.certificatePem,
      clientPrivateKeyPem: identity.privateKeyPem,
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
