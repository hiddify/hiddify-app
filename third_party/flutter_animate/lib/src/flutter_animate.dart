import 'package:flutter/widgets.dart';
import '../flutter_animate.dart';

/// Provides a common interface for [Animate] and [AnimateList] to attach [Effect] extensions.
mixin AnimateManager<T> {
  T addEffect(Effect effect) => throw (UnimplementedError());
  T addEffects(List<Effect> effects) {
    for (Effect o in effects) {
      addEffect(o);
    }
    return this as T;
  }
}

/// Because [Effect] classes are immutable and may be reused between multiple
/// [Animate] (or [AnimateList]) instances, an [EffectEntry] is created to store
/// values that may be different between instances. For example, due to an
/// `interval` on `AnimateList`, or from inheriting timing parameters.
@immutable
class EffectEntry {
  const EffectEntry({
    required this.effect,
    required this.delay,
    required this.duration,
    required this.curve,
    required this.owner,
  });

  /// The delay for this entry.
  final Duration delay;

  /// The duration for this entry.
  final Duration duration;

  /// The curve used by this entry.
  final Curve curve;

  /// The effect associated with this entry.
  final Effect effect;

  /// The [Animate] instance that created this entry. This can be used by effects
  /// to read information about the animation. Effects _should not_ modify
  /// the animation (ex. by calling [Animate.addEffect]).
  final Animate owner;

  /// The begin time for this entry.
  Duration get begin => delay;

  /// The end time for this entry.
  Duration get end => delay + duration;

  /// Builds a sub-animation based on the properties of this entry.
  ///
  /// Hiddify: drive(CurveTween) instead of CurvedAnimation. This runs from [Effect.build] on
  /// every rebuild of the [Animate] widget, and a CurvedAnimation registers itself on the
  /// controller and is never disposed, so every rebuild leaked one per effect for the life of
  /// the widget (gskinner/flutter_animate#155, fix of PR #166).
  Animation<double> buildAnimation(
    AnimationController controller, {
    Curve? curve,
  }) {
    int ttlT = controller.duration?.inMicroseconds ?? 0;
    int beginT = begin.inMicroseconds, endT = end.inMicroseconds;
    return controller.drive(
      CurveTween(curve: Interval(beginT / ttlT, endT / ttlT, curve: curve ?? this.curve)),
    );
  }
}
