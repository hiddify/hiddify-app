import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';

enum NovaRitualState { disconnected, connecting, connected, error }

class NovaRitualHero extends StatelessWidget {
  const NovaRitualHero({
    super.key,
    required this.state,
    required this.statusLabel,
    required this.child,
    this.callToActionLabel,
  });

  final NovaRitualState state;
  final String statusLabel;
  final String? callToActionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final connected = state == NovaRitualState.connected;
    final reduceMotion = MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context);

    return SizedBox(
      height: 318,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NovaRadarPainter(
                active: connected,
                accent: nova.accent,
                line: nova.separator,
                node: nova.disabled,
              ),
            ),
          ),
          ..._glyphs.map(
            (glyph) => Positioned(
              left: glyph.x,
              top: glyph.y,
              child: ExcludeSemantics(
                child: AnimatedOpacity(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                  opacity: connected ? 0.35 : 0.82,
                  child: Text(
                    glyph.value,
                    style: TextStyle(
                      color: nova.tertiaryText.withValues(alpha: connected ? 0.35 : 0.82),
                      fontFamily: 'monospace',
                      fontSize: glyph.size,
                      fontWeight: FontWeight.w600,
                      shadows: connected
                          ? null
                          : [Shadow(color: nova.secondaryText.withValues(alpha: 0.45), blurRadius: 10)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (connected && callToActionLabel != null)
            Positioned(
              top: 10,
              child: Text(
                callToActionLabel!,
                style: TextStyle(
                  color: nova.accentHover,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.8,
                  shadows: [Shadow(color: nova.accent.withValues(alpha: 0.45), blurRadius: 12)],
                ),
              ),
            ),
          if (state == NovaRitualState.connecting)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: -0.2, end: 1.2),
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
                  builder: (context, progress, _) => Align(
                    alignment: Alignment(progress * 2 - 1, 0.16),
                    child: Icon(
                      Icons.pets_rounded,
                      color: nova.primaryText,
                      size: 34,
                      shadows: [Shadow(color: nova.primaryText.withValues(alpha: 0.7), blurRadius: 10)],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 44,
            left: 20,
            right: 20,
            bottom: 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                child,
                const SizedBox(height: NovaSpacing.lg),
                Text(
                  statusLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: state == NovaRitualState.error ? Theme.of(context).colorScheme.error : nova.tertiaryText,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 0.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glyph {
  const _Glyph(this.value, this.x, this.y, this.size);

  final String value;
  final double x;
  final double y;
  final double size;
}

const _glyphs = <_Glyph>[
  _Glyph('ア', 24, 34, 22),
  _Glyph('0', 18, 134, 18),
  _Glyph('<', 54, 238, 20),
  _Glyph('ソ', 318, 48, 19),
  _Glyph('#', 334, 146, 24),
  _Glyph('1', 310, 242, 17),
];

class _NovaRadarPainter extends CustomPainter {
  const _NovaRadarPainter({required this.active, required this.accent, required this.line, required this.node});

  final bool active;
  final Color accent;
  final Color line;
  final Color node;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final radius = math.min(size.width * 0.54, size.height * 0.7);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: active ? 0.11 : 0.035),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glow);

    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final factor in const [0.32, 0.58, 0.84, 1.0]) {
      canvas.drawCircle(center, radius * factor, linePaint);
    }

    for (var i = 0; i < 4; i++) {
      final angle = math.pi * i / 4;
      final delta = Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(center - delta, center + delta, linePaint);
    }

    final nodePaint = Paint()..color = node;
    for (final offset in const [Offset(-84, -58), Offset(74, -86), Offset(104, 35), Offset(-108, 68)]) {
      canvas.drawCircle(center + offset, 2.2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NovaRadarPainter oldDelegate) =>
      oldDelegate.active != active ||
      oldDelegate.accent != accent ||
      oldDelegate.line != line ||
      oldDelegate.node != node;
}
