import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that animates the target between the specified [begin] and [end]
/// alignments (via [Align]).
/// Defaults to `begin=Align.topCenter, end=Align.center`.
@immutable
class AlignEffect extends Effect<Alignment> {
  static const Alignment neutralValue = Alignment.center;
  static const Alignment defaultValue = Alignment.topCenter;

  const AlignEffect({
    super.delay,
    super.duration,
    super.curve,
    Alignment? begin,
    Alignment? end,
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
    Animation<Alignment> animation = buildAnimation(controller, entry);
    return getOptimizedBuilder<Alignment>(
      animation: animation,
      builder: (_, __) {
        return Align(
          alignment: animation.value,
          child: child,
        );
      },
    );
  }
}

/// Adds [AlignEffect] related extensions to [AnimateManager].
extension AlignEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds an [AlignEffect] that animates the target between the specified
  /// [begin] and [end] alignments (via [Align]).
  T align({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Alignment? begin,
    Alignment? end,
  }) =>
      addEffect(AlignEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
      ));
}
