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
/// unblocker's door, letting the traffic through. Still and grey while [animate] is false.
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
        ChainType.unblocker => PassingDoor(size: 20, color: animate ? main : still, animate: animate),
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

/// The unblocker's double door, seen from above: three dots, the traffic, run into it while it is
/// shut and wait; it opens, they drive through one after another, and it shuts again, over and over.
/// The door gets the traffic through, where a lock would only guard it. With [animate] false, the
/// door stands shut and empty.
class PassingDoor extends StatelessWidget {
  const PassingDoor({super.key, required this.size, required this.color, this.animate = true});

  final double size;
  final Color color;
  final bool animate;

  static const _run = 6800;

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return CustomPaint(
        size: Size.square(size),
        painter: _DoorPainter(t: null, color: color),
      );
    }
    return Animate(
      onPlay: (c) => c.repeat(),
      effects: [
        CustomEffect(
          duration: _run.ms,
          builder: (context, v, child) => CustomPaint(
            size: Size.square(size),
            painter: _DoorPainter(t: v * _run / 1000, color: color),
          ),
        ),
      ],
      child: SizedBox.square(dimension: size),
    );
  }
}

/// The wall, its two leaves and the dots at [t] seconds into a run, on a 24 px grid; no dots and
/// the door shut when [t] is null.
class _DoorPainter extends CustomPainter {
  _DoorPainter({required this.t, required this.color});
  final double? t;
  final Color color;

  /// The first dot hits the door, the door opens, the first dot goes, the door shuts.
  static const _impact = .8;
  static const _opens = 2.5;
  static const _goes = 2.9;
  static const _shuts = 5.55;

  static const _wall = 1.8;
  static const _dot = 1.2;
  static const _top = 7.0;
  static const _bottom = 17.0;

  /// Where the dots come in from, off the left edge.
  static const _from = -2.0;

  /// Where the first dot touches the shut door.
  static const _touch = 12 - _wall / 2 - _dot;

  /// Where each dot waits: the first a little back from the door, after bouncing off it, the others
  /// behind it, with room between them.
  static const _waits = [_touch - 1.6, _touch - 1.6 - 3.6, _touch - 1.6 - 7.2];

  /// How open the door is: shut, pushed a little by the hit and springing back, open, shut again.
  static double _open(double s) {
    if (s < _impact) return 0;
    if (s < _opens) return .1 * exp(-5 * (s - _impact)) * sin((s - _impact) * 2 * pi / .4);
    if (s >= _shuts) return 1 - Curves.easeInOutCubic.transform(((s - _shuts) / .6).clamp(0, 1));
    return Curves.easeInOutCubic.transform(((s - _opens) / .6).clamp(0, 1));
  }

  /// Dot [i]'s place, its squash (1 round, less flattened against the door) and how visible it is.
  static (double x, double squash, double alpha) _dotAt(double s, int i) {
    final wait = _waits[i];
    double x;
    var squash = 1.0;
    if (i == 0) {
      // drives straight into the door, bounces off it twice, less each time, and rolls back to wait
      // a little away from it
      final k = s - _impact;
      x = k < 0
          ? _from + (_touch - _from) * Curves.easeIn.transform(s / _impact)
          : _touch -
                (_touch - wait) * Curves.easeOut.transform((k / .5).clamp(0, 1)) -
                .9 * exp(-6 * k) * sin(k * pi / .22).abs();
      if (k >= 0) squash = 1 - .35 * exp(-25 * k);
    } else {
      // comes later, at speed, and brakes to a stop behind the one ahead, rocking forward a little,
      // like a jam forming
      final enter = .55 * i;
      final arrive = enter + .9;
      final k = s - arrive;
      x = k < 0
          ? _from + (wait - _from) * Curves.easeOutQuad.transform(((s - enter) / .9).clamp(0, 1))
          : wait + .3 * exp(-8 * k) * sin(k * 2 * pi / .35);
    }
    // green: the first goes, then the next, each speeding up, like cars at a light
    final go = ((s - (_goes + .3 * i)) / 1.1).clamp(0.0, 1.0);
    x += (25 - wait) * go * go;
    final alpha = (1 - ((x - 20) / 4).clamp(0.0, 1.0)) * ((x - _from) / 2).clamp(0.0, 1.0);
    return (x, squash, alpha);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _wall
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(12, 2), const Offset(12, _top), stroke);
    canvas.drawLine(const Offset(12, _bottom), const Offset(12, 22), stroke);
    // the two leaves turn on their hinges, from along the wall to along the way through
    final s = t;
    final a = s == null ? 0.0 : _open(s) * pi / 2;
    const half = (_bottom - _top) / 2;
    for (final (hinge, sign) in [(const Offset(12, _top), 1.0), (const Offset(12, _bottom), -1.0)]) {
      canvas.drawLine(hinge, hinge + Offset(sin(a), sign * cos(a)) * half, stroke);
    }
    if (s == null) return;
    for (var i = 0; i < _waits.length; i++) {
      final (x, squash, alpha) = _dotAt(s, i);
      if (alpha <= 0) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + _dot * (1 - squash), 12),
          width: 2 * _dot * squash,
          height: 2 * _dot / sqrt(squash),
        ),
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_DoorPainter old) => old.t != t || old.color != color;
}
