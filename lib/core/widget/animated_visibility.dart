import 'package:flutter/widgets.dart';

class AnimatedVisibility extends StatelessWidget {
  const AnimatedVisibility({
    super.key,
    required this.visible,
    this.axis = Axis.horizontal,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  final bool visible;
  final Axis axis;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final replacement = axis == Axis.vertical ? const SizedBox(width: double.infinity) : const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: visible
          ? AnimatedPadding(padding: padding, duration: const Duration(milliseconds: 200), child: child)
          : replacement,
    );
  }
}
