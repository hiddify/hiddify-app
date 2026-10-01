import 'dart:convert';
import 'dart:typed_data';

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
