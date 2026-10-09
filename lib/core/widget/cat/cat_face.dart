import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hiddify/core/theme/cat/cat_ears_border.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/widget/cat/cat_gaze.dart';

/// How the cat feels, which is how the app is doing.
enum CatMood {
  /// Asleep, eyes shut, z's floating up. Disconnected.
  napping,

  /// Eyes half open, looking around. Connecting.
  wakingUp,

  /// Wide awake and content. Connected.
  purring,

  /// Eyes closing. Disconnecting.
  dozingOff,

  /// Ears flat, fangs out. Something went wrong.
  hissing,

  /// Head tilted, ears up, a question mark. Waiting on the user.
  curious,

  /// Eyes shut contentedly, tongue out: tidying up, such as applying settings.
  grooming;

  CatPose get pose => switch (this) {
    napping => const CatPose(closedStyle: -1, earAngle: .12, blush: .25, zzz: 1, whiskerDroop: .08),
    wakingUp => const CatPose(eyeOpen: .48, squint: .1, pupilSize: .65, wander: 1, pulse: 1),
    purring => const CatPose(eyeOpen: 1, closedStyle: 1, squint: .14, pupilSize: .55, earAngle: -.06, blush: .55),
    dozingOff => const CatPose(eyeOpen: .2, closedStyle: -1, earAngle: .14, zzz: .5, whiskerDroop: .06, pulse: .6),
    hissing => const CatPose(
      eyeOpen: .9,
      lidSlant: 1,
      squint: .12,
      pupilSize: 0,
      earAngle: .95,
      mouthOpen: 1,
      fangs: 1,
      anger: 1,
      whiskerDroop: -.14,
    ),
    curious => const CatPose(eyeOpen: 1, lidSlant: -.25, pupilSize: 1, earAngle: -.2, headTilt: .14, question: 1),
    grooming => const CatPose(closedStyle: 1, tongue: 1, earAngle: .05, blush: .3, pulse: .8),
  };
}

/// Everything about a cat's face that changes with its [CatMood]. Two poses
/// blend smoothly, so the cat moves from one mood to the next.
@immutable
class CatPose {
  const CatPose({
    this.eyeOpen = 0,
    this.closedStyle = 0,
    this.lidSlant = 0,
    this.squint = 0,
    this.pupilSize = .5,
    this.earAngle = 0,
    this.mouthOpen = 0,
    this.fangs = 0,
    this.tongue = 0,
    this.blush = 0,
    this.headTilt = 0,
    this.whiskerDroop = 0,
    this.wander = 0,
    this.pulse = 0,
    this.zzz = 0,
    this.question = 0,
    this.anger = 0,
  });

  factory CatPose.lerp(CatPose a, CatPose b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return CatPose(
      eyeOpen: l(a.eyeOpen, b.eyeOpen),
      closedStyle: l(a.closedStyle, b.closedStyle),
      lidSlant: l(a.lidSlant, b.lidSlant),
      squint: l(a.squint, b.squint),
      pupilSize: l(a.pupilSize, b.pupilSize),
      earAngle: l(a.earAngle, b.earAngle),
      mouthOpen: l(a.mouthOpen, b.mouthOpen),
      fangs: l(a.fangs, b.fangs),
      tongue: l(a.tongue, b.tongue),
      blush: l(a.blush, b.blush),
      headTilt: l(a.headTilt, b.headTilt),
      whiskerDroop: l(a.whiskerDroop, b.whiskerDroop),
      wander: l(a.wander, b.wander),
      pulse: l(a.pulse, b.pulse),
      zzz: l(a.zzz, b.zzz),
      question: l(a.question, b.question),
      anger: l(a.anger, b.anger),
    );
  }

  /// 0 shut, 1 wide open.
  final double eyeOpen;

  /// How shut eyes are drawn: -1 sleepy (◡), 1 happy (∩).
  final double closedStyle;

  /// Tilt of the upper eyelids: 1 angry, -1 worried.
  final double lidSlant;

  /// How far the lower eyelids rise: a content or suspicious squint.
  final double squint;

  /// 0 a thin slit, 1 big and round.
  final double pupilSize;

  /// Turns the ears outward, in radians: flat ears when angry, perked up
  /// when negative.
  final double earAngle;

  final double mouthOpen;
  final double fangs;
  final double tongue;
  final double blush;

  /// Tilts the whole head, in radians.
  final double headTilt;

  /// Turns the whiskers down, in radians; negative bristles them up.
  final double whiskerDroop;

  /// How much the eyes wander around instead of following the pointer.
  final double wander;

  /// Rings pulsing out of the aura: the cat is busy.
  final double pulse;

  /// Opacity of the z's, the question mark and the anger mark.
  final double zzz;
  final double question;
  final double anger;
}

/// A cat's head drawn in code: ears, eyes, nose, whiskers and, if asked, a
/// collar and a glowing aura. It breathes, blinks, twitches its ears and
/// follows the pointer with its eyes; long-pressing it pets it.
///
/// Use a [GlobalKey] to reach [CatFaceState] and [CatFaceState.boop] it or
/// make it [CatFaceState.celebrate].
class CatFace extends StatefulWidget {
  const CatFace({
    super.key,
    required this.mood,
    this.size = 48,
    this.aura,
    this.collar,
    this.accent,
    this.alive = true,
    this.followPointer = false,
    this.pettable = false,
    this.onPurr,
  });

  final CatMood mood;

  /// Width and height. The face fits a square; ears, z's and hearts may
  /// reach a little past it.
  final double size;

  /// Glow behind the head. Null leaves it out.
  final Color? aura;

  /// Collar color. Null leaves the collar off.
  final Color? collar;

  /// Color of the z's while the cat sleeps. Defaults to the theme's muted
  /// text color.
  final Color? accent;

  /// Idle life: breathing, blinking, ear twitches, drifting z's. Off, the cat
  /// still changes mood, just without moving in between. Also off when the
  /// platform asks for fewer animations.
  final bool alive;

  /// Follow the pointer with the eyes: anywhere inside a [CatGazeRegion], or
  /// over the face itself without one.
  final bool followPointer;

  /// Long-pressing purrs: eyes close happily, hearts float up.
  final bool pettable;

  /// Called for each heart while the cat is petted, for haptic feedback.
  final VoidCallback? onPurr;

  @override
  State<CatFace> createState() => CatFaceState();
}

class CatFaceState extends State<CatFace> with SingleTickerProviderStateMixin {
  final _CatFrame _frame = _CatFrame();
  final math.Random _random = math.Random();
  late final Ticker _ticker;

  bool _reduceMotion = false;
  bool get _idle => widget.alive && !_reduceMotion;

  double _lastTick = 0;
  CatPose _fromPose = const CatPose();
  CatPose _toPose = const CatPose();
  double _poseProgress = 1;

  double _nextBlink = 2;
  double _blinkPhase = -1;
  bool _secondBlink = false;
  double _nextTwitch = 3;
  double _twitchPhase = -1;
  bool _twitchLeft = true;
  double _boopPhase = -1;
  bool _petting = false;
  double _heartTimer = 0;

  ValueListenable<Offset?>? _gaze;
  Offset _gazeTarget = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _frame.pose = _toPose = widget.mood.pose;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ValueListenable<Offset?>? gaze = widget.followPointer ? CatGaze.maybeOf(context) : null;
    if (gaze != _gaze) {
      _gaze?.removeListener(_onGaze);
      _gaze = gaze?..addListener(_onGaze);
    }
    _wake();
  }

  @override
  void didUpdateWidget(CatFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _fromPose = _frame.pose;
      _toPose = widget.mood.pose;
      if (_reduceMotion || _ticker.muted) {
        _frame.pose = _toPose;
        _poseProgress = 1;
        _frame.changed();
      } else {
        _poseProgress = 0;
      }
      if (widget.mood == CatMood.purring && _idle) celebrate();
    }
    if (oldWidget.followPointer != widget.followPointer) didChangeDependencies();
    _wake();
  }

  @override
  void dispose() {
    _gaze?.removeListener(_onGaze);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  /// A tap on the nose: the head squashes for a moment and the eyes blink.
  void boop() {
    _boopPhase = 0;
    if (_blinkPhase < 0) _blinkPhase = 0;
    _wake();
  }

  /// A burst of hearts.
  void celebrate([int hearts = 6]) {
    for (int i = 0; i < hearts; i++) {
      _spawnHeart(delay: i * .09);
    }
    _wake();
  }

  void _pet({required bool petting}) {
    _petting = petting;
    _heartTimer = 0;
    _wake();
  }

  void _onGaze() => _lookAt(_gaze?.value, global: true);

  void _lookAt(Offset? position, {required bool global}) {
    if (!mounted) return;
    if (position == null) {
      _gazeTarget = Offset.zero;
    } else {
      final RenderObject? box = context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return;
      final Offset local = global ? box.globalToLocal(position) : position;
      final double unit = box.size.shortestSide / 100;
      final Offset eyes = box.size.center(Offset(0, 11 * unit));
      final Offset toPointer = local - eyes;
      final double distance = toPointer.distance;
      final double reach = box.size.shortestSide * .9;
      _gazeTarget = distance < 1 ? Offset.zero : toPointer / distance * math.min(1, distance / reach);
    }
    _wake();
  }

  void _spawnHeart({double delay = 0}) {
    double between(double a, double b) => a + _random.nextDouble() * (b - a);
    _frame.hearts.add(
      _Heart(
        position: Offset(50 + between(-14, 14), 30 + between(-4, 4)),
        velocity: Offset(between(-9, 9), between(-36, -24)),
        life: between(1.1, 1.6),
        size: between(7, 10.5),
        spin: between(-.6, .6),
        age: -delay,
      ),
    );
  }

  bool get _busy =>
      _idle ||
      _poseProgress < 1 ||
      _blinkPhase >= 0 ||
      _twitchPhase >= 0 ||
      _boopPhase >= 0 ||
      _petting ||
      _frame.purr > .005 ||
      _frame.hearts.isNotEmpty ||
      (_frame.look - _gazeTarget).distance > .005;

  void _wake() {
    if (_busy && !_ticker.isActive) {
      _lastTick = 0;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final double now = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final double dt = (now - _lastTick).clamp(0, .1);
    _lastTick = now;
    final _CatFrame f = _frame;
    if (_idle) f.time += dt;

    if (_poseProgress < 1) {
      _poseProgress = math.min(1, _poseProgress + dt / .45);
      f.pose = CatPose.lerp(_fromPose, _toPose, Curves.easeInOutCubic.transform(_poseProgress));
    }

    if (_idle) {
      f.breath = math.sin(f.time * 2 * math.pi / (f.pose.zzz > .5 ? 4.4 : 3.3));
      _nextBlink -= dt;
      if (_nextBlink <= 0 && _blinkPhase < 0 && f.pose.eyeOpen > .3) {
        _blinkPhase = 0;
        _secondBlink = _random.nextDouble() < .25;
        _nextBlink = 2.2 + _random.nextDouble() * 4;
      }
      _nextTwitch -= dt;
      if (_nextTwitch <= 0 && _twitchPhase < 0) {
        _twitchPhase = 0;
        _twitchLeft = _random.nextBool();
        _nextTwitch = 2.5 + _random.nextDouble() * 5;
      }
    } else {
      f.breath = 0;
    }

    if (_blinkPhase >= 0) {
      _blinkPhase += dt / .17;
      if (_blinkPhase >= 1) {
        _blinkPhase = _secondBlink ? 0 : -1;
        _secondBlink = false;
        f.blink = 0;
      } else {
        f.blink = math.sin(math.pi * _blinkPhase);
      }
    }

    if (_twitchPhase >= 0) {
      _twitchPhase += dt / .28;
      final double twitch = _twitchPhase >= 1 ? 0 : math.sin(math.pi * _twitchPhase);
      if (_twitchPhase >= 1) _twitchPhase = -1;
      f.twitchLeft = _twitchLeft ? twitch : 0;
      f.twitchRight = _twitchLeft ? 0 : twitch;
    }

    if (_boopPhase >= 0) {
      _boopPhase += dt / .32;
      f.boop = _boopPhase >= 1 ? 0 : math.sin(math.pi * _boopPhase);
      if (_boopPhase >= 1) _boopPhase = -1;
    }

    f.purr += ((_petting ? 1 : 0) - f.purr) * (1 - math.exp(-dt * 8));
    if (_petting) {
      _heartTimer -= dt;
      if (_heartTimer <= 0) {
        _spawnHeart();
        _heartTimer = .34;
        widget.onPurr?.call();
      }
    }

    // wander around while busy, otherwise follow the pointer
    final Offset wander = Offset(
      math.sin(f.time * 2 * math.pi / 1.9) * .85,
      math.sin(f.time * 2 * math.pi / 3.1 + 1) * .35,
    );
    final Offset target = Offset.lerp(_gazeTarget, wander, f.pose.wander)!;
    f.look = Offset.lerp(f.look, target, 1 - math.exp(-dt * 9))!;

    for (final heart in f.hearts) {
      heart.age += dt;
      if (heart.age > 0) heart.position += heart.velocity * dt;
    }
    f.hearts.removeWhere((heart) => heart.age >= heart.life);

    f.changed();
    if (!_busy) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget face = CustomPaint(
      size: Size.square(widget.size),
      willChange: _idle,
      painter: _CatFacePainter(
        frame: _frame,
        cat: CatTheme.of(context),
        aura: widget.aura,
        collar: widget.collar,
        accent: widget.accent ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
    if (widget.pettable) {
      face = GestureDetector(
        // petting is a little extra, not something to announce
        excludeFromSemantics: true,
        onLongPressStart: (_) => _pet(petting: true),
        onLongPressEnd: (_) => _pet(petting: false),
        onLongPressCancel: () => _pet(petting: false),
        child: face,
      );
    }
    if (widget.followPointer && _gaze == null) {
      face = MouseRegion(
        onHover: (event) => _lookAt(event.localPosition, global: false),
        onExit: (_) => _lookAt(null, global: false),
        child: face,
      );
    }
    return RepaintBoundary(child: face);
  }
}

class _Heart {
  _Heart({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
    required this.spin,
    required this.age,
  });

  Offset position;
  final Offset velocity;
  final double life;
  final double size;
  final double spin;
  double age;
}

/// What the painter draws on the next frame. Notifies on every change.
class _CatFrame extends ChangeNotifier {
  CatPose pose = const CatPose();
  double time = 0;
  double breath = 0;
  double blink = 0;
  double twitchLeft = 0;
  double twitchRight = 0;
  double boop = 0;
  double purr = 0;
  Offset look = Offset.zero;
  final List<_Heart> hearts = [];

  void changed() => notifyListeners();
}

/// Draws the cat in a 100 × 100 box scaled to the canvas: the head spans
/// 14–86 across and 28–92 down, the ears reach up to about 10.
class _CatFacePainter extends CustomPainter {
  _CatFacePainter({required this.frame, required this.cat, this.aura, this.collar, required this.accent})
    : super(repaint: frame);

  final _CatFrame frame;
  final CatTheme cat;
  final Color? aura;
  final Color? collar;
  final Color accent;

  static final Path _head = Path()
    ..moveTo(50, 28)
    ..cubicTo(71, 28, 86, 42, 86, 62)
    ..cubicTo(86, 80, 70, 92, 50, 92)
    ..cubicTo(30, 92, 14, 80, 14, 62)
    ..cubicTo(14, 42, 29, 28, 50, 28)
    ..close();

  static final Path _tufts = Path()
    ..moveTo(84.5, 60)
    ..lineTo(91.5, 66.5)
    ..lineTo(85.5, 69)
    ..lineTo(90, 75)
    ..lineTo(81, 77.5)
    ..close()
    ..moveTo(15.5, 60)
    ..lineTo(8.5, 66.5)
    ..lineTo(14.5, 69)
    ..lineTo(10, 75)
    ..lineTo(19, 77.5)
    ..close();

  static final Path _nose = Path()
    ..moveTo(46.2, 68.4)
    ..quadraticBezierTo(50, 67.2, 53.8, 68.4)
    ..quadraticBezierTo(54.9, 69.1, 53.8, 70.3)
    ..lineTo(51, 72.5)
    ..quadraticBezierTo(50, 73.3, 49, 72.5)
    ..lineTo(46.2, 70.3)
    ..quadraticBezierTo(45.1, 69.1, 46.2, 68.4)
    ..close();

  static final Path _mouth = Path()
    ..moveTo(50, 72.8)
    ..lineTo(50, 75)
    ..quadraticBezierTo(48.2, 78.2, 45, 76.4)
    ..moveTo(50, 75)
    ..quadraticBezierTo(51.8, 78.2, 55, 76.4);

  static Path _heart(double s) => Path()
    ..moveTo(0, s * .35)
    ..cubicTo(-s * .55, -s * .05, -s * .3, -s * .55, 0, -s * .22)
    ..cubicTo(s * .3, -s * .55, s * .55, -s * .05, 0, s * .35)
    ..close();

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.shortestSide / 100;
    final CatPose pose = frame.pose;
    canvas
      ..save()
      ..translate((size.width - unit * 100) / 2, (size.height - unit * 100) / 2)
      ..scale(unit);

    _paintAura(canvas, pose);

    // the head turns and squashes around the chin
    final double shiver = frame.purr * math.sin(frame.time * 2 * math.pi * 13) * .7;
    final double breathe = frame.breath * .016;
    final double squash = frame.boop * .075;
    canvas
      ..save()
      ..translate(50 + shiver, 92)
      ..rotate(pose.headTilt)
      ..scale(1 + squash - breathe * .3, 1 - squash + breathe)
      ..translate(-50, -92);

    _paintEars(canvas, pose);
    canvas
      ..drawPath(_tufts, Paint()..color = cat.fur)
      ..drawPath(_tufts, _stroke(cat.outline, 1.2));
    _paintHead(canvas);
    if (cat.stripes) _paintStripes(canvas);
    _paintMuzzle(canvas, pose.blush + frame.purr * .4);
    _paintEyes(canvas, pose);
    _paintMouth(canvas, pose);
    _paintWhiskers(canvas, pose);
    if (collar != null) _paintCollar(canvas, collar!);
    canvas.restore();

    _paintZzz(canvas, pose.zzz);
    _paintQuestion(canvas, pose.question);
    _paintAnger(canvas, pose.anger);
    _paintHearts(canvas);
    canvas.restore();
  }

  void _paintAura(Canvas canvas, CatPose pose) {
    final Color? glow = aura;
    if (glow == null) return;
    const Offset center = Offset(50, 60);
    final Rect bounds = Rect.fromCircle(center: center, radius: 56);
    canvas.drawCircle(
      center,
      56,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: .5), glow.withValues(alpha: .16), glow.withValues(alpha: 0)],
          stops: const [0, .62, 1],
        ).createShader(bounds),
    );
    if (pose.pulse <= .01) return;
    for (final double offset in [0, .5]) {
      final double p = (frame.time / 1.6 + offset) % 1;
      canvas.drawCircle(
        center,
        40 + 16 * p,
        _stroke(glow.withValues(alpha: .55 * (1 - p) * pose.pulse), 2.4 * (1 - p) + .4),
      );
    }
  }

  void _paintEars(Canvas canvas, CatPose pose) {
    final double flatten = pose.earAngle + frame.purr * .1;
    final double length = 35 * (1 - .15 * flatten.clamp(0, 1));
    final Paint fur = Paint()..color = cat.fur;
    final Paint outline = _stroke(cat.outline, 1.4);
    final Paint inner = Paint()..color = cat.innerEar;
    for (final double side in [-1, 1]) {
      final double twitch = side < 0 ? frame.twitchLeft : frame.twitchRight;
      final CatEarGeometry ear = CatEarGeometry.build(
        baseCenter: Offset(50 + side * 18, 45),
        halfBase: 12.5,
        length: length,
        tilt: side * (.24 + flatten + twitch * .35),
      );
      canvas
        ..drawPath(ear.outer, fur)
        ..drawPath(ear.outer, outline)
        ..drawPath(ear.inner, inner);
    }
  }

  void _paintHead(Canvas canvas) {
    const Rect bounds = Rect.fromLTRB(14, 28, 86, 92);
    canvas
      ..drawPath(
        _head,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.25, -.4),
            radius: .95,
            colors: [Color.lerp(cat.fur, Colors.white, .18)!, cat.fur, Color.lerp(cat.fur, cat.furShade, .4)!],
            stops: const [0, .55, 1],
          ).createShader(bounds),
      )
      ..drawPath(_head, _stroke(cat.outline, 1.4));
  }

  void _paintStripes(Canvas canvas) {
    final Paint stripe = _stroke(cat.furShade, 2.6);
    canvas
      ..drawLine(const Offset(50, 31), const Offset(50, 38.5), stripe)
      ..drawLine(const Offset(43.5, 32.2), const Offset(44.6, 38.6), stripe)
      ..drawLine(const Offset(56.5, 32.2), const Offset(55.4, 38.6), stripe)
      ..drawLine(const Offset(16, 56), const Offset(22.5, 57.5), stripe)
      ..drawLine(const Offset(15.5, 62), const Offset(21.5, 62.5), stripe)
      ..drawLine(const Offset(84, 56), const Offset(77.5, 57.5), stripe)
      ..drawLine(const Offset(84.5, 62), const Offset(78.5, 62.5), stripe);
  }

  void _paintMuzzle(Canvas canvas, double blush) {
    final Paint muzzle = Paint()..color = cat.muzzle;
    canvas
      ..drawCircle(const Offset(44.6, 76), 8.2, muzzle)
      ..drawCircle(const Offset(55.4, 76), 8.2, muzzle);
    if (blush <= .01) return;
    final Paint cheek = Paint()..color = cat.blush.withValues(alpha: (.5 * blush).clamp(0, .8));
    canvas
      ..drawOval(Rect.fromCenter(center: const Offset(24.5, 72), width: 11, height: 6), cheek)
      ..drawOval(Rect.fromCenter(center: const Offset(75.5, 72), width: 11, height: 6), cheek);
  }

  void _paintEyes(Canvas canvas, CatPose pose) {
    final double purr = frame.purr;
    final double open = (pose.eyeOpen * (1 - frame.blink) * (1 - purr)).clamp(0, 1);
    final double closedStyle = purr > .5 ? 1 : (pose.eyeOpen < .1 ? pose.closedStyle : .25);
    for (final double side in [-1, 1]) {
      _paintEye(canvas, Offset(50 + side * 15, 61), side, open, closedStyle, pose);
    }
  }

  void _paintEye(Canvas canvas, Offset c, double side, double open, double closedStyle, CatPose pose) {
    const double rx = 8.6;
    const double ry = 9.6;
    final Rect eye = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    // n runs from the outer corner (-1) to the inner one (1)
    double lid(double n) => c.dy - ry + (1 - open) * ry * 2.05 + pose.lidSlant * ry * .5 * (n + .25);
    final double lidLeft = lid(side < 0 ? -1 : 1);
    final double lidRight = lid(side < 0 ? 1 : -1);
    final double bottom = c.dy + ry - pose.squint * ry * .75;

    if (bottom - lid(0) < 1.6) {
      final double y = c.dy + 1.5;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - rx * .9, y)
          ..quadraticBezierTo(c.dx, y - 4.2 * closedStyle, c.dx + rx * .9, y),
        _stroke(cat.line, 2.2),
      );
      return;
    }

    final Path visible = Path()
      ..moveTo(c.dx - rx - 1, lidLeft)
      ..lineTo(c.dx + rx + 1, lidRight)
      ..lineTo(c.dx + rx + 1, bottom)
      ..lineTo(c.dx - rx - 1, bottom)
      ..close();

    if (cat.glowingEyes) {
      canvas.drawOval(
        eye.inflate(2.5),
        Paint()
          ..color = cat.iris.withValues(alpha: .45 * open)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
    }

    canvas
      ..save()
      ..clipPath(Path()..addOval(eye))
      ..clipPath(visible)
      ..drawOval(
        eye,
        Paint()
          ..shader = RadialGradient(
            colors: [Color.lerp(cat.iris, Colors.white, .35)!, cat.iris, Color.lerp(cat.iris, Colors.black, .25)!],
            stops: const [0, .6, 1],
          ).createShader(eye),
      );
    final Offset pupil = c + Offset(frame.look.dx * rx * .42, frame.look.dy * ry * .3);
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: pupil,
          width: rx * 2 * lerpDouble(.16, .62, pose.pupilSize)!,
          height: ry * 2 * lerpDouble(.9, .72, pose.pupilSize)!,
        ),
        Paint()..color = cat.pupil,
      )
      ..drawCircle(pupil + const Offset(-rx * .3, -ry * .32), rx * .27, Paint()..color = cat.eyeShine)
      ..drawCircle(
        pupil + const Offset(rx * .24, ry * .22),
        rx * .12,
        Paint()..color = cat.eyeShine.withValues(alpha: .8),
      )
      ..drawLine(Offset(c.dx - rx - 1, lidLeft), Offset(c.dx + rx + 1, lidRight), _stroke(cat.line, 1.8))
      ..restore()
      ..save()
      ..clipPath(visible)
      ..drawOval(eye, _stroke(cat.line, 1.3))
      ..restore();
  }

  void _paintMouth(Canvas canvas, CatPose pose) {
    final double m = pose.mouthOpen;
    if (m > .02) {
      final Rect mouth = Rect.fromCenter(center: Offset(50, 77.6 + 1.6 * m), width: 3 + 6 * m, height: 2 + 6.5 * m);
      canvas
        ..drawOval(mouth, Paint()..color = const Color(0xFF5B2333))
        ..drawOval(
          Rect.fromCenter(
            center: Offset(50, mouth.bottom - mouth.height * .22),
            width: mouth.width * .62,
            height: mouth.height * .4,
          ),
          Paint()..color = cat.nose,
        );
      if (pose.fangs > .02) {
        final Paint fang = Paint()..color = Colors.white.withValues(alpha: pose.fangs);
        for (final double side in [-1, 1]) {
          final double x = 50 + side * mouth.width * .26;
          canvas.drawPath(
            Path()
              ..moveTo(x - 1.1, mouth.top + .6)
              ..lineTo(x, mouth.top + 3.2 * m)
              ..lineTo(x + 1.1, mouth.top + .6)
              ..close(),
            fang,
          );
        }
      }
    }
    if (pose.tongue > .02) {
      final Rect tongue = Rect.fromLTWH(48.1, 75.4, 3.8, 5 * pose.tongue);
      canvas
        ..drawRRect(
          RRect.fromRectAndCorners(
            tongue,
            bottomLeft: const Radius.circular(1.9),
            bottomRight: const Radius.circular(1.9),
          ),
          Paint()..color = cat.nose,
        )
        ..drawLine(
          Offset(50, tongue.top + .6),
          Offset(50, tongue.top + tongue.height * .6),
          _stroke(Color.lerp(cat.nose, cat.line, .4)!, .6),
        );
    }
    canvas
      ..drawPath(_mouth, _stroke(cat.line, 1.35))
      ..drawPath(_nose, Paint()..color = cat.nose)
      ..drawCircle(const Offset(48.4, 69.2), .8, Paint()..color = Colors.white.withValues(alpha: .6));
  }

  void _paintWhiskers(Canvas canvas, CatPose pose) {
    final Paint whisker = _stroke(cat.whisker.withValues(alpha: .85), .9);
    final double twitch =
        math.sin(frame.time * 2 * math.pi * .7) * .025 * (1 - pose.zzz) +
        frame.purr * math.sin(frame.time * 2 * math.pi * 6) * .04;
    for (final double side in [-1, 1]) {
      final Offset root = Offset(50 + side * 10.5, 74);
      for (final (double angle, double length) in [(-.22, 27.0), (0.0, 29.0), (.22, 27.0)]) {
        final double a = angle + pose.whiskerDroop + twitch;
        final Offset direction = Offset(side * math.cos(a), math.sin(a));
        final Offset start = root + direction * 3;
        final Offset end = root + direction * length;
        final Offset bend = Offset.lerp(start, end, .5)! + const Offset(0, -1.6);
        canvas.drawPath(
          Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(bend.dx, bend.dy, end.dx, end.dy),
          whisker,
        );
      }
    }
  }

  void _paintCollar(Canvas canvas, Color color) {
    final Path band = Path()
      ..moveTo(27, 85.6)
      ..quadraticBezierTo(50, 99.5, 73, 85.6);
    const Offset bell = Offset(50, 95.2);
    const Color gold = Color(0xFFF4C542);
    const Color goldShade = Color(0xFFB98A1C);
    canvas
      ..drawPath(band, _stroke(color, 5.2))
      ..drawPath(band, _stroke(Colors.white.withValues(alpha: .25), 1.1))
      ..drawCircle(bell, 4.6, Paint()..color = gold)
      ..drawCircle(bell, 4.6, _stroke(goldShade, .8))
      ..drawLine(bell + const Offset(-3.6, .6), bell + const Offset(3.6, .6), _stroke(goldShade, .8))
      ..drawCircle(bell + const Offset(0, 2.4), .9, Paint()..color = const Color(0xFF7A5A10))
      ..drawCircle(bell + const Offset(-1.6, -1.8), 1.1, Paint()..color = Colors.white.withValues(alpha: .7));
  }

  void _paintZzz(Canvas canvas, double amount) {
    if (amount <= .01) return;
    for (int i = 0; i < 3; i++) {
      final double phase = (frame.time / 2.6 + i / 3) % 1;
      final double s = 4.5 + 6 * phase;
      final Offset c = Offset(73 + 17 * phase + math.sin(phase * math.pi * 2) * 2, 30 - 26 * phase);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - s / 2, c.dy - s / 2)
          ..lineTo(c.dx + s / 2, c.dy - s / 2)
          ..lineTo(c.dx - s / 2, c.dy + s / 2)
          ..lineTo(c.dx + s / 2, c.dy + s / 2),
        _stroke(accent.withValues(alpha: accent.a * amount * math.sin(math.pi * phase)), 1.5 + .8 * phase),
      );
    }
  }

  void _paintQuestion(Canvas canvas, double amount) {
    if (amount <= .01) return;
    final Color color = cat.auraCurious.withValues(alpha: amount);
    canvas
      ..save()
      ..translate(85, 15 + math.sin(frame.time * 2 * math.pi / 1.4) * 1.5)
      ..rotate(.18)
      ..drawPath(
        Path()
          ..moveTo(-4.2, -3.6)
          ..cubicTo(-4.2, -9.4, 4.6, -9.4, 4.6, -3.8)
          ..cubicTo(4.6, -.6, 0, -.2, 0, 3.4),
        _stroke(color, 2.8),
      )
      ..drawCircle(const Offset(0, 7.6), 1.7, Paint()..color = color)
      ..restore();
  }

  void _paintAnger(Canvas canvas, double amount) {
    if (amount <= .01) return;
    final Paint mark = _stroke(cat.auraError.withValues(alpha: amount), 2);
    canvas
      ..save()
      ..translate(81, 27)
      ..scale(1 + math.sin(frame.time * 2 * math.pi * 1.8) * .08);
    for (int k = 0; k < 4; k++) {
      canvas
        ..drawPath(
          Path()
            ..moveTo(1.4, 5)
            ..quadraticBezierTo(1.4, 1.4, 5, 1.4),
          mark,
        )
        ..rotate(math.pi / 2);
    }
    canvas.restore();
  }

  void _paintHearts(Canvas canvas) {
    for (final heart in frame.hearts) {
      if (heart.age < 0) continue;
      final double t = heart.age / heart.life;
      final double grow = .6 + .4 * Curves.easeOutBack.transform(math.min(1, t * 3));
      canvas
        ..save()
        ..translate(heart.position.dx, heart.position.dy)
        ..rotate(heart.spin * t)
        ..scale(grow)
        ..drawPath(_heart(heart.size), Paint()..color = cat.heart.withValues(alpha: (1 - t * t).clamp(0, 1)))
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_CatFacePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.cat != cat ||
      oldDelegate.aura != aura ||
      oldDelegate.collar != collar ||
      oldDelegate.accent != accent;
}
