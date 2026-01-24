import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:grpc/grpc.dart';

class MTLSChannelCredentials extends ChannelCredentials {
  final SecurityContext ctx = SecurityContext(withTrustedRoots: false);

  MTLSChannelCredentials({
    required Uint8List serverPublicKey,
    required AsymmetricKeyPair<PublicKey, PrivateKey> clientKey,
  }) : super.secure() {
    // Ensure server public key is in PEM format
    final serverPublicKeyPem = String.fromCharCodes(serverPublicKey);
    if (!serverPublicKeyPem.contains('-----BEGIN CERTIFICATE-----')) {
      throw ArgumentError('Server public key must be in PEM format.');
    }
    // Set the server's public key as trusted
    ctx.setTrustedCertificatesBytes(serverPublicKey);

    // Convert the client's private key to PEM format
    String privateKeyPem;
    if (clientKey.privateKey is ECPrivateKey) {
      privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(clientKey.privateKey as ECPrivateKey);
    } else if (clientKey.privateKey is RSAPrivateKey) {
      privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(clientKey.privateKey as RSAPrivateKey);
    } else {
      throw ArgumentError('Unsupported private key type.');
    }
    ctx.usePrivateKeyBytes(Uint8List.fromList(privateKeyPem.codeUnits));

    final cert = X509Utils.generateSelfSignedCertificate(clientKey.privateKey, 'CN=Client', 365);

    ctx.useCertificateChainBytes(Uint8List.fromList(cert.codeUnits));
  }

  @override
  SecurityContext get securityContext => ctx;

  @override
  bool get isSecure => true;
}
