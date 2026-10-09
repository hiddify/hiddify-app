import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Paints a cat's paw print: one big pad and four toe beans above it.
///
/// [size] is the height of the whole print; [center] is the middle of it.
/// [rotation] turns it clockwise, in radians, with the toes pointing up at 0.
void paintPawPrint(Canvas canvas, Offset center, double size, Paint paint, {double rotation = 0}) {
  if (size <= 0) return;
  canvas
    ..save()
    ..translate(center.dx, center.dy)
    ..rotate(rotation)
    ..scale(size)
    ..drawPath(_PawPrintShape.pad, paint);
  for (final toe in _PawPrintShape.toes) {
    canvas
      ..save()
      ..translate(toe.center.dx, toe.center.dy)
      ..rotate(toe.angle)
      ..drawOval(Rect.fromCenter(center: Offset.zero, width: toe.width, height: toe.height), paint)
      ..restore();
  }
  canvas.restore();
}

/// A paw print outline as a single path, [size] tall, centered on the origin.
Path pawPrintPath(double size) {
  final Path path = Path()..addPath(_PawPrintShape.pad, Offset.zero);
  for (final toe in _PawPrintShape.toes) {
    final Path oval = Path()..addOval(Rect.fromCenter(center: Offset.zero, width: toe.width, height: toe.height));
    final double c = math.cos(toe.angle);
    final double s = math.sin(toe.angle);
    path.addPath(
      oval.transform(Float64List.fromList([c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, toe.center.dx, toe.center.dy, 0, 1])),
      Offset.zero,
    );
  }
  final Float64List scale = Float64List.fromList([size, 0, 0, 0, 0, size, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
  return path.transform(scale);
}

/// The print at unit height, centered on the origin.
abstract final class _PawPrintShape {
  static final Path pad = Path()
    ..moveTo(0, -.02)
    ..cubicTo(.17, -.02, .31, .14, .29, .27)
    ..cubicTo(.27, .40, .13, .43, 0, .37)
    ..cubicTo(-.13, .43, -.27, .40, -.29, .27)
    ..cubicTo(-.31, .14, -.17, -.02, 0, -.02)
    ..close();

  static const List<({Offset center, double width, double height, double angle})> toes = [
    (center: Offset(-.34, -.10), width: .19, height: .25, angle: -.42),
    (center: Offset(-.125, -.30), width: .2, height: .26, angle: -.12),
    (center: Offset(.125, -.30), width: .2, height: .26, angle: .12),
    (center: Offset(.34, -.10), width: .19, height: .25, angle: .42),
  ];
}
