import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// Drives an [Animate] animation from a [ValueNotifier]. The value from the
/// notifier should be in the range `0-1`.
///
/// See [Adapter] for information on [direction] and [animated].
class ValueNotifierAdapter extends Adapter {
  ValueNotifierAdapter(this.notifier, {bool? animated, Direction? direction})
      : super(animated: animated, direction: direction);

  final ValueNotifier<double> notifier;

  @override
  void attach(AnimationController controller) {
    config(
      controller,
      notifier.value,
      notifier: notifier,
      listener: () => updateValue(notifier.value),
    );
  }
}
