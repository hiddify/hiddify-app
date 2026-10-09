import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/cat/cat_ears_border.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';

/// A speech bubble with cat ears that pops up over a widget, floats up with a
/// few hearts and fades away. For a cat saying "Meow" when it's tapped.
abstract final class CatBubble {
  static OverlayEntry? _current;

  /// Shows [text] over the widget of [context]. A new bubble replaces the
  /// one still on screen.
  static void show(BuildContext context, String text) {
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    final RenderObject? box = context.findRenderObject();
    if (overlay == null || box is! RenderBox || !box.hasSize) return;
    final RenderObject? overlayBox = overlay.context.findRenderObject();
    final Rect anchor = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;

    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FloatingBubble(
        anchor: anchor,
        text: text,
        onDone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _FloatingBubble extends StatefulWidget {
  const _FloatingBubble({required this.anchor, required this.text, required this.onDone});

  final Rect anchor;
  final String text;
  final VoidCallback onDone;

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _life = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
    ..forward().whenCompleteOrCancel(widget.onDone);

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CatTheme cat = CatTheme.of(context);
    final Widget bubble = DecoratedBox(
      decoration: ShapeDecoration(
        color: theme.colorScheme.primaryContainer,
        shadows: kElevationToShadow[2],
        shape: CatEarsBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          earHeight: 8,
          earWidth: 12,
          earInset: 16,
          innerEarColor: cat.innerEar,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_rounded, size: 16, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 6),
            Text(widget.text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );

    return IgnorePointer(
      // an overlay entry sits outside any page, so it brings its own text style
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _life,
          builder: (context, child) {
            final double t = _life.value;
            final double pop = Curves.easeOutBack.transform(math.min(1, t * 4));
            final double fade = t < .7 ? 1 : 1 - (t - .7) / .3;
            final double rise = 28 * Curves.easeOut.transform(t);
            return Stack(
              children: [
                CustomSingleChildLayout(
                  delegate: _AboveAnchor(widget.anchor, rise),
                  child: Opacity(
                    opacity: fade.clamp(0, 1),
                    child: Transform.scale(
                      scale: .6 + .4 * pop,
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          child!,
                          for (int i = 0; i < 3; i++)
                            Positioned(
                              left: -6 + i * 26.0,
                              top: -10 - 22 * Curves.easeOut.transform(math.max(0, t - i * .12)),
                              child: Opacity(
                                opacity: (1 - t).clamp(0, 1),
                                child: Icon(Icons.favorite_rounded, size: 12.0 + i * 2, color: cat.heart),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: bubble,
        ),
      ),
    );
  }
}

/// Centers the bubble just above the anchor, kept on screen.
class _AboveAnchor extends SingleChildLayoutDelegate {
  _AboveAnchor(this.anchor, this.rise);

  final Rect anchor;
  final double rise;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double margin = 8;
    final double x = (anchor.center.dx - childSize.width / 2).clamp(
      margin,
      math.max(margin, size.width - childSize.width - margin),
    );
    final double y = math.max(margin + 12, anchor.top - childSize.height - 6 - rise);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_AboveAnchor oldDelegate) => oldDelegate.anchor != anchor || oldDelegate.rise != rise;
}
