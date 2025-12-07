import 'package:flutter/material.dart';

/// A placeholder skeleton widget used for loading states.
/// 
/// Displays a subtle colored box that can be animated with shimmer effects.
/// Commonly used with [ShimmerSkeleton] for loading indicators.
/// 
/// Usage:
/// ```dart
/// Skeleton(
///   width: 100,
///   height: 20,
///   shape: BoxShape.rectangle,
/// )
/// ```
class Skeleton extends StatelessWidget {
  /// Creates a skeleton placeholder.
  /// 
  /// Use [width] and [height] for fixed sizes.
  /// Use [widthFactor] and [heightFactor] for relative sizes.
  /// [borderRadius] controls the corner rounding for rectangle shapes.
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.widthFactor,
    this.heightFactor,
    this.shape = BoxShape.rectangle,
    this.alignment = AlignmentDirectional.center,
    this.borderRadius,
  });

  /// Fixed width of the skeleton.
  final double? width;
  
  /// Fixed height of the skeleton.
  final double? height;
  
  /// Relative width factor (0.0 to 1.0).
  final double? widthFactor;
  
  /// Relative height factor (0.0 to 1.0).
  final double? heightFactor;
  
  /// Shape of the skeleton box.
  final BoxShape shape;
  
  /// Alignment within the parent.
  final AlignmentGeometry alignment;
  
  /// Border radius for rectangle shapes. Defaults to 8.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: shape == BoxShape.rectangle 
              ? effectiveBorderRadius 
              : null,
          shape: shape,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
