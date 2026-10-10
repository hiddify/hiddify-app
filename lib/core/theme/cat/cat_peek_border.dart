import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/cat/cat_ears_border.dart';

/// A rounded rectangle with a cat peeking over its top edge: the top of its
/// head, two ears, two eyes reading what's below and two paws holding on to
/// the edge.
///
/// Made for dialogs. The head and paws are filled with the dialog's own color,
/// so the dialog reads as the cat's sign; the face is painted on top.
@immutable
class CatPeekBorder extends OutlinedBorder {
  const CatPeekBorder({
    super.side,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.alignment = .8,
    this.peek = 1,
    required this.lineColor,
    required this.innerEarColor,
    required this.irisColor,
    required this.pupilColor,
    required this.blushColor,
  });

  final BorderRadius borderRadius;

  /// Where the cat sits along the top edge, from the start (0) to the end
  /// (1). Mirrored in right-to-left layouts.
  final double alignment;

  /// How much of the cat shows: 0 hides it, 1 shows all of it.
  final double peek;

  final Color lineColor;
  final Color innerEarColor;
  final Color irisColor;
  final Color pupilColor;
  final Color blushColor;

  @override
  CatPeekBorder copyWith({
    BorderSide? side,
    BorderRadius? borderRadius,
    double? alignment,
    double? peek,
    Color? lineColor,
    Color? innerEarColor,
    Color? irisColor,
    Color? pupilColor,
    Color? blushColor,
  }) => CatPeekBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
    alignment: alignment ?? this.alignment,
    peek: peek ?? this.peek,
    lineColor: lineColor ?? this.lineColor,
    innerEarColor: innerEarColor ?? this.innerEarColor,
    irisColor: irisColor ?? this.irisColor,
    pupilColor: pupilColor ?? this.pupilColor,
    blushColor: blushColor ?? this.blushColor,
  );

  @override
  CatPeekBorder scale(double t) =>
      copyWith(side: side.scale(t), borderRadius: borderRadius * t, peek: (peek * t).clamp(0, 1));

  factory CatPeekBorder.lerp(CatPeekBorder a, CatPeekBorder b, double t) => CatPeekBorder(
    side: BorderSide.lerp(a.side, b.side, t),
    borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
    alignment: lerpDouble(a.alignment, b.alignment, t)!,
    peek: lerpDouble(a.peek, b.peek, t)!,
    lineColor: Color.lerp(a.lineColor, b.lineColor, t)!,
    innerEarColor: Color.lerp(a.innerEarColor, b.innerEarColor, t)!,
    irisColor: Color.lerp(a.irisColor, b.irisColor, t)!,
    pupilColor: Color.lerp(a.pupilColor, b.pupilColor, t)!,
    blushColor: Color.lerp(a.blushColor, b.blushColor, t)!,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    return switch (a) {
      final CatPeekBorder from => CatPeekBorder.lerp(from, this, t),
      final RoundedRectangleBorder from => CatPeekBorder.lerp(
        copyWith(side: from.side, borderRadius: from.borderRadius.resolve(TextDirection.ltr), peek: 0),
        this,
        t,
      ),
      _ => super.lerpFrom(a, t),
    };
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    return switch (b) {
      final CatPeekBorder to => CatPeekBorder.lerp(this, to, t),
      final RoundedRectangleBorder to => CatPeekBorder.lerp(
        this,
        copyWith(side: to.side, borderRadius: to.borderRadius.resolve(TextDirection.ltr), peek: 0),
        t,
      ),
      _ => super.lerpTo(b, t),
    };
  }

  _PeekingCat? _cat(Rect rect, TextDirection? textDirection) {
    if (peek <= .01) return null;
    final double width = (rect.width * .2).clamp(56, 80) * peek;
    // keep the paws off the rounded corners
    final double margin = borderRadius.topLeft.x + width * .85;
    if (rect.width < margin * 2) return null;
    final double align = textDirection == TextDirection.rtl ? 1 - alignment : alignment;
    final double cx = (rect.left + rect.width * align).clamp(rect.left + margin, rect.right - margin);
    return _PeekingCat(cx, rect.top, width);
  }

  RRect _body(Rect rect) => borderRadius.toRRect(rect);

  Path _path(Rect rect, TextDirection? textDirection) {
    final Path body = Path()..addRRect(_body(rect));
    final _PeekingCat? cat = _cat(rect, textDirection);
    if (cat == null) return body;
    // one region at a time: the parts overlap and may wind either way
    Path path = Path.combine(PathOperation.union, body, cat.head);
    for (final part in [cat.leftEar.outer, cat.rightEar.outer, cat.leftPaw, cat.rightPaw]) {
      path = Path.combine(PathOperation.union, path, part);
    }
    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect, textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_body(rect).deflate(math.max(side.strokeInset, 0)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final _PeekingCat? cat = _cat(rect, textDirection);
    if (cat != null) cat.paintFace(canvas, this);
    if (side.style == BorderStyle.solid) {
      canvas.drawPath(_path(rect.inflate(side.strokeOffset / 2), textDirection), side.toPaint());
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatPeekBorder &&
        other.side == side &&
        other.borderRadius == borderRadius &&
        other.alignment == alignment &&
        other.peek == peek &&
        other.lineColor == lineColor &&
        other.innerEarColor == innerEarColor &&
        other.irisColor == irisColor &&
        other.pupilColor == pupilColor &&
        other.blushColor == blushColor;
  }

  @override
  int get hashCode =>
      Object.hash(side, borderRadius, alignment, peek, lineColor, innerEarColor, irisColor, pupilColor, blushColor);

  @override
  String toString() => '${objectRuntimeType(this, 'CatPeekBorder')}($side, $borderRadius, peek: $peek)';
}

/// The cat over a dialog's top edge, [width] wide, centered on [cx].
class _PeekingCat {
  _PeekingCat(this.cx, this.edge, this.width)
    : rise = width * .4,
      leftEar = CatEarGeometry.build(
        baseCenter: Offset(cx - width * .26, edge - width * .4 * .6),
        halfBase: width * .17,
        length: width * .36,
        tilt: -.32,
      ),
      rightEar = CatEarGeometry.build(
        baseCenter: Offset(cx + width * .26, edge - width * .4 * .6),
        halfBase: width * .17,
        length: width * .36,
        tilt: .32,
      );

  final double cx;
  final double edge;
  final double width;
  final double rise;
  final CatEarGeometry leftEar;
  final CatEarGeometry rightEar;

  double get _half => width / 2;

  Path get head => Path()
    ..moveTo(cx - _half, edge + 6)
    ..lineTo(cx - _half, edge - rise * .35)
    ..cubicTo(cx - _half, edge - rise * .9, cx - width * .28, edge - rise, cx, edge - rise)
    ..cubicTo(cx + width * .28, edge - rise, cx + _half, edge - rise * .9, cx + _half, edge - rise * .35)
    ..lineTo(cx + _half, edge + 6)
    ..close();

  Offset _pawCenter(double side) => Offset(cx + side * width * .68, edge + 1);
  Size get _pawSize => Size(width * .3, width * .22);

  Path get leftPaw =>
      Path()..addOval(Rect.fromCenter(center: _pawCenter(-1), width: _pawSize.width, height: _pawSize.height));
  Path get rightPaw =>
      Path()..addOval(Rect.fromCenter(center: _pawCenter(1), width: _pawSize.width, height: _pawSize.height));

  void paintFace(Canvas canvas, CatPeekBorder style) {
    // the inside of the ears, where they stand clear of the head
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromCenter(center: Offset(cx, edge), width: width * 4, height: width * 4)),
          head,
        ),
      );
    final Paint innerEar = Paint()..color = style.innerEarColor;
    canvas
      ..drawPath(leftEar.inner, innerEar)
      ..drawPath(rightEar.inner, innerEar)
      ..restore();

    final Paint line = Paint()
      ..color = style.lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, width * .025)
      ..strokeCap = StrokeCap.round;

    // tabby stripes on the forehead
    for (final double dx in [-.09, 0, .09]) {
      canvas.drawLine(
        Offset(cx + width * dx, edge - rise * .96),
        Offset(cx + width * dx * .8, edge - rise * (dx == 0 ? .74 : .8)),
        line,
      );
    }

    // eyes, looking down at the dialog
    final double eyeY = edge - rise * .4;
    final Size eye = Size(width * .17, width * .19);
    for (final double side in [-1, 1]) {
      final Offset center = Offset(cx + side * width * .2, eyeY);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: eye.width, height: eye.height),
        Paint()..color = style.irisColor,
      );
      canvas.drawOval(
        Rect.fromCenter(center: center + Offset(0, eye.height * .16), width: eye.width * .42, height: eye.height * .74),
        Paint()..color = style.pupilColor,
      );
      canvas.drawCircle(
        center + Offset(-eye.width * .16, -eye.height * .14),
        eye.width * .13,
        Paint()..color = Colors.white.withValues(alpha: .9),
      );
      // blush, just above the edge
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * width * .33, edge - rise * .1),
          width: width * .18,
          height: width * .08,
        ),
        Paint()..color = style.blushColor.withValues(alpha: .45),
      );
    }

    // toes: two short lines split each paw into three beans
    for (final double side in [-1, 1]) {
      final Offset paw = _pawCenter(side);
      for (final double dx in [-.17, .17]) {
        canvas.drawLine(
          paw + Offset(_pawSize.width * dx, -_pawSize.height * .48),
          paw + Offset(_pawSize.width * dx, -_pawSize.height * .1),
          line,
        );
      }
    }
  }
}
