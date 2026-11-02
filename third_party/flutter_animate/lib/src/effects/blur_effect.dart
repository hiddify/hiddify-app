import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that animates a blur on the target between the
/// specified [begin] and [end] blur radiuses (via [ImageFiltered]).
/// Defaults to `begin=0, end=4`.
@immutable
class BlurEffect extends Effect<Offset> {
  static const Offset neutralValue = Offset(neutralBlur, neutralBlur);
  static const Offset defaultValue = Offset(defaultBlur, defaultBlur);

  static const double neutralBlur = 0.0;
  static const double defaultBlur = 4.0;
  static const double minBlur = 0.01;

  const BlurEffect({
    super.delay,
    super.duration,
    super.curve,
    Offset? begin,
    Offset? end,
  }) : super(
          begin: begin ?? neutralValue,
          end: end ?? (begin == null ? defaultValue : neutralValue),
        );

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    Animation<Offset> animation = buildAnimation(controller, entry);
    return getOptimizedBuilder<Offset>(
      animation: animation,
      builder: (_, __) {
        final double sigmaX = _normalizeSigma(animation.value.dx);
        final double sigmaY = _normalizeSigma(animation.value.dy);
        return ImageFiltered(
          enabled: sigmaX > minBlur || sigmaY > minBlur,
          imageFilter: ImageFilter.blur(
            sigmaX: sigmaX,
            sigmaY: sigmaY,
            tileMode: TileMode.decal,
          ),
          child: child,
        );
      },
    );
  }

  double _normalizeSigma(double sigma) {
    // Initially added to address a Flutter issue where near-zero blurs caused RTEs.
    // https://github.com/flutter/engine/pull/36575
    // This has been fixed, but now blurs with a zero value cause visual issues on macOS.
    return sigma < minBlur ? minBlur : sigma;
  }
}

/// Adds [BlurEffect] related extensions to [AnimateManager].
extension BlurEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [BlurEffect] that animates a blur on the target between
  /// the specified [begin] and [end] blur radiuses (via [ImageFiltered]).
  T blur({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Offset? begin,
    Offset? end,
  }) =>
      addEffect(BlurEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
      ));

  /// Adds a [BlurEffect] that animates a horizontal blur on the target between
  /// the specified [begin] and [end] blur radiuses (via [ImageFiltered]).
  T blurX({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) {
    end ??= (begin == null ? BlurEffect.defaultBlur : BlurEffect.neutralBlur);
    begin ??= BlurEffect.neutralBlur;
    return addEffect(BlurEffect(
      delay: delay,
      duration: duration,
      curve: curve,
      begin: BlurEffect.neutralValue.copyWith(dx: begin),
      end: BlurEffect.neutralValue.copyWith(dx: end),
    ));
  }

  /// Adds a [BlurEffect] that animates a vertical blur on the target between
  /// the specified [begin] and [end] blur radiuses (via [ImageFiltered]).
  T blurY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) {
    end ??= (begin == null ? BlurEffect.defaultBlur : BlurEffect.neutralBlur);
    begin ??= BlurEffect.neutralBlur;
    return addEffect(BlurEffect(
      delay: delay,
      duration: duration,
      curve: curve,
      begin: BlurEffect.neutralValue.copyWith(dy: begin),
      end: BlurEffect.neutralValue.copyWith(dy: end),
    ));
  }

  /// Adds a [BlurEffect] that animates a uniform blur on the target between
  /// the specified [begin] and [end] blur radiuses (via [ImageFiltered]).
  T blurXY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) {
    end ??= (begin == null ? BlurEffect.defaultBlur : BlurEffect.neutralBlur);
    begin ??= BlurEffect.neutralBlur;
    return addEffect(BlurEffect(
      delay: delay,
      duration: duration,
      curve: curve,
      begin: Offset(begin, begin),
      end: Offset(end, end),
    ));
  }
}
