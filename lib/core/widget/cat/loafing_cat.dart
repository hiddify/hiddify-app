import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hiddify/core/theme/cat/cat_ears_border.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/widget/cat/cat_bubble.dart';

/// A cat loafing on whatever sits right below it, seen from the side: tucked
/// up, asleep, breathing, its tail swishing now and then.
///
/// Tapping wakes it for a few seconds; with [meow] set it also says so.
/// It faces the end of the line of reading, so it looks into the app from
/// the start side.
class LoafingCat extends StatefulWidget {
  const LoafingCat({super.key, this.width = 64, this.meow, this.onWake});

  final double width;

  /// What the cat says when woken. Null wakes it silently.
  final String? meow;

  /// Called when a tap wakes the cat, for haptic feedback.
  final VoidCallback? onWake;

  @override
  State<LoafingCat> createState() => _LoafingCatState();
}

class _LoafingCatState extends State<LoafingCat> with SingleTickerProviderStateMixin {
  static const Size _box = Size(76, 44);

  /// Breathing, the tail and the z's all share this period, so the cat can
  /// stop between two of them without a jump.
  static const double period = 3.2;

  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0);
  final math.Random _random = math.Random();
  Timer? _nap;
  double _lastTick = 0;
  double _moveFor = 0;
  double _awake = 0;
  double _awakeFor = 0;
  double _twitch = 0;
  double _nextTwitch = 2;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _nap?.cancel();
      _ticker.stop();
    } else if (!_ticker.isActive && _nap == null) {
      _move();
    }
  }

  /// Moves for two periods, then keeps still for a while: a sleeping cat
  /// doesn't need every frame the screen can draw.
  void _move() {
    _nap?.cancel();
    _nap = null;
    _moveFor = period * 2;
    if (!_ticker.isActive) {
      _lastTick = 0;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final double now = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final double dt = (now - _lastTick).clamp(0, .1);
    _lastTick = now;
    _awakeFor = math.max(0, _awakeFor - dt);
    _awake += ((_awakeFor > 0 ? 1 : 0) - _awake) * (1 - math.exp(-dt * 6));
    _nextTwitch -= dt;
    if (_nextTwitch <= 0) {
      _twitch = 1;
      _nextTwitch = 2 + _random.nextDouble() * 3;
    }
    _twitch = math.max(0, _twitch - dt / .3);
    _moveFor -= dt;
    if (_moveFor <= 0 && _awakeFor <= 0 && _awake < .01) {
      // back where the cycle starts, so the still cat matches the moving one
      _time.value = 0;
      _awake = 0;
      _ticker.stop();
      _nap = Timer(Duration(milliseconds: 5000 + _random.nextInt(7000)), _move);
      return;
    }
    _time.value += dt;
  }

  void _wake() {
    _awakeFor = period;
    if (_reduceMotion) {
      _awake = 1;
      _time.value += .001;
    } else {
      _move();
    }
    widget.onWake?.call();
    if (widget.meow != null) CatBubble.show(context, widget.meow!);
  }

  @override
  void dispose() {
    _nap?.cancel();
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _wake,
          child: Transform.flip(
            flipX: rtl,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(widget.width, widget.width * _box.height / _box.width),
                painter: _LoafPainter(
                  time: _time,
                  awake: () => _awake,
                  twitch: () => _twitch,
                  cat: CatTheme.of(context),
                  zColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoafPainter extends CustomPainter {
  _LoafPainter({required this.time, required this.awake, required this.twitch, required this.cat, required this.zColor})
    : super(repaint: time);

  final ValueNotifier<double> time;
  final double Function() awake;
  final double Function() twitch;
  final CatTheme cat;
  final Color zColor;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = time.value;
    final double up = awake();
    final double scale = size.width / _LoafingCatState._box.width;
    final double breath = math.sin(t * 2 * math.pi / _LoafingCatState.period);
    canvas
      ..save()
      ..scale(scale);

    _paintTail(canvas, t, up);

    // the body breathes, rising from the ground
    canvas
      ..save()
      ..translate(0, 44)
      ..scale(1, 1 + breath * .035)
      ..translate(0, -44);
    const Rect bodyRect = Rect.fromLTRB(8, 18, 60, 44);
    final RRect body = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(6),
    );
    canvas
      ..drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(cat.fur, Colors.white, .15)!, cat.fur, Color.lerp(cat.fur, cat.furShade, .35)!],
          ).createShader(bodyRect),
      )
      ..drawRRect(body, _stroke(cat.outline, 1.3));
    if (cat.stripes) {
      final Paint stripe = _stroke(cat.furShade, 2.4);
      for (final double x in [22, 30, 38]) {
        canvas.drawLine(Offset(x, 19.6), Offset(x - 2, 25), stripe);
      }
    }
    // front paws, tucked under
    for (final double x in [49, 57]) {
      final Rect paw = Rect.fromCenter(center: Offset(x, 42), width: 10, height: 5.5);
      canvas
        ..drawOval(paw, Paint()..color = cat.muzzle)
        ..drawOval(paw, _stroke(cat.outline, 1));
    }
    canvas.restore();

    canvas
      ..save()
      ..translate(0, -breath * .8 - up * 2);
    _paintHead(canvas, t, up);
    canvas.restore();

    if (up < .5) _paintZzz(canvas, t, 1 - up * 2);
    canvas.restore();
  }

  void _paintTail(Canvas canvas, double t, double up) {
    // a woken cat swishes twice as fast
    final double swish = math.sin(t * 2 * math.pi / _LoafingCatState.period * (1 + up));
    final Offset tip = Offset(
      3 + swish * (3 + up * 3),
      20 - up * 8 + (1 - math.cos(t * 2 * math.pi / _LoafingCatState.period)) * 1.5,
    );
    final Path tail = Path()
      ..moveTo(18, 39)
      ..cubicTo(4, 42, -1, 32, tip.dx, tip.dy);
    canvas
      ..drawPath(tail, _stroke(cat.outline, 7.6))
      ..drawPath(tail, _stroke(cat.fur, 5.4));
    // a darker tip
    for (final metric in tail.computeMetrics()) {
      canvas.drawPath(metric.extractPath(metric.length * .78, metric.length), _stroke(cat.furShade, 5.4));
    }
  }

  void _paintHead(Canvas canvas, double t, double up) {
    final double perk = up * -.15 + twitch() * .3;
    final Paint fur = Paint()..color = cat.fur;
    final Paint outline = _stroke(cat.outline, 1.2);
    for (final (Offset base, double tilt) in [(const Offset(51.5, 13), -.28), (const Offset(63, 11.5), .22 + perk)]) {
      final CatEarGeometry ear = CatEarGeometry.build(baseCenter: base, halfBase: 5.2, length: 11.5, tilt: tilt);
      canvas
        ..drawPath(ear.outer, fur)
        ..drawPath(ear.outer, outline)
        ..drawPath(ear.inner, Paint()..color = cat.innerEar);
    }
    final Rect head = Rect.fromCenter(center: const Offset(59, 21), width: 27, height: 23);
    canvas
      ..drawOval(head, fur)
      ..drawOval(head, outline)
      ..drawOval(Rect.fromCenter(center: const Offset(66.5, 25.2), width: 10, height: 7), Paint()..color = cat.muzzle)
      ..drawOval(
        Rect.fromCenter(center: const Offset(58.5, 25.5), width: 5.5, height: 2.8),
        Paint()..color = cat.blush.withValues(alpha: .5),
      );

    // eyes: shut and sleepy, open and round when woken
    for (final (Offset eye, double size) in [(const Offset(57.5, 19.5), 1.0), (const Offset(65.5, 19.5), .85)]) {
      if (up < .5) {
        canvas.drawPath(
          Path()
            ..moveTo(eye.dx - 2.6 * size, eye.dy)
            ..quadraticBezierTo(eye.dx, eye.dy + 2.4 * size, eye.dx + 2.6 * size, eye.dy),
          _stroke(cat.line, 1.3),
        );
      } else {
        final Rect iris = Rect.fromCenter(center: eye, width: 5.2 * size, height: 6 * size * (up - .5) * 2);
        canvas
          ..drawOval(iris, Paint()..color = cat.iris)
          ..drawOval(
            Rect.fromCenter(center: eye.translate(.6, 0), width: 2 * size, height: iris.height * .85),
            Paint()..color = cat.pupil,
          )
          ..drawCircle(eye.translate(-.4, -1), .8 * size, Paint()..color = cat.eyeShine)
          ..drawOval(iris, _stroke(cat.line, .8));
      }
    }

    // nose, mouth, whiskers
    canvas
      ..drawPath(
        Path()
          ..moveTo(69.2, 22.6)
          ..lineTo(72, 22.8)
          ..lineTo(70.4, 24.8)
          ..close(),
        Paint()..color = cat.nose,
      )
      ..drawPath(
        Path()
          ..moveTo(70.4, 24.8)
          ..quadraticBezierTo(70, 26.6, 68.4, 26)
          ..moveTo(70.4, 24.8)
          ..quadraticBezierTo(71, 26.6, 72.4, 26),
        _stroke(cat.line, .8),
      );
    final Paint whisker = _stroke(cat.whisker.withValues(alpha: .85), .6);
    canvas
      ..drawLine(const Offset(70, 26), const Offset(80, 24.5), whisker)
      ..drawLine(const Offset(70, 26.6), const Offset(79.5, 28.2), whisker);
  }

  void _paintZzz(Canvas canvas, double t, double amount) {
    for (int i = 0; i < 2; i++) {
      final double phase = (t / _LoafingCatState.period + i / 2) % 1;
      final double s = 3 + 3 * phase;
      final Offset c = Offset(70 + 8 * phase, 6 - 14 * phase);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - s / 2, c.dy - s / 2)
          ..lineTo(c.dx + s / 2, c.dy - s / 2)
          ..lineTo(c.dx - s / 2, c.dy + s / 2)
          ..lineTo(c.dx + s / 2, c.dy + s / 2),
        _stroke(zColor.withValues(alpha: zColor.a * amount * math.sin(math.pi * phase)), 1.1),
      );
    }
  }

  @override
  bool shouldRepaint(_LoafPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.cat != cat || oldDelegate.zColor != zColor;
}
