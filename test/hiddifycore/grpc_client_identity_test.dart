import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/hiddifycore/core_interface/grpc_client_identity.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('grpc_identity_test');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('the identity is made once and every later load returns the same one', () async {
    final first = await GrpcClientIdentity.loadOrCreate(directory);
    final second = await GrpcClientIdentity.loadOrCreate(directory);

    expect(first.certificatePem, contains('BEGIN CERTIFICATE'));
    // PKCS#8, which the Android keystore classes read
    expect(first.privateKeyPem, contains('BEGIN PRIVATE KEY'));
    expect(second.certificatePem, first.certificatePem);
    expect(second.privateKeyPem, first.privateKeyPem);
    expect(File('${directory.path}/${GrpcClientIdentity.certificateFile}').existsSync(), isTrue);
    expect(File('${directory.path}/${GrpcClientIdentity.privateKeyFile}').existsSync(), isTrue);
  });

  test('an unreadable identity is replaced instead of failing', () async {
    final first = await GrpcClientIdentity.loadOrCreate(directory);
    await File('${directory.path}/${GrpcClientIdentity.privateKeyFile}').writeAsString('garbage');

    final second = await GrpcClientIdentity.loadOrCreate(directory);

    expect(second.certificatePem, isNot(first.certificatePem));
    expect(second.privateKeyPem, contains('BEGIN PRIVATE KEY'));
  });
}
