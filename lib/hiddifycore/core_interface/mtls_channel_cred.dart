import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:grpc/grpc.dart';

/// mTLS credentials for the local hiddify-core gRPC server.
///
/// Trusts only [serverCertificatePem] (pinned), presents a self-signed client
/// certificate, and sets authority to `127.0.0.1` to match the server SAN.
class MTLSChannelCredentials extends ChannelCredentials {
  MTLSChannelCredentials._({
    required SecurityContext context,
    required this.clientCertificatePem,
    required Uint8List serverCertificateDer,
    required String serverPemBody,
  })  : _ctx = context,
        super.secure(
          authority: '127.0.0.1',
          onBadCertificate: (X509Certificate cert, String host) {
            if (!_isLoopbackHost(host)) return false;
            // Prefer exact DER pin; fall back to PEM body match (macOS sometimes
            // re-encodes the presented cert so raw DER bytes differ).
            if (_bytesEqual(cert.der, serverCertificateDer)) return true;
            final presented = _pemBody(cert.pem);
            return presented.isNotEmpty && presented == serverPemBody;
          },
        );

  final SecurityContext _ctx;

  /// PEM of the client certificate that must be registered with the Go core
  /// via `add_grpc_client_public_key` before connecting.
  final String clientCertificatePem;

  factory MTLSChannelCredentials({
    required Uint8List serverCertificatePem,
    required AsymmetricKeyPair<PublicKey, PrivateKey> clientKey,
  }) {
    final serverPem = utf8.decode(serverCertificatePem);
    if (!serverPem.contains('-----BEGIN CERTIFICATE-----')) {
      throw ArgumentError('Server certificate must be PEM.');
    }

    final String privateKeyPem;
    final String clientCertPem;
    if (clientKey.privateKey is RSAPrivateKey && clientKey.publicKey is RSAPublicKey) {
      final priv = clientKey.privateKey as RSAPrivateKey;
      final pub = clientKey.publicKey as RSAPublicKey;
      privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(priv);
      final csr = X509Utils.generateRsaCsrPem({'CN': 'HiddifyClient'}, priv, pub);
      clientCertPem = X509Utils.generateSelfSignedCertificate(
        priv,
        csr,
        3650,
        extKeyUsage: [ExtendedKeyUsage.CLIENT_AUTH],
      );
    } else if (clientKey.privateKey is ECPrivateKey && clientKey.publicKey is ECPublicKey) {
      final priv = clientKey.privateKey as ECPrivateKey;
      final pub = clientKey.publicKey as ECPublicKey;
      privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(priv);
      final csr = X509Utils.generateEccCsrPem({'CN': 'HiddifyClient'}, priv, pub);
      clientCertPem = X509Utils.generateSelfSignedCertificate(
        priv,
        csr,
        3650,
        extKeyUsage: [ExtendedKeyUsage.CLIENT_AUTH],
      );
    } else {
      throw ArgumentError('Unsupported private key type.');
    }

    if (!clientCertPem.contains('-----BEGIN CERTIFICATE-----')) {
      throw StateError('Failed to generate client certificate PEM.');
    }

    final serverDer = _pemToDer(serverPem);
    final serverPemBody = _pemBody(serverPem);

    final ctx = SecurityContext(withTrustedRoots: false);
    ctx.setAlpnProtocols(supportedAlpnProtocols, false);
    // PEM works across Android/desktop; DER triggers BAD_PKCS12_DATA on macOS desktop.
    ctx.setTrustedCertificatesBytes(utf8.encode(serverPem));
    ctx.useCertificateChainBytes(utf8.encode(clientCertPem));
    ctx.usePrivateKeyBytes(utf8.encode(privateKeyPem));

    return MTLSChannelCredentials._(
      context: ctx,
      clientCertificatePem: clientCertPem,
      serverCertificateDer: serverDer,
      serverPemBody: serverPemBody,
    );
  }

  static bool _isLoopbackHost(String host) {
    // grpc-dart may pass "127.0.0.1:port" or just "127.0.0.1".
    final name = host.split(':').first.replaceAll('[', '').replaceAll(']', '');
    return name == '127.0.0.1' || name == 'localhost' || name == '::1';
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String _pemBody(String pem) {
    return pem
        .replaceAll('-----BEGIN CERTIFICATE-----', '')
        .replaceAll('-----END CERTIFICATE-----', '')
        .replaceAll(RegExp(r'\s'), '');
  }

  static Uint8List _pemToDer(String pem) {
    return Uint8List.fromList(base64.decode(_pemBody(pem)));
  }

  @override
  SecurityContext get securityContext => _ctx;

  @override
  String? get authority => '127.0.0.1';

  @override
  bool get isSecure => true;
}
