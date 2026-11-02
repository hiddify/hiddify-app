import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that animates a 2.5D card flip rotation effect (via [Transform]).
/// The effect can be horizontal or vertical.
///
/// The [begin] and [end] values specify the number of "flips" (ie. half turns,
/// 180° or 𝝅 radians) from nominal. For example, `0.5` would be a 90 degree
/// rotation (half a "flip").
/// It defaults to `begin=-0.5, end=0`.
///
/// [alignment] lets you set the origin of the rotation (ie. the point around which the rotation
/// will occur). For example an alignment of [Alignment.topCenter] would rotate around the top
/// of the child on a vertical flip. Default is [Alignment.center].
///
/// [perspective] lets you adjust the focal length for the 2.5D effect. A higher number
/// increases perspective transform (ie. reduces focal length). Default is `1`.
///
/// [direction] indicates the direction of the flip. For example [Axis.horizontal]
/// would cause it to rotate around the Y axis — flipping horizontally.
/// Default is [Axis.vertical].
@immutable
class FlipEffect extends Effect<double> {
  static const double neutralValue = 0.0;
  static const double defaultValue = -0.5;

  static const Axis defaultAxis = Axis.vertical;
  static const double defaultPerspective = 1.0;

  const FlipEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    alignment,
    perspective,
    direction,
  })  : alignment = alignment ?? Alignment.center,
        perspective = perspective ?? defaultPerspective,
        direction = direction ?? defaultAxis,
        super(
          begin: begin ?? (end == null ? defaultValue : neutralValue),
          end: end ?? neutralValue,
        );

  final Alignment alignment;
  final double perspective;
  final Axis direction;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    Animation<double> animation = buildAnimation(controller, entry);
    return getOptimizedBuilder<double>(
      animation: animation,
      builder: (_, __) => Transform(
        alignment: alignment,
        transform: getTransformMatrix(animation.value, direction, perspective),
        child: child,
      ),
    );
  }

  static Matrix4 getTransformMatrix(
    double value,
    Axis direction,
    double perspective,
  ) {
    final Matrix4 mtx = Matrix4(
      1.0, 0.0, 0.0, 0.0, //
      0.0, 1.0, 0.0, 0.0, //
      0.0, 0.0, 1.0, 0.002 * perspective, //
      0.0, 0.0, 0.0, 1.0,
    );
    if (value != 0) {
      if (direction == Axis.vertical) {
        mtx.rotateX(value * pi);
      } else {
        mtx.rotateY(value * pi);
      }
    }
    return mtx;
  }
}

/// Adds [FlipEffect] related extensions to [AnimateManager].
extension FlipEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [FlipEffect] that animates a 2.5D card flip rotation effect (via [Transform]).
  /// The effect can be horizontal or vertical.
  /// The [begin] and [end] values specify the number of "flips" (ie. half turns,
  /// 180° or 𝝅 radians) from nominal.
  T flip({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Alignment? alignment,
    double? perspective,
    Axis? direction,
  }) =>
      addEffect(FlipEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        alignment: alignment,
        perspective: perspective,
        direction: direction,
      ));

  /// Adds a [FlipEffect] that animates a horizontal 2.5D card flip rotation effect (via [Transform]).
  /// The [begin] and [end] values specify the number of "flips" (ie. half turns,
  /// 180° or 𝝅 radians) from nominal.
  T flipH({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Alignment? alignment,
    double? perspective,
  }) =>
      addEffect(FlipEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        alignment: alignment,
        perspective: perspective,
        direction: Axis.horizontal,
      ));

  /// Adds a [FlipEffect] that animates a vertical 2.5D card flip rotation effect (via [Transform]).
  /// The [begin] and [end] values specify the number of "flips" (ie. half turns,
  /// 180° or 𝝅 radians) from nominal.
  T flipV({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Alignment? alignment,
    double? perspective,
  }) =>
      addEffect(FlipEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        alignment: alignment,
        perspective: perspective,
        direction: Axis.vertical,
      ));
}
