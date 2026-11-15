import 'dart:math' as math;
import 'dart:typed_data';
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

  /// Seconds the button's motion has run: a clock that stops while the button stands still, so
  /// what it shows then is the moment it stopped at.
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
  bool operator ==(Object other) => other is EclipseTraffic && other.down == down && other.up == up;

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
/// Nothing in it is blurred while it is drawn: the light, the button's shadow and its bevel are
/// meshes of triangles that hold the softness already (see [_Light] and [_Body]), so a frame is a
/// few draw calls. Blurring layers of sharp strokes offscreen, on every frame, was most of what
/// the button cost, with a graphics card and without one.
class EclipseButtonPainter extends CustomPainter {
  EclipseButtonPainter({
    required this.frame,
    required this.radius,
    required this.traffic,
    required this.dark,
    this.drawLogo = true,
    this.logoOpacity = 1,
    this.pixelRatio = 1,
    this.simple = false,
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

  /// The screen's device pixels per logical pixel: the sparks are drawn from a finer dot on a
  /// dense screen.
  final double pixelRatio;

  /// The button stands still: reduce animations (connected only), the system's reduce motion, or
  /// the endless motion stopped. The light round it is the same light, rays, flares and sparks, as
  /// it was at [EclipseFrame.time], which no longer runs, and the logo keeps its resting shape.
  /// It is drawn once and kept, until the traffic steps to another level.
  final bool simple;

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
      old.logoOpacity != logoOpacity ||
      old.pixelRatio != pixelRatio ||
      old.simple != simple;
}

void _paintLook(_Ctx x) {
  switch (x.f.look) {
    case EclipseLook.idle:
      x.disc();
      x.logo();
    case EclipseLook.starting:
      x.disc();
      _barsWave(x);
    case EclipseLook.waiting:
      x.disc();
      _radar(x);
      _barsWave(x);
    case EclipseLook.connected:
      _connected(x);
    case EclipseLook.stopping:
      x.disc();
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
  if (!x.p.drawLogo) return;
  final color = _alpha(x.col, x.p.logoOpacity);
  double rank(int part) => backwards ? _HiLogo.rank.last - _HiLogo.rank[part] : _HiLogo.rank[part];
  final shade = [for (var i = 0; i < 4; i++) _alpha(color, .4 + .6 * _bump((x.f.time - rank(i) * .3) % 1.6))];
  x.logoSpace((c) {
    // the H stays one piece: its crossbar fades from the short bar's shade into the tall bar's
    c.drawPath(
      _HiLogo.h,
      Paint()..shader = ui.Gradient.linear(const Offset(16.84, 0), const Offset(23.58, 0), [shade[0], shade[1]]),
    );
    c.drawPath(_HiLogo.stem, Paint()..color = shade[2]);
    c.drawPath(_HiLogo.dot, Paint()..color = shade[3]);
  });
}

/// A soft sweep turning inside the button, over two faint guide circles, kept out of the logo.
void _radar(_Ctx x) {
  final c = x.c;
  c.drawCircle(
    x.center,
    x.r - .5,
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
  // the logo keeps the button's white under it, so a faded bar doesn't show the radar through it
  if (x.p.drawLogo) x.logoSpace((c) => c.drawPath(_HiLogo.all, Paint()..color = Colors.white));
}

/// The signal steps down to weak, then keeps searching, and the error badge breathes, sending out a
/// soft ring now and then to draw the eye to it.
void _error(_Ctx x) {
  final s = x.f.since;
  x.disc();
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

  // The sun's yellow close to the button, the plasma's blue further out and on top, so the two
  // stay apart instead of mixing to grey. Standing still it is the same light, at the moment its
  // clock stopped: two plain glows in its place looked like another button
  _Light.sun.paint(x, downColor, down, additive: x.p.dark);
  _Light.plasma.paint(x, upColor, up, additive: false);

  x.ripple(s, x.col, duration: 1.4);
  x.disc();
  // the thin bright edge where the light meets the button
  x.ring(x.r - .5, _alpha(Color.lerp(downColor, upColor, up / (down + up + 1e-6))!, .55 * math.max(down, up)), 1.6);

  // the bars settle with a spring, then breathe in a slow wave, a little taller with more traffic,
  // and the dot floats; a button that stands still keeps them at rest
  final alive = _easeInOut((s - 1.2) / 1.2);
  final motion = x.p.simple ? 0.0 : alive;
  final h = [for (var b = 0; b < 3; b++) .75 + .25 * _spring(s * 1.1 - b * .12)];
  double breathe(int bar) => 1 - motion * (.035 * _osc(x.f.time, 3.2, -bar * .12) - .03 * t.total);
  final stem = h[2] * breathe(2);
  x.logo(
    parts: [
      _Part(scaleY: h[0] * breathe(0)),
      _Part(scaleY: h[1] * breathe(1)),
      _Part(scaleY: stem),
      _Part(dy: (1 - stem) * 35.2 - 1.2 * motion * _osc(x.f.time, 2.6)),
    ],
  );
  x.star(x.toPx(const Offset(67, -2)), 6 * _bump((s - .5) / .9));
  if (alive <= 0 || !x.p.drawLogo) return;
  x.logoSpace((c) {
    // Both are white over the logo's box, and show only on the logo: the button under it is
    // white already. So the box is clip enough, and far cheaper than the logo's outline.
    c.clipRect(const Rect.fromLTRB(-2, -2, 66, 66));
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

// ---------------------------------------------------------------------------------------------
// The light and the button's body, as meshes
//
// Nothing soft is blurred while it is drawn. A soft stroke is a strip of triangles that carries
// the cross-section of a blurred stroke as its texture ([_Soft], worked out once) and fades along
// its length through its corners' colours; a glow is rings of corners that shade from one to the
// next. A frame of the full light is four draw calls, and costs about as little without a
// graphics card as with one.

/// One colour of the eclipse's light: a halo, rays, flares and sparks.
class _Light {
  _Light({
    required this.reach,
    required this.flareReach,
    required this.curled,
    required int rays,
    required int raySeed,
    required this.seed,
  }) : _angle = Float64List.fromList([for (var i = 0; i < rays; i++) 2 * math.pi * _hash(i, raySeed)]),
       _turn = Float64List.fromList([for (var i = 0; i < rays; i++) _hash(i, raySeed + 1) > .5 ? 1 : -1]),
       _length = Float64List.fromList([for (var i = 0; i < rays; i++) .45 + .55 * _hash(i, raySeed + 2)]),
       _flarePhase = Float64List.fromList([for (var k = 0; k < _flares; k++) _hash(k, seed)]),
       _sparkSpeed = Float64List.fromList([for (var i = 0; i < _sparks; i++) .18 + .1 * _hash(i, seed + 4)]),
       _sparkPhase = Float64List.fromList([for (var i = 0; i < _sparks; i++) _hash(i, seed + 5)]),
       _sparkX = Float64List.fromList([for (var i = 0; i < _sparks; i++) math.cos(2 * math.pi * _hash(i, seed + 6))]),
       _sparkY = Float64List.fromList([for (var i = 0; i < _sparks; i++) math.sin(2 * math.pi * _hash(i, seed + 6))]);

  /// The sun's yellow, close to the button: straight rays.
  static final sun = _Light(reach: .6, flareReach: .75, curled: false, rays: 32, raySeed: 10, seed: 60);

  /// The plasma's blue, further out: a hollow ring of thin filaments that curl.
  static final plasma = _Light(reach: .95, flareReach: 1.05, curled: true, rays: 52, raySeed: 40, seed: 80);

  static const _flares = 7;
  static const _sparks = 16;

  /// How far the rays reach at full traffic, in button radii; the flares and sparks reach
  /// [flareReach].
  final double reach;
  final double flareReach;

  /// Thin filaments that curl, round a hollow ring; straight rays from the button's edge
  /// otherwise.
  final bool curled;
  final int seed;

  // where each ray points, which way it drifts, and how long it is next to the others
  final Float64List _angle;
  final Float64List _turn;
  final Float64List _length;
  final Float64List _flarePhase;
  final Float64List _sparkSpeed;
  final Float64List _sparkPhase;
  final Float64List _sparkX;
  final Float64List _sparkY;

  /// Draws it in [color] at [level], under the button, which is drawn next. [additive] adds it
  /// to what is under it, as real light does on a dark background.
  void paint(_Ctx x, Color color, double level, {required bool additive}) {
    if (level <= .01) return;
    // Where strokes cross they cover one another: adding each to the next burns the crossings
    // out. So the strokes go down first, over one another, and the glow is added to them; without
    // adding, the glow lies under the strokes.
    if (!additive) _halo(x, color, level, BlendMode.srcOver);
    _strokes(x, color, level);
    if (additive) _halo(x, color, level, BlendMode.plus);
  }

  /// A soft glow out to where the rays reach, kept low so the two lights add up without burning
  /// out to white. It is plain colour over the largest area of all, so it is drawn apart from the
  /// textured strokes.
  void _halo(_Ctx x, Color color, double level, BlendMode blend) {
    final mesh = _Mesh.shared;
    final r = x.r;
    final outer = r * (1.04 + reach * level);
    // under the button's edge, where nothing shows
    final inner = r * .98;
    // the plasma's glow is a ring away from the button
    final peak = curled ? inner + (outer - inner) * .35 : inner;
    mesh.begin(x.center, color);
    mesh.rings([if (curled) (inner, 0.0), (peak, .3 * level), (peak + (outer - peak) * .35, .1 * level), (outer, 0.0)]);
    mesh.draw(x.c, blend, textured: false);
  }

  void _strokes(_Ctx x, Color color, double level) {
    final mesh = _Mesh.shared;
    final r = x.r;
    final time = x.f.time;
    mesh.begin(x.center, color);
    // rays that reach further out as the level rises, drifting slowly round the button
    final soft = curled ? _Soft.filament : _Soft.ray;
    final from = r - 2 + (curled ? r * .12 : 0);
    final drift = time * (curled ? .04 : .025);
    for (var i = 0; i < _angle.length; i++) {
      final len = r * reach * 1.2 * level * _length[i] * (.7 + .3 * math.sin(time * .35 + i));
      mesh.stroke(
        soft,
        r,
        angle: _angle[i] + drift * _turn[i],
        from: from,
        span: r + len - from,
        bent: curled ? len * .18 * math.sin(time * .5 + i * 1.7) : 0,
        lead: 0,
        opacity: .45 * level,
        curved: curled,
      );
    }
    // flares: long streamers that rise from behind the button, each from a new place, curl a
    // little and fade; longer and brighter as the level rises
    for (var k = 0; k < _flares; k++) {
      final clock = time / 3.4 + _flarePhase[k];
      final round = clock.floor();
      final p = clock - round;
      final fade = _soft(p);
      final len = r * flareReach * level * (.6 + .4 * _hash(round * 7 + k, seed + 2)) * _easeOut(p / .6);
      if (fade <= 0 || len <= 0) continue;
      mesh.stroke(
        _Soft.flare,
        r,
        angle: 2 * math.pi * _hash(round * 7 + k, seed + 1),
        from: r - 1,
        span: len + 1,
        bent: len * .25 * (_hash(round, seed + 3) - .5),
        lead: .1,
        opacity: level * fade,
        curved: true,
      );
    }
    // small sparks drifting out, sharp, over the flares
    final fine = x.p.pixelRatio > 2;
    for (var i = 0; i < _sparks; i++) {
      final p = _fract(time * _sparkSpeed[i] + _sparkPhase[i]);
      final alpha = .7 * level * _bump(p);
      if (alpha <= 0) continue;
      final out = r + 3 + p * r * flareReach * level;
      mesh.dot(x.center.dx + _sparkX[i] * out, x.center.dy + _sparkY[i] * out, 1.6, alpha, fine: fine);
    }
    mesh.draw(x.c, BlendMode.srcOver, textured: true);
  }
}

/// The button itself: a soft shadow, the white disc, and a bevel near its edge. The shadow and
/// the bevel are meshes, built once for a button and kept.
class _Body {
  _Body._(this._center, this._r, this._dark, this._shadow, this._bevel);

  static _Body? _kept;

  final Offset _center;
  final double _r;
  final bool _dark;
  final ui.Vertices _shadow;
  final ui.Vertices _bevel;

  /// A disc blurred by a sigma of 6: how dark it is at each distance from its edge, in sigmas.
  static const _shade = [
    (-.75, .773),
    (-.25, .599),
    (.25, .401),
    (.75, .227),
    (1.25, .106),
    (1.75, .04),
    (2.4, .008),
    (3.2, 0.0),
  ];

  /// The body of a button of radius [r] at [center], the one kept if it is the same.
  factory _Body(Offset center, double r, bool dark) {
    final kept = _kept;
    if (kept != null && kept._center == center && kept._r == r && kept._dark == dark) return kept;
    kept?._shadow.dispose();
    kept?._bevel.dispose();
    final mesh = _Mesh.shared;
    // the shadow falls a little below the button; only what is outside the button shows
    mesh.begin(center.translate(0, 3), Colors.black);
    mesh.rings([for (final (at, share) in _shade) (r + at * 6, (dark ? .45 : .18) * share)]);
    final shadow = mesh.vertices(textured: false);
    // the bevel: darker towards the edge, a soft shade inside the lower edge and a thin
    // highlight on the upper left
    mesh.begin(center, Colors.black);
    mesh.rings([(r * .8, 0.0), (r, .07)]);
    mesh.arc(_Soft.shade, radius: r - 4, start: math.pi * .1, sweep: math.pi * .55, opacity: .045);
    mesh.paintIn(Colors.white);
    mesh.arc(
      _Soft.shine,
      radius: r - 2.5,
      start: math.pi * 1.1,
      sweep: math.pi * .5,
      opacity: .8,
      cap: _Soft.shine.cap,
    );
    return _kept = _Body._(center, r, dark, shadow, mesh.vertices(textured: true));
  }

  void paint(Canvas canvas) {
    _Mesh.paint(canvas, _shadow, BlendMode.srcOver, textured: false);
    canvas.drawCircle(_center, _r, Paint()..color = Colors.white);
    _Mesh.paint(canvas, _bevel, BlendMode.srcOver, textured: true);
  }
}

/// A kind of soft stroke: a stroke of some width blurred by [sigma], or a narrow one over a wide
/// one, each at its strength. Its cross-section is a column of the [_Atlas].
class _Soft {
  _Soft(this._column, {required this.sigma, required this.widths}) : assert(widths.length <= 2) {
    final (wide, under) = widths.first;
    final (narrow, over) = widths.last;
    final stacked = widths.length == 2;
    // what is left of it further out than 2.5 sigma cannot be seen, and is not drawn
    half = wide / 2 + 2.5 * sigma;
    // Where the two overlap the upper one hides some of the lower, the more the stronger both
    // are. The column holds the shape at half strength, which is close to it at any.
    _shape = [(wide, under), if (stacked) (narrow, over - .5 * under * over)];
    _floor = _at(half);
    _centre = _at(0);
    _linear = under * _blurred(0, wide) + (stacked ? over * _blurred(0, narrow) : 0);
    _hidden = stacked ? under * over * _blurred(0, narrow) : 0;
    // a round cap is half a circle: as a length of the whole width, an eighth of pi times it
    cap = math.pi / 8 * (stacked ? (wide * under + narrow * over) / (under + over) : wide);
  }

  final int _column;
  final double sigma;

  /// The strokes' widths and strengths, the widest first.
  final List<(double width, double strength)> widths;

  /// How far the blurred stroke reaches from its centre line.
  late final double half;

  /// How far a round cap carries the stroke past its end.
  late final double cap;
  late final List<(double, double)> _shape;
  late final double _floor;
  late final double _centre;
  late final double _linear;
  late final double _hidden;

  /// The column's centre in the atlas.
  double get u => _Atlas.columnWidth * (_column + .5);

  /// A stroke of [width] blurred by [sigma], [v] from its centre line.
  double _blurred(double v, double width) {
    final k = 1 / (sigma * math.sqrt2);
    return .5 * (_erf((v + width / 2) * k) - _erf((v - width / 2) * k));
  }

  double _at(double v) => _shape.fold(0, (sum, w) => sum + w.$2 * _blurred(v, w.$1));

  /// The opacity [v] from the centre line as a share of the centre's, reaching nothing at
  /// [half]: what the atlas holds.
  double profile(double v) => (_at(v) - _floor) / (_centre - _floor);

  /// The opacity on the centre line when the strokes are drawn at [opacity].
  double strength(double opacity) => opacity * (_linear - _hidden * opacity);

  /// The sun's rays.
  static final ray = _Soft(0, sigma: 4, widths: const [(3.5, 1)]);

  /// The plasma's filaments.
  static final filament = _Soft(1, sigma: 2.5, widths: const [(2.2, 1)]);

  /// A flare: a bright core over a wide halo.
  static final flare = _Soft(2, sigma: 4, widths: const [(7, .35), (2.4, .7)]);

  /// The shade inside the button's lower edge, and the highlight on its upper left.
  static final shade = _Soft(3, sigma: 4, widths: const [(6, 1)]);
  static final shine = _Soft(4, sigma: 1.5, widths: const [(2, 1)]);
  static final all = [ray, filament, flare, shade, shine];
}

/// The texture of the meshes: a column for each [_Soft] stroke's cross-section, a white column
/// for plain colour, and a round dot for the sparks.
abstract final class _Atlas {
  static const columnWidth = 4.0;
  static const height = 64.0;
  static const _white = 5;

  /// The centre of the white column.
  static const whiteU = columnWidth * (_white + .5);
  static const whiteV = height / 2;

  /// The squares of two round dots, each filling its square but for a fifth: a fine one for dense
  /// screens, and a coarse one that a screen of one or two pixels to the point shrinks without
  /// losing its round edge. Clear texels lie between them and the white column, which would show
  /// as a line on a dot's side otherwise.
  static const fineDot = Rect.fromLTWH(26, 0, 16, 16);
  static const coarseDot = Rect.fromLTWH(26, 18, 8, 8);
  static const _width = 44;

  static const _keep = Duration(seconds: 30);
  static final _age = Stopwatch();
  static ui.ImageShader? _shader;

  /// The texture as a shader. It is made again every [_keep]: a texture lives on the graphics
  /// card, which can drop it (the app in the background, a display driver that restarts), and a
  /// lost one would leave the light dark for as long as the app runs. Making it is a few rows of
  /// pixels.
  static ui.ImageShader get shader {
    final kept = _shader;
    if (kept != null && _age.elapsed < _keep) return kept;
    // the frames already drawn keep their own reference to it
    kept?.dispose();
    _age
      ..reset()
      ..start();
    return _shader = _bake();
  }

  static ui.ImageShader _bake() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final texel = Paint()
      ..blendMode = BlendMode.src
      ..isAntiAlias = false;
    for (final soft in _Soft.all) {
      for (var row = 0; row < height; row++) {
        final v = ((row + .5) / height * 2 - 1) * soft.half;
        canvas.drawRect(
          Rect.fromLTWH(soft._column * columnWidth, row.toDouble(), columnWidth, 1),
          texel..color = Colors.white.withValues(alpha: _c01(soft.profile(v))),
        );
      }
    }
    canvas.drawRect(const Rect.fromLTWH(_white * columnWidth, 0, columnWidth, height), texel..color = Colors.white);
    for (final dot in [fineDot, coarseDot]) {
      canvas.drawCircle(dot.center, dot.width * .4, Paint()..color = Colors.white);
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_width, height.toInt());
    picture.dispose();
    final shader = ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
      filterQuality: FilterQuality.low,
    );
    // the shader keeps its own reference to the image
    image.dispose();
    return shader;
  }
}

/// Triangles for one draw call, in buffers kept from frame to frame: rings of plain colour, and
/// soft strokes and dots textured from the [_Atlas].
class _Mesh {
  _Mesh._();

  static final shared = _Mesh._();

  /// Corners there is room for. The largest mesh, the plasma's strokes and sparks, takes about 900.
  static const _room = 1280;

  /// Steps round a ring.
  static const _round = 64;
  static final _cos = Float64List.fromList([for (var k = 0; k < _round; k++) math.cos(2 * math.pi * k / _round)]);
  static final _sin = Float64List.fromList([for (var k = 0; k < _round; k++) math.sin(2 * math.pi * k / _round)]);

  final _positions = Float32List(_room * 2);
  final _texture = Float32List(_room * 2);
  final _colors = Int32List(_room);
  final _indices = Uint16List(_room * 4);
  var _corners = 0;
  var _used = 0;
  var _cx = 0.0;
  var _cy = 0.0;
  var _rgb = 0;

  // one stroke's sections: where along it, and how opaque
  final _ts = Float64List(8);
  final _as = Float64List(8);

  /// Starts a mesh round [center] in [color].
  void begin(Offset center, Color color) {
    _corners = 0;
    _used = 0;
    _cx = center.dx;
    _cy = center.dy;
    paintIn(color);
  }

  /// What is added from here on is in [color].
  void paintIn(Color color) {
    _rgb = color.toARGB32() & 0xFFFFFF;
  }

  /// What was added since [begin], to keep. With [textured] false it is plain colour, for a mesh
  /// of rings alone.
  ui.Vertices vertices({required bool textured}) {
    assert(_corners <= _room);
    return ui.Vertices.raw(
      VertexMode.triangles,
      Float32List.sublistView(_positions, 0, _corners * 2),
      textureCoordinates: textured ? Float32List.sublistView(_texture, 0, _corners * 2) : null,
      colors: Int32List.sublistView(_colors, 0, _corners),
      indices: Uint16List.sublistView(_indices, 0, _used),
    );
  }

  /// Draws what was added since [begin].
  void draw(Canvas canvas, BlendMode blend, {required bool textured}) {
    if (_used == 0) return;
    final mesh = vertices(textured: textured);
    paint(canvas, mesh, blend, textured: textured);
    // the frame being recorded keeps its own reference
    mesh.dispose();
  }

  /// Draws [vertices] made with the same [textured].
  static void paint(Canvas canvas, ui.Vertices vertices, BlendMode blend, {required bool textured}) {
    final paint = Paint()..blendMode = blend;
    if (textured) paint.shader = _Atlas.shader;
    // the corners' colour: times the texture, or alone
    canvas.drawVertices(vertices, textured ? BlendMode.modulate : BlendMode.dst, paint);
  }

  /// The mesh's colour at [alpha], as a corner holds it.
  int _shade(double alpha) => ((alpha <= 0 ? 0 : (alpha >= 1 ? 255 : (alpha * 255 + .5).toInt())) << 24) | _rgb;

  int _corner(double x, double y, double u, double v, int color) {
    final n = _corners++;
    _positions[2 * n] = x;
    _positions[2 * n + 1] = y;
    _texture[2 * n] = u;
    _texture[2 * n + 1] = v;
    _colors[n] = color;
    return n;
  }

  /// Two triangles between the corners a, b on one side and c, d on the other.
  void _quad(int a, int b, int c, int d) {
    final i = _used;
    _indices[i] = a;
    _indices[i + 1] = b;
    _indices[i + 2] = c;
    _indices[i + 3] = b;
    _indices[i + 4] = d;
    _indices[i + 5] = c;
    _used = i + 6;
  }

  /// Rings of colour round the centre, each a radius and an opacity, shading from one to the next.
  void rings(List<(double radius, double alpha)> rings) {
    final first = _corners;
    for (final (radius, alpha) in rings) {
      final color = _shade(alpha);
      for (var k = 0; k < _round; k++) {
        _corner(_cx + _cos[k] * radius, _cy + _sin[k] * radius, _Atlas.whiteU, _Atlas.whiteV, color);
      }
    }
    for (var ring = 0; ring + 1 < rings.length; ring++) {
      final a = first + ring * _round;
      for (var k = 0; k < _round; k++) {
        final next = (k + 1) % _round;
        _quad(a + k, a + next, a + _round + k, a + _round + next);
      }
    }
  }

  /// One soft stroke out of the centre, as [soft] is when blurred: it begins [from] the centre,
  /// softly, and fades to nothing [span] further out. It is [bent] sideways in its middle, and
  /// [lead] moves the bend's top towards the far end. Nothing of it is added under the button of
  /// radius [r], which is drawn over it.
  void stroke(
    _Soft soft,
    double r, {
    required double angle,
    required double from,
    required double span,
    required double bent,
    required double lead,
    required double opacity,
    required bool curved,
  }) {
    if (span <= .5) return;
    // a strip cannot curl tighter than it is wide without folding over itself; nor could the
    // blurred stroke be seen to
    final tightest = .2 * span * span / soft.half;
    final bend = bent.clamp(-tightest, tightest);
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    final ts = _ts;
    final as = _as;
    // how fast it moves out at its start, and where its round cap begins
    final speed = span * (1 + lead);
    final start = -soft.cap / speed;
    // a blurred stroke begins softly: nothing a sigma and a half before its start, half its
    // strength there, all of it as far again. From there it fades evenly to its far end
    final soften = 1.5 * soft.sigma / speed;
    final full = math.min(start + soften, curved ? .2 : .5);
    ts[0] = start - soften;
    as[0] = 0;
    ts[1] = start;
    as[1] = .5 * soft.strength(opacity);
    ts[2] = full;
    // a stroke too short to reach its strength stays as far below it
    final rise = .5 + .5 * math.min(1.0, (full - start) / soften);
    as[2] = rise * soft.strength(opacity * (1 - (1 + lead) * full + lead * full * full));
    var n = 3;
    if (curved) {
      // enough sections to follow the bend
      for (var t = .4; t < .9; t += .2) {
        ts[n] = t;
        as[n++] = soft.strength(opacity * (1 - (1 + lead) * t + lead * t * t));
      }
    }
    ts[n] = 1;
    as[n++] = 0;
    // the strip begins at the button's edge
    final edge = (r - 1 - from) / speed;
    var first = 0;
    while (first + 2 < n && ts[first + 1] <= edge) {
      first++;
    }
    if (ts[first] < edge) {
      final f = math.min(1.0, (edge - ts[first]) / (ts[first + 1] - ts[first]));
      as[first] += (as[first + 1] - as[first]) * f;
      ts[first] = edge;
    }
    var before = -1;
    for (var s = first; s < n; s++) {
      final t = ts[s];
      // how far out the stroke is at t and how far aside, and which way it runs there. Before
      // its start it runs straight on, the way it starts
      final curve = t > 0;
      final out = from + (curve ? span * ((1 + lead) * t - lead * t * t) : speed * t);
      final side = 2 * bend * (curve ? t * (1 - t) : t);
      final ahead = curve ? span * (1 + lead - 2 * lead * t) : speed;
      final aside = 2 * bend * (curve ? 1 - 2 * t : 1);
      final k = soft.half / math.sqrt(ahead * ahead + aside * aside);
      final tx = (dx * ahead - dy * aside) * k;
      final ty = (dy * ahead + dx * aside) * k;
      final x = _cx + dx * out - dy * side;
      final y = _cy + dy * out + dx * side;
      final color = _shade(as[s]);
      final a = _corner(x - ty, y + tx, soft.u, 0, color);
      _corner(x + ty, y - tx, soft.u, _Atlas.height, color);
      if (before >= 0) _quad(before, before + 1, a, a + 1);
      before = a;
    }
  }

  /// A soft stroke along the circle of [radius], from the angle [start] over [sweep], as [soft]
  /// is when blurred: soft at both ends. [cap] is how far a round cap reaches past each end.
  void arc(
    _Soft soft, {
    required double radius,
    required double start,
    required double sweep,
    required double opacity,
    double cap = 0,
  }) {
    final peak = soft.strength(opacity);
    final soften = 1.5 * soft.sigma / radius;
    final from = start - cap / radius;
    final to = start + sweep + cap / radius;
    var before = -1;
    void section(double angle, double alpha) {
      final x = math.cos(angle);
      final y = math.sin(angle);
      final color = _shade(alpha);
      final a = _corner(_cx + x * (radius - soft.half), _cy + y * (radius - soft.half), soft.u, 0, color);
      _corner(_cx + x * (radius + soft.half), _cy + y * (radius + soft.half), soft.u, _Atlas.height, color);
      if (before >= 0) _quad(before, before + 1, a, a + 1);
      before = a;
    }

    section(from - soften, 0);
    section(from, .5 * peak);
    // a section every nine degrees keeps it round
    final inside = to - from - 2 * soften;
    final steps = math.max(1, (inside / (math.pi / 20)).ceil());
    for (var s = 0; s <= steps; s++) {
      section(from + soften + inside * s / steps, peak);
    }
    section(to, .5 * peak);
    section(to + soften, 0);
  }

  /// A sharp round dot of [radius] at ([x], [y]), from the [fine] dot of the atlas or the coarse.
  void dot(double x, double y, double radius, double alpha, {required bool fine}) {
    final square = fine ? _Atlas.fineDot : _Atlas.coarseDot;
    // the dot's square on the canvas
    final half = radius / .8;
    final color = _shade(alpha);
    final a = _corner(x - half, y - half, square.left, square.top, color);
    _corner(x + half, y - half, square.right, square.top, color);
    _corner(x - half, y + half, square.left, square.bottom, color);
    _corner(x + half, y + half, square.right, square.bottom, color);
    _quad(a, a + 1, a + 2, a + 3);
  }
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

  /// The white button with its soft shadow and bevel.
  void disc() => _Body(center, r, p.dark).paint(c);

  void logo({List<_Part>? parts, Color? ghost, double dx = 0}) {
    if (!p.drawLogo) return;
    c.save();
    c.translate(dx * k, 0);
    _paintLogo(c, logoRect, color: _alpha(col, p.logoOpacity), parts: parts, ghost: ghost);
    c.restore();
  }

  /// Paints in logo units.
  void logoSpace(void Function(Canvas c) paint) {
    c.save();
    c.translate(logoRect.left, logoRect.top);
    c.scale(k);
    paint(c);
    c.restore();
  }

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

/// What is left of [x] after its whole part, from 0 up to 1.
double _fract(double x) => x - x.floorToDouble();

/// The same scattered number from 0 to 1 for the same [i] and [salt].
double _hash(int i, int salt) => _fract(math.sin(i * 12.9898 + salt * 78.233) * 43758.5453);

/// The error function, to 1.5e-7.
double _erf(double x) {
  final t = 1 / (1 + .3275911 * x.abs());
  final y =
      1 -
      (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - .284496736) * t + .254829592) *
          t *
          math.exp(-x * x);
  return x < 0 ? -y : y;
}

Color _alpha(Color c, double a) => c.withValues(alpha: c.a * _c01(a));
