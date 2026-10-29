import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/utils/laststeam.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/grpc_client_identity.dart';
import 'package:hiddify/hiddifycore/core_interface/mtls_channel_cred.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';

import 'package:hiddify/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

class CoreInterfaceMobile extends CoreInterface with InfraLogger {
  static const channelPrefix = "com.hiddify.app";
  static const methodChannel = MethodChannel("$channelPrefix/method");
  static const statusChannel = EventChannel("$channelPrefix/service.status", JSONMethodCodec());
  static const alertsChannel = EventChannel("$channelPrefix/service.alerts", JSONMethodCodec());

  /// Made once and kept in the app's private folder, then reused by every launch and by the
  /// platform service (see GrpcClientIdentity).
  late GrpcClientIdentity _identity;

  static const portBack = 17079;
  static const portFront = 17078;

  bool _isBgClientAvailable = false;
  bool _debug = false;
  bool _useMtls = false;
  ChannelCredentials _credentials = const ChannelCredentials.insecure();

  late LastStream<CoreStatus> _status;
  StreamSubscription<CoreStatus>? _nativeStatusSubscription;
  final _managedStatus = BehaviorSubject<CoreStatus>.seeded(const CoreStatus.stopped());
  ClientChannel? _fgChannel;
  ClientChannel? _bgChannel;

  bool _isMtlsMode(int mode) => mode == 1 || mode == 2;

  @override
  // Platform VPN/service status is the source of truth on mobile (survives app relaunch).
  Stream<CoreStatus>? get managedStatus => _managedStatus.stream;

  @override
  Future<void> dispose() async {
    await _nativeStatusSubscription?.cancel();
    _nativeStatusSubscription = null;
  }

  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    _debug = debug;
    _useMtls = _isMtlsMode(mode);
    // The identity is kept in the private base folder only while the core runs with mTLS: the
    // core and the platform service take its presence as the switch, and trust it by reading the
    // file, so nothing is passed over the method channel.
    final identityDirectory = Directory('${directories.baseDir.path}/grpc');
    if (_useMtls) {
      _identity = await GrpcClientIdentity.loadOrCreate(identityDirectory);
    } else if (await identityDirectory.exists()) {
      await identityDirectory.delete(recursive: true);
    }

    // Created once. setup runs again on every resume, including the one right after the VPN
    // dialog closes; a replaced stream would leave a start that is waiting on it deaf.
    if (_nativeStatusSubscription == null) {
      final status = statusChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);
      final alerts = alertsChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);
      final merged = ValueConnectableStream(Rx.merge([status, alerts])).autoConnect();
      _status = LastStream(merged);
      _nativeStatusSubscription = merged.listen(_managedStatus.add);
    }

    // Start the core first — the server certificate only exists after setup.
    if (!await isPortOpen('127.0.0.1', portFront)) {
      final setupResult = await methodChannel.invokeMethod<dynamic>('setup', {
        'baseDir': directories.baseDir.path,
        'workingDir': directories.workingDir.path,
        'tempDir': directories.tempDir.path,
        'grpcPort': portFront,
        'mode': mode,
        'debug': debug,
      });
      _applyNativeStatusPayload(setupResult);
      if (!await waitUntilPort(portFront, true, null)) {
        return 'failed to start foreground gRPC';
      }
    } else if (Platform.isIOS) {
      // Fg core already up (e.g. resume); still reload NE status so a live tunnel is mirrored.
      final syncResult = await methodChannel.invokeMethod<dynamic>('setup_vpn');
      _applyNativeStatusPayload(syncResult);
    }

    try {
      _credentials = await _buildCredentials();
    } catch (e, st) {
      loggy.error('mTLS credentials failed', e, st);
      return 'mTLS setup failed: $e';
    }

    // Probe that the channel works before replacing clients.
    final helloChannel = ClientChannel(
      '127.0.0.1',
      port: portFront,
      options: ChannelOptions(credentials: _credentials),
    );
    try {
      final helloClient = HelloClient(helloChannel);
      final res = await helloClient.sayHello(HelloRequest(name: 'test'));
      loggy.info(res.toString());
    } catch (e, st) {
      loggy.error('gRPC hello failed', e, st);
      await helloChannel.shutdown();
      return 'gRPC hello failed: $e';
    } finally {
      unawaited(helloChannel.shutdown());
    }

    // setup runs again every time the app is resumed. The channels it replaces
    // used to stay open until their idle timeout, so each resume left one more
    // connection to the VPN extension, which has a tight memory cap on iOS.
    final previousChannels = [_fgChannel, _bgChannel];
    _fgChannel = ClientChannel(
      '127.0.0.1',
      port: portFront,
      options: ChannelOptions(credentials: _credentials),
    );
    _bgChannel = ClientChannel(
      '127.0.0.1',
      port: portBack,
      options: ChannelOptions(credentials: _credentials),
    );
    fgClient = CoreClient(_fgChannel!);
    bgClient = CoreClient(_bgChannel!);
    for (final channel in previousChannels) {
      unawaited(channel?.shutdown());
    }

    // Tunnel can outlive the Flutter process; treat a live bg port as available.
    if (await isPortOpen('127.0.0.1', portBack)) {
      _isBgClientAvailable = true;
    }
    return '';
  }

  void _applyNativeStatusPayload(dynamic payload) {
    if (payload is! Map) return;
    try {
      _managedStatus.add(CoreStatus.fromEvent(Map<String, dynamic>.from(payload)));
    } catch (e) {
      loggy.warning('native status payload: $e');
    }
  }

  Future<ChannelCredentials> _buildCredentials() async {
    if (!_useMtls) {
      return const ChannelCredentials.insecure();
    }

    final serverCert = await methodChannel.invokeMethod<Uint8List>('get_grpc_server_public_key');
    if (serverCert == null || serverCert.isEmpty) {
      throw StateError('empty gRPC server certificate');
    }

    final mtls = MTLSChannelCredentials.fromPem(
      serverCertificatePem: serverCert,
      clientCertificatePem: _identity.certificatePem,
      clientPrivateKeyPem: _identity.privateKeyPem,
    );
    // nothing is passed to the platform: the core and the platform service read the same identity
    // from the private storage
    return mtls;
  }

  @override
  Future<CoreStatus> setupBackground(String path, String name) async {
    // Stop any previous VPN gRPC server. A stuck port is logged but start is
    // still attempted — Android waits out Stopping before Mobile.setup.
    if (!await stop()) {
      loggy.warning('previous background core still closing; starting anyway');
    }
    _status.clean();
    await methodChannel.invokeMethod('start', {
      'path': path,
      'name': name,
      'grpcPort': portBack,
      'startBg': true,
      'debug': _debug,
    });

    _isBgClientAvailable = true;
    loggy.info('Waiting for starting core');
    final waitingSince = DateTime.now();
    // The reply to "start" only means the service was asked to start; whether it did arrives
    // later on the status stream. Wait for the first status that settles it: up, or stopped
    // with a reason. On timeout the port check below decides.
    try {
      final res = await _status.get(
        timeout: const Duration(seconds: 20),
        where: (status) => switch (status) {
          // the platform service is up: the core's own status takes over from here
          CoreStarted() || CoreWaiting() || CoreNoAvailableProxies() || CoreHotReloading() => true,
          CoreStopped(:final alert) => alert != null,
          _ => false,
        },
      );
      if (res is CoreStopped) return res;
    } on TimeoutException {
      loggy.warning('no start status from the service in 20 s');
    }
    loggy.info('Waiting for starting core finished after ${DateTime.now().difference(waitingSince).inMilliseconds}ms');

    if (!await waitUntilPort(portBack, true, null)) {
      await stopMethodChannel();
      return const CoreStatus.stopped(alert: CoreAlert.startService, message: 'starting background core...');
    }

    return const CoreStarted();
  }

  @override
  Future<bool> stop() async {
    // Always ask the platform to stop: on iOS the tunnel can be up while the
    // extension gRPC port is unreachable (new app process / mTLS key), and
    // skipping disconnect left the VPN stuck in Settings.
    // MethodChannel stop already waits until the VPN service reports Stopped
    // (after Mobile.close), so only briefly poll the gRPC port.
    await stopMethodChannel();
    if (!await isPortOpen('127.0.0.1', portBack)) {
      _isBgClientAvailable = false;
      return true;
    }
    if (!await waitUntilPort(portBack, false, null)) {
      loggy.warning('background port $portBack still open after stop');
      // Platform stop finished; do not leave Disconnecting forever (#2395).
      _isBgClientAvailable = false;
      return true;
    }

    _isBgClientAvailable = false;
    return true;
  }

  Future stopMethodChannel() async {
    await methodChannel.invokeMethod('stop');
  }

  @override
  Future<bool> isBgClientAvailable() async {
    return _isBgClientAvailable;
  }

  @override
  Future<bool> resetTunnel() async {
    await methodChannel.invokeMethod('reset');
    return true;
  }

  @override
  Future<bool> isActiveFg() async {
    return await isPortOpen('127.0.0.1', portFront);
  }

  @override
  Future<bool> isActiveBg() async {
    return await isPortOpen('127.0.0.1', portBack);
  }
}

Future<bool> waitUntilPort(
  int portNumber,
  bool isOpen,
  Future Function()? callFunctionAfterEachFail, {
  int maxTry = 10,
}) async {
  for (var i = 0; i < maxTry; i++) {
    if (await isPortOpen('127.0.0.1', portNumber) == isOpen) {
      return true;
    }
    if (callFunctionAfterEachFail != null) {
      await callFunctionAfterEachFail();
    }

    await Future.delayed(const Duration(milliseconds: 200));
  }
  return false;
}

Future<bool> isPortOpen(String host, int port, {Duration timeout = const Duration(milliseconds: 300)}) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    await socket.close();
    return true;
  } on SocketException catch (_) {
    return false;
  } catch (_) {
    return false;
  }
}
