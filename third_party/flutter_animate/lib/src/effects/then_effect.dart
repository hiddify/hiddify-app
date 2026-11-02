import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// A special convenience "effect" that makes it easier to sequence effects after
/// one another. It does this by establishing a new baseline time equal to the
/// previous effect's end time and its own optional [delay].
/// All subsequent effect delays are relative to this new baseline.
///
/// This example demonstrates [ThenEffect] and how it interacts with [delay]:
///
/// ```
/// Text("Hello").animate()
///   .fadeIn(delay: 300.ms, duration: 500.ms) // end @ 800ms
///   .then()                  // baseline=800ms (prior end)
///   .slide(duration: 400.ms) // start @ 800ms, end @ 1200ms
///   .then(delay: 300.ms)     // baseline=1500ms (1200+300)
///   .blur(delay: -150.ms)    // start @ 1350ms (1500-150)
///   .tint()                  // start @ 1350ms (inherited)
///   .shake(delay: 0.ms)      // start @ 1500ms (1500+0)
/// ```
@immutable
class ThenEffect extends Effect<double> {
  // NOTE: this is just an empty effect, the logic happens in Animate
  // when it recognizes the type.
  const ThenEffect({super.delay, super.duration, super.curve});
}

/// Adds [ThenEffect] related extensions to [AnimateManager].
extension ThenEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [ThenEffect] that makes it easier to sequence effects after
  /// one another. It does this by establishing a new baseline time equal to the
  /// previous effect's end time and its own optional [delay].
  /// All subsequent effect delays are relative to this new baseline.
  T then({Duration? delay, Duration? duration, Curve? curve}) =>
      addEffect(ThenEffect(delay: delay, duration: duration, curve: curve));
}
