import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChainModeIcon extends HookConsumerWidget {
  const ChainModeIcon({super.key, required this.mode, this.size = 16});

  final ChainMode mode;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Icon(mode.icon(), color: mode.color(), size: size);
  }
}

/// A chain type's icon, as on the home proxy card: extra security's shield with an orbiting light,
/// unblocker's door, opening. Still and grey while [animate] is false.
class ChainTypeIcon extends StatelessWidget {
  const ChainTypeIcon({super.key, required this.type, required this.mode, this.animate = true});

  final ChainType type;
  final ChainMode mode;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final (main, accent) = type.colors(mode);
    final still = Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = SizedBox.square(
      dimension: 22,
      child: switch (type) {
        ChainType.extraSecurity =>
          animate ? _OrbitShield(main, accent) : Icon(Icons.shield_rounded, size: 17, color: still),
        ChainType.unblocker =>
          animate ? OpeningDoor(size: 18, color: main) : Icon(Icons.meeting_room_rounded, size: 18, color: still),
      },
    );
    // the loop repaints these 22 px alone, not the card or the page round them
    return animate ? RepaintBoundary(child: icon) : icon;
  }
}

/// Extra security: a soft light circles the shield every 8 s on a faint tilted ring, with a short
/// tail. Behind the shield it dims and shrinks gradually, so nothing jumps.
class _OrbitShield extends StatelessWidget {
  const _OrbitShield(this.main, this.light);
  final Color main;
  final Color light;

  @override
  Widget build(BuildContext context) => Animate(
    onPlay: (c) => c.repeat(),
    effects: [
      CustomEffect(
        duration: 8000.ms,
        builder: (context, v, child) {
          Widget half({required bool front}) => CustomPaint(
            size: const Size.square(22),
            painter: _OrbitPainter(angle: v * 2 * pi, front: front, light: light),
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              half(front: false),
              Icon(Icons.shield_rounded, size: 17, color: main),
              half(front: true),
            ],
          );
        },
      ),
    ],
    child: const SizedBox.square(dimension: 22),
  );
}

/// One half of the orbit, the one behind the shield or the one in front of it: the ring and the
/// light at [angle], with its tail.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.angle, required this.front, required this.light});
  final double angle;
  final bool front;
  final Color light;

  static const _tilt = -.22;
  static const _tail = .6;
  static const _ring = .22;

  /// A point of the ellipse, tilted, in the 22 px box.
  Offset _at(Size size, double a) {
    final x = cos(a) * 10;
    final y = sin(a) * 3.5;
    return size.center(Offset(x * cos(_tilt) - y * sin(_tilt), x * sin(_tilt) + y * cos(_tilt)));
  }

  /// 0 at the back of the orbit, 1 at the front.
  double _near(double a) => (sin(a) + 1) / 2;

  bool _inFront(double a) => sin(a) > 0;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    const segments = 64;
    for (var i = 0; i < segments; i++) {
      final a = i / segments * 2 * pi;
      final b = (i + 1) / segments * 2 * pi;
      if (_inFront((a + b) / 2) != front) continue;
      ring.color = light.withValues(alpha: _ring * (.45 + .55 * _near((a + b) / 2)));
      canvas.drawLine(_at(size, a), _at(size, b), ring);
    }
    // the tail: dots that thin and fade away from the light, drawn from its end to the light
    const steps = 18;
    for (var i = steps; i >= 0; i--) {
      final k = i / steps; // 0: the light, 1: the tail's end
      final a = angle - k * _tail;
      if (_inFront(a) != front) continue;
      final alpha = (1 - k) * (.3 + .5 * _near(a));
      final radius = (i == 0 ? 1.6 : 1.3 * (1 - k * .7)) * (.78 + .22 * _near(a));
      final at = _at(size, a);
      if (i == 0) {
        canvas.drawCircle(
          at,
          radius * 2.2,
          Paint()
            ..color = light.withValues(alpha: alpha * .35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      canvas.drawCircle(at, radius, Paint()..color = light.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.angle != angle || old.front != front || old.light != light;
}

/// The unblocker's door, swinging open on its left hinge toward the viewer, staying open a while,
/// shutting and resting, over and over: the door gets through, where a lock would only guard.
class OpeningDoor extends StatelessWidget {
  const OpeningDoor({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  /// How open the door is at [v] of a loop: opens in the first third, stays open, shuts, rests.
  static double _loop(double v) => switch (v) {
    < .3 => Curves.easeOutBack.transform(v / .3).clamp(0, 1.05),
    < .7 => 1,
    < .85 => 1 - Curves.easeInCubic.transform((v - .7) / .15),
    _ => 0,
  };

  @override
  Widget build(BuildContext context) => Animate(
    onPlay: (c) => c.repeat(),
    effects: [
      CustomEffect(
        duration: 3600.ms,
        builder: (context, v, child) => CustomPaint(
          size: Size.square(size),
          painter: _DoorPainter(open: _loop(v), color: color),
        ),
      ),
    ],
    child: SizedBox.square(dimension: size),
  );
}

/// The frame, and the door in it turned by [open] (0 shut, 1 about 63° open), on a 24 px grid.
class _DoorPainter extends CustomPainter {
  _DoorPainter({required this.open, required this.color});
  final double open;
  final Color color;

  static const _frame = Rect.fromLTRB(5, 3, 19, 21);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(_frame, const Radius.circular(1)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // light through the doorway, brighter the wider it opens
    canvas.drawRect(_frame.deflate(.9), Paint()..color = color.withValues(alpha: .3 * open.clamp(0, 1)));
    // the door turns toward the viewer: narrower, and its free edge taller, as it opens
    final angle = open * 1.1;
    final edge = _frame.left + _frame.width * cos(angle);
    final grow = 2.4 * sin(angle);
    canvas.saveLayer(Offset.zero & const Size.square(24), Paint());
    canvas.drawPath(
      Path()
        ..moveTo(_frame.left, _frame.top)
        ..lineTo(edge, _frame.top - grow)
        ..lineTo(edge, _frame.bottom + grow)
        ..lineTo(_frame.left, _frame.bottom)
        ..close(),
      Paint()..color = color,
    );
    // the knob, cut out of the door near its free edge
    canvas.drawCircle(
      Offset(edge - 2.4 * cos(angle), _frame.center.dy),
      1.2 * max(cos(angle), .45),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoorPainter old) => old.open != open || old.color != color;
}
