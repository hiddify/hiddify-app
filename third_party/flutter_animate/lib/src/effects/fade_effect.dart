import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// Animates the opacity of the target between the specified
/// [begin] and [end] values (via [FadeTransition]).
/// It defaults to `begin=0, end=1`.
@immutable
class FadeEffect extends Effect<double> {
  static const double neutralValue = 1.0;
  static const double defaultValue = 0.0;

  const FadeEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
  }) : super(
          begin: begin ?? (end == null ? defaultValue : neutralValue),
          end: end ?? neutralValue,
        );

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    return FadeTransition(
      opacity: buildAnimation(controller, entry),
      child: child,
    );
  }
}

/// Adds [FadeEffect] related extensions to [AnimateManager].
extension FadeEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [FadeEffect] that animates the opacity of the target between the
  /// specified [begin] and [end] values (via [FadeTransition]).
  T fade({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      addEffect(FadeEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
      ));

  /// Adds a [FadeEffect] that animates the opacity of the target between the
  /// specified [begin] value and `1.0` (via [FadeTransition]).
  T fadeIn({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
  }) =>
      addEffect(FadeEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin ?? FadeEffect.defaultValue,
        end: 1.0,
      ));

  /// Adds a [FadeEffect] that animates the opacity of the target between `0.0`
  /// and the specified [end] value (via [FadeTransition]).
  T fadeOut({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
  }) =>
      addEffect(FadeEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin ?? FadeEffect.neutralValue,
        end: 0.0,
      ));
}
