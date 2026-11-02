import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// An effect that animates a [Color] between [begin] and [end], composited with
/// the target using [blendMode] (via [ColorFiltered]). A color value of `null`
/// will be interpreted as a fully transparent version of the other color.
/// Defaults to `begin=null, end=Color(0x800099FF)`.
///
/// [blendMode] defaults to [BlendMode.color].
/// Note that most blend modes in Flutter (including `color`)
/// do not preserve the alpha channel correctly. See [BlendMode.srcATop] or
/// [BlendMode.srcIn] for options that do maintain alpha.
///
/// The following example animates from red to blue with a `multiply` blend:
///
/// ```
/// Image.asset('assets/rainbow.jpg').animate()
///   .color(begin: Colors.red, end: Colors.blue, blendMode: BlendMode.multiply)
/// ```
///
/// See also: [TintEffect], which provides a simpler interface for single color
/// tints.
@immutable
class ColorEffect extends Effect<Color?> {
  static const Color? neutralValue = null;
  static const Color defaultValue = Color(0x800099FF);
  static const BlendMode defaultBlendMode = BlendMode.color;

  const ColorEffect({
    super.delay,
    super.duration,
    super.curve,
    Color? begin,
    Color? end,
    this.blendMode,
  }) : super(
          begin: begin ?? neutralValue,
          end: end ?? (begin == null ? defaultValue : neutralValue),
        );

  final BlendMode? blendMode;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    Animation<double> animation = entry.buildAnimation(controller);
    return getOptimizedBuilder<double>(
      animation: animation,
      builder: (_, __) {
        Color color = ColorTween(begin: begin, end: end).evaluate(animation) ??
            const Color(0x00000000);
        return ColorFiltered(
          colorFilter: ColorFilter.mode(color, blendMode ?? defaultBlendMode),
          child: child,
        );
      },
    );
  }
}

/// Adds [ColorEffect] related extensions to [AnimateManager].
extension ColorEffectExtension<T extends AnimateManager<T>> on T {
  /// Adds a [ColorEffect] that animates a [Color] between [begin] and [end], composited with
  /// the target using [blendMode] (via [ColorFiltered]). A color value of `null`
  /// will be interpreted as a fully transparent version of the other color.
  T color({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Color? begin,
    Color? end,
    BlendMode? blendMode,
  }) =>
      addEffect(ColorEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        blendMode: blendMode,
      ));
}
