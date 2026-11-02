import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that swaps out the incoming child for a new child at a particular
/// point in time. This includes all preceding effects. It uses a [builder] so
/// that the effect can be reused, but note that the builder is only called once
/// when the effect initially builds.
///
/// For example, this would fade out `foo`, swap it for `Bar()` (including
/// discarding the `fadeOut` effect) and apply a fade in effect.
///
/// ```
/// foo.animate()
///   .fadeOut(duration: 500.ms)
///   .swap( // inherits duration from fadeOut
///     builder: (_, __) => Bar().animate().fadeIn(),
///   )
/// ```
///
/// It also includes the original child of the animation as a parameter of the
/// builder. For example, normally fading out and then back in will not work
/// as expected because both effects are active (ie. the 0 opacity from
/// fading out is still applied), but you can work around this by beginning a
/// new animation with the original child:
///
/// ```
/// foo.animate()
///   .fadeOut(duration: 500.ms)
///   .swap( // inherits duration from fadeOut
///     builder: (_, originalChild) => originalChild.animate().fadeIn(),
///   )
/// ```
///
/// Note that the builder is returning a new [Animate] instance with its own
/// [AnimationController]. So, for example, repeating the first animation (the
/// fade out) via its controller will not affect the second animation (fade in).
@immutable
class SwapEffect extends Effect<void> {
  const SwapEffect({
    super.delay,
    super.duration,
    super.curve,
    required this.builder,
  });

  final Widget Function(BuildContext, Widget) builder;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    // instead of setting up an animation, we can optimize a bit to calculate the callback time once:
    double ratio = getEndRatio(controller, entry);
    Widget endChild = builder(context, entry.owner.child);

    // this could use toggleBuilder, but everything is pre-built, so this is simpler:
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => (controller.value < ratio) ? child : endChild,
    );
  }
}

/// Adds [SwapEffect] related extensions to [AnimateManager].
extension SwapEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [SwapEffect] that swaps out the incoming child for a new child at a particular
  /// point in time. This includes all preceding effects.
  T swap({
    Duration? delay,
    Duration? duration,
    required TransitionBuilder builder,
  }) =>
      addEffect(SwapEffect(
        delay: delay,
        duration: duration,
        builder: builder,
      ));
}
