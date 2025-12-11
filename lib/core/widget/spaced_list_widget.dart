import 'package:flutter/widgets.dart';

/// Extension on [List<Widget>] to add spacing between elements.
/// 
/// Usage:
/// ```dart
/// Column(
///   children: [
///     Widget1(),
///     Widget2(),
///     Widget3(),
///   ].spaceBy(height: 8),
/// )
/// ```
extension SpacedWidgets on List<Widget> {
  /// Inserts [SizedBox] spacing between each widget in the list.
  /// 
  /// [width] adds horizontal spacing.
  /// [height] adds vertical spacing.
  /// [separatorBuilder] allows custom separator widgets.
  List<Widget> spaceBy({
    double? width,
    double? height,
    Widget Function(int index)? separatorBuilder,
  }) =>
      [
        for (int i = 0; i < length; i++) ...[
          if (i > 0)
            separatorBuilder?.call(i) ?? SizedBox(width: width, height: height),
          this[i],
        ],
      ];
}
