import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';

/// Uses Apple's material on iOS and the existing optical treatment elsewhere.
/// The material owns no gestures or clock; the child remains the action.
class BlizzardGlass extends StatelessWidget {
  const BlizzardGlass({super.key, required this.child, required this.active, required this.radius, this.lens = false});
  final Widget child;
  final bool active;
  final double radius;
  final bool lens;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Motion preferences freeze decoration; UIKit observes Reduce Transparency
    // independently, so stopping animation must not replace glass with a fill.
    final opaque = media.highContrast;
    final native = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (!active) return const SizedBox.shrink();
                    if (opaque) return const ColoredBox(color: BlizzardPalette.elevated);
                    if (native) {
                      return UiKitView(
                        key: ValueKey((radius, lens)),
                        viewType: 'app.blizzard/native-liquid-glass',
                        creationParams: {'radius': radius, 'lens': lens},
                        creationParamsCodec: const StandardMessageCodec(),
                      );
                    }
                    final size = constraints.biggest;
                    final transform = Matrix4.identity()
                      ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
                      ..scaleByDouble(BlizzardGlassMetrics.lensScale, BlizzardGlassMetrics.lensScale, 1, 1)
                      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
                    final blur = ui.ImageFilter.blur(
                      sigmaX: lens ? BlizzardGlassMetrics.connectionBlur : BlizzardGlassMetrics.blur,
                      sigmaY: lens ? BlizzardGlassMetrics.connectionBlur : BlizzardGlassMetrics.blur,
                    );
                    return BackdropFilter(
                      filter: lens
                          ? ui.ImageFilter.compose(outer: ui.ImageFilter.matrix(transform.storage), inner: blur)
                          : blur,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: lens ? BlizzardPalette.connectionGlass : BlizzardPalette.glass,
                          gradient: lens
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    BlizzardPalette.glassHighlight,
                                    Colors.transparent,
                                    BlizzardPalette.glassShade,
                                  ],
                                  stops: [0, 0.38, 1],
                                ),
                        ),
                        child: lens
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      BlizzardPalette.connectionHighlight,
                                      Colors.transparent,
                                      BlizzardPalette.glassShade,
                                    ],
                                    stops: [0, 0.5, 1],
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (active && native && !lens && !opaque)
            const Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x2EEFF7FD), Color(0x0AEFF7FD)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          child,
          if (active && (!native || opaque || !lens))
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _GlassEdgePainter(radius, opaque, soft: lens, nativeDock: native && !lens),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter(this.radius, this.opaque, {required this.soft, this.nativeDock = false});
  final double radius;
  final bool opaque;
  final bool soft;
  final bool nativeDock;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.75), Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = BlizzardGlassMetrics.edgeWidth;
    if (opaque) {
      paint.color = BlizzardPalette.secondary;
      canvas.drawRRect(shape, paint);
      return;
    }
    if (nativeDock) {
      paint.shader = ui.Gradient.linear(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), [
        BlizzardPalette.primary.withValues(alpha: 0.48),
        BlizzardPalette.primary.withValues(alpha: 0.18),
      ]);
      canvas.drawRRect(shape, paint);
      paint.shader!.dispose();
      return;
    }
    if (soft) {
      paint
        ..strokeWidth = 0.75
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [
            BlizzardPalette.accent.withValues(alpha: 0.36),
            BlizzardPalette.primary.withValues(alpha: 0.13),
            BlizzardPalette.accent.withValues(alpha: 0.07),
            BlizzardPalette.primary.withValues(alpha: 0.2),
          ],
          [0, 0.3, 0.65, 1],
        );
      canvas.drawRRect(shape, paint);
      paint.shader!.dispose();
      return;
    }
    paint.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      [
        BlizzardPalette.glassEdge,
        BlizzardPalette.primary.withValues(alpha: 0.12),
        BlizzardPalette.accent.withValues(alpha: 0.08),
        BlizzardPalette.glassEdge.withValues(alpha: 0.48),
      ],
      [0, 0.3, 0.63, 1],
    );
    canvas.drawRRect(shape, paint);
    paint.shader!.dispose();
    paint
      ..strokeWidth = 0.6
      ..shader = ui.Gradient.linear(
        Offset(size.width, 0),
        Offset(0, size.height),
        [
          BlizzardPalette.primary.withValues(alpha: 0.34),
          BlizzardPalette.primary.withValues(alpha: 0),
          BlizzardPalette.accent.withValues(alpha: 0.24),
        ],
        [0, 0.48, 1],
      );
    canvas.drawRRect(shape.deflate(2.2), paint);
    paint.shader!.dispose();
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.opaque != opaque ||
      oldDelegate.soft != soft ||
      oldDelegate.nativeDock != nativeDock;
}
