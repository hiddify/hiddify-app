import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'glass_kit.dart';

/// Full-screen background: deep navy, aurora glow, and a glowing globe
/// with network nodes and arcs on top (as in the reference design).
class OrcaBackground extends StatelessWidget {
  const OrcaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _BackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final full = Offset.zero & size;

    // 1) Base gradient
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OrcaColors.bgTop,
            OrcaColors.bgMid,
            OrcaColors.bgBottom,
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(full),
    );

    // 2) Aurora glows
    _glow(canvas, Offset(w * 0.92, h * 0.10), w * 0.75,
        OrcaColors.violet.withValues(alpha: 0.42));
    _glow(canvas, Offset(w * 0.05, h * 0.16), w * 0.60,
        OrcaColors.blue.withValues(alpha: 0.32));
    _glow(canvas, Offset(w * 0.50, h * 0.40), w * 0.85,
        const Color(0xFF3A2BFF).withValues(alpha: 0.20));
    _glow(canvas, Offset(w * 0.95, h * 0.72), w * 0.55,
        OrcaColors.violet.withValues(alpha: 0.18));

    // 3) Globe
    final r = w * 1.02;
    final center = Offset(w / 2, h * 0.128 + r);
    final globe = Rect.fromCircle(center: center, radius: r);

    canvas.save();
    canvas.clipPath(Path()..addOval(globe));

    // globe body
    canvas.drawRect(
      globe,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1.0),
          radius: 1.1,
          colors: [
            const Color(0xFF1B2D86).withValues(alpha: 0.70),
            const Color(0xFF0A1050).withValues(alpha: 0.55),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.75],
        ).createShader(globe),
    );

    // land-ish dotted texture
    const dotColor = Color(0xFF6C7CFF);
    final dotPaint = Paint();
    final texH = h * 0.30;
    for (double y = globe.top; y < globe.top + texH; y += 9) {
      final fade = (1 - ((y - globe.top) / texH)).clamp(0.0, 1.0);
      for (double x = 0; x < w; x += 9) {
        final v = math.sin(x * 0.021 + 1.3) + math.cos(y * 0.034 + x * 0.008);
        if (v > 0.55) {
          dotPaint.color =
              (v > 1.55 ? OrcaColors.pink : dotColor).withValues(alpha: 0.55 * fade);
          canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
        }
      }
    }
    canvas.restore();

    // rim light
    final rim = globe.inflate(1);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            OrcaColors.blue,
            OrcaColors.cyan,
            OrcaColors.violet,
            OrcaColors.pink,
          ],
        ).createShader(rim),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            OrcaColors.blue.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.95),
            OrcaColors.violet.withValues(alpha: 0.9),
          ],
        ).createShader(rim),
    );

    // 4) Network nodes + arcs
    final rnd = math.Random(11);
    final nodes = <Offset>[];
    for (var i = 0; i < 16; i++) {
      final x = w * (0.04 + rnd.nextDouble() * 0.92);
      final y = h * (0.15 + rnd.nextDouble() * 0.20);
      nodes.add(Offset(x, y));
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.16);
    for (var i = 0; i < nodes.length - 1; i += 2) {
      final a = nodes[i];
      final b = nodes[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, math.min(a.dy, b.dy) - 50);
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
        arc,
      );
    }
    for (final n in nodes) {
      canvas.drawCircle(
        n,
        5,
        Paint()
          ..color = OrcaColors.cyan.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(n, 2.2, Paint()..color = Colors.white);
    }
  }

  void _glow(Canvas c, Offset center, double radius, Color color) {
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


/// Quiet version of the background for every page behind the home screen:
/// navy gradient + soft aurora glows, no globe. Sits behind the whole app.
class OrcaAmbientBackground extends StatelessWidget {
  const OrcaAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _AmbientPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final full = Offset.zero & size;

    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OrcaColors.bgTop,
            OrcaColors.bgMid,
            OrcaColors.bgBottom,
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(full),
    );

    void glow(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    glow(Offset(w * 0.92, h * 0.08), w * 0.75, OrcaColors.violet.withValues(alpha: 0.32));
    glow(Offset(w * 0.04, h * 0.30), w * 0.60, OrcaColors.blue.withValues(alpha: 0.24));
    glow(Offset(w * 0.90, h * 0.78), w * 0.70, OrcaColors.violet.withValues(alpha: 0.16));
    glow(Offset(w * 0.10, h * 0.95), w * 0.55, OrcaColors.cyan.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
