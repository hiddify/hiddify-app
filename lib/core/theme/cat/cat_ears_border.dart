import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A rounded rectangle with two cat ears on its top edge.
///
/// The ears stick out above the rect the shape is given, the way a shadow
/// does: they take no room in the layout and catch no taps, so a button keeps
/// its size and its hit area. Give a button a different ear per state and the
/// [Material] underneath animates between them: ears perk up on press and
/// droop when the button is disabled.
@immutable
class CatEarsBorder extends OutlinedBorder {
  const CatEarsBorder({
    super.side,
    this.borderRadius,
    required this.earHeight,
    this.earWidth,
    this.earSpread = .3,
    this.earInset,
    this.earTilt = 0,
    this.innerEarColor,
  });

  /// The corners. Null makes a stadium, as round as the height allows.
  final BorderRadius? borderRadius;

  /// How far the ear tips reach above the top edge.
  final double earHeight;

  /// The width of an ear at its base. Defaults to 1.5 × [earHeight].
  final double? earWidth;

  /// Where the ears sit along the top edge when [earInset] is null: 0 puts
  /// them next to the corners, 1 brings them together in the middle.
  final double earSpread;

  /// The distance from a side edge to the middle of the ear next to it.
  /// Overrides [earSpread]; handy on wide surfaces such as bottom sheets.
  final double? earInset;

  /// Turns the ear tips outward, in radians: positive is a droopy, sleepy
  /// cat, negative an alert one.
  final double earTilt;

  /// Paints the inside of the ears. Null leaves them plain.
  final Color? innerEarColor;

  double get _earWidth => earWidth ?? earHeight * 1.5;

  bool get _hasEars => earHeight > .5;

  @override
  CatEarsBorder copyWith({
    BorderSide? side,
    BorderRadius? borderRadius,
    double? earHeight,
    double? earWidth,
    double? earSpread,
    double? earInset,
    double? earTilt,
    Color? innerEarColor,
  }) => CatEarsBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
    earHeight: earHeight ?? this.earHeight,
    earWidth: earWidth ?? this.earWidth,
    earSpread: earSpread ?? this.earSpread,
    earInset: earInset ?? this.earInset,
    earTilt: earTilt ?? this.earTilt,
    innerEarColor: innerEarColor ?? this.innerEarColor,
  );

  @override
  CatEarsBorder scale(double t) => CatEarsBorder(
    side: side.scale(t),
    borderRadius: borderRadius == null ? null : borderRadius! * t,
    earHeight: earHeight * t,
    earWidth: earWidth == null ? null : earWidth! * t,
    earSpread: earSpread,
    earInset: earInset == null ? null : earInset! * t,
    earTilt: earTilt,
    innerEarColor: innerEarColor,
  );

  /// Interpolates two eared shapes. A stadium is treated as a rect with very
  /// round corners, so it can blend with a plain rounded one.
  factory CatEarsBorder.lerp(CatEarsBorder a, CatEarsBorder b, double t) {
    if (t == 0) return a;
    if (t == 1) return b;
    final BorderRadius? radius = a.borderRadius == null && b.borderRadius == null
        ? null
        : BorderRadius.lerp(a.borderRadius ?? _stadiumRadius, b.borderRadius ?? _stadiumRadius, t);
    return CatEarsBorder(
      side: BorderSide.lerp(a.side, b.side, t),
      borderRadius: radius,
      earHeight: lerpDouble(a.earHeight, b.earHeight, t)!,
      earWidth: a.earWidth == null && b.earWidth == null ? null : lerpDouble(a._earWidth, b._earWidth, t),
      earSpread: lerpDouble(a.earSpread, b.earSpread, t)!,
      earInset: a.earInset == null || b.earInset == null
          ? (t < .5 ? a.earInset : b.earInset)
          : lerpDouble(a.earInset, b.earInset, t),
      earTilt: lerpDouble(a.earTilt, b.earTilt, t)!,
      innerEarColor: Color.lerp(a.innerEarColor, b.innerEarColor, t),
    );
  }

  static const BorderRadius _stadiumRadius = BorderRadius.all(Radius.circular(9999));

  /// The same shape without ears, so plain shapes from other themes grow
  /// ears smoothly instead of jumping.
  CatEarsBorder _earless(BorderSide side, BorderRadius? radius) =>
      copyWith(side: side, borderRadius: radius ?? _stadiumRadius, earHeight: 0);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    return switch (a) {
      final CatEarsBorder from => CatEarsBorder.lerp(from, this, t),
      final RoundedRectangleBorder from => CatEarsBorder.lerp(
        _earless(from.side, from.borderRadius.resolve(TextDirection.ltr)),
        this,
        t,
      ),
      final StadiumBorder from => CatEarsBorder.lerp(_earless(from.side, null), this, t),
      _ => super.lerpFrom(a, t),
    };
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    return switch (b) {
      final CatEarsBorder to => CatEarsBorder.lerp(this, to, t),
      final RoundedRectangleBorder to => CatEarsBorder.lerp(
        this,
        _earless(to.side, to.borderRadius.resolve(TextDirection.ltr)),
        t,
      ),
      final StadiumBorder to => CatEarsBorder.lerp(this, _earless(to.side, null), t),
      _ => super.lerpTo(b, t),
    };
  }

  RRect _body(Rect rect) {
    final double maxRadius = math.min(rect.width, rect.height) / 2;
    if (borderRadius == null) return RRect.fromRectAndRadius(rect, Radius.circular(maxRadius));
    Radius clamp(Radius r) => Radius.elliptical(math.min(r.x, rect.width / 2), math.min(r.y, rect.height / 2));
    return RRect.fromRectAndCorners(
      rect,
      topLeft: clamp(borderRadius!.topLeft),
      topRight: clamp(borderRadius!.topRight),
      bottomLeft: clamp(borderRadius!.bottomLeft),
      bottomRight: clamp(borderRadius!.bottomRight),
    );
  }

  /// The two ears, or nothing when the rect is too small to carry them.
  List<CatEarGeometry> _ears(Rect rect) {
    if (!_hasEars || rect.width < _earWidth * 2.4 || rect.height < 4) return const [];
    final RRect body = _body(rect);
    final double halfBase = _earWidth / 2;
    final double minInset = math.max(halfBase * 1.2, math.min(body.tlRadiusX, body.trRadiusX) * .5);
    final double maxInset = math.max(minInset, rect.width / 2 - halfBase * 1.1);
    final double inset = (earInset ?? lerpDouble(minInset, maxInset, earSpread.clamp(0, 1))!).clamp(minInset, maxInset);

    // The base sits a little inside the body, deep enough that its corners
    // are covered even where they land on a rounded corner.
    double depthAt(double dx, Radius corner) {
      if (corner.x <= 0 || dx >= corner.x) return 0;
      final double u = (corner.x - dx) / corner.x;
      return corner.y * (1 - math.sqrt(math.max(0, 1 - u * u)));
    }

    final double depth = math.min(
      rect.height / 2,
      math.max(depthAt(inset - halfBase, body.tlRadius), depthAt(inset - halfBase, body.trRadius)) + 1.5,
    );

    return [
      CatEarGeometry.build(
        baseCenter: Offset(rect.left + inset, rect.top + depth),
        halfBase: halfBase,
        length: earHeight + depth,
        tilt: -earTilt,
      ),
      CatEarGeometry.build(
        baseCenter: Offset(rect.right - inset, rect.top + depth),
        halfBase: halfBase,
        length: earHeight + depth,
        tilt: earTilt,
      ),
    ];
  }

  Path _path(Rect rect) {
    final Path body = Path()..addRRect(_body(rect));
    final List<CatEarGeometry> ears = _ears(rect);
    if (ears.isEmpty) return body;
    final Path earPaths = Path();
    for (final ear in ears) {
      earPaths.addPath(ear.outer, Offset.zero);
    }
    return Path.combine(PathOperation.union, body, earPaths);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_body(rect).deflate(math.max(side.strokeInset, 0)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (innerEarColor != null && _hasEars) {
      final Paint paint = Paint()..color = innerEarColor!;
      canvas.save();
      // only the part of the ear above the edge: the rest is the face
      canvas.clipRect(
        Rect.fromLTRB(rect.left - earHeight * 4, rect.top - earHeight * 4, rect.right + earHeight * 4, rect.top),
      );
      for (final ear in _ears(rect)) {
        canvas.drawPath(ear.inner, paint);
      }
      canvas.restore();
    }
    switch (side.style) {
      case BorderStyle.none:
        return;
      case BorderStyle.solid:
        if (side.width == 0) {
          canvas.drawPath(_path(rect), side.toPaint());
        } else {
          canvas.drawPath(_path(rect.inflate(side.strokeOffset / 2)), side.toPaint());
        }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatEarsBorder &&
        other.side == side &&
        other.borderRadius == borderRadius &&
        other.earHeight == earHeight &&
        other.earWidth == earWidth &&
        other.earSpread == earSpread &&
        other.earInset == earInset &&
        other.earTilt == earTilt &&
        other.innerEarColor == innerEarColor;
  }

  @override
  int get hashCode => Object.hash(side, borderRadius, earHeight, earWidth, earSpread, earInset, earTilt, innerEarColor);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CatEarsBorder')}($side, $borderRadius, earHeight: $earHeight, earTilt: $earTilt)';
}

/// One cat ear: a triangle with a rounded tip, plus the smaller inside of it.
@immutable
class CatEarGeometry {
  const CatEarGeometry._(this.outer, this.inner, this.tip);

  /// Builds an ear standing on [baseCenter], reaching [length] up.
  ///
  /// [tilt] turns the tip around the middle of the base, in radians; positive
  /// turns it to the right. The base stays put, so an ear tucked into a head
  /// never shows a gap however far it turns.
  factory CatEarGeometry.build({
    required Offset baseCenter,
    required double halfBase,
    required double length,
    double tilt = 0,
    double tipRoundness = .28,
  }) {
    final Offset left = baseCenter.translate(-halfBase, 0);
    final Offset right = baseCenter.translate(halfBase, 0);
    final Offset tip = baseCenter + Offset(math.sin(tilt) * length, -math.cos(tilt) * length);

    Path triangle(Offset a, Offset apex, Offset b, double round) {
      final Offset beforeTip = Offset.lerp(a, apex, 1 - round)!;
      final Offset afterTip = Offset.lerp(apex, b, round)!;
      return Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(beforeTip.dx, beforeTip.dy)
        ..quadraticBezierTo(apex.dx, apex.dy, afterTip.dx, afterTip.dy)
        ..lineTo(b.dx, b.dy)
        ..close();
    }

    final Offset centroid = (left + right + tip) / 3;
    Offset shrink(Offset p) => centroid + (p - centroid) * .56 + (tip - centroid) * .12;

    return CatEarGeometry._(
      triangle(left, tip, right, tipRoundness),
      triangle(shrink(left), shrink(tip), shrink(right), tipRoundness * 1.2),
      tip,
    );
  }

  final Path outer;
  final Path inner;
  final Offset tip;
}
