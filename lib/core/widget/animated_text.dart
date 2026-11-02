import 'package:flutter/material.dart';

/// Text that changes with Material's fade through: the old text fades out first, then the new one
/// fades in, growing slightly. Nothing slides, so a change reads calmly.
class AnimatedText extends Text {
  const AnimatedText(super.data, {super.key, super.style, this.duration = const Duration(milliseconds: 600)});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        // the old text leaves in the first third, the new one comes in after it.
        // drive(), not CurvedAnimation: the switcher calls this builder again on every rebuild
        // (the closure is new each time), and a CurvedAnimation registers itself on the
        // switcher's controller and is never disposed, so each rebuild leaked one for good.
        final shown = animation.drive(
          CurveTween(
            curve: child.key == ValueKey<String>(data!)
                ? const Interval(.35, 1, curve: Curves.easeOut)
                : const Interval(.65, 1, curve: Curves.easeIn),
          ),
        );
        return FadeTransition(
          opacity: shown,
          child: ScaleTransition(scale: shown.drive(Tween(begin: .94, end: 1.0)), child: child),
        );
      },
      child: Text(data!, key: ValueKey<String>(data!), style: style),
    );
  }
}
