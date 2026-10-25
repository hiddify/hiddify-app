import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// What the connect button shows. Each look animates on its own clock, [EclipseFrame.since].
enum EclipseLook { idle, starting, waiting, connected, stopping, error }

/// One moment of the button: its look, the look before it, and how long ago each clock started.
class EclipseFrame {
  const EclipseFrame({
    required this.look,
    required this.previous,
    required this.since,
    required this.time,
    required this.color,
    required this.previousColor,
  });

  final EclipseLook look;
  final EclipseLook previous;

  /// Seconds since [look] began.
  final double since;

  /// Seconds since the button appeared.
  final double time;

  final Color color;
  final Color previousColor;

  /// The logo's colour, eased from the look before.
  Color get logoColor => Color.lerp(previousColor, color, _easeInOut(since / .45))!;

  EclipseFrame get _before => EclipseFrame(
    look: previous,
    previous: previous,
    since: 3 + since,
    time: time,
    color: previousColor,
    previousColor: previousColor,
  );
}

/// How much is flowing, each from 0 to 1 on a log scale.
class EclipseTraffic {
  const EclipseTraffic({this.down = 0, this.up = 0});

  final double down;
  final double up;

  double get total => math.max(down, up);

  @override
  bool operator ==(Object other) =>
      other is EclipseTraffic && other.down == down && other.up == up;

  @override
  int get hashCode => Object.hash(down, up);

  /// Speeds in bytes a second and the level each reaches; between two, the level follows the speed
  /// on a log scale.
  static const _steps = [(200.0, .2), (500.0, .5), (1024.0, .65), (10 * 1024.0, .8), (100 * 1024.0, 1.0)];

  /// [bytesPerSecond] as a level: 20% by 200 B/s, 50% by 500 B/s, 65% by 1 KB/s, 80% by 10 KB/s, and
  /// full from 100 KB/s.
  static double level(num bytesPerSecond) {
    final b = bytesPerSecond.toDouble();
    if (b <= 0) return 0;
    var (from, fromLevel) = _steps.first;
    // below the first step a log scale has nowhere to start from, so it rises in a straight line
    if (b <= from) return fromLevel * b / from;
    for (final (to, toLevel) in _steps.skip(1)) {
      if (b <= to) return fromLevel + (toLevel - fromLevel) * math.log(b / from) / math.log(to / from);
      (from, fromLevel) = (to, toLevel);
    }
    return 1;
  }
}

/// The connect button: a white button in front of the sun. Flat in the middle, curving only near
/// its edge. While connected, the traffic is the sun's light round it: download in sun yellow close
/// to the button, upload in plasma blue further out, both reaching further as more flows. A failed
/// connection shows a weak signal and an error badge, whose place [errorBadgeRect] gives.
///
/// Soft glows are drawn sharp into a bounded [Canvas.saveLayer] and blurred once with
/// [ui.ImageFilter.blur], not with a [MaskFilter] on every stroke. Same look, far cheaper.
class EclipseButtonPainter extends CustomPainter {
  EclipseButtonPainter({
    required this.frame,
    required this.radius,
    required this.traffic,
    required this.dark,
    this.drawLogo = true,
    this.logoOpacity = 1,
    super.repaint,
  });

  final EclipseFrame frame;

  /// The radius of the white button.
  final double radius;
  final EclipseTraffic traffic;
  final bool dark;

  /// False when something else, such as a seasonal image, takes the logo's place.
  final bool drawLogo;
  final double logoOpacity;

  static const _fade = .35;

  /// Where the error badge sits in a button of [radius] centred at [center].
  static Rect errorBadgeRect(Offset center, double radius) =>
      Rect.fromCircle(center: center + Offset.fromDirection(math.pi / 4, radius * .74), radius: radius * .22);

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    _Ctx ctx(EclipseFrame frame) => _Ctx(this, canvas, size.center(Offset.zero), frame);
    if (f.since >= _fade || f.previous == f.look) return _paintLook(ctx(f));
    // the looks cross-fade, over a button that stays put; clip the layers to this
    // painter so the offscreen buffers stay small
    final a = _easeInOut(f.since / _fade);
    final bounds = Offset.zero & size;
    ctx(f).disc();
    canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, 1 - a));
    _paintLook(ctx(f._before));
    canvas.restore();
    canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, a));
    _paintLook(ctx(f));
    canvas.restore();
  }

  @override
  bool shouldRepaint(EclipseButtonPainter old) =>
      old.frame.look != frame.look ||
      old.frame.previous != frame.previous ||
      old.frame.since != frame.since ||
      old.frame.time != frame.time ||
      old.frame.color != frame.color ||
      old.frame.previousColor != frame.previousColor ||
      old.traffic != traffic ||
      old.dark != dark ||
      old.radius != radius ||
      old.drawLogo != drawLogo ||
      old.logoOpacity != logoOpacity;
}

void _paintLook(_Ctx x) {
  switch (x.f.look) {
    case EclipseLook.idle:
      x.disc();
      x.bevel();
      x.logo();
    case EclipseLook.starting:
      x.disc();
      x.bevel();
      _barsWave(x);
    case EclipseLook.waiting:
      x.disc();
      x.bevel();
      _radar(x);
      _barsWave(x);
    case EclipseLook.connected:
      _connected(x);
    case EclipseLook.stopping:
      x.disc();
      x.bevel();
      _barsWave(x, backwards: true);
    case EclipseLook.error:
      _error(x);
  }
}

// ---------------------------------------------------------------------------------------------
// The looks

/// The bars brighten one after another, left to right; [backwards], as while disconnecting, from the
/// i back to the short bar, the starting wave played in reverse.
void _barsWave(_Ctx x, {bool backwards = false}) {
  final p = (x.f.time % 1.6) / 1.6;
  double rank(int part) => backwards ? _HiLogo.rank.last - _HiLogo.rank[part] : _HiLogo.rank[part];
  x.logo(parts: _each((i) => _Part(opacity: .4 + .6 * _bump(p * 1.6 - rank(i) * .3))));
}

/// A soft sweep turning inside the button, over two faint guide circles.
void _radar(_Ctx x) {
  final c = x.c;
  c.save();
  x.clipDisc();
  c.drawCircle(
    x.center,
    x.r,
    Paint()
      ..shader = SweepGradient(
        colors: [_alpha(x.col, 0), _alpha(x.col, .14)],
        stops: const [.72, 1],
        transform: GradientRotation(2 * math.pi * x.f.time / 3.6),
      ).createShader(Rect.fromCircle(center: x.center, radius: x.r)),
  );
  for (final g in [.45, .75]) {
    c.drawCircle(
      x.center,
      x.r * g,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _alpha(x.col, .07),
    );
  }
  c.restore();
}

/// The signal steps down to weak, then keeps searching, and the error badge breathes, sending out a
/// soft ring now and then to draw the eye to it.
void _error(_Ctx x) {
  final s = x.f.since;
  x.disc();
  x.bevel();
  const weak = [.72, .52, .34];
  final settled = _easeOut((s - .7) / .6);
  x.logo(
    ghost: _alpha(x.col, .16),
    dx: _shake(s),
    parts: _each((i) {
      final bar = _HiLogo.bar[i];
      final drop = _easeOut((s - (2 - bar) * .1) / .55);
      final waver = .06 * math.sin(x.f.time * 2.3 + bar * 1.7) * settled;
      final fade = bar == 2 ? 1 - .4 * _osc(x.f.time, 2.2) * settled : 1.0;
      return _Part(fill: _lerp(1, weak[bar], drop) + waver, opacity: fade);
    }),
  );
  final badge = EclipseButtonPainter.errorBadgeRect(x.center, x.r);
  final p = ((s - .9) % 1.8) / 1.8;
  if (s > .9) {
    x.c.drawCircle(
      badge.center,
      badge.width / 2 + 2.5 + 12 * _easeOut(p),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - p) + .5
        ..color = _alpha(x.col, .55 * (1 - p)),
    );
  }
  x.badge(_spring((s - .1) * 1.4) * (1 + .05 * _osc(s - .9, 1.8) * settled));
}

/// The eclipse: the button covers the sun, and the traffic is the light round it.
void _connected(_Ctx x) {
  final s = x.f.since;
  final t = x.p.traffic;
  final appear = _easeOut((s - .6) / 1.4);
  final down = t.down * appear;
  final up = t.up * appear;
  final downColor = x.p.dark ? const Color(0xFFFFB020) : const Color(0xFFF59E0B);
  final upColor = x.p.dark ? const Color(0xFF3F7BFF) : const Color(0xFF2563EB);

  // the sun's yellow close to the button, the plasma's blue further out and on top, so the two
  // stay apart instead of mixing to grey
  _corona(x, color: downColor, level: down, reach: .6, rays: 32, seed: 10, plasma: false);
  _flares(x, color: downColor, level: down, seed: 60, reach: .75, additive: true);
  _corona(x, color: upColor, level: up, reach: .95, rays: 52, seed: 40, plasma: true, additive: false, hollow: 1);
  _flares(x, color: upColor, level: up, seed: 80, reach: 1.05, additive: false);

  x.ripple(s, x.col, duration: 1.4);
  x.disc();
  x.bevel();
  // the thin bright edge where the light meets the button
  x.ring(x.r - .5, _alpha(Color.lerp(downColor, upColor, up / (down + up + 1e-6))!, .55 * math.max(down, up)), 1.6);

  // the bars settle with a spring, then breathe in a slow wave, a little taller with more traffic,
  // and the dot floats
  final alive = _easeInOut((s - 1.2) / 1.2);
  final h = [for (var b = 0; b < 3; b++) .75 + .25 * _spring(s * 1.1 - b * .12)];
  double breathe(int bar) => 1 - alive * (.035 * _osc(x.f.time, 3.2, -bar * .12) - .03 * t.total);
  final stem = h[2] * breathe(2);
  x.logo(
    parts: [
      _Part(scaleY: h[0] * breathe(0)),
      _Part(scaleY: h[1] * breathe(1)),
      _Part(scaleY: stem),
      _Part(dy: (1 - stem) * 35.2 - 1.2 * alive * _osc(x.f.time, 2.6)),
    ],
  );
  x.star(x.toPx(const Offset(67, -2)), 6 * _bump((s - .5) / .9));
  if (alive <= 0 || !x.p.drawLogo) return;
  x.logoSpace((c) {
    // some depth: a little lighter at the top
    c.drawRect(
      const Rect.fromLTRB(-2, -2, 66, 66),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .16 * alive),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTRB(0, 0, 64, 64)),
    );
    // a faint shine every 6 s
    final p = ((s - 1.5) % 6) / 1.6;
    if (p <= 0 || p >= 1) return;
    final cx = _lerp(-30, 94, _easeInOut(p));
    c.translate(32, 32);
    c.rotate(.35);
    c.translate(-32, -32);
    final band = Rect.fromLTWH(cx - 12, -30, 24, 124);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .28 * alive),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
  });
}

/// Soft glow at half resolution: blur cost scales with pixels, look stays the same once scaled up.
void _blurredLayer(
  Canvas c,
  Rect bounds,
  double sigma,
  BlendMode blend,
  void Function(Canvas c) paint,
) {
  const scale = 0.5;
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;
  c.save();
  c.translate(cx, cy);
  c.scale(scale);
  c.translate(-cx, -cy);
  // Layer is half the device pixels; sigma scales with it so the soft edge matches full-res.
  c.saveLayer(
    bounds,
    Paint()
      ..blendMode = blend
      ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma * scale, sigmaY: sigma * scale, tileMode: TileMode.decal),
  );
  paint(c);
  c.restore();
  c.restore();
}

/// A corona of [color] behind the button: a soft glow and [rays] that reach further out as [level]
/// rises. [plasma] curls the rays like filaments; [hollow] moves the glow out into a ring.
void _corona(
  _Ctx x, {
  required Color color,
  required double level,
  required double reach,
  required int rays,
  required int seed,
  required bool plasma,
  bool additive = true,
  double hollow = 0,
}) {
  if (level <= .01) return;
  final c = x.c;
  final time = x.f.time;
  // light adds up on a dark background, as real light does
  final blend = additive && x.p.dark ? BlendMode.plus : BlendMode.srcOver;
  final outer = x.r * (1.04 + reach * level);
  final edge = x.r / outer * .98;
  final peak = edge + (1 - edge) * (.35 * hollow);
  c.drawCircle(
    x.center,
    outer,
    Paint()
      ..blendMode = blend
      ..shader = RadialGradient(
        // kept low, so the two lights add up without burning out to white
        colors: [
          _alpha(color, .34 * level * (1 - hollow)),
          _alpha(color, .3 * level),
          _alpha(color, .1 * level),
          _alpha(color, 0),
        ],
        stops: [edge, peak, peak + (1 - peak) * .35, 1],
      ).createShader(Rect.fromCircle(center: x.center, radius: outer)),
  );
  final sigma = plasma ? 2.5 : 4.0;
  final bounds = Rect.fromCircle(center: x.center, radius: outer + sigma * 2);
  _blurredLayer(c, bounds, sigma, blend, (layer) {
    for (var i = 0; i < rays; i++) {
      final drift = time * (plasma ? .04 : .025) * (_hash(i, seed + 1) > .5 ? 1 : -1);
      final dir = Offset.fromDirection(2 * math.pi * _hash(i, seed) + drift);
      final len = x.r * reach * 1.2 * level * (.45 + .55 * _hash(i, seed + 2)) * (.7 + .3 * math.sin(time * .35 + i));
      final from = x.center + dir * (x.r - 2 + hollow * x.r * .12);
      final to = x.center + dir * (x.r + len);
      final path = Path()..moveTo(from.dx, from.dy);
      if (plasma) {
        final bend = Offset(-dir.dy, dir.dx) * (len * .18 * math.sin(time * .5 + i * 1.7));
        final mid = Offset.lerp(from, to, .5)! + bend;
        path.quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
      } else {
        path.lineTo(to.dx, to.dy);
      }
      layer.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = plasma ? 2.2 : 3.5
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(from, to, [_alpha(color, .45 * level), _alpha(color, 0)]),
      );
    }
  });
}

/// Flares of [color]: long streamers that rise from behind the button, each from a new place, curl a
/// little and fade, and small sparks drifting out; longer and brighter as [level] rises.
void _flares(
  _Ctx x, {
  required Color color,
  required double level,
  required int seed,
  required double reach,
  required bool additive,
}) {
  if (level <= .01) return;
  final c = x.c;
  final time = x.f.time;
  final blend = additive && x.p.dark ? BlendMode.plus : BlendMode.srcOver;
  const life = 3.4;
  // Halo + core in one half-res blur (same widths/alphas as the old dual MaskFilter passes).
  final flares = <({Path path, Offset from, Offset to, double fade})>[];
  for (var k = 0; k < 7; k++) {
    final clock = time / life + _hash(k, seed);
    final p = clock % 1;
    final round = clock.floor();
    final dir = Offset.fromDirection(2 * math.pi * _hash(round * 7 + k, seed + 1));
    final len = x.r * reach * level * (.6 + .4 * _hash(round * 7 + k, seed + 2)) * _easeOut(p / .6);
    final fade = _soft(p);
    if (fade <= 0 || len <= 0) continue;
    final from = x.center + dir * (x.r - 1);
    final to = x.center + dir * (x.r + len);
    final bend = Offset(-dir.dy, dir.dx) * (len * .25 * (_hash(round, seed + 3) - .5));
    final mid = Offset.lerp(from, to, .55)! + bend;
    flares.add((
      path: Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy),
      from: from,
      to: to,
      fade: fade,
    ));
  }
  if (flares.isNotEmpty) {
    final bounds = Rect.fromCircle(center: x.center, radius: x.r * (1 + reach * level) + 20);
    _blurredLayer(c, bounds, 4.0, blend, (layer) {
      for (final f in flares) {
        for (final (width, strength) in [(7.0, .35), (2.4, .7)]) {
          layer.drawPath(
            f.path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round
              ..shader = ui.Gradient.linear(f.from, f.to, [
                _alpha(color, strength * level * f.fade),
                _alpha(color, 0),
              ]),
          );
        }
      }
    });
  }
  for (var i = 0; i < 16; i++) {
    final p = (time * (.18 + .1 * _hash(i, seed + 4)) + _hash(i, seed + 5)) % 1;
    final at = x.center + Offset.fromDirection(2 * math.pi * _hash(i, seed + 6), x.r + 3 + p * x.r * reach * level);
    c.drawCircle(
      at,
      1.6,
      Paint()
        ..blendMode = blend
        ..color = _alpha(color, .7 * level * _bump(p)),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Painting helpers

/// Soft disc + bevel, recorded once per (radius, dark) so every frame only draws a picture.
ui.Picture? _bodyPicture;
double? _bodyR;
bool? _bodyDark;
const _bodyPad = 24.0;

ui.Picture _bodyFor(double r, bool dark) {
  if (_bodyPicture != null && _bodyR == r && _bodyDark == dark) return _bodyPicture!;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final center = Offset(r + _bodyPad, r + _bodyPad);
  final shadowColor = dark ? const Color(0x73000000) : const Color(0x2E000000);
  canvas.drawCircle(
    center.translate(0, 3),
    r,
    Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  canvas.drawCircle(center, r, Paint()..color = Colors.white);
  final rect = Rect.fromCircle(center: center, radius: r);
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: .07),
        ],
        stops: const [0, .8, 1],
      ).createShader(rect),
  );
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: r - 4),
    math.pi * .1,
    math.pi * .55,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.black.withValues(alpha: .045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: r - 2.5),
    math.pi * 1.1,
    math.pi * .5,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
  );
  _bodyPicture = rec.endRecording();
  _bodyR = r;
  _bodyDark = dark;
  return _bodyPicture!;
}

class _Ctx {
  _Ctx(this.p, this.c, this.center, this.f) : r = p.radius;

  final EclipseButtonPainter p;
  final Canvas c;
  final Offset center;
  final EclipseFrame f;
  final double r;

  Color get col => f.logoColor;

  /// The logo's box: it fills half the button's width.
  Rect get logoRect => Rect.fromCenter(center: center.translate(0, -r * .02), width: r, height: r);

  /// Logo units to pixels.
  double get k => r / 64;

  Offset toPx(Offset logoPoint) => logoRect.topLeft + logoPoint * k;

  /// White disc, soft shadow and bevel (cached).
  void disc() {
    final picture = _bodyFor(r, p.dark);
    c.save();
    c.translate(center.dx - r - _bodyPad, center.dy - r - _bodyPad);
    c.drawPicture(picture);
    c.restore();
  }

  /// Bevel is baked into [disc]'s cached picture; kept so call sites stay readable.
  void bevel() {}

  void logo({List<_Part>? parts, Color? ghost, double dx = 0}) {
    if (!p.drawLogo) return;
    c.save();
    c.translate(dx * k, 0);
    _paintLogo(c, logoRect, color: _alpha(col, p.logoOpacity), parts: parts, ghost: ghost);
    c.restore();
  }

  /// Paints in logo units, clipped to the logo's shape.
  void logoSpace(void Function(Canvas c) paint) {
    c.save();
    c.translate(logoRect.left, logoRect.top);
    c.scale(k);
    c.clipPath(_HiLogo.all);
    paint(c);
    c.restore();
  }

  void clipDisc() => c.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r - .5)));

  void ring(double radius, Color color, double width) {
    if (color.a <= 0) return;
    c.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  /// One ring that leaves the button and fades.
  void ripple(double since, Color color, {double duration = 1}) {
    final p = since / duration;
    if (p < 0 || p >= 1) return;
    ring(r * (1 + .45 * _easeOut(p)), _alpha(color, .6 * (1 - p)), 3 * (1 - p) + .5);
  }

  void badge(double appear) {
    if (appear <= 0) return;
    final rect = EclipseButtonPainter.errorBadgeRect(center, r);
    final at = rect.center;
    final br = rect.width / 2 * appear;
    c.drawCircle(at, br + 2.5, Paint()..color = Colors.white);
    c.drawCircle(at, br, Paint()..color = col);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = br * .22
      ..strokeCap = StrokeCap.round;
    c.drawLine(at.translate(0, -br * .45), at.translate(0, br * .1), stroke);
    c.drawCircle(at.translate(0, br * .42), br * .12, Paint()..color = Colors.white);
  }

  void star(Offset at, double size) {
    if (size <= 0) return;
    final path = Path()
      ..moveTo(at.dx, at.dy - size)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + size, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + size)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - size, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - size)
      ..close();
    c.drawPath(path, Paint()..color = col);
  }
}

// ---------------------------------------------------------------------------------------------
// The Hi logo, from assets/images/logo.svg, in its 64 × 64 units, in four parts: the short bar with
// the crossbar, the tall bar, the stem and the dot

Path _svgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[MCLVHZ]|-?\d*\.?\d+').allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = '';
  var x = 0.0;
  var y = 0.0;
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp('[A-Z]').hasMatch(tokens[i])) cmd = tokens[i++];
    switch (cmd) {
      case 'M':
        x = n();
        y = n();
        path.moveTo(x, y);
        cmd = 'L';
      case 'L':
        x = n();
        y = n();
        path.lineTo(x, y);
      case 'H':
        x = n();
        path.lineTo(x, y);
      case 'V':
        y = n();
        path.lineTo(x, y);
      case 'C':
        final x1 = n();
        final y1 = n();
        final x2 = n();
        final y2 = n();
        x = n();
        y = n();
        path.cubicTo(x1, y1, x2, y2, x, y);
      case 'Z':
        path.close();
    }
  }
  return path;
}

abstract final class _HiLogo {
  static final dot = _svgPath(
    'M47.1582 14.4283C47.1582 13.8368 47.4684 13.2886 47.9757 12.9842L61.4494 4.89891C62.5721 4.22529 64.0003 '
    '5.03389 64.0003 6.34306V20.2103C64.0003 21.1405 63.2461 21.8945 62.3161 21.8945H48.8424C47.9124 21.8945 '
    '47.1582 21.1405 47.1582 20.2103V14.4283Z',
  );

  static final h = _svgPath(
    'M24.3966 26.4593C23.8893 26.7637 23.5789 27.3118 23.5789 27.9034V43.7921L23.5789 45.4751L23.5789 45.4763L23.5789 '
    '48.0001C23.5789 48.9301 22.8249 49.6001 21.8947 49.6001H18.5263C17.5962 49.6001 16.8421 48.9301 16.8421 48.0001V '
    '45.4751V34.976C16.8421 33.6669 15.4139 32.8583 14.2913 33.5319L0.817607 41.6171C0.310362 41.9216 0 42.4696 0 '
    '43.0615V60.6342C0 61.5642 0.754048 62.3184 1.68421 62.3184H15.1579C16.0881 62.3184 16.8421 61.5642 16.8421 '
    '60.6342V58.9488V56.8314C16.8421 55.9011 17.5962 55.3376 18.5263 55.3376H21.8947C22.8249 55.3376 23.5789 55.9011 '
    '23.5789 56.8314V58.9488L23.5789 60.6342C23.5789 61.5642 24.333 62.3184 25.2632 62.3184H38.7368C39.6669 62.3184 '
    '40.4211 61.5642 40.4211 60.6342V45.4763V43.7921V19.8182C40.4211 18.509 38.9928 17.7004 37.8701 18.374L24.3966 '
    '26.4593Z',
  )..fillType = PathFillType.evenOdd;

  static final stem = _svgPath(
    'M47.1592 28.7999V60.7999C47.1592 61.6836 47.9132 62.3999 48.8434 62.3999H62.3171C63.2472 62.3999 64.0013 61.6836 '
    '64.0013 60.7999V28.7999C64.0013 27.9162 63.2472 27.1999 62.3171 27.1999H48.8434C47.9132 27.1999 47.1592 27.9162 '
    '47.1592 28.7999Z',
  );

  static final all = Path.combine(PathOperation.union, Path.combine(PathOperation.union, h, stem), dot);

  static Path pathOf(int part) => part < 2 ? h : (part == 2 ? stem : dot);

  static Rect clipOf(int part) => switch (part) {
    0 => const Rect.fromLTRB(-2, -2, 23.58, 66),
    1 => const Rect.fromLTRB(23.58, -2, 42, 66),
    _ => const Rect.fromLTRB(-2, -2, 66, 66),
  };

  static const tops = [32.9, 18.2, 27.2, 4.2];
  static const bottoms = [62.32, 62.32, 62.4, 21.9];
  static const centersX = [8.4, 32.0, 55.6, 55.6];

  /// The signal bar each part belongs to: the stem and the dot are the third.
  static const bar = [0, 1, 2, 2];

  /// The order the parts light up in: the dot just after the stem.
  static const rank = [0.0, 1.0, 2.0, 2.6];
}

/// How one part of the logo looks.
class _Part {
  const _Part({this.fill = 1, this.opacity = 1, this.dy = 0, this.scaleY = 1});

  /// How much of the part is coloured, from the bottom up.
  final double fill;
  final double opacity;
  final double dy;
  final double scaleY;
}

List<_Part> _each(_Part Function(int part) style) => [for (var i = 0; i < 4; i++) style(i)];

void _paintLogo(Canvas c, Rect r, {required Color color, List<_Part>? parts, Color? ghost}) {
  c.save();
  c.translate(r.left, r.top);
  c.scale(r.width / 64);
  for (var i = 0; i < 4; i++) {
    final s = parts?[i] ?? const _Part();
    final top = _HiLogo.tops[i];
    final bottom = _HiLogo.bottoms[i];
    c.save();
    c.translate(0, s.dy);
    if (s.scaleY != 1) {
      c.translate(_HiLogo.centersX[i], bottom);
      c.scale(1, s.scaleY);
      c.translate(-_HiLogo.centersX[i], -bottom);
    }
    // not antialiased, so the two halves of the H meet without a seam
    c.clipRect(_HiLogo.clipOf(i), doAntiAlias: false);
    final path = _HiLogo.pathOf(i);
    if (ghost != null) c.drawPath(path, Paint()..color = ghost);
    if (s.fill > 0 && s.opacity > 0) {
      if (s.fill < 1) c.clipRect(Rect.fromLTRB(-2, bottom - s.fill * (bottom - top), 66, 66));
      c.drawPath(path, Paint()..color = _alpha(color, s.opacity));
    }
    c.restore();
  }
  c.restore();
}

// ---------------------------------------------------------------------------------------------
// Easing

double _c01(double x) => x.clamp(0.0, 1.0);
double _easeOut(double x) => Curves.easeOutCubic.transform(_c01(x));
double _easeInOut(double x) => Curves.easeInOutCubic.transform(_c01(x));
double _lerp(double a, double b, double t) => a + (b - a) * t;

/// 0 → 1 → 0 over one [period].
double _osc(double t, double period, [double phase = 0]) => .5 - .5 * math.cos(2 * math.pi * (t / period + phase));

/// 0 → 1 → 0 while x goes from 0 to 1, and 0 outside.
double _bump(double x) => x <= 0 || x >= 1 ? 0 : math.sin(math.pi * x);

/// 0 → 1 → 0 with no corners.
double _soft(double x) => x <= 0 || x >= 1 ? 0 : .5 - .5 * math.cos(2 * math.pi * x);

/// Settles on 1 with one soft overshoot.
double _spring(double x) => x <= 0 ? 0 : 1 - math.exp(-6 * x) * math.cos(9 * x);

/// A short horizontal shake that dies out.
double _shake(double s) => math.sin(s * 38) * math.exp(-s * 6) * 3;

double _hash(int i, int salt) => ((math.sin(i * 12.9898 + salt * 78.233) * 43758.5453) % 1 + 1) % 1;

Color _alpha(Color c, double a) => c.withValues(alpha: c.a * _c01(a));
