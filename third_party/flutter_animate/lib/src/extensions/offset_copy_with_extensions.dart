import 'package:flutter/widgets.dart';

/// Adds a `copyWith` method to Offset.
extension OffsetCopyWithExtensions on Offset {
  Offset copyWith({double? dx, double? dy}) =>
      Offset(dx ?? this.dx, dy ?? this.dy);
}
