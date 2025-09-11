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
    // Use a conservative cross-fade to avoid layout glitches inside Slivers/Rows
    const replacement = SizedBox.shrink();

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 180),
      firstChild: Padding(padding: padding, child: child),
      secondChild: replacement,
      crossFadeState:
          visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      sizeCurve: Curves.easeInOut,
    );
  }
}
