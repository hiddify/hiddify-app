import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/theme/cat/paw_print.dart';

/// Faint trails of paw prints behind [child], as if a cat had walked across
/// the page, and a fresh print wherever the page is touched.
class PawPrintsBackground extends StatefulWidget {
  const PawPrintsBackground({super.key, required this.child, this.color, this.stampOnTouch = true});

  final Widget child;

  /// Color of the prints. Defaults to the theme cat's paw print color.
  final Color? color;

  /// Leaves a print under every touch or click, fading away.
  final bool stampOnTouch;

  @override
  State<PawPrintsBackground> createState() => _PawPrintsBackgroundState();
}

class _PawPrintsBackgroundState extends State<PawPrintsBackground> with SingleTickerProviderStateMixin {
  static const Duration _stampLife = Duration(milliseconds: 1400);
  static const int _maxStamps = 12;

  final List<_Stamp> _stamps = [];
  final ValueNotifier<Duration> _clock = ValueNotifier(Duration.zero);
  final math.Random _random = math.Random();
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  void _tick(Duration elapsed) {
    _clock.value = elapsed;
    _stamps.removeWhere((stamp) => elapsed - stamp.born > _stampLife);
    if (_stamps.isEmpty) {
      _ticker.stop();
      _clock.value = Duration.zero;
    }
  }

  bool _reduceMotion = false;

  void _stamp(PointerDownEvent event) {
    if (_reduceMotion) return;
    if (!_ticker.isActive) _ticker.start();
    if (_stamps.length >= _maxStamps) _stamps.removeAt(0);
    _stamps.add(_Stamp(event.localPosition, _clock.value, (_random.nextDouble() - .5) * .9));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Color color = widget.color ?? CatTheme.of(context).pawPrint;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Widget page = CustomPaint(
      painter: _StampsPainter(_stamps, _clock, color.withValues(alpha: dark ? .3 : .22), _stampLife),
      child: widget.child,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(isComplex: true, painter: _TrailsPainter(color.withValues(alpha: dark ? .085 : .07))),
          ),
        ),
        if (widget.stampOnTouch)
          Listener(behavior: HitTestBehavior.translucent, onPointerDown: _stamp, child: page)
        else
          page,
      ],
    );
  }
}

class _Stamp {
  _Stamp(this.position, this.born, this.rotation);

  final Offset position;
  final Duration born;
  final double rotation;
}

/// The trails: a few cats walking across the page in gentle curves, steps
/// alternating left and right. Seeded, so the page looks the same every time.
class _TrailsPainter extends CustomPainter {
  _TrailsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Paint paint = Paint()..color = color;
    final math.Random random = math.Random(7);
    const double paw = 22;
    final double diagonal = size.longestSide * 1.4;

    for (final (Offset start, double heading) in [
      (Offset(-paw, size.height * .78), -.42),
      (Offset(size.width * .08, -paw), 1.05),
      (Offset(size.width + paw, size.height * .3), math.pi - .45),
    ]) {
      double angle = heading;
      Offset position = start;
      for (int step = 0; step * paw * 1.7 < diagonal; step++) {
        angle += (random.nextDouble() - .5) * .18;
        position += Offset(math.cos(angle), math.sin(angle)) * paw * 1.7;
        final double side = step.isEven ? 1 : -1;
        // a print sits to one side of the path, toes along the heading
        final Offset print = position + Offset(-math.sin(angle), math.cos(angle)) * paw * .45 * side;
        paintPawPrint(canvas, print, paw * (.9 + random.nextDouble() * .2), paint, rotation: angle + math.pi / 2);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailsPainter oldDelegate) => oldDelegate.color != color;
}

/// Prints under touches: they press in quickly and fade.
class _StampsPainter extends CustomPainter {
  _StampsPainter(this.stamps, this.clock, this.color, this.life) : super(repaint: clock);

  final List<_Stamp> stamps;
  final ValueNotifier<Duration> clock;
  final Color color;
  final Duration life;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stamp in stamps) {
      final double t = ((clock.value - stamp.born).inMicroseconds / life.inMicroseconds).clamp(0, 1);
      final double press = Curves.easeOutBack.transform(math.min(1, t * 5));
      final Paint paint = Paint()..color = color.withValues(alpha: color.a * (1 - Curves.easeIn.transform(t)));
      paintPawPrint(canvas, stamp.position, 34 * press, paint, rotation: stamp.rotation);
    }
  }

  @override
  bool shouldRepaint(_StampsPainter oldDelegate) => true;
}
