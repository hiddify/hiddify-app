import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/hiddifycore/core_interface/mtls_channel_cred.dart';

String _selfSignedServerCert() {
  final pair = CryptoUtils.generateRSAKeyPair();
  final priv = pair.privateKey as RSAPrivateKey;
  final pub = pair.publicKey as RSAPublicKey;
  final csr = X509Utils.generateRsaCsrPem({'CN': '127.0.0.1'}, priv, pub, san: ['127.0.0.1', 'localhost']);
  return X509Utils.generateSelfSignedCertificate(
    priv,
    csr,
    365,
    sans: ['127.0.0.1', 'localhost'],
    extKeyUsage: [ExtendedKeyUsage.SERVER_AUTH, ExtendedKeyUsage.CLIENT_AUTH],
  );
}

void main() {
  test('MTLSChannelCredentials builds pinned context and client cert PEM', () {
    final serverCertPem = _selfSignedServerCert();
    expect(serverCertPem.contains('BEGIN CERTIFICATE'), isTrue);

    final clientKey = CryptoUtils.generateRSAKeyPair();
    final creds = MTLSChannelCredentials(
      serverCertificatePem: Uint8List.fromList(utf8.encode(serverCertPem)),
      clientKey: clientKey,
    );

    expect(creds.isSecure, isTrue);
    expect(creds.authority, '127.0.0.1');
    expect(creds.clientCertificatePem.contains('BEGIN CERTIFICATE'), isTrue);
    expect(creds.securityContext, isNotNull);
  });

  test('MTLSChannelCredentials rejects non-PEM server cert', () {
    final clientKey = CryptoUtils.generateRSAKeyPair();
    expect(
      () => MTLSChannelCredentials(
        serverCertificatePem: Uint8List.fromList(utf8.encode('not-a-cert')),
        clientKey: clientKey,
      ),
      throwsArgumentError,
    );
  });
}
