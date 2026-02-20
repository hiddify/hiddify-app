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

class CoreInterfaceMobile extends CoreInterface with InfraLogger {
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

  late LastStream<CoreStatus> _status;
  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
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
    final status = statusChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);
    final alerts = alertsChannel.receiveBroadcastStream().map(CoreStatus.fromEvent);

    _status = LastStream(ValueConnectableStream(Rx.merge([status, alerts])).autoConnect());
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
