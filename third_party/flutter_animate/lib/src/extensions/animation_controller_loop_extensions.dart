import 'package:flutter/widgets.dart';

/// Adds a [loop] extension on [AnimationController] identical to [repeat] but
/// adding a `count` parameter specifying how many times to repeat before stopping:
///
///   - `count = null`: the animation loops infinitely
///   - `count = 0`: the animation won't play
///   - `count > 0`: the animation will play `count` times
///
/// The total time will always be `count * duration` (or `count * period` if specified).
/// Therefore, if `reverse` is true, one "count" is still considered animating in a single direction.
///
/// For example, the following would play forward (fade in) and back (fade out) once, then stop:
///
/// ```
/// Text('Hello World').animate(
///   onPlay: (controller) => controller.loop(
///     reverse: true,
///     count: 2,
///   ),
/// ).fadeIn();
/// ```
extension AnimationControllerLoopExtensions on AnimationController {
  TickerFuture loop({
    int? count,
    bool reverse = false,
    double? min,
    double? max,
    Duration? period,
  }) {
    assert(count == null || count >= 0);
    assert(period != null || duration != null);

    min ??= lowerBound;
    max ??= upperBound;
    period ??= duration;

    if (count == 0) return animateTo(min, duration: Duration.zero);

    final tickerFuture = repeat(
      min: min,
      max: max,
      reverse: reverse,
      period: period,
    );

    if (count != null) {
      // timeout ~1 tick before it should complete (@120hz):
      int t = period!.inMilliseconds * count - 8;
      tickerFuture.timeout(Duration(milliseconds: t), onTimeout: () async {
        if (isAnimating) animateTo(reverse && count.isEven ? min! : max!);
      });
    }

    return tickerFuture;
  }
}
