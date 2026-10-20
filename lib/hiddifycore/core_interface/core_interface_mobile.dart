import 'dart:async';
import 'dart:io';

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
import 'package:loggy/loggy.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Loggy('FFIHiddifyCoreService');

enum IosCoreSetupCode { helloTimedOut, nativeSetupTimedOut, nativeSetupFailed, vpnPreferencesFailed, helloFailed }

enum IosCoreSetupStage { unknown, firstHello, nativeSetup, secondHello }

class IosCoreSetupException implements Exception {
  const IosCoreSetupException(this.code, {this.stage = IosCoreSetupStage.unknown});

  final IosCoreSetupCode code;
  final IosCoreSetupStage stage;

  @override
  String toString() => 'IosCoreSetupException(${code.name},${stage.name})';
}

class CoreInterfaceMobile extends CoreInterface with InfraLogger {
  CoreInterfaceMobile({this.iosSetupDeadline = const Duration(seconds: 5)});

  final Duration iosSetupDeadline;
  Future<String>? _iosSetupInFlight;
  Future<void>? _pendingNativeSetup;

  static const channelPrefix = "com.hiddify.app";
  static const methodChannel = MethodChannel("$channelPrefix/method");
  static const statusChannel = EventChannel("$channelPrefix/service.status", JSONMethodCodec());
  static const alertsChannel = EventChannel("$channelPrefix/service.alerts", JSONMethodCodec());

  late Uint8List serverPublicKey;
  static final cert = CryptoUtils.generateEcKeyPair();

  static const portBack = 17079;
  static const portFront = 17078;

  bool _isBgClientAvailable = false;
  bool _debug = false;

  late final Stream<CoreStatus> _nativeStatus = statusChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);
  late final Stream<CoreStatus> _nativeAlerts = alertsChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);
  late final LastStream<CoreStatus> _status = LastStream(Rx.merge([_nativeStatus, _nativeAlerts]));

  @override
  bool get supportsSystemStatus => Platform.isIOS;

  @override
  Stream<CoreStatus> get systemStatusStream => _nativeStatus;

  @override
  Future<String> setup(Directories directories, bool debug, int mode) {
    if (!supportsSystemStatus) return _setupLegacy(directories, debug, mode);
    // One attempt owns client publication. A retry cannot race an older attempt.
    return _iosSetupInFlight ??= _setupIos(directories, debug, mode).whenComplete(() => _iosSetupInFlight = null);
  }

  Future<String> _setupIos(Directories directories, bool debug, int mode) async {
    final credentials = [1, 2].contains(mode)
        ? MTLSChannelCredentials(serverPublicKey: serverPublicKey, clientKey: cert)
        : const ChannelCredentials.insecure();
    final helloChannel = ClientChannel(
      '127.0.0.1',
      port: portFront,
      options: ChannelOptions(credentials: credentials),
    );
    final hello = HelloClient(helloChannel);
    var stage = IosCoreSetupStage.firstHello;
    _status.clean();
    try {
      // A timed-out native callback is still executing. Wait for that same
      // operation before probing readiness or issuing another native setup.
      if (_pendingNativeSetup case final pending?) {
        stage = IosCoreSetupStage.nativeSetup;
        await _waitForNativeSetup(pending);
        stage = IosCoreSetupStage.firstHello;
      }
      try {
        await hello.sayHello(
          HelloRequest(name: 'test'),
          options: CallOptions(timeout: iosSetupDeadline),
        );
      } on GrpcError catch (error) {
        if (error.code == StatusCode.deadlineExceeded) {
          throw IosCoreSetupException(IosCoreSetupCode.helloTimedOut, stage: stage);
        }
        if (error.code != StatusCode.unavailable) {
          throw IosCoreSetupException(IosCoreSetupCode.helloFailed, stage: stage);
        }
        stage = IosCoreSetupStage.nativeSetup;
        final pending = methodChannel.invokeMethod<void>('setup', {
          'baseDir': directories.baseDir.path,
          'workingDir': directories.workingDir.path,
          'tempDir': directories.tempDir.path,
          'grpcPort': portFront,
          'mode': mode,
          'debug': debug,
        });
        _pendingNativeSetup = pending;
        void clearPending() {
          if (identical(_pendingNativeSetup, pending)) _pendingNativeSetup = null;
        }

        unawaited(pending.then<void>((_) => clearPending(), onError: (Object _, StackTrace _) => clearPending()));
        await _waitForNativeSetup(pending);
        stage = IosCoreSetupStage.secondHello;
        await hello.sayHello(
          HelloRequest(name: 'test'),
          options: CallOptions(timeout: iosSetupDeadline),
        );
      }
      _debug = debug;
      fgClient = CoreClient(
        ClientChannel(
          '127.0.0.1',
          port: portFront,
          options: ChannelOptions(credentials: credentials),
        ),
      );
      bgClient = CoreClient(
        ClientChannel(
          '127.0.0.1',
          port: portBack,
          options: ChannelOptions(credentials: credentials),
        ),
      );
      return '';
    } on IosCoreSetupException {
      rethrow;
    } on GrpcError catch (error) {
      throw IosCoreSetupException(
        error.code == StatusCode.deadlineExceeded ? IosCoreSetupCode.helloTimedOut : IosCoreSetupCode.helloFailed,
        stage: stage,
      );
    } finally {
      await helloChannel.terminate();
    }
  }

  Future<void> _waitForNativeSetup(Future<void> pending) async {
    try {
      await pending.timeout(iosSetupDeadline);
    } on TimeoutException {
      throw const IosCoreSetupException(IosCoreSetupCode.nativeSetupTimedOut, stage: IosCoreSetupStage.nativeSetup);
    } on PlatformException catch (error) {
      throw IosCoreSetupException(
        error.code == 'SETUP' ? IosCoreSetupCode.vpnPreferencesFailed : IosCoreSetupCode.nativeSetupFailed,
        stage: IosCoreSetupStage.nativeSetup,
      );
    } catch (_) {
      throw const IosCoreSetupException(IosCoreSetupCode.nativeSetupFailed, stage: IosCoreSetupStage.nativeSetup);
    }
  }

  Future<String> _setupLegacy(Directories directories, bool debug, int mode) async {
    final channelOption = [1, 2].contains(mode)
        ? MTLSChannelCredentials(serverPublicKey: serverPublicKey, clientKey: cert)
        : const ChannelCredentials.insecure();
    _debug = debug;
    final helloClient = HelloClient(
      ClientChannel(
        '127.0.0.1',
        port: portFront,
        options: ChannelOptions(credentials: channelOption),
      ),
    );
    _status.clean();
    try {
      await helloClient.sayHello(HelloRequest(name: "test"));
      loggy.info("core is already started!");
    } catch (e) {
      //core is not started yet

      await methodChannel.invokeMethod("setup", {
        "baseDir": directories.baseDir.path,
        "workingDir": directories.workingDir.path,
        "tempDir": directories.tempDir.path,
        "grpcPort": portFront,
        "mode": mode,
        "debug": debug,
      });
      final res = await helloClient.sayHello(HelloRequest(name: "test"));
      loggy.info(res.toString());
    }

    // serverPublicKey = await methodChannel.invokeMethod<Uint8List>("get_grpc_server_public_key") ?? Uint8List.fromList([]);
    // await methodChannel.invokeMethod(
    //   "add_grpc_client_public_key",
    //   {
    //     "clientPublicKey": ascii.encode(CryptoUtils.encodeEcPublicKeyToPem(cert.publicKey as ECPublicKey)),
    //   },
    // );
    // serverPublicKey = X509Utils.x509CertificateFromPem(String.fromCharCodes(serverPublicKey));
    // var chanelOption = ChannelOptions(
    //   credentials: MTLSChannelCredentials(serverPublicKey: serverPublicKey, clientPrivateKey: cert.privateKey as ECPrivateKey),
    // );
    fgClient = CoreClient(
      ClientChannel(
        '127.0.0.1',
        port: portFront,
        options: ChannelOptions(credentials: channelOption),
      ),
    );

    bgClient = CoreClient(
      ClientChannel(
        '127.0.0.1',
        port: portBack,
        options: ChannelOptions(credentials: channelOption),
      ),
    );
    // await start("/sdcard/Android/data/app.hiddify.com/files/configs/cdc633e9-8cfc-4a67-948d-009f779a5c91.json", "hiddify");
    return "";
  }

  @override
  Future<CoreStatus?> getSystemStatus() async {
    if (!Platform.isIOS) return null;
    final status = await methodChannel.invokeMethod<int>("get_vpn_status");
    return switch (status) {
      0 || 1 => const CoreStatus.stopped(),
      2 || 4 => const CoreStatus.starting(),
      3 => const CoreStatus.started(),
      5 => const CoreStatus.stopping(),
      _ => throw StateError("Unexpected iOS VPN status"),
    };
  }

  @override
  Future<CoreStatus> setupBackground(String path, String name) async {
    // if (!await waitUntilPort(portBack, false, stop)) return const CoreStatus.stopped(alert: CoreAlert.createService);
    if (!await stop()) return const CoreStatus.stopped(alert: CoreAlert.createService);
    _status.clean();
    await methodChannel.invokeMethod("start", {
      "path": path,
      "name": name,
      "grpcPort": portBack,
      "startBg": true,
      "debug": _debug,
    });

    _isBgClientAvailable = true;
    loggy.info("Waiting for starting core");
    for (var i = 0; i < 20; i++) {
      try {
        final res = await _status.get(timeout: const Duration(seconds: 1));

        switch (res) {
          case CoreStarted():
            break;
          case CoreStopped():
            if (res.alert != null) {
              return res;
            }

          case CoreStopping():
          // return res;
          case CoreStarting():
        }
        await Future.delayed(const Duration(milliseconds: 200));
      } on TimeoutException {
        // just retry
      }
    }
    loggy.info("Waiting for starting core finished");

    if (!await waitUntilPort(portBack, true, null, maxTry: 10)) {
      await stopMethodChannel();
      return const CoreStatus.stopped(alert: CoreAlert.startService, message: "starting background core...");
    }
    return const CoreStarted();
  }

  @override
  Future<bool> stop() async {
    await stopMethodChannel();
    if (!await waitUntilPort(portBack, false, null, maxTry: 10)) {
      return false;
    }

    _isBgClientAvailable = false;
    return true;
  }

  Future stopMethodChannel() async {
    await methodChannel.invokeMethod("stop");
  }

  @override
  Future<bool> isBgClientAvailable() async {
    return _isBgClientAvailable;
  }

  @override
  Future<bool> resetTunnel() async {
    await methodChannel.invokeMethod("reset");
    return true;
  }

  @override
  Future<bool> isActiveFg() async {
    return await isPortOpen("127.0.0.1", portFront);
  }

  @override
  Future<bool> isActiveBg() async {
    return await isPortOpen("127.0.0.1", portBack);
  }
}

Future<bool> waitUntilPort(
  int portNumber,
  bool isOpen,
  Future Function()? callFunctionAfterEachFail, {
  int maxTry = 10,
}) async {
  for (var i = 0; i < maxTry; i++) {
    if (await isPortOpen("127.0.0.1", portNumber) == isOpen) {
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
