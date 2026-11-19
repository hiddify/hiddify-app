import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/core/widget/ambient_motion.dart';
import 'package:hiddify/core/widget/skeleton_widget.dart';

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    this.width,
    this.height,
    this.widthFactor,
    this.heightFactor,
    this.color,
    this.duration = const Duration(seconds: 1),
    super.key,
  });

  final double? width;
  final double? height;
  final double? widthFactor;
  final double? heightFactor;
  final Color? color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final skeleton = Skeleton(width: width, height: height, widthFactor: widthFactor, heightFactor: heightFactor);
    // a loading placeholder can stay for a long time (a ping that never answers): it sweeps on the
    // ambient clock, and stands still where the endless decoration does
    return AmbientLoop(
      period: duration,
      still: (_) => skeleton,
      // the sweep repaints the skeleton alone, not the row or page round it
      builder: (context, phase) => RepaintBoundary(
        child: skeleton
            .animate(adapter: ValueNotifierAdapter(phase))
            .shimmer(duration: duration, angle: 45, color: color ?? Theme.of(context).colorScheme.secondary),
      ),
    );
  }
}
