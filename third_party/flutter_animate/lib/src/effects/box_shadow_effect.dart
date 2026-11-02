import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that animates a [BoxShadow] between [begin] and [end] (via [DecoratedBox]).
/// A value of `null` for either will be interpreted as a shadow that matches the other shadow but
/// with a zero offset and blurRadius.
/// You can also specify a [borderRadius] that defines rounded corners for the shadow.
/// Defaults to `begin=null, end=BoxShadow(color: Color(0x80000000), blurRadius: 8.0, offset: Offset(0.0, 4.0))`
///
/// This can also be used for glow effects (by setting a `0` offset, and a color).
///
/// See also: [ElevationEffect] for simpler animated shadows based on elevation.
@immutable
class BoxShadowEffect extends Effect<BoxShadow> {
  static const BoxShadow? neutralValue = null;
  static const BoxShadow defaultValue = BoxShadow(
      color: Color(0x80000000), blurRadius: 8.0, offset: Offset(0.0, 4.0));

  const BoxShadowEffect({
    super.delay,
    super.duration,
    super.curve,
    BoxShadow? begin,
    BoxShadow? end,
    this.borderRadius,
  }) : super(
          begin: begin ?? neutralValue,
          end: end ?? (begin == null ? defaultValue : neutralValue),
        );

  final BorderRadius? borderRadius;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    Animation<double> animation = entry.buildAnimation(controller);
    return getOptimizedBuilder<double>(
      animation: animation,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow.lerp(begin, end, animation.value)!],
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

/// Adds [BoxShadowEffect] related extensions to [AnimateManager].
extension BoxShadowEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [BoxShadowEffect] which  animates a [BoxShadow] between
  /// [begin] and [end] (via [DecoratedBox]).
  T boxShadow({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    BoxShadow? begin,
    BoxShadow? end,
    BorderRadius? borderRadius,
  }) =>
      addEffect(BoxShadowEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        borderRadius: borderRadius,
      ));
}
