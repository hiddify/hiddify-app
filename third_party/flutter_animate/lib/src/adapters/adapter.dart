import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Adapters provide a mechanism to drive an animation from an arbitrary source.
/// For example, synchronizing an animation with a scroll, controlling
/// an animation with a slider input, or progressing an animation based on
/// the time of day.
///
/// [animated] specifies that the adapter should animate to new values. If `false`, it
/// will jump to the new value, if `true` it will animate to the value using a
/// duration calculated from the animation's total duration and the value change.
/// Defaults to `false`.
///
/// Setting [direction] to [Direction.forward] or [Direction.reverse] will cause
/// the adapter to only update if the new value is greater than or less than the
/// current value respectively.
///
/// Adapter implementations must expose an [attach] method which accepts the
/// [AnimationController] used by an [Animate] instance, and adds the logic
/// to drive it from an external source by updating its `value` (0-1). See the
/// included adapters for implementation examples.
abstract class Adapter {
  Adapter({bool? animated, this.direction}) : animated = animated ?? false;

  final bool animated;

  final Direction? direction;

  AnimationController? _controller;
  ChangeNotifier? _notifier;
  VoidCallback? _listener;
  Ticker? _ticker;
  double _value = 0;
  int _prevT = 0;

  // this is called by Animate to associate the AnimationController.
  // implementers must call config.
  void attach(AnimationController controller) => config(controller, 0);

  // disassociates the controller, which also allows the adapter to be re-attached.
  @mustCallSuper
  void detach() {
    _notifier?.removeListener(_listener!);
    _notifier = _listener = _controller = null;
    _ticker?.stop();
  }

  // called by implementers to attach the controller, and set an initial value.
  void config(AnimationController controller, double value,
      {ChangeNotifier? notifier, VoidCallback? listener}) {
    assert(_controller == null, 'An adapter was assigned twice.');
    assert((notifier == null) == (listener == null));
    _controller = controller;
    _controller?.value = _value = value;
    _notifier = notifier?..addListener(listener!);
    _listener = listener;
    _ticker = Ticker(_tick);
  }

  // called by implementers to update the value. Manages direction and animated.
  void updateValue(double value) {
    AnimationController controller = _controller!;
    if (_value == value ||
        (direction == Direction.forward && value < _value) ||
        (direction == Direction.reverse && value > _value)) {
      return;
    }
    _value = value;

    if (!animated) {
      controller.value = value;
    } else if (value != controller.value) {
      Ticker ticker = _ticker!;
      _prevT = DateTime.now().microsecondsSinceEpoch;
      if (!ticker.isActive) ticker.start();
    }
  }

  // The first tick from a Ticker always has a zero duration, which causes
  // animateTo to lock or stutter when changing values repeatedly so this
  // uses a custom implementation to animate between values.
  void _tick(_) {
    AnimationController controller = _controller!;

    int t = DateTime.now().microsecondsSinceEpoch;
    double d = (t - _prevT) / controller.duration!.inMicroseconds;
    double val = controller.value;

    if (val < _value) {
      val = min(_value, val + d);
    } else {
      val = max(_value, val - d);
    }

    _prevT = t;
    controller.value = val;
    if (val == _value) _ticker!.stop();
  }
}

enum Direction { forward, reverse }
