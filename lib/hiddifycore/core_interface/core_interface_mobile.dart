import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/utils/laststeam.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
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

  // RSA matches the Go server crypto stack and avoids EC PKCS#8 quirks on iOS.
  static final _clientKey = CryptoUtils.generateRSAKeyPair();

  static const portBack = 17079;
  static const portFront = 17078;

  bool _isBgClientAvailable = false;
  bool _debug = false;
  bool _useMtls = false;
  ChannelCredentials _credentials = const ChannelCredentials.insecure();
  MTLSChannelCredentials? _mtls;

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
  Future<String> setup(Directories directories, bool debug, int mode) async {
    _debug = debug;
    _useMtls = _isMtlsMode(mode);

    final status = statusChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);
    final alerts = alertsChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);
    final merged = ValueConnectableStream(Rx.merge([status, alerts])).autoConnect();
    _status = LastStream(merged);
    await _nativeStatusSubscription?.cancel();
    _nativeStatusSubscription = merged.listen(_managedStatus.add);

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
      await _registerClientCertWithExtension();
    }
    return '';
  }

  /// Best-effort: trust this session's client cert in a tunnel that was started earlier.
  Future<void> _registerClientCertWithExtension() async {
    if (_mtls == null) return;
    try {
      await methodChannel.invokeMethod('add_grpc_client_public_key', {
        'clientPublicKey': Uint8List.fromList(utf8.encode(_mtls!.clientCertificatePem)),
        'toExtension': true,
      });
    } catch (e) {
      loggy.warning('extension mTLS client cert registration: $e');
    }
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
      _mtls = null;
      return const ChannelCredentials.insecure();
    }

    final serverCert = await methodChannel.invokeMethod<Uint8List>('get_grpc_server_public_key');
    if (serverCert == null || serverCert.isEmpty) {
      throw StateError('empty gRPC server certificate');
    }

    final mtls = MTLSChannelCredentials(
      serverCertificatePem: serverCert,
      clientKey: _clientKey,
    );
    await methodChannel.invokeMethod('add_grpc_client_public_key', {
      'clientPublicKey': Uint8List.fromList(utf8.encode(mtls.clientCertificatePem)),
    });
    _mtls = mtls;
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
      if (_mtls != null) 'clientPublicKey': Uint8List.fromList(utf8.encode(_mtls!.clientCertificatePem)),
    });

    _isBgClientAvailable = true;
    loggy.info('Waiting for starting core');
    for (var i = 0; i < 20; i++) {
      try {
        final res = await _status.get(timeout: const Duration(seconds: 1));

        switch (res) {
          case CoreStarted() || CoreHotReloading():
            break;
          case CoreStopped():
            if (res.alert != null) {
              return res;
            }

          case CoreStopping():
          case CoreStarting():
        }
        await Future.delayed(const Duration(milliseconds: 200));
      } on TimeoutException {
        // just retry
      }
    }
    loggy.info('Waiting for starting core finished');

    if (!await waitUntilPort(portBack, true, null)) {
      await stopMethodChannel();
      return const CoreStatus.stopped(alert: CoreAlert.startService, message: 'starting background core...');
    }

    // Re-register the client cert with the extension (separate address space).
    await _registerClientCertWithExtension();
    return const CoreStarted();
  }

  @override
  Future<bool> stop() async {
    // Always ask the platform to stop: on iOS the tunnel can be up while the
    // extension gRPC port is unreachable (new app process / mTLS key), and
    // skipping disconnect left the VPN stuck in Settings.
    await stopMethodChannel();
    if (!await isPortOpen('127.0.0.1', portBack)) {
      _isBgClientAvailable = false;
      return true;
    }
    // Port should drop once Mobile.close uses the same setup mode as start
    // (mTLS background is mode 2; insecure is 4).
    if (!await waitUntilPort(portBack, false, null, maxTry: 50)) {
      loggy.warning('background port $portBack still open after stop');
      return false;
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
