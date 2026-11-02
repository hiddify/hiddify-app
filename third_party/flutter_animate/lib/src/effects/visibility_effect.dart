import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that toggles the visibility of the target (via [Visibility]).
/// Defaults to `end=true`.
///
/// [maintain] is assigned to the [Visibility] properties `maintainSize`,
/// `maintainAnimation`, `maintainState`, `maintainInteractivity` and `maintainSemantics`.
/// It defaults to `null`.
@immutable
class VisibilityEffect extends Effect<bool> {
  static const bool neutralValue = true;

  static const bool defaultMaintain = true;

  const VisibilityEffect({
    super.delay,
    super.duration,
    super.curve,
    bool? end,
    bool? maintain,
  })  : maintain = maintain ?? defaultMaintain,
        super(
          begin: !(end ?? neutralValue),
          end: end ?? neutralValue,
        );

  final bool maintain;

  @override
  Widget build(BuildContext context, Widget child,
      AnimationController controller, EffectEntry entry) {
    double ratio = getEndRatio(controller, entry);
    return getToggleBuilder(
      animation: controller,
      child: child,
      toggle: () => begin! == (controller.value < ratio),
      builder: (_, b, __) => Visibility(
        visible: b,
        maintainSize: maintain,
        maintainAnimation: maintain,
        maintainState: maintain,
        maintainSemantics: maintain,
        maintainInteractivity: maintain,
        child: child,
      ),
    );
  }
}

/// Adds [VisibilityEffect] related extensions to [AnimateManager].
extension VisibilityEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [VisibilityEffect] that toggles the visibility of the target (via [Visibility]).
  T visibility({
    Duration? delay,
    Duration? duration,
    bool? end,
    bool? maintain,
  }) =>
      addEffect(VisibilityEffect(
        delay: delay,
        duration: duration,
        end: end,
        maintain: maintain,
      ));

  /// Adds a [VisibilityEffect] that toggles the visibility of the target to `true` (via [Visibility]).
  T show({
    Duration? delay,
    Duration? duration,
    bool? maintain,
  }) =>
      addEffect(VisibilityEffect(
        delay: delay,
        duration: duration,
        end: true,
        maintain: maintain,
      ));

  /// Adds a [VisibilityEffect] that toggles the visibility of the target to `false` (via [Visibility]).
  T hide({
    Duration? delay,
    Duration? duration,
    bool? maintain,
  }) =>
      addEffect(VisibilityEffect(
        delay: delay,
        duration: duration,
        end: false,
        maintain: maintain,
      ));
}
