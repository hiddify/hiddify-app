import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// Drives an [Animate] animation directly from a value in the range `0-1`
///
/// For example, this would fade/slide in text based on the value of a `Slider`:
///
/// ```
/// // note: Slider range defaults to 0-1
/// Slider(
///   value: _sliderVal
///   onChanged: (val) => setState(() => _sliderVal = val)),
/// );
/// Text("Hello").animate(adapter: ValueAdapter(_sliderVal))
///   .fadeIn().slide();
/// ```
///
/// See [Adapter] for information on [direction] and [animated].
class ValueAdapter extends ValueNotifierAdapter {
  ValueAdapter(double value, {bool? animated, Direction? direction})
      : super(
          ValueNotifier<double>(value),
          animated: animated,
          direction: direction,
        );

  set value(double value) => notifier.value = value;
}
