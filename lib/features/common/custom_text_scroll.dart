import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:text_scroll/text_scroll.dart';

class CustomTextScroll extends ConsumerWidget {
  const CustomTextScroll(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  double calculateHeight(BuildContext context) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
      textScaler: MediaQuery.of(context).textScaler,
    )..layout();
    return textPainter.height;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: calculateHeight(context),
      child: TextScroll(
        text,
        mode: TextScrollMode.bouncing,
        velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
        pauseOnBounce: const Duration(seconds: 2),
        pauseBetween: const Duration(seconds: 2),
        style: style,
      ),
    );
  }
}
