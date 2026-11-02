import 'package:flutter/widgets.dart';
import 'package:flutter_animate/src/warn.dart';
import '../flutter_animate.dart';

/// The Flutter Animate library makes adding beautiful animated effects to your widgets
/// simple. It supports both a declarative and chained API. The latter is exposed
/// via the `Widget.animate` extension, which simply wraps the widget in `Animate`.
///
/// ```
/// // declarative:
/// Animate(child: foo, effects: [FadeEffect(), ScaleEffect()])
///
/// // chained API:
/// foo.animate().fade().scale() // equivalent to above
/// ```
///
/// Effects are always run in parallel (ie. the fade and scale effects in the
/// example above would be run simultaneously), but you can apply delays to
/// offset them or run them in sequence.
///
/// All effects classes are immutable, and can be shared between `Animate`
/// instances, which lets you create libraries of effects to reuse throughout
/// your app.
///
/// ```
/// List<Effect> transitionIn = [
///   FadeEffect(duration: 100.ms, curve: Curves.easeOut),
///   ScaleEffect(begin: 0.8, curve: Curves.easeIn)
/// ];
/// // then:
/// Animate(child: foo, effects: transitionIn)
/// // or:
/// foo.animate(effects: transitionIn)
/// ```
///
/// Effects inherit some of their properties (delay, duration, curve) from the
/// previous effect if unspecified. So in the examples above, the scale will use
/// the same duration as the fade that precedes it. All effects have
/// reasonable defaults, so they can be used simply: `foo.animate().fade()`
///
/// Note that all effects are composed together, not run sequentially. For example,
/// the following would not fade in myWidget, because the fadeOut effect would still be
/// applying an opacity of 0:
///
/// ```
/// myWidget.animate().fadeOut(duration: 200.ms).fadeIn(delay: 200.ms)
/// ```
///
/// See [SwapEffect] for one approach to work around this.

// ignore: must_be_immutable
class Animate extends StatefulWidget with AnimateManager<Animate> {
  /// Default duration for effects.
  static Duration defaultDuration = const Duration(milliseconds: 300);

  /// Default curve for effects.
  static Curve defaultCurve = Curves.linear;

  /// If true, then animations will automatically restart whenever a hot reload
  /// occurs. This is useful for testing animations quickly during development.
  ///
  /// You can get similar results for an individual animation by passing it a
  /// [UniqueKey], which will cause it to restart each time it is rebuilt.
  ///
  /// ```
  /// myWidget.animate(key: UniqueKey()).fade()
  /// ```
  static bool restartOnHotReload = false;

  /// Widget types to reparent, mapped to a method that handles that type. This is used
  /// to make it easy to work with widgets that require specific parents. For example,
  /// the [Positioned] widget, which needs its immediate parent to be a [Stack].
  ///
  /// Handles [Flexible], [Positioned], and [Expanded] by default, but you can add additional
  /// handlers as appropriate. Example, this would add support for a hypothetical
  /// "AlignPositioned" widget, that has an `alignment` property.
  ///
  /// ```
  /// Animate.reparentTypes[AlignPositioned] = (parent, child) {
  ///   AlignPositioned o = parent as AlignPositioned;
  ///   return AlignPositioned(alignment: o.alignment, child: child);
  /// }
  /// ```
  static Map reparentTypes = <Type, ReparentChildBuilder>{
    Flexible: (parent, child) {
      Flexible o = parent as Flexible;
      return Flexible(key: o.key, flex: o.flex, fit: o.fit, child: child);
    },
    Positioned: (parent, child) {
      Positioned o = parent as Positioned;
      return Positioned(
        key: o.key,
        left: o.left,
        top: o.top,
        right: o.right,
        bottom: o.bottom,
        width: o.width,
        height: o.height,
        child: child,
      );
    },
    Expanded: (parent, child) {
      Expanded o = parent as Expanded;
      return Expanded(key: o.key, flex: o.flex, child: child);
    }
  };

  /// Creates an Animate instance that will manage a list of effects and apply
  /// them to the specified child.
  Animate({
    super.key,
    this.child = const SizedBox.shrink(),
    List<Effect>? effects,
    this.onInit,
    this.onPlay,
    this.onComplete,
    bool? autoPlay,
    Duration? delay,
    this.controller,
    this.adapter,
    this.value,
    this.target,
  })  : autoPlay = autoPlay ?? true,
        delay = delay ?? Duration.zero {
    warn(
      autoPlay != false || onPlay == null,
      'Animate.onPlay is not called when Animate.autoPlay=false',
    );
    warn(
      controller == null || onInit == null,
      'Animate.onInit is not called when used with Animate.controller',
    );
    if (this.delay != Duration.zero) {
      String s = "Animate.delay has no effect when used with";
      warn(autoPlay != false, '$s Animate.autoPlay=false');
      warn(adapter == null, '$s Animate.adapter');
      warn(target == null, '$s Animate.target');
      warn(value == null, '$s Animate.value');
    }
    _entries = [];
    if (effects != null) addEffects(effects);
  }

  /// The widget to apply animated effects to.
  final Widget child;

  /// Called immediately after the controller is fully initialized, before
  /// the [Animate.delay] or the animation starts playing (see: [onPlay]).
  /// This is not called if an external [controller] is provided.
  ///
  /// For example, this would pause the animation at its halfway point, and
  /// save a reference to the controller so it can be started later.
  /// ```
  /// foo.animate(
  ///   autoPlay: false,
  ///   onInit: (controller) {
  ///     controller.value = 0.5;
  ///     _myController = controller;
  ///   }
  /// ).slideY()
  /// ```
  final AnimateCallback? onInit;

  /// Called when the animation begins playing (ie. after [Animate.delay],
  /// immediately after [AnimationController.forward] is called).
  /// Provides an opportunity to manipulate the [AnimationController]
  /// (ex. to loop, reverse, stop, etc). This is never called if [autoPlay]
  /// is `false`. See also: [onInit].
  ///
  /// For example, this would pause the animation at its start:
  /// ```
  /// foo.animate(
  ///   onPlay: (controller) => controller.stop()
  /// ).fadeIn()
  /// ```
  /// This would loop the animation, reversing it on each loop:
  /// ```
  /// foo.animate(
  ///   onPlay: (controller) => controller.repeat(reverse: true)
  /// ).fadeIn()
  /// ```
  final AnimateCallback? onPlay;

  /// Called when all effects complete. Provides an opportunity to
  /// manipulate the [AnimationController] (ex. to loop, reverse, etc).
  final AnimateCallback? onComplete;

  /// Setting [autoPlay] to `false` prevents the animation from automatically
  /// starting its controller (ie. calling [AnimationController.forward]).
  final bool autoPlay;

  /// Defines a delay before the animation is started. Unlike [Effect.delay],
  /// this is not a part of the overall animation, and only runs once if the
  /// animation is looped. [onPlay] is called after this delay.
  final Duration delay;

  /// An external [AnimationController] can optionally be specified. By default
  /// Animate creates its own controller internally, which can be accessed via
  /// [onInit] or [onPlay].
  ///
  /// While a controller can be shared between multiple Animate instances,
  /// unexpected behaviors and errors will occur if the animations do not have
  /// identical total durations.
  final AnimationController? controller;

  /// An [Adapter] can drive the animation from an external source (ex. a [ScrollController],
  /// [ValueNotifier], or arbitrary `0-1` value). For more information see [Adapter]
  /// or an adapter class ([ChangeNotifierAdapter], [ScrollAdapter], [ValueAdapter],
  /// [ValueNotifierAdapter]).
  ///
  /// If an adapter is provided, then [delay] is ignored, and you should not
  /// make changes to the [AnimationController] directly (ex. via [onPlay])
  /// because it can cause unexpected results.
  final Adapter? adapter;

  /// Sets a target position for the animation between 0 (start) and 1 (end).
  /// When [target] is changed, it will animate to the new position.
  ///
  /// Ex. fade and scale a button when an `_over` state changes:
  /// ```
  /// MyButton().animate(target: _over ? 1 : 0)
  ///   .fade(end: 0.8).scaleXY(end: 1.1)
  /// ```
  final double? target;

  /// Sets an initial position for the animation between 0 (start) and 1 (end).
  /// This corresponds to the `value` of the animation's [controller].
  /// When [value] is changed, it will jump to the new position.
  ///
  /// For example, this can be used with [autoPlay]`=false` to display an animation
  /// at a specific point (half way through a fade in this case):
  ///
  /// ```
  /// foo.animate(value: 0.5, autoPlay: false).fadeIn()
  /// ```
  final double? value;

  late final List<EffectEntry> _entries;
  Duration _duration = Duration.zero;
  EffectEntry? _lastEntry;
  Duration _baseDelay = Duration.zero;

  /// The total duration for all effects.
  Duration get duration => _duration;

  @override
  State<Animate> createState() => _AnimateState();

  /// Adds an effect. This is mostly used by [Effect] extension methods to append effects
  /// to an [Animate] instance.
  @override
  Animate addEffect(Effect effect) {
    EffectEntry? prior = _lastEntry;

    Duration zero = Duration.zero, delay = zero;
    if (effect is ThenEffect) {
      delay = _baseDelay = (prior?.end ?? zero) + (effect.delay ?? zero);
    } else if (effect.delay != null) {
      delay = _baseDelay + effect.delay!;
    } else {
      delay = prior?.delay ?? _baseDelay;
    }

    assert(delay >= zero, 'Calculated delay cannot be negative.');

    EffectEntry entry = EffectEntry(
      effect: effect,
      delay: delay,
      duration: effect.duration ?? prior?.duration ?? Animate.defaultDuration,
      curve: effect.curve ?? prior?.curve ?? Animate.defaultCurve,
      owner: this,
    );

    _entries.add(entry);
    _lastEntry = entry;
    if (entry.end > _duration && effect is! ThenEffect) _duration = entry.end;
    return this;
  }
}

class _AnimateState extends State<Animate> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isInternalController = false;
  Adapter? _adapter;
  Future<void>? _delayed;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(Animate oldWidget) {
    if (oldWidget.controller != widget.controller ||
        oldWidget._duration != widget._duration) {
      _initController();
      _play();
    } else if (oldWidget.adapter != widget.adapter) {
      _initAdapter();
    } else if (widget.target != oldWidget.target ||
        widget.value != oldWidget.value) {
      _play();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Animate.restartOnHotReload) _restart();
  }

  void _restart() {
    _delayed?.ignore();
    _initController();
    _updateValue();
    _delayed = Future.delayed(widget.delay, () => _play());
  }

  void _initController() {
    AnimationController? controller;
    bool callback = false;

    if (widget.controller != null) {
      // externally provided AnimationController.
      _disposeController();
      controller = widget.controller!;
    } else if (!_isInternalController) {
      // create a new internal AnimationController.
      controller = AnimationController(vsync: this);
      callback = _isInternalController = true;
    } else {
      // pre-existing controller.
    }

    if (controller != null) {
      // new controller.
      _controller = controller;
      _controller.addStatusListener(_handleAnimationStatus);
    }

    _controller.duration = widget._duration;

    _initAdapter();

    if (callback) widget.onInit?.call(_controller);
  }

  void _initAdapter() {
    _adapter?.detach();
    _adapter = widget.adapter;
    _adapter?.attach(_controller);
  }

  void _disposeController() {
    if (_isInternalController) _controller.dispose();
    _isInternalController = false;
  }

  @override
  void dispose() {
    _adapter?.detach();
    _delayed?.ignore();
    _disposeController();
    super.dispose();
  }

  void _handleAnimationStatus(status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call(_controller);
    }
  }

  void _play() {
    _delayed?.ignore(); // for poorly timed hot reloads.
    _updateValue();
    double? pos = widget.target;
    if (pos != null) {
      _controller.animateTo(pos);
    } else if (widget.autoPlay && _adapter == null) {
      _controller.forward(from: widget.value ?? 0);
      widget.onPlay?.call(_controller);
    }
  }

  void _updateValue() {
    if (widget.value == null) return;
    _controller.value = widget.value!;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child, parent = child;
    ReparentChildBuilder? reparent = Animate.reparentTypes[child.runtimeType];
    if (reparent != null) child = (child as dynamic).child;
    for (EffectEntry entry in widget._entries) {
      child = entry.effect.build(context, child, _controller, entry);
    }
    return reparent?.call(parent, child) ?? child;
  }
}

/// Adds [Animate] related extensions to [Widget].
extension AnimateWidgetExtensions on Widget {
  /// Wraps the target [Widget] in an [Animate] instance, and returns
  /// the instance for chaining calls.
  /// Ex. `myWidget.animate()` is equivalent to `Animate(child: myWidget)`.
  Animate animate({
    Key? key,
    List<Effect>? effects,
    AnimateCallback? onInit,
    AnimateCallback? onPlay,
    AnimateCallback? onComplete,
    bool? autoPlay,
    Duration? delay,
    AnimationController? controller,
    Adapter? adapter,
    double? target,
    double? value,
  }) =>
      Animate(
        key: key,
        effects: effects,
        onInit: onInit,
        onPlay: onPlay,
        onComplete: onComplete,
        autoPlay: autoPlay,
        delay: delay,
        controller: controller,
        adapter: adapter,
        target: target,
        value: value,
        child: this,
      );
}

/// The builder type used by [Animate.reparentTypes]. It must accept an existing
/// parent widget, and rebuild it with the provided child. In effect, it clones
/// the provided parent widget with the new child.
typedef ReparentChildBuilder = Widget Function(Widget parent, Widget child);

/// Function signature for [Animate] callbacks.
typedef AnimateCallback = void Function(AnimationController controller);
