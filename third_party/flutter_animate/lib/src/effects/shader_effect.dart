import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import '../../flutter_animate.dart';

/// Effect that applies an animated fragment shader to a target. See
/// [Writing and using fragment shaders](https://docs.flutter.dev/development/ui/advanced/shaders)
/// for information on how to include shaders in your app.
///
/// [shader] is the [FragmentShader] to apply to the target. If `null` no effect
/// will be applied.
///
/// [overflow] defines a buffer space around the target to draw the shader. This
/// is useful for effects that draw outside of the target bounds, such as blurs.
/// Defaults to [EdgeInsets.zero].
///
/// [layer] allows you to layer the shader above, below, or completely replace
/// the target visually. Defaults to [ShaderLayer.replace].
///
/// [update] is an optional callback that allows you to update the shader. It
/// is called whenever the animation value changes. It accepts a
/// [ShaderUpdateDetails] object. It can update uniforms directly via
/// `setFloat` or `setImageSampler`, by using [ShaderUpdateDetails.updateUniforms].
///
/// If [update] is not specified, the shader will be updated automatically based
/// on the "standardized" uniforms defined in [ShaderUpdateDetails.updateUniforms].
///
/// The [update] callback may return an [EdgeInsets] to define the overflow, or
/// `null` to use the [overflow] value.
@immutable
class ShaderEffect extends Effect<double> {
  const ShaderEffect({
    super.delay,
    super.duration,
    super.curve,
    this.shader,
    this.overflow,
    ShaderLayer? layer,
    this.update,
  })  : layer = layer ?? ShaderLayer.replace,
        super(
          begin: 0,
          end: 1,
        );

  final ui.FragmentShader? shader;
  final EdgeInsets? overflow;
  final ShaderLayer layer;
  final ShaderUpdateCallback? update;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    double ratio = 1 / MediaQuery.of(context).devicePixelRatio;
    Animation<double> animation = buildAnimation(controller, entry);
    return getOptimizedBuilder<double>(
      animation: animation,
      builder: (_, __) {
        return AnimatedSampler(
          (ui.Image image, Size size, Canvas canvas) {
            ShaderUpdateDetails details = ShaderUpdateDetails(
              shader: shader!,
              value: animation.value,
              size: size,
              image: image,
            );

            EdgeInsets? insets = overflow;
            if (update != null) {
              insets ??= update!(details);
            } else {
              details.updateUniforms();
            }

            Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
            rect = insets?.inflateRect(rect) ?? rect;

            drawImage() {
              canvas.save();
              canvas.scale(ratio, ratio);
              canvas.drawImage(image, Offset.zero, Paint());
              canvas.restore();
            }

            if (layer == ShaderLayer.foreground) drawImage();
            if (shader != null) canvas.drawRect(rect, Paint()..shader = shader);
            if (layer == ShaderLayer.background) drawImage();
          },
          enabled: shader != null,
          child: child,
        );
      },
    );
  }
}

/// Adds [ShaderEffect] related extensions to [AnimateManager].
extension ShaderEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [ShaderEffect] that applies an animated fragment shader to a target.
  T shader({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    ui.FragmentShader? shader,
    EdgeInsets? overflow,
    ShaderLayer? layer,
    ShaderUpdateCallback? update,
  }) =>
      addEffect(ShaderEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        shader: shader,
        overflow: overflow,
        layer: layer,
        update: update,
      ));
}

enum ShaderLayer { foreground, background, replace }

/// Passed to the [ShaderEffect.update] callback. Contains information necessary
/// for updating the shader:
///
/// [shader] is the shader to update.
/// [value] is the current animation value of the effect.
/// [size] is the on-screen dimensions of the target.
/// [image] is a snapshot of the target, which can be used as an input texture.
///
/// It also exposes the [updateUniforms] helper method which can be used to update
/// uniforms. Alternatively, you can simply set uniforms on the shader directly.
class ShaderUpdateDetails {
  ShaderUpdateDetails({
    required this.shader,
    required this.value,
    required this.size,
    required this.image,
  });

  final ui.FragmentShader shader;
  final double value;
  final Size size;
  final ui.Image image;

  /// Optional helper method that updates uniforms on the shader.
  ///
  /// It assumes a standardized set of initial uniforms:
  /// - float `0`: width
  /// - float `1`: height
  /// - float `2`: value
  /// - image sampler `0`: image
  ///
  /// For example, this could be defined in the fragment shader as:
  /// ``` glsl
  /// uniform vec2 size; // float 0 and 1
  /// uniform float value; // float 2
  /// uniform sampler2D image; // image sampler 0
  /// ```
  ///
  /// You can specify [value] to override the current animation value.
  ///
  /// You can also pass additional uniforms via [floats] and [images]. These
  /// will be set in the shader in the order they are passed. For example,
  /// if you pass `floats: [intensity]`, then the intensity value will be
  /// assigned to float `3`.
  void updateUniforms({
    double? value,
    List<double>? floats,
    List<ui.Image>? images,
  }) {
    // floats:
    int i = 0;
    shader.setFloat(i, size.width);
    shader.setFloat(++i, size.height);
    shader.setFloat(++i, value ?? this.value);
    floats?.forEach((o) => shader.setFloat(++i, o));

    // images:
    i = 0;
    shader.setImageSampler(i, image);
    images?.forEach((o) => shader.setImageSampler(++i, o));
  }
}

/// Function signature for [ShaderEffect] update handlers.
typedef ShaderUpdateCallback = EdgeInsets? Function(
    ShaderUpdateDetails details);
