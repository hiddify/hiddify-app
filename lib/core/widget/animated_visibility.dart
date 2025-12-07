import 'package:flutter/widgets.dart';

/// A widget that animates visibility changes with fade and size transitions.
/// 
/// When [visible] changes, the widget smoothly fades in/out and animates
/// its size along the specified [axis].
/// 
/// Usage:
/// ```dart
/// AnimatedVisibility(
///   visible: isExpanded,
///   axis: Axis.vertical,
///   child: DetailContent(),
/// )
/// ```
class AnimatedVisibility extends StatelessWidget {
  /// Creates an animated visibility widget.
  /// 
  /// [visible] controls whether the child is shown.
  /// [axis] determines the direction of size animation.
  /// [padding] adds animated padding around the child.
  /// [duration] controls the animation speed.
  /// [curve] defines the animation curve.
  const AnimatedVisibility({
    super.key,
    required this.visible,
    this.axis = Axis.horizontal,
    this.padding = EdgeInsets.zero,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    required this.child,
  });

  /// Whether the child widget should be visible.
  final bool visible;
  
  /// The axis along which to animate the size change.
  final Axis axis;
  
  /// Padding to animate around the child.
  final EdgeInsets padding;
  
  /// Duration of the visibility animation.
  final Duration duration;
  
  /// The animation curve to use.
  final Curve curve;
  
  /// The child widget to show/hide.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) => SizeTransition(
        axis: axis,
        sizeFactor: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: visible
          ? AnimatedPadding(
              key: const ValueKey('visible'),
              padding: padding,
              duration: duration,
              curve: curve,
              child: child,
            )
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}
