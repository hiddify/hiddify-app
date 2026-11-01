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
        // the old text leaves in the first third, the new one comes in after it
        final shown = CurvedAnimation(
          parent: animation,
          curve: child.key == ValueKey<String>(data!)
              ? const Interval(.35, 1, curve: Curves.easeOut)
              : const Interval(.65, 1, curve: Curves.easeIn),
        );
        return FadeTransition(
          opacity: shown,
          child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(shown), child: child),
        );
      },
      child: Text(data!, key: ValueKey<String>(data!), style: style),
    );
  }
}
