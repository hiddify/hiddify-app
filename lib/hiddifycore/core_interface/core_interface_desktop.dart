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
import 'package:hiddify/hiddifycore/core_interface/core_process.dart';
import 'package:hiddify/hiddifycore/core_interface/grpc_client_identity.dart';
import 'package:hiddify/hiddifycore/core_interface/mtls_channel_cred.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello_service.pbgrpc.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:meta/meta.dart';

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

  // The core's process (see [CoreProcess]), when this build has its launcher. Without one the core
  // is the library loaded into this process (the FFI path below).
  static CoreProcess? _process;
  static Future<CoreProcess> Function()? _startProcess;
  static final List<DateTime> _restarts = [];
  // A core that keeps crashing is not started again more often than this.
  static const _maxRestarts = 3;
  static const _restartWindow = Duration(minutes: 1);

  /// Windows and Linux: the app's own work (profiles, settings, the VPN service, the system proxy)
  /// runs in the library loaded into this process, and only a proxy-mode connection runs in the
  /// core's process (see [startEngine]), as a VPN runs in the VPN service. Without it (macOS) the
  /// core's process is the app's core, kept out of this process for App Nap.
  @protected
  bool get libraryForFrontend => false;

  // The proxy engine's process (Windows, Linux), started for a proxy-mode connection only.
  static CoreProcess? _engine;
  static ClientChannel? _engineChannel;
  static CoreClient? _engineClient;
  static Future<CoreProcess> Function()? _startEngineProcess;
  static GrpcClientIdentity? _engineIdentity;

  /// The port the engine's process listens on, beside the library's.
  int get enginePort => port + 1;

  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    final executable = CoreProcess.executablePath();
    if (executable == null) return _setupLibrary(directories, debug, mode);
    if (!libraryForFrontend) return _setupProcess(executable, directories, debug, mode);
    final error = await _prepareEngine(executable, directories, debug, mode);
    if (error.isNotEmpty) return error;
    return _setupLibrary(directories, debug, mode);
  }

  /// Makes ready what [startEngine] needs: the engine trusts the client certificate it finds in
  /// the base folder when it starts, as the core's process does.
  Future<String> _prepareEngine(String executable, Directories directories, bool debug, int mode) async {
    final useMtls = _isMtlsMode(mode);
    try {
      _engineIdentity = useMtls
          ? await GrpcClientIdentity.loadOrCreate(Directory(p.join(directories.baseDir.path, 'grpc')))
          : null;
    } catch (e, st) {
      loggy.error('mTLS identity failed', e, st);
      return 'mTLS setup failed: $e';
    }
    _startEngineProcess = () => _startProcessRetrying(
      executable: executable,
      baseDir: directories.baseDir.path,
      workingDir: directories.workingDir.path,
      tempDir: directories.tempDir.path,
      listen: '127.0.0.1:$enginePort',
      mode: useMtls ? SetupMode.GRPC_NORMAL.value : SetupMode.GRPC_NORMAL_INSECURE.value,
      secret: secret,
      debug: debug,
    );
    return '';
  }

  /// The engine's client while its process runs, else null.
  CoreClient? get engineClient => _engine == null ? null : _engineClient;

  /// Starts the proxy engine's process, or returns the one that runs. Null without a launcher (or
  /// without [libraryForFrontend]): the core this app set up runs the engine then.
  Future<CoreClient?> startEngine() async {
    final running = engineClient;
    if (running != null) return running;
    final start = _startEngineProcess;
    if (start == null) return null;
    final process = await start();
    final identity = _engineIdentity;
    final channel = ClientChannel(
      '127.0.0.1',
      port: enginePort,
      options: ChannelOptions(
        credentials: identity == null ? const ChannelCredentials.insecure() : _processCredentials(process, identity),
      ),
    );
    _engine = process;
    _engineChannel = channel;
    _engineClient = CoreClient(channel);
    unawaited(
      process.exitCode.then((code) async {
        if (!identical(_engine, process) || process.stopping) return;
        final reason = await process.crashReason();
        _forgetEngine();
        loggy.error('engine process exited unexpectedly ($code)${reason == null ? '' : ': $reason'}');
        onCoreProcessExited(
          reason == null
              ? 'The core stopped unexpectedly (exit code $code).'
              : 'The core stopped unexpectedly (exit code $code): $reason',
        );
      }),
    );
    return _engineClient;
  }

  /// Stops the engine's process, which restores the system proxy it set as it exits.
  Future<void> stopEngine() async {
    final process = _engine;
    final channel = _engineChannel;
    _forgetEngine();
    if (channel != null) unawaited(channel.shutdown().catchError((Object _) {}));
    await process?.stop();
  }

  void _forgetEngine() {
    _engine = null;
    _engineChannel = null;
    _engineClient = null;
  }

  Future<String> _setupProcess(String executable, Directories directories, bool debug, int mode) async {
    final useMtls = _isMtlsMode(mode);
    final setupMode = useMtls ? SetupMode.GRPC_NORMAL.value : SetupMode.GRPC_NORMAL_INSECURE.value;
    // The core trusts the client certificate it finds in the base folder when it is set up, as on
    // Android and iOS, so it must be there before the core starts.
    GrpcClientIdentity? identity;
    try {
      if (useMtls) {
        identity = await GrpcClientIdentity.loadOrCreate(Directory(p.join(directories.baseDir.path, 'grpc')));
      }
    } catch (e, st) {
      loggy.error('mTLS identity failed', e, st);
      return 'mTLS setup failed: $e';
    }

    _startProcess = () => _startProcessRetrying(
      executable: executable,
      baseDir: directories.baseDir.path,
      workingDir: directories.workingDir.path,
      tempDir: directories.tempDir.path,
      listen: '127.0.0.1:$port',
      mode: setupMode,
      secret: secret,
      debug: debug,
    );
    var process = _process;
    if (process == null) {
      try {
        process = await _startProcess!();
      } catch (e) {
        loggy.error('core process failed to start', e);
        return 'The core failed to start: $e';
      }
      _adoptProcess(process);
    }

    try {
      _credentials = identity == null ? const ChannelCredentials.insecure() : _processCredentials(process, identity);
    } catch (e, st) {
      loggy.error('mTLS credentials failed', e, st);
      return 'mTLS setup failed: $e';
    }
    return _connect();
  }

  /// Starts the core, waiting a little when its port is still taken: a core that was just asked to
  /// stop (the previous run of a hot restart) can still hold it.
  static Future<CoreProcess> _startProcessRetrying({
    required String executable,
    required String baseDir,
    required String workingDir,
    required String tempDir,
    required String listen,
    required int mode,
    required String secret,
    required bool debug,
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await CoreProcess.start(
          executable: executable,
          baseDir: baseDir,
          workingDir: workingDir,
          tempDir: tempDir,
          listen: listen,
          mode: mode,
          secret: secret,
          debug: debug,
        );
      } on CoreProcessException catch (e) {
        if (attempt >= 5 || !e.message.contains('already in use')) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  ChannelCredentials _processCredentials(CoreProcess process, GrpcClientIdentity identity) {
    final serverPem = process.serverCertificatePem;
    if (!serverPem.contains('BEGIN CERTIFICATE')) throw StateError('empty gRPC server certificate');
    return MTLSChannelCredentials.fromPem(
      serverCertificatePem: Uint8List.fromList(utf8.encode(serverPem)),
      clientCertificatePem: identity.certificatePem,
      clientPrivateKeyPem: identity.privateKeyPem,
    );
  }

  void _adoptProcess(CoreProcess process) {
    _process = process;
    unawaited(
      process.exitCode.then((code) async {
        if (!identical(_process, process) || process.stopping) return;
        _process = null;
        // before the restart, which moves the crash output into the crash reports
        final reason = await process.crashReason();
        loggy.error('core process exited unexpectedly ($code)${reason == null ? '' : ': $reason'}');
        onCoreProcessExited(
          reason == null
              ? 'The core stopped unexpectedly (exit code $code).'
              : 'The core stopped unexpectedly (exit code $code): $reason',
        );
        unawaited(_restartProcess(process));
      }),
    );
  }

  /// Starts the core again after a crash. It listens on the same port with the same certificate (the
  /// core keeps its key), so the open channel reconnects to it on its own.
  Future<void> _restartProcess(CoreProcess crashed) async {
    final start = _startProcess;
    if (start == null) return;
    final now = DateTime.now();
    _restarts.removeWhere((time) => now.difference(time) > _restartWindow);
    if (_restarts.length >= _maxRestarts) {
      loggy.error('the core keeps crashing; not starting it again');
      return;
    }
    _restarts.add(now);
    await Future<void>.delayed(const Duration(seconds: 1));
    try {
      final process = await start();
      _adoptProcess(process);
      if (process.serverCertificatePem != crashed.serverCertificatePem) {
        loggy.warning('the restarted core has another certificate; it is reached after the next setup');
      }
      loggy.info('core process restarted');
      onCoreProcessRestarted();
    } catch (e) {
      loggy.error('core process failed to restart', e);
    }
  }

  /// Called when the core's process ends without being asked to. The app's core is started again;
  /// the proxy engine is not, its connection has ended.
  @protected
  void onCoreProcessExited(String message) {}

  /// Called once the core's process runs again after a crash: listeners on the old one have ended.
  @protected
  void onCoreProcessRestarted() {}

  @override
  Future<void> shutdown() async {
    final process = _process;
    _process = null;
    _startProcess = null;
    _startEngineProcess = null;
    await Future.wait([stopEngine(), if (process != null) process.stop()]);
  }

  Future<String> _setupLibrary(Directories directories, bool debug, int mode) async {
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
    return _connect();
  }

  /// Checks that the core answers, then replaces the channel and the clients.
  Future<String> _connect() async {
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
    // setup runs again whenever the app comes back to the front: a connection that runs in the VPN
    // service keeps its client there, or every stream of it (proxies, pings, status) would ask this
    // app's own core, which runs nothing in VPN mode ("hiddify service not found")
    final backgroundWasForeground = !isInitialized() || identical(bgClient, fgClient);
    fgClient = CoreClient(_channel!);
    if (backgroundWasForeground) bgClient = fgClient;
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
