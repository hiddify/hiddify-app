import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/cat/paw_print.dart';

/// A slider thumb that is a round toe bean with a paw print on it. It grows a
/// little while it is dragged.
class PawSliderThumbShape extends SliderComponentShape {
  const PawSliderThumbShape({this.radius = 11, this.pawColor});

  final double radius;

  /// The print on the thumb. Defaults to white, at the thumb's opacity.
  final Color? pawColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Color thumbColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation)!;
    final double r = radius * (1 + .18 * activationAnimation.value);

    canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: center, radius: r)), Colors.black, 2, true);
    canvas.drawCircle(center, r, Paint()..color = thumbColor);
    paintPawPrint(
      canvas,
      center + Offset(0, r * .04),
      r * 1.25,
      Paint()..color = (pawColor ?? Colors.white).withValues(alpha: thumbColor.a * .95),
      rotation: (value - .5) * .6,
    );
  }
}
