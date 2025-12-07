import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/core/widget/skeleton_widget.dart';

/// A skeleton widget with animated shimmer effect for loading states.
/// 
/// Wraps [Skeleton] and adds a looping shimmer animation to indicate
/// loading content. Uses the secondary color from the theme by default.
/// 
/// Usage:
/// ```dart
/// ShimmerSkeleton(
///   width: 200,
///   height: 16,
///   duration: Duration(milliseconds: 800),
/// )
/// ```
class ShimmerSkeleton extends StatelessWidget {
  /// Creates a shimmer skeleton.
  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.widthFactor,
    this.heightFactor,
    this.color,
    this.duration = const Duration(seconds: 1),
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
  
  /// Custom shimmer color. Defaults to theme secondary color.
  final Color? color;
  
  /// Duration of one shimmer animation cycle.
  final Duration duration;
  
  /// Border radius for the skeleton.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
          width: width,
          height: height,
          widthFactor: widthFactor,
          heightFactor: heightFactor,
          borderRadius: borderRadius,
        )
        .animate(onPlay: (controller) => controller.loop())
        .shimmer(
          duration: duration,
          angle: 45,
          color: color ?? Theme.of(context).colorScheme.secondary,
        );
  }
}
