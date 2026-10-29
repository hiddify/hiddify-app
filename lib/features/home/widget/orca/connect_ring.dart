import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_kit.dart';

enum OrcaConnectionState { disconnected, connecting, connected }

/// The big neon ring with the orca logo and the connection status text.
class ConnectRing extends StatefulWidget {
  const ConnectRing({
    super.key,
    required this.state,
    required this.statusLabel,
    this.size = 330,
  });

  final OrcaConnectionState state;
  final String statusLabel; // Persian sub-label under the divider
  final double size;

  @override
  State<ConnectRing> createState() => _ConnectRingState();
}

class _ConnectRingState extends State<ConnectRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _englishLabel => switch (widget.state) {
        OrcaConnectionState.disconnected => 'DISCONNECTED',
        OrcaConnectionState.connecting => 'CONNECTING',
        OrcaConnectionState.connected => 'CONNECTED',
      };

  Color get _accent => switch (widget.state) {
        OrcaConnectionState.connected => OrcaColors.success,
        _ => OrcaColors.cyan,
      };

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(
                size: Size.square(s),
                painter: _RingPainter(
                  t: _c.value,
                  state: widget.state,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/orca/orca_logo.png',
                width: s * 0.44,
                height: s * 0.44,
                filterQuality: FilterQuality.high,
              ),
              SizedBox(height: s * 0.035),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: s * 0.052,
                  letterSpacing: s * 0.013,
                  fontWeight: FontWeight.w500,
                  color: widget.state == OrcaConnectionState.disconnected
                      ? const Color(0xFFB7C0EE)
                      : _accent,
                ),
                child: Text(_englishLabel),
              ),
              const SizedBox(height: 8),
              Container(
                width: 26,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.statusLabel,
                style: TextStyle(
                  fontSize: s * 0.055,
                  fontWeight: FontWeight.w500,
                  color: OrcaColors.textPrimary.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.t, required this.state});

  final double t; // 0..1 looping
  final OrcaConnectionState state;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: R);

    final connected = state == OrcaConnectionState.connected;
    final connecting = state == OrcaConnectionState.connecting;
    final spin = t * 2 * math.pi * (connecting ? 2 : 1);

    final colors = connected
        ? const [
            OrcaColors.success,
            OrcaColors.cyan,
            OrcaColors.blue,
            OrcaColors.success,
          ]
        : const [
            OrcaColors.cyan,
            OrcaColors.blue,
            OrcaColors.violet,
            OrcaColors.pink,
            OrcaColors.cyan,
          ];

    // outer faint ring
    canvas.drawCircle(
      c,
      R * 0.985,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = OrcaColors.blue.withValues(alpha: 0.28),
    );

    // glow under main ring
    final mainR = R * 0.84;
    final sweep = SweepGradient(
      colors: colors,
      transform: GradientRotation(spin * 0.25),
    ).createShader(rect);

    canvas.drawCircle(
      c,
      mainR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.085
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
        ..shader = sweep,
    );
    // main ring
    canvas.drawCircle(
      c,
      mainR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.075
        ..shader = sweep,
    );
    // glossy highlight on the ring
    canvas.drawCircle(
      c,
      mainR - R * 0.03,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // second thin ring
    canvas.drawCircle(
      c,
      R * 0.93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = SweepGradient(
          colors: [
            OrcaColors.cyan.withValues(alpha: 0.55),
            Colors.transparent,
            OrcaColors.violet.withValues(alpha: 0.55),
            Colors.transparent,
            OrcaColors.cyan.withValues(alpha: 0.55),
          ],
          transform: GradientRotation(-spin * 0.5),
        ).createShader(rect),
    );

    // inner glass disc
    final innerR = R * 0.735;
    canvas.drawCircle(
      c,
      innerR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF070B2C),
            const Color(0xFF04061A),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: innerR)),
    );
    canvas.drawCircle(
      c,
      innerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = OrcaColors.blue.withValues(alpha: 0.35),
    );

    // travelling bright arc (the "scanner")
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = R * 0.022
      ..color = Colors.white.withValues(alpha: connecting ? 0.95 : 0.7);
    final start = connecting || connected ? spin : -math.pi / 2 - 0.1;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: R * 0.955),
      start,
      0.42,
      false,
      arcPaint
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.t != t || old.state != state;
}
