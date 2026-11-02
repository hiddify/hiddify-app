import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

// Note: this whole thing is pretty messy / complex because AnimationController
// wasn't really designed to support this. For example, it doesn't provide any
// status changes when looping, and it emits a "value change" event when status
// changes, even though the value didn't change. As such, there's a lot of fussy
// logic. It also doesn't work super well if the value is updated manually,
// ex. with an adapter.

/// An effect that calls a [callback] function at a particular point in the animation.
/// It includes a boolean value indicating if the animation is playing in reverse.
///
/// This example would execute the callback halfway through the animation:
///
/// ```
/// Text("Hello")
///   .animate(onPlay: (controller) => controller.repeat(reverse: true))
///   .fadeIn(duration: 600.ms)
///   .callback(
///     duration: 300.ms,
///     callback: (rev) => print('halfway (reverse: $rev)')
///   )
/// ```
///
/// **NOTE:** This should be reliable for time-based animations, but callbacks on
/// an animation that is driven by an [Adapter] (or manipulated via its controller)
/// may behave unexpectedly in certain circumstances.
///
/// See also: [CustomEffect] and [ListenEffect].
@immutable
class CallbackEffect extends Effect<void> {
  const CallbackEffect({
    super.delay,
    super.duration,
    super.curve,
    required this.callback,
  });

  final ValueChanged<bool> callback;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    // instead of setting up an animation, we can optimize a bit to calculate the callback time once:
    double ratio = getEndRatio(controller, entry);
    double prevVal = controller.value;
    AnimationStatus prevStatus = controller.status;
    controller.addListener(() {
      double val = controller.value;
      AnimationStatus status = controller.status;
      if (val == prevVal && status == prevStatus) return;

      if (!controller.isAnimating) {
        // adapter (probably!)
        _resolve(ratio, prevVal, val, callback);
      } else if (status == AnimationStatus.forward) {
        if (prevStatus == AnimationStatus.dismissed) {
          // just started (probably)
          _resolve(ratio, controller.lowerBound - 1, val, callback);
        } else if (prevStatus == AnimationStatus.reverse) {
          // repeated from reverse to forward (probably)
          _resolve(ratio, prevVal, controller.lowerBound, callback);
          _resolve(ratio, controller.lowerBound, val, callback);
        } else if (val < prevVal) {
          // repeated forward to forward (probably)
          _resolve(ratio, prevVal, controller.upperBound, callback);
          _resolve(ratio, controller.lowerBound - 1, val, callback);
        } else {
          // playing forward (probably)
          _resolve(ratio, prevVal, val, callback);
        }
      } else if (status == AnimationStatus.reverse) {
        if (prevStatus == AnimationStatus.dismissed) {
          // just started (probably)
          _resolve(ratio, controller.upperBound + 1, val, callback);
        } else if (prevStatus == AnimationStatus.forward) {
          // repeated from forward to reverse (probably)
          _resolve(ratio, prevVal, controller.upperBound, callback);
          _resolve(ratio, controller.upperBound, val, callback);
        } else if (val > prevVal) {
          // repeated reverse to reverse (probably)
          _resolve(ratio, prevVal, controller.lowerBound, callback);
          _resolve(ratio, controller.upperBound + 1, val, callback);
        } else {
          // playing in reverse (probably)
          _resolve(ratio, prevVal, val, callback);
        }
      }
      prevVal = val;
      prevStatus = status;
    });
    return child;
  }

  void _resolve(double v, double v0, double v1, ValueChanged<bool> callback) {
    bool reverse = v0 > v1;
    if ((!reverse && v > v0 && v <= v1) || (reverse && v < v0 && v >= v1)) {
      callback(reverse);
    }
  }
}

/// Adds [CallbackEffect] related extensions to [AnimateManager].
extension CallbackEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [CallbackEffect] that calls a [callback] function at a particular point in the animation.
  /// It includes a boolean value indicating if the animation is playing in reverse.
  T callback({
    Duration? delay,
    Duration? duration,
    required ValueChanged<bool> callback,
  }) =>
      addEffect(CallbackEffect(
        delay: delay,
        duration: duration,
        callback: callback,
      ));
}
