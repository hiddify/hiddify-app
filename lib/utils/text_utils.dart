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
