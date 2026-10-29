import 'dart:ui';

import 'package:flutter/material.dart';

/// Colors extracted from the OrcaNet reference design.
abstract class OrcaColors {
  static const bgTop = Color(0xFF04061A);
  static const bgMid = Color(0xFF070B2E);
  static const bgBottom = Color(0xFF03040F);

  static const cyan = Color(0xFF1DE9F6);
  static const blue = Color(0xFF2D6BFF);
  static const violet = Color(0xFF8B3DFF);
  static const pink = Color(0xFFFF5CD1);

  static const textPrimary = Color(0xFFF4F6FF);
  static const textSecondary = Color(0xFF8E9ACB);
  static const success = Color(0xFF2BFF88);

  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cyan, blue, violet, pink],
    stops: [0.0, 0.38, 0.72, 1.0],
  );
}

/// A frosted-glass surface: backdrop blur + translucent gradient fill +
/// gradient hairline border + soft outer glow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.blur = 22,
    this.glow,
    this.borderWidth = 1.2,
    this.onTap,
    this.onLongPress,
    this.frosted = true,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? glow;
  final double borderWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Backdrop blur is expensive; turn it off for items inside long lists.
  final bool frosted;

  /// Neon cyan border, used for the selected item of a list.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    final Widget content = Stack(
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: highlight ? 0.14 : 0.10),
                const Color(0xFF3B4BFF).withValues(alpha: 0.06),
                const Color(0xFF8B3DFF).withValues(alpha: 0.10),
              ],
            ),
          ),
          child: child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GradientBorderPainter(
                radius: radius,
                width: highlight ? borderWidth + 0.6 : borderWidth,
                highlight: highlight,
              ),
            ),
          ),
        ),
      ],
    );

    Widget surface = ClipRRect(
      borderRadius: br,
      child: frosted
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            )
          : content,
    );

    if (onTap != null || onLongPress != null) {
      surface = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: surface,
      );
    }

    final glowColor = highlight ? OrcaColors.cyan : (glow ?? OrcaColors.violet);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: highlight ? 0.30 : 0.20),
            blurRadius: 30,
            spreadRadius: -6,
          ),
        ],
      ),
      child: surface,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.radius,
    required this.width,
    required this.highlight,
  });

  final double radius;
  final double width;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      Radius.circular(radius),
    );
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: highlight
          ? [
              OrcaColors.cyan.withValues(alpha: 0.95),
              OrcaColors.blue.withValues(alpha: 0.70),
              OrcaColors.violet.withValues(alpha: 0.85),
              OrcaColors.cyan.withValues(alpha: 0.60),
            ]
          : [
              Colors.white.withValues(alpha: 0.38),
              OrcaColors.blue.withValues(alpha: 0.22),
              OrcaColors.violet.withValues(alpha: 0.50),
              OrcaColors.cyan.withValues(alpha: 0.25),
            ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(rect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.radius != radius || old.width != width || old.highlight != highlight;
}

/// Gradient-filled text (used for the "Net" part of the brand name).
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => const LinearGradient(
        colors: [OrcaColors.cyan, OrcaColors.violet, OrcaColors.pink],
      ).createShader(r),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
