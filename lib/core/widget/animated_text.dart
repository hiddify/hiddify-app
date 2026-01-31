import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';

class AnimatedText extends Text {
  const AnimatedText(
    super.data, {
    super.key,
    super.style,
    this.duration = kAnimationDuration,
    this.size = true,
    this.slide = true,
  });

  final Duration duration;

  final bool size;

  final bool slide;

  @override
  Widget build(BuildContext context) {
    final textData = data ?? '';

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        Widget result = FadeTransition(opacity: animation, child: child);

        if (size) {
          result = SizeTransition(
            axis: Axis.horizontal,
            fixedCrossAxisSizeFactor: 1,
            sizeFactor: Tween<double>(begin: 0.88, end: 1).animate(animation),
            child: result,
          );
        }

        if (slide) {
          result = SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(animation),
            child: result,
          );
        }

        return result;
      },
      child: Text(
        textData,
        key: ValueKey<String>(textData),
        style: style,
        semanticsLabel: textData,
      ),
    );
  }
}
