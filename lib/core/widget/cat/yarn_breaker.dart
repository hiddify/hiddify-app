import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/theme/cat/paw_print.dart';

enum YarnBreakerPhase { ready, playing, won, lost }

/// A small brick breaker to pass the time while connecting: a paw bats a ball
/// of yarn at rows of blocks.
///
/// Drag anywhere or move the mouse to steer the paw, tap or press space to
/// launch the yarn; the arrow keys steer too. The field is measured in widths
/// of the widget, so the game plays the same at any size.
class YarnBreaker extends StatefulWidget {
  const YarnBreaker({super.key, this.onChanged});

  /// Called with the score, the lives left and the phase whenever one changes.
  final void Function(int score, int lives, YarnBreakerPhase phase)? onChanged;

  @override
  State<YarnBreaker> createState() => YarnBreakerState();
}

class YarnBreakerState extends State<YarnBreaker> with SingleTickerProviderStateMixin {
  static const int columns = 7;
  static const int rows = 5;
  static const int startLives = 3;
  static const double paddleWidth = .24;
  static const double paddleHeight = .045;
  static const double radius = .024;
  static const double startSpeed = .85;
  static const double maxSpeed = 1.45;

  late final Ticker _ticker = createTicker(_tick);
  final _game = _Game();
  final _held = <LogicalKeyboardKey>{};
  Duration _last = Duration.zero;
  double _height = 1.5;

  int get score => _game.score;
  int get lives => _game.lives;
  YarnBreakerPhase get phase => _game.phase;

  /// Where the yarn is, in widths of the field from its top left corner.
  Offset get ball => _game.ball;

  /// How many blocks are still standing.
  int get blocksLeft => _game.bricks.where((b) => !b.broken).length;

  @override
  void initState() {
    super.initState();
    _reset();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Starts a new game with every block back in place.
  void restart() {
    _reset();
    _changed();
  }

  void _reset() {
    _game
      ..score = 0
      ..lives = startLives
      ..bricks = [
        for (var r = 0; r < rows; r++)
          for (var c = 0; c < columns; c++) _Brick(r, c),
      ];
    _serve();
  }

  void _serve() {
    _game
      ..phase = YarnBreakerPhase.ready
      ..speed = startSpeed
      ..velocity = Offset.zero;
    _stickToPaddle();
  }

  void _stickToPaddle() => _game.ball = Offset(_game.paddle, _paddleTop - radius);

  double get _paddleTop => _height - .1;

  void _launch() {
    switch (_game.phase) {
      case YarnBreakerPhase.ready:
        // a slight angle, so the first bounce isn't straight back down
        final double angle = (_game.paddle < .5 ? 1 : -1) * math.pi / 9;
        _game
          ..phase = YarnBreakerPhase.playing
          ..velocity = Offset(math.sin(angle), -math.cos(angle)) * _game.speed;
        _changed();
      case YarnBreakerPhase.won || YarnBreakerPhase.lost:
        restart();
      case YarnBreakerPhase.playing:
        break;
    }
  }

  void _steer(double x) {
    _game.paddle = x.clamp(paddleWidth / 2, 1 - paddleWidth / 2);
    if (_game.phase == YarnBreakerPhase.ready) _stickToPaddle();
  }

  void _changed() => widget.onChanged?.call(_game.score, _game.lives, _game.phase);

  void _tick(Duration elapsed) {
    // a long frame (the app was in the background) must not teleport the yarn
    final double dt = math.min((elapsed - _last).inMicroseconds / 1e6, 1 / 30);
    _last = elapsed;

    final double keys =
        (_held.contains(LogicalKeyboardKey.arrowRight) ? 1 : 0) -
        (_held.contains(LogicalKeyboardKey.arrowLeft) ? 1 : 0);
    if (keys != 0) _steer(_game.paddle + keys * 1.3 * dt);

    if (_game.phase == YarnBreakerPhase.playing) {
      // small steps keep a fast ball from tunnelling through a block
      const int substeps = 4;
      for (var i = 0; i < substeps && _game.phase == YarnBreakerPhase.playing; i++) {
        _step(dt / substeps);
      }
    }
    _game.spin += dt * _game.velocity.dx * 40;
    setState(() {});
  }

  void _step(double dt) {
    var ball = _game.ball + _game.velocity * dt;
    var v = _game.velocity;

    // walls and ceiling
    if (ball.dx < radius && v.dx < 0 || ball.dx > 1 - radius && v.dx > 0) v = Offset(-v.dx, v.dy);
    if (ball.dy < radius && v.dy < 0) v = Offset(v.dx, -v.dy);

    // the paw: the farther from its middle, the steeper the bounce
    final double top = _paddleTop;
    if (v.dy > 0 &&
        ball.dy + radius >= top &&
        ball.dy - radius <= top + paddleHeight &&
        (ball.dx - _game.paddle).abs() <= paddleWidth / 2 + radius) {
      final double offset = ((ball.dx - _game.paddle) / (paddleWidth / 2)).clamp(-1.0, 1.0);
      final double angle = offset * math.pi / 3;
      v = Offset(math.sin(angle), -math.cos(angle)) * _game.speed;
      ball = Offset(ball.dx, top - radius);
      HapticFeedback.selectionClick();
    }

    // blocks: hit at most one per step, and bounce off the side it was hit on
    for (final brick in _game.bricks) {
      if (brick.broken) continue;
      final Rect rect = _brickRect(brick);
      final Offset nearest = Offset(ball.dx.clamp(rect.left, rect.right), ball.dy.clamp(rect.top, rect.bottom));
      if ((ball - nearest).distanceSquared > radius * radius) continue;
      brick.broken = true;
      final double overlapX = math.min(ball.dx + radius - rect.left, rect.right - (ball.dx - radius));
      final double overlapY = math.min(ball.dy + radius - rect.top, rect.bottom - (ball.dy - radius));
      v = overlapX < overlapY ? Offset(-v.dx, v.dy) : Offset(v.dx, -v.dy);
      _game
        ..score += (rows - brick.row) * 10
        ..speed = math.min(maxSpeed, _game.speed + .015);
      v = v / v.distance * _game.speed;
      if (_game.bricks.every((b) => b.broken)) {
        _game.phase = YarnBreakerPhase.won;
        HapticFeedback.mediumImpact();
      }
      _changed();
      break;
    }

    _game
      ..ball = ball
      ..velocity = v;

    if (ball.dy - radius > _height) {
      _game.lives--;
      HapticFeedback.heavyImpact();
      if (_game.lives <= 0) {
        _game.phase = YarnBreakerPhase.lost;
        _changed();
      } else {
        _serve();
        _changed();
      }
    }
  }

  Rect _brickRect(_Brick brick) {
    const double margin = .04;
    const double gap = .014;
    const double top = .16;
    const double height = .05;
    const double width = (1 - 2 * margin - (columns - 1) * gap) / columns;
    return Rect.fromLTWH(margin + brick.column * (width + gap), top + brick.row * (height + gap), width, height);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (event is KeyDownEvent) _launch();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      if (event is KeyUpEvent) {
        _held.remove(key);
      } else {
        _held.add(key);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cat = CatTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      autofocus: true,
      onKeyEvent: _key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          _height = constraints.maxHeight / width;
          if (_game.phase == YarnBreakerPhase.ready) _stickToPaddle();
          return MouseRegion(
            onHover: (event) => _steer(event.localPosition.dx / width),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _launch,
              onPanDown: (details) => _steer(details.localPosition.dx / width),
              onPanUpdate: (details) => _steer(details.localPosition.dx / width),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(width, constraints.maxHeight),
                  painter: _YarnBreakerPainter(
                    game: _game,
                    bricks: [
                      for (final b in _game.bricks)
                        if (!b.broken) (_brickRect(b), b.row),
                    ],
                    paddleTop: _paddleTop,
                    cat: cat,
                    scheme: scheme,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Brick {
  _Brick(this.row, this.column);

  final int row;
  final int column;
  bool broken = false;
}

class _Game {
  YarnBreakerPhase phase = YarnBreakerPhase.ready;
  int score = 0;
  int lives = YarnBreakerState.startLives;
  double paddle = .5;
  double speed = YarnBreakerState.startSpeed;
  double spin = 0;
  Offset ball = Offset.zero;
  Offset velocity = Offset.zero;
  List<_Brick> bricks = [];
}

class _YarnBreakerPainter extends CustomPainter {
  _YarnBreakerPainter({
    required this.game,
    required this.bricks,
    required this.paddleTop,
    required this.cat,
    required this.scheme,
  });

  final _Game game;
  final List<(Rect, int)> bricks;
  final double paddleTop;
  final CatTheme cat;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = size.width;
    canvas.save();
    canvas.scale(u);

    // blocks, one color per row, each with a pair of ears
    final colors = [cat.nose, cat.fur, cat.iris, cat.auraCurious, cat.furShade];
    for (final (rect, row) in bricks) {
      final paint = Paint()..color = colors[row % colors.length];
      final double ear = rect.height * .42;
      canvas
        ..drawPath(
          Path()
            ..moveTo(rect.left + rect.width * .14, rect.top + 1e-3)
            ..lineTo(rect.left + rect.width * .22, rect.top - ear)
            ..lineTo(rect.left + rect.width * .36, rect.top + 1e-3)
            ..moveTo(rect.right - rect.width * .14, rect.top + 1e-3)
            ..lineTo(rect.right - rect.width * .22, rect.top - ear)
            ..lineTo(rect.right - rect.width * .36, rect.top + 1e-3)
            ..close(),
          paint,
        )
        ..drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height * .35)), paint);
    }

    // the paw: a soft pad with toe beans
    final Rect paddle = Rect.fromLTWH(
      game.paddle - YarnBreakerState.paddleWidth / 2,
      paddleTop,
      YarnBreakerState.paddleWidth,
      YarnBreakerState.paddleHeight,
    );
    canvas
      ..drawRRect(RRect.fromRectAndRadius(paddle, Radius.circular(paddle.height / 2)), Paint()..color = cat.fur)
      ..drawRRect(
        RRect.fromRectAndRadius(paddle, Radius.circular(paddle.height / 2)),
        Paint()
          ..color = cat.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = .004,
      );
    paintPawPrint(canvas, paddle.center, paddle.height * .8, Paint()..color = cat.innerEar);
    for (final dx in [-.3, .3]) {
      paintPawPrint(
        canvas,
        paddle.center + Offset(paddle.width * dx, 0),
        paddle.height * .55,
        Paint()..color = cat.innerEar.withValues(alpha: .7),
      );
    }

    // the yarn: a ball wound with a few strands that turn as it rolls
    const double r = YarnBreakerState.radius;
    if (game.phase != YarnBreakerPhase.lost) {
      final Offset b = game.ball;
      canvas
        ..drawCircle(b, r, Paint()..color = cat.heart)
        ..save()
        ..translate(b.dx, b.dy)
        ..rotate(game.spin);
      final strand = Paint()
        ..color = Color.lerp(cat.heart, Colors.white, .45)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .16
        ..strokeCap = StrokeCap.round;
      for (var i = -1; i <= 1; i++) {
        canvas.drawArc(Rect.fromCircle(center: Offset(i * r * .5, 0), radius: r * .85), -1.1, 2.2, false, strand);
      }
      canvas
        ..drawLine(const Offset(r * .9, r * .2), const Offset(r * 1.5, r * .9), strand)
        ..restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_YarnBreakerPainter oldDelegate) => true;
}
