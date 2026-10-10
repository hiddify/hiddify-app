import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/cat/paw_print.dart';

/// A progress bar whose fill ends in a round toe bean with a paw print on it,
/// as if a cat had walked that far. Stands in for [LinearProgressIndicator].
class CatProgressBar extends StatelessWidget {
  const CatProgressBar({super.key, required this.value, this.height = 6, this.color, this.backgroundColor});

  /// From 0 to 1.
  final double value;
  final double height;

  /// Defaults to the theme's primary color.
  final Color? color;

  /// Defaults to the theme's highest surface container color.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double v = value.clamp(0, 1);
    return Semantics(
      value: '${(v * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => CustomPaint(
          size: Size(double.infinity, height + 4),
          painter: _CatProgressPainter(
            value: animated,
            height: height,
            color: color ?? scheme.primary,
            onColor: color == null ? scheme.onPrimary : Colors.white,
            track: backgroundColor ?? scheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

class _CatProgressPainter extends CustomPainter {
  _CatProgressPainter({
    required this.value,
    required this.height,
    required this.color,
    required this.onColor,
    required this.track,
  });

  final double value;
  final double height;
  final Color color;
  final Color onColor;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final double knob = height * 1.25;
    final double top = (size.height - height) / 2;
    final Radius round = Radius.circular(height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, height), round), Paint()..color = track);
    if (value <= 0) return;
    final double end = knob + (size.width - knob * 2) * value;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, top, end, height), round), Paint()..color = color);
    final Offset bean = Offset(end, size.height / 2);
    canvas
      ..drawCircle(bean, knob, Paint()..color = color)
      ..drawCircle(
        bean,
        knob,
        Paint()
          ..color = track.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    paintPawPrint(
      canvas,
      bean + Offset(0, knob * .05),
      knob * 1.45,
      Paint()..color = onColor.withValues(alpha: .9),
      rotation: math.pi / 2,
    );
  }

  @override
  bool shouldRepaint(_CatProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.height != height ||
      oldDelegate.color != color ||
      oldDelegate.onColor != onColor ||
      oldDelegate.track != track;
}
