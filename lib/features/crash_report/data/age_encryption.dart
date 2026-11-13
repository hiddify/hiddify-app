import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Encrypts to an X25519 recipient in the age format (https://age-encryption.org/v1), so a report
/// is opened with the stock tools and nothing of ours: `age -d -i key.txt report.zip.age`.
///
/// Only the holder of the recipient's private key can decrypt: the file key is wrapped with a
/// secret shared between a one-time key made here and the recipient's public key, and the one-time
/// private key is never kept.
class AgeEncryption {
  AgeEncryption._();

  static const _hrp = 'age';
  static const _chunkSize = 64 * 1024;

  /// Whether [recipient] is an `age1…` X25519 public key, as `age-keygen` prints it.
  static bool isRecipient(String recipient) {
    try {
      _decodeRecipient(recipient);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [plaintext] encrypted to [recipient], in its own isolate: a 20 MB report takes a while in
  /// pure Dart, and the dialog keeps animating meanwhile.
  static Future<Uint8List> encrypt(Uint8List plaintext, String recipient) =>
      Isolate.run(() => _encrypt(plaintext, recipient));

  static Future<Uint8List> _encrypt(Uint8List plaintext, String recipient) async {
    final recipientKey = _decodeRecipient(recipient);
    final random = Random.secure();
    List<int> randomBytes(int length) => List<int>.generate(length, (_) => random.nextInt(256));

    final fileKey = randomBytes(16);

    // the X25519 recipient stanza: the file key wrapped for the recipient
    final x25519 = X25519();
    final ephemeral = await x25519.newKeyPair();
    final ephemeralShare = (await ephemeral.extractPublicKey()).bytes;
    final shared = await x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(recipientKey, type: KeyPairType.x25519),
    );
    final wrapKey = await _hkdf(await shared.extractBytes(), [
      ...ephemeralShare,
      ...recipientKey,
    ], 'age-encryption.org/v1/X25519');
    final wrapped = await _seal(wrapKey, List<int>.filled(12, 0), fileKey);

    final header = StringBuffer()
      ..write('age-encryption.org/v1\n')
      ..write('-> X25519 ${_b64(ephemeralShare)}\n')
      ..write(_wrapLines(_b64(wrapped)))
      ..write('---');
    final macKey = await _hkdf(fileKey, const [], 'header');
    final mac = await Hmac.sha256().calculateMac(utf8.encode(header.toString()), secretKey: SecretKey(macKey));
    header.write(' ${_b64(mac.bytes)}\n');

    // the payload: a nonce, then STREAM chunks of 64 KiB, the last one flagged
    final nonce = randomBytes(16);
    final payloadKey = await _hkdf(fileKey, nonce, 'payload');
    final out = BytesBuilder(copy: false)
      ..add(utf8.encode(header.toString()))
      ..add(nonce);
    var offset = 0;
    var counter = 0;
    do {
      final end = min(offset + _chunkSize, plaintext.length);
      final last = end == plaintext.length;
      final chunkNonce = Uint8List(12);
      // an 11-byte big-endian counter, then the last-chunk flag
      var c = counter;
      for (var i = 10; i >= 0 && c > 0; i--) {
        chunkNonce[i] = c & 0xff;
        c >>= 8;
      }
      chunkNonce[11] = last ? 1 : 0;
      out.add(await _seal(payloadKey, chunkNonce, Uint8List.sublistView(plaintext, offset, end)));
      offset = end;
      counter++;
    } while (offset < plaintext.length);
    return out.takeBytes();
  }

  static Future<List<int>> _hkdf(List<int> ikm, List<int> salt, String info) async {
    final key = await Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    ).deriveKey(secretKey: SecretKey(ikm), nonce: salt, info: utf8.encode(info));
    return key.extractBytes();
  }

  /// ChaCha20-Poly1305: the ciphertext followed by its 16-byte tag.
  static Future<List<int>> _seal(List<int> key, List<int> nonce, List<int> plaintext) async {
    final box = await Chacha20.poly1305Aead().encrypt(plaintext, secretKey: SecretKey(key), nonce: nonce);
    return [...box.cipherText, ...box.mac.bytes];
  }

  /// Standard base64 without padding, as age writes it.
  static String _b64(List<int> bytes) => base64.encode(bytes).replaceAll('=', '');

  /// A stanza body in lines of 64 columns, the last one always shorter.
  static String _wrapLines(String text) {
    final lines = StringBuffer();
    var offset = 0;
    while (text.length - offset >= 64) {
      lines.write('${text.substring(offset, offset + 64)}\n');
      offset += 64;
    }
    lines.write('${text.substring(offset)}\n');
    return lines.toString();
  }

  /// The 32-byte key in an `age1…` bech32 string, checksum checked.
  static List<int> _decodeRecipient(String recipient) {
    final text = recipient.trim().toLowerCase();
    final separator = text.lastIndexOf('1');
    if (separator < 1 || text.substring(0, separator) != _hrp) throw const FormatException('not an age recipient');
    const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
    final data = [
      for (final char in text.substring(separator + 1).split(''))
        if (charset.indexOf(char) case final value when value >= 0) value else throw const FormatException('bad char'),
    ];
    if (data.length < 6) throw const FormatException('too short');
    final expanded = [for (final c in _hrp.codeUnits) c >> 5, 0, for (final c in _hrp.codeUnits) c & 31];
    if (_polymod([...expanded, ...data]) != 1) throw const FormatException('bad checksum');

    // 5-bit groups to bytes
    final bytes = <int>[];
    var accumulator = 0;
    var bits = 0;
    for (final value in data.sublist(0, data.length - 6)) {
      accumulator = (accumulator << 5) | value;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        bytes.add((accumulator >> bits) & 0xff);
      }
    }
    if (bits >= 5 || (accumulator & ((1 << bits) - 1)) != 0) throw const FormatException('bad padding');
    if (bytes.length != 32) throw const FormatException('not a 32-byte key');
    return bytes;
  }

  static int _polymod(List<int> values) {
    const generator = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
    var checksum = 1;
    for (final value in values) {
      final top = checksum >> 25;
      checksum = ((checksum & 0x1ffffff) << 5) ^ value;
      for (var i = 0; i < 5; i++) {
        if ((top >> i) & 1 == 1) checksum ^= generator[i];
      }
    }
    return checksum;
  }
}
