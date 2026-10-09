import 'package:flutter/material.dart';
import 'package:hiddify/core/widget/cat/cat_bubble.dart';
import 'package:hiddify/core/widget/cat/cat_face.dart';

/// A [CatFace] that answers a tap: a boop on the nose and a bubble with
/// [meow]. Decorative, so screen readers skip it.
class TappableCat extends StatefulWidget {
  const TappableCat({
    super.key,
    required this.mood,
    required this.meow,
    this.size = 32,
    this.alive = true,
    this.followPointer = false,
    this.pettable = false,
    this.onTap,
  });

  final CatMood mood;
  final String meow;
  final double size;

  /// See [CatFace.alive]. A tap still boops a cat that isn't.
  final bool alive;
  final bool followPointer;
  final bool pettable;

  /// Called on every tap, for haptic feedback.
  final VoidCallback? onTap;

  @override
  State<TappableCat> createState() => _TappableCatState();
}

class _TappableCatState extends State<TappableCat> {
  final GlobalKey<CatFaceState> _face = GlobalKey();

  void _tap() {
    _face.currentState?.boop();
    widget.onTap?.call();
    CatBubble.show(context, widget.meow);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          child: CatFace(
            key: _face,
            mood: widget.mood,
            size: widget.size,
            alive: widget.alive,
            followPointer: widget.followPointer,
            pettable: widget.pettable,
          ),
        ),
      ),
    );
  }
}
