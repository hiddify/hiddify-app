import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';

/// A text widget that animates changes with fade, size, and slide transitions.
/// 
/// When [data] changes, the widget smoothly transitions to the new value
/// using configurable animations.
/// 
/// Usage:
/// ```dart
/// AnimatedText(
///   counter.toString(),
///   style: TextStyle(fontSize: 24),
///   slide: true,
///   size: true,
/// )
/// ```
class AnimatedText extends Text {
  /// Creates an animated text widget.
  /// 
  /// [data] is the text content to display.
  /// [duration] controls the animation speed.
  /// [size] enables size transition during animation.
  /// [slide] enables vertical slide transition during animation.
  const AnimatedText(
    super.data, {
    super.key,
    super.style,
    this.duration = kAnimationDuration,
    this.size = true,
    this.slide = true,
  });

  /// Duration of the transition animation.
  final Duration duration;
  
  /// Whether to animate the size change.
  final bool size;
  
  /// Whether to animate with a vertical slide.
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
