import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that applies an animated [color] tint to the target (via [ColorFiltered]).
/// The [begin] and [end] values indicate the strength of the tint (0 - 0% tint, 1 - 100% tint).
/// Defaults to `begin=0, end=1`.
///
/// The default [color] is opaque black (`Color(0xFF000000)`).
/// The opacity of [color] is multiplied against the strength.
/// For example, `Colors.black54` at strength `0.5` would apply a 27%
/// black tint.
///
/// This example would animate in a 50% blue tint over 2 seconds:
///
/// ```
/// Image.asset('assets/rainbow.jpg').animate()
///   .tint(color: Colors.blue, end: 0.5, duration: 2.seconds)
/// ```
///
/// See also: [ColorEffect], which animates between two different colors, and
/// supports blend modes.
@immutable
class TintEffect extends Effect<double> {
  static const double neutralValue = 0.0;
  static const double defaultValue = 1.0;

  const TintEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    Color? color,
  })  : color = color ?? const Color(0xFF000000),
        super(
          begin: begin ?? neutralValue,
          end: end ?? (begin == null ? defaultValue : neutralValue),
        );

  final Color color;

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
      builder: (_, __) => ColorFiltered(
        colorFilter: ColorFilter.matrix(getTintMatrix(animation.value, color)),
        child: child,
      ),
    );
  }

  static List<double> getTintMatrix(double strength, Color color) {
    double v = 1 - strength * color.alpha / 255;

    return <double>[
      v, 0, 0, 0, color.red * (1 - v), // r
      0, v, 0, 0, color.green * (1 - v), // g
      0, 0, v, 0, color.blue * (1 - v), // b
      0, 0, 0, 1, 0, // a
    ];
  }
}

/// Adds [TintEffect] related extensions to [AnimateManager].
extension TintEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [TintEffect] that applies an animated [color] tint to the target (via [ColorFiltered]).
  /// Defaults to a begin value of `0` (0% tint) and an end value of `1` (100% tint).
  T tint({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Color? color,
  }) =>
      addEffect(TintEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        color: color,
      ));

  /// Adds a [TintEffect] that applies an animated [color] tint to the target (via [ColorFiltered]).
  /// Defaults to a begin value of `1` (100% tint) and an end value of `0` (0% tint).
  T untint({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Color? color,
  }) =>
      addEffect(TintEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin ?? 1.0,
        end: end ?? TintEffect.neutralValue,
        color: color,
      ));
}
