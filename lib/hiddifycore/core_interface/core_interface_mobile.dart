import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/mtls_channel_cred.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello_service.pbgrpc.dart';

import 'package:hiddify/utils/utils.dart';
import 'package:loggy/loggy.dart';

final _logger = Loggy('FFIHiddifyCoreService');

class CoreInterfaceMobile extends CoreInterface with InfraLogger {
  static const channelPrefix = "com.hiddify.app";
  static const methodChannel = MethodChannel("$channelPrefix/method");

  late Uint8List serverPublicKey;
  static final cert = CryptoUtils.generateEcKeyPair();

  static const portBack = 17079;
  static const portFront = 17078;

  bool _isBgClientAvailable = false;

  late HelloClient helloClient;
  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    await methodChannel.invokeMethod(
      "setup",
      {
        "baseDir": directories.baseDir.path,
        "workingDir": directories.workingDir.path,
        "tempDir": directories.tempDir.path,
        "grpcPort": portFront,
        "mode": mode,
      },
    );
    // serverPublicKey = await methodChannel.invokeMethod<Uint8List>("get_grpc_server_public_key") ?? Uint8List.fromList([]);
    await methodChannel.invokeMethod(
      "add_grpc_client_public_key",
      {
        "clientPublicKey": ascii.encode(CryptoUtils.encodeEcPublicKeyToPem(cert.publicKey as ECPublicKey)),
      },
    );
    // serverPublicKey = X509Utils.x509CertificateFromPem(String.fromCharCodes(serverPublicKey));
    // var chanelOption = ChannelOptions(
    //   credentials: MTLSChannelCredentials(serverPublicKey: serverPublicKey, clientPrivateKey: cert.privateKey as ECPrivateKey),
    // );
    final channelOption = [1, 2].contains(mode)
        ? MTLSChannelCredentials(
            serverPublicKey: serverPublicKey,
            clientKey: cert,
          )
        : const ChannelCredentials.insecure();

    helloClient = HelloClient(ClientChannel('127.0.0.1', port: portFront, options: ChannelOptions(credentials: channelOption)));
    final res = await helloClient.sayHello(HelloRequest(name: "test"));

    loggy.info(res.toString());
    fgClient = CoreClient(ClientChannel('127.0.0.1', port: portFront, options: ChannelOptions(credentials: channelOption)));

    bgClient = CoreClient(ClientChannel('127.0.0.1', port: portBack, options: ChannelOptions(credentials: channelOption)));
    // await start("/sdcard/Android/data/app.hiddify.com/files/configs/cdc633e9-8cfc-4a67-948d-009f779a5c91.json", "hiddify");
    return "";
  }

  @override
  Future<bool> start(String path, String name) async {
    await stop();
    if (!await waitUntilPort(portBack, false)) return false;

    await methodChannel.invokeMethod(
      "start",
      {
        "path": path,
        "name": name,
        "grpcPort": portBack,
        "startBg": true,
      },
    );
    if (!await waitUntilPort(portBack, true)) return false;
    _isBgClientAvailable = true;
    return true;
  }

  Future<bool> waitUntilPort(int portNumber, bool isOpen) async {
    for (var i = 0; i < 100; i++) {
      if (await isPortOpen("127.0.0.1", portNumber) == isOpen) {
        return true;
      }
      // Non-blocking pause for 100 milliseconds
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }
  // @override
  // Future<bool> restart(String path, String name) async {
  //   await stop();

  //   // await methodChannel.invokeMethod(
  //   //   "restart",
  //   //   {"path": path, "name": name},
  //   // );
  //   sleep(1);
  //   return await start(path, name);
  // }

  @override
  Future<bool> stop() async {
    await methodChannel.invokeMethod(
      "stop",
    );
    if (!await waitUntilPort(portBack, false)) {
      await methodChannel.invokeMethod(
        "stop",
      );
      return false;
    }
    _isBgClientAvailable = false;
    return true;
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
}

Future<bool> isPortOpen(String host, int port, {Duration timeout = const Duration(seconds: 5)}) async {
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
