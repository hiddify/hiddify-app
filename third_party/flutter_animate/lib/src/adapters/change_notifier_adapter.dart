import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// Drives an [Animate] animation from a [ChangeNotifier]. The [valueGetter]
/// should provide a value in the range `0-1` when a change occurs.
///
/// See [Adapter] for information on [direction] and [animated].
///
/// This example creates a `ChangeNotifierAdapter` that fades in the `myIcon`
/// widget based on the progress of the `myProgressNotifier` [ChangeNotifier].
/// The `valueGetter` is called whenever `myProgressNotifier` changes, and
/// returns a position value between `0-1`, calculated from the `loaded` and
/// `total` properties of `myProgressNotifier`.
///
/// ```dart
/// myIcon.animate(
///   adapter: ChangeNotifierAdapter(
///     myProgressNotifier,
///     () => myProgressNotifier.loaded / myProgressNotifier.total,
///   )
/// ).fadeIn();
/// ```
class ChangeNotifierAdapter extends Adapter {
  ChangeNotifierAdapter(
    this.notifier,
    this.valueGetter, {
    bool? animated,
    Direction? direction,
  }) : super(animated: animated, direction: direction);

  final ChangeNotifier notifier;
  final ValueGetter<double> valueGetter;

  @override
  void attach(AnimationController controller) {
    config(
      controller,
      valueGetter(),
      notifier: notifier,
      listener: () => updateValue(valueGetter()),
    );
  }
}
