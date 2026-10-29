import 'dart:io';
import 'dart:isolate';

import 'package:basic_utils/basic_utils.dart';

/// The client certificate and private key the app and the platform service present to the local
/// hiddify-core gRPC server (mTLS).
///
/// They are made once and kept in a private folder, so every launch, and the native service
/// (Android), use the same identity: the core knows it by its certificate alone. The key is
/// PKCS#8 PEM, which both Dart and the Android keystore classes read.
class GrpcClientIdentity {
  const GrpcClientIdentity({required this.certificatePem, required this.privateKeyPem});

  final String certificatePem;
  final String privateKeyPem;

  static const certificateFile = 'client.crt';
  static const privateKeyFile = 'client.key';

  /// An identity made more than this long ago is replaced before it can expire.
  static const _validityDays = 3650;
  static const _renewBefore = Duration(days: 30);

  /// Reads the identity from [directory], or makes and saves one when there is none, or it is
  /// unreadable or about to expire.
  static Future<GrpcClientIdentity> loadOrCreate(Directory directory) async {
    final certificate = File('${directory.path}/$certificateFile');
    final privateKey = File('${directory.path}/$privateKeyFile');
    try {
      if (await certificate.exists() && await privateKey.exists()) {
        final identity = GrpcClientIdentity(
          certificatePem: await certificate.readAsString(),
          privateKeyPem: await privateKey.readAsString(),
        );
        if (identity._isUsable()) return identity;
      }
    } on FileSystemException {
      // unreadable: made again below
    }
    // RSA key generation is slow, and far slower in debug builds on a phone: not on the UI thread
    final identity = await Isolate.run(GrpcClientIdentity.generate);
    await directory.create(recursive: true);
    await _write(privateKey, identity.privateKeyPem);
    await _write(certificate, identity.certificatePem);
    return identity;
  }

  /// A new RSA identity: RSA matches the Go server's crypto and avoids EC PKCS#8 quirks on iOS.
  factory GrpcClientIdentity.generate() {
    final pair = CryptoUtils.generateRSAKeyPair();
    final privateKey = pair.privateKey as RSAPrivateKey;
    final publicKey = pair.publicKey as RSAPublicKey;
    final csr = X509Utils.generateRsaCsrPem({'CN': 'HiddifyClient'}, privateKey, publicKey);
    final certificate = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      _validityDays,
      extKeyUsage: [ExtendedKeyUsage.CLIENT_AUTH],
    );
    if (!certificate.contains('-----BEGIN CERTIFICATE-----')) {
      throw StateError('Failed to generate client certificate PEM.');
    }
    return GrpcClientIdentity(
      certificatePem: certificate,
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
    );
  }

  bool _isUsable() {
    if (!certificatePem.contains('-----BEGIN CERTIFICATE-----') ||
        !privateKeyPem.contains('-----BEGIN PRIVATE KEY-----')) {
      return false;
    }
    try {
      final notAfter = X509Utils.x509CertificateFromPem(certificatePem).tbsCertificate?.validity.notAfter;
      return notAfter != null && notAfter.isAfter(DateTime.now().add(_renewBefore));
    } on Object {
      return false;
    }
  }

  /// Writes through a temporary file, so a crash never leaves half a key behind.
  static Future<void> _write(File file, String content) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(file.path);
  }
}
