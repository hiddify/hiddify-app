import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/crash_report/data/age_encryption.dart';

// A throwaway key made with filippo.io/age; its private half was never kept. Decryption itself was
// checked against that library (`age -d`), which Dart has no implementation of to test with here.
const _recipient = 'age12w4dyfmv9pymzvlujejavhthpn2u7cj7dqnxxve4k9z246j03ecsllvff2';

/// The 16-byte nonce, then a 16-byte tag per started 64 KiB chunk, and one chunk for no data.
int _payloadSize(int size) => 16 + size + 16 * (size == 0 ? 1 : (size + 65535) ~/ 65536);

void main() {
  test('takes an age X25519 public key and nothing else', () {
    expect(AgeEncryption.isRecipient(_recipient), isTrue);
    expect(AgeEncryption.isRecipient(_recipient.toUpperCase()), isTrue);
    // one character changed: the bech32 checksum fails
    expect(AgeEncryption.isRecipient(_recipient.replaceRange(10, 11, 'q')), isFalse);
    expect(AgeEncryption.isRecipient('AGE-SECRET-KEY-1QQQQ'), isFalse);
    expect(AgeEncryption.isRecipient(''), isFalse);
  });

  test('writes an age v1 header for one X25519 recipient', () async {
    final out = await AgeEncryption.encrypt(Uint8List.fromList(utf8.encode('report')), _recipient);
    final lines = latin1.decode(out).split('\n');
    expect(lines[0], 'age-encryption.org/v1');
    expect(lines[1], matches(RegExp(r'^-> X25519 [A-Za-z0-9+/]{43}$')));
    // the wrapped 16-byte file key and its tag
    expect(lines[2], matches(RegExp(r'^[A-Za-z0-9+/]{43}$')));
    expect(lines[3], matches(RegExp('^--- [A-Za-z0-9+/]{43}')));
  });

  test('splits the payload into 64 KiB chunks', () async {
    for (final size in [0, 1, 65535, 65536, 65537, 200000]) {
      final out = await AgeEncryption.encrypt(Uint8List(size), _recipient);
      final header = latin1.decode(out).indexOf('\n---');
      final headerEnd = latin1.decode(out).indexOf('\n', header + 1) + 1;
      expect(out.length - headerEnd, _payloadSize(size), reason: '$size bytes');
    }
  });

  test('encrypts the same data differently every time', () async {
    final data = Uint8List(1000);
    final first = await AgeEncryption.encrypt(data, _recipient);
    final second = await AgeEncryption.encrypt(data, _recipient);
    expect(first, isNot(equals(second)));
  });
}
