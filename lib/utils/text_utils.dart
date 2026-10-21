import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show Archive, ZipDecoder;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

extension TextAlignX on BuildContext {
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  TextAlign get textAlign {
    if (isRtl) {
      return TextAlign.right;
    } else {
      return TextAlign.left;
    }
  }
}

extension StringX on String {
  TextDirection get textDirection {
    return intl.Bidi.detectRtlDirectionality(this) ? TextDirection.rtl : TextDirection.ltr;
  }
}

extension TextEditingControllerX on TextEditingController {
  TextDirection? get textDirection {
    if (text.isEmpty) return null;
    return text.textDirection;
  }
}

/// Decodes bytes that are meant to be read as text, whatever the file's format.
///
/// Skips a UTF-8 byte order mark, and replaces bytes it can't make sense of
/// rather than throwing, so a single stray byte never fails the whole read.
String decodeTextBytes(Uint8List bytes) {
  if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
    return utf8.decode(bytes.sublist(3), allowMalformed: true);
  }
  return utf8.decode(bytes, allowMalformed: true);
}

/// Files bigger than this are skipped when reading a zip. A config is a few KB.
const _maxZipFileBytes = 256 * 1024;

/// Goes between the files of a zip in the text they are merged into. The core reads a line that starts with `#` as a
/// comment, so it ends one config and starts the next.
const zipTextSeparator = '\n#===\n';

/// Reads every file in a zip as text, in the order they are stored, and merges them into one text with
/// [zipTextSeparator] between them.
///
/// Never looks at what a file contains, so whether it is a valid config is for the caller to find out.
/// Skips folders, the metadata macOS adds when it zips a folder (`__MACOSX/` and names starting with `._`),
/// and files over 256 KB. Returns an empty string when [bytes] is not a zip or no file could be read.
String readZipText(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    return '';
  }
  final texts = <String>[];
  for (final file in archive) {
    final segments = file.name.replaceAll('\\', '/').split('/');
    final fileName = segments.last;
    if (!file.isFile || segments.contains('__MACOSX') || fileName.startsWith('._') || file.size > _maxZipFileBytes) {
      continue;
    }
    try {
      texts.add(decodeTextBytes(file.readBytes() ?? Uint8List(0)));
    } catch (_) {
      // A damaged or password-protected file must not stop the others from being read.
    }
  }
  return texts.join(zipTextSeparator);
}
