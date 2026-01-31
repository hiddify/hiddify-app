import 'package:flutter/widgets.dart';

class AnimatedVisibility extends StatelessWidget {
  const AnimatedVisibility({
    required this.visible,
    required this.child,
    super.key,
    this.axis = Axis.horizontal,
    this.padding = EdgeInsets.zero,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });

  final bool visible;

  final Axis axis;

  final EdgeInsets padding;

  final Duration duration;

  final Curve curve;

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
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
