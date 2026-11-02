import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// Effect that rotates the target between [begin] and [end] (via [RotationTransition]).
/// Values are specified in "turns" (360° or 2𝝅 radians), so a `begin=0.25, end=2.25` would start with the child
/// rotated a quarter turn clockwise (90 degrees), and rotate two full turns (ending at 810 degrees).
/// Defaults to `begin=-1.0, end=0`.
///
/// [alignment] lets you set the origin of the rotation (the point around which the rotation
/// will occur). For example an alignment of [Alignment.topLeft] would rotate around the top left
/// corner of the child. Defaults to [Alignment.center].
@immutable
class RotateEffect extends Effect<double> {
  static const double neutralValue = 0.0;
  static const double defaultValue = -1.0;
  static const bool defaultTransformHitTests = true;

  const RotateEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    this.alignment,
    bool? transformHitTests,
  })  : transformHitTests = transformHitTests ?? defaultTransformHitTests,
        super(
          begin: begin ?? (end == null ? defaultValue : neutralValue),
          end: end ?? neutralValue,
        );

  final Alignment? alignment;
  final bool transformHitTests;

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
      builder: (_, __) {
        return Transform.rotate(
          angle: animation.value * 2 * math.pi,
          alignment: alignment ?? Alignment.center,
          transformHitTests: transformHitTests,
          child: child,
        );
      },
    );
  }
}

/// Adds [RotateEffect] related extensions to [AnimateManager].
extension RotateEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [RotateEffect] that rotates the target between [begin] and [end] (via [RotationTransition]).
  /// Values are specified in "turns" (360° or 2𝝅 radians).
  T rotate({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Alignment? alignment,
    bool? transformHitTests,
  }) =>
      addEffect(RotateEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        alignment: alignment,
        transformHitTests: transformHitTests,
      ));
}
