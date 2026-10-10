import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/cat/paw_print.dart';

/// A loading indicator: a cat walking in circles, leaving paw prints that
/// fade behind it. Stands in for [CircularProgressIndicator].
class PawSpinner extends StatefulWidget {
  const PawSpinner({super.key, this.size = 44, this.color, this.semanticsLabel});

  final double size;

  /// Defaults to the theme's primary color.
  final Color? color;

  final String? semanticsLabel;

  @override
  State<PawSpinner> createState() => _PawSpinnerState();
}

class _PawSpinnerState extends State<PawSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _walk.stop();
    } else if (!_walk.isAnimating) {
      _walk.repeat();
    }
  }

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _PawCirclePainter(_walk, widget.color ?? Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _PawCirclePainter extends CustomPainter {
  _PawCirclePainter(this.walk, this.color) : super(repaint: walk);

  static const int steps = 8;

  final Animation<double> walk;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide * .36;
    final double paw = size.shortestSide * .24;
    final double head = walk.value * steps;
    for (int i = 0; i < steps; i++) {
      // how many steps ago the cat was here: fresh prints are darkest
      final double age = (head - i) % steps;
      final double alpha = math.pow(1 - age / steps, 1.6).toDouble();
      final double angle = 2 * math.pi * i / steps - math.pi / 2;
      final double r = radius + (i.isEven ? 1 : -1) * size.shortestSide * .045;
      paintPawPrint(
        canvas,
        center + Offset(math.cos(angle), math.sin(angle)) * r,
        paw,
        Paint()..color = color.withValues(alpha: color.a * (.12 + .88 * alpha)),
        rotation: angle + math.pi,
      );
    }
  }

  @override
  bool shouldRepaint(_PawCirclePainter oldDelegate) => oldDelegate.color != color || oldDelegate.walk != walk;
}
