import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that animates a Material elevation shadow between [begin] and [end] (via [PhysicalModel]).
/// You can also specify a shadow [color] and [borderRadius] to add rounded corners.
/// It defaults to `begin=0, end=8`.
///
/// See [PhysicalModel] for more information.
///
/// See also: [BoxShadowEffect] for more control over animated shadows.
@immutable
class ElevationEffect extends Effect<double> {
  static const double neutralValue = 0.0;
  static const double defaultValue = 8.0;

  const ElevationEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    Color? color,
    this.borderRadius,
  })  : color = color ?? const Color(0xFF000000),
        super(
          begin: begin ?? neutralValue,
          end: end ?? (begin == null ? defaultValue : neutralValue),
        );

  final Color color;
  final BorderRadius? borderRadius;

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
      builder: (_, __) => PhysicalModel(
        elevation: animation.value,
        shadowColor: color,
        color: const Color(0x00000000),
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

/// Adds [ElevationEffect] related extensions to [AnimateManager].
extension ElevationEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds an [ElevationEffect] that animates a Material elevation shadow between [begin] and [end] (via [PhysicalModel]).
  /// You can also specify a shadow [color] and [borderRadius] to add rounded corners.
  T elevation({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Color? color,
    BorderRadius? borderRadius,
  }) =>
      addEffect(ElevationEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        color: color,
        borderRadius: borderRadius,
      ));
}
