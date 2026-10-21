import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/utils/text_utils.dart';

/// Builds a zip in memory. A name ending in `/` becomes a folder.
Uint8List zipOf(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, text) {
    archive.add(name.endsWith('/') ? ArchiveFile.directory(name) : ArchiveFile.string(name, text));
  });
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  group('readZipText', () {
    test('merges every file in order, with the separator between them', () {
      final text = readZipText(
        zipOf({'export/': '', 'export/a.conf': 'one\ntwo', 'export/sub/b.txt': 'three', 'c': 'four'}),
      );
      expect(text, 'one\ntwo\n#===\nthree\n#===\nfour');
    });

    test('gives the text of a single file as it is', () {
      expect(readZipText(zipOf({'a.conf': 'one'})), 'one');
    });

    test('skips macOS metadata but keeps names that only start with a dot', () {
      final text = readZipText(
        zipOf({
          'export/. 🇳🇱 Free-1.conf': 'kept',
          '__MACOSX/export/._. 🇳🇱 Free-1.conf': 'junk',
          'export/._other.conf': 'junk',
          'export/.hidden': 'kept too',
        }),
      );
      expect(text, 'kept\n#===\nkept too');
    });

    test('skips files over 256 KB', () {
      expect(readZipText(zipOf({'big.conf': 'x' * (256 * 1024 + 1), 'small.conf': 'ok'})), 'ok');
    });

    test('drops a UTF-8 byte order mark', () {
      final archive = Archive()..add(ArchiveFile.bytes('a.conf', [0xEF, 0xBB, 0xBF, ...utf8.encode('text')]));
      expect(readZipText(ZipEncoder().encodeBytes(archive)), 'text');
    });

    test('gives an empty string when the zip holds only folders and macOS metadata', () {
      expect(readZipText(zipOf({'export/': '', '__MACOSX/export/._a.conf': 'junk'})), isEmpty);
    });

    test('gives an empty string when the bytes are not a zip', () {
      expect(readZipText(Uint8List.fromList(utf8.encode('[Interface]\nAddress = 10.0.0.2/32'))), isEmpty);
    });
  });
}
