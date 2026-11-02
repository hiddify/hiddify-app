import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that calls a [callback] function with its current animation value
/// between [begin] and [end].
///
/// By default, the callback will only be called while this effect is "active"
/// (ie. after delay, and before duration) and will return a value between 0-1
/// (unless the curve transforms it beyond this range). If [clamp] is set to `false`,
/// the callback will be called on every tick while the enclosing [Animate] is
/// running, and may return values outside its nominal range (ex. it will return a
/// negative value before delay).
///
/// This example will print the current animation value (which matches the value
/// of the preceding fade effect's opacity value):
///
/// ```
/// Text("Hello").animate().fadeIn(curve: Curves.easeOutExpo)
///  .listen(callback: (value) => print('current opacity: $value'))
/// ```
///
/// This can easily be used to drive a [ValueNotifier]:
///
/// ```
/// ValueNotifier<double> notifier = ValueNotifier<double>(0);
/// Text("Hello").animate()
///   .fadeIn(delay: 400.ms, duration: 900.ms)
///   .listen(callback: (value) => notifier.value)
/// ```
///
/// See also: [CustomEffect] and [CallbackEffect].
@immutable
class ListenEffect extends Effect<double> {
  const ListenEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    required this.callback,
    this.clamp = true,
  }) : super(
          begin: begin ?? 0.0, // Should this use "smart" defaults?
          end: end ?? 1.0,
        );

  final ValueChanged<double> callback;
  final bool clamp;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    // build an animation without a curve, so we get a linear 0-1 value back so we can determine start / end.
    Animation<double> animation = entry.buildAnimation(
      controller,
      curve: Curves.linear,
    );
    double prev = 0.0, begin = this.begin ?? 0.0, end = this.end ?? 1.0;
    animation.addListener(() {
      double value = animation.value;
      if (!clamp || value != prev) {
        callback(begin + (end - begin) * entry.curve.transform(value));
        prev = value;
      }
    });
    return child;
  }
}

/// Adds [ListenEffect] related extensions to [AnimateManager].
extension ListenEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [ListenEffect] that calls a [callback] function with its current animation value
  /// between [begin] and [end].
  T listen({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    required ValueChanged<double> callback,
    bool clamp = true,
  }) =>
      addEffect(ListenEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        callback: callback,
        clamp: clamp,
      ));
}
