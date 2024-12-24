import 'dart:convert';

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
import 'package:posix/posix.dart';

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

    helloClient = HelloClient(ClientChannel('localhost', port: portFront, options: ChannelOptions(credentials: channelOption)));
    final res = await helloClient.sayHello(HelloRequest(name: "test"));

    loggy.info(res.toString());
    fgClient = CoreClient(ClientChannel('localhost', port: portFront, options: ChannelOptions(credentials: channelOption)));

    bgClient = CoreClient(ClientChannel('localhost', port: portBack, options: ChannelOptions(credentials: channelOption)));
    // await start("/sdcard/Android/data/app.hiddify.com/files/configs/cdc633e9-8cfc-4a67-948d-009f779a5c91.json", "hiddify");
    return "";
  }

  @override
  Future<bool> start(String path, String name) async {
    await methodChannel.invokeMethod(
      "start",
      {
        "path": path,
        "name": name,
        "grpcPort": portBack,
      },
    );
    _isBgClientAvailable = true;
    return true;
  }

  @override
  Future<bool> restart(String path, String name) async {
    await stop();

    // await methodChannel.invokeMethod(
    //   "restart",
    //   {"path": path, "name": name},
    // );
    sleep(1);
    return await start(path, name);
  }

  @override
  Future<bool> stop() async {
    await methodChannel.invokeMethod(
      "stop",
    );
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
