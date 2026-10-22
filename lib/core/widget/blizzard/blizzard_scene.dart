import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';

enum BlizzardParticlePreset { hero, staticHero, quiet, off, envelope }

/// Decoration has no semantics, gestures, or application state. Only the Home
/// hero owns an ambient clock; quieter surfaces keep their static decoration.
class BlizzardScene extends StatefulWidget {
  const BlizzardScene({super.key, this.preset = BlizzardParticlePreset.quiet});
  final BlizzardParticlePreset preset;

  @override
  State<BlizzardScene> createState() => _BlizzardSceneState();
}

class _BlizzardSceneState extends State<BlizzardScene> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _drift;
  final _ribbon = _RibbonTexture();
  bool _visible = false;
  bool _reduced = false;
  late AppLifecycleState _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _drift = AnimationController(vsync: this, duration: BlizzardMetrics.waveDuration);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    _reduced = media.disableAnimations || media.accessibleNavigation || media.highContrast;
    _visible = TickerMode.of(context);
    _syncClock();
  }

  @override
  void didUpdateWidget(covariant BlizzardScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncClock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _syncClock();
  }

  void _syncClock() {
    final animate =
        (widget.preset == BlizzardParticlePreset.hero || widget.preset == BlizzardParticlePreset.envelope) &&
        !_reduced &&
        _visible &&
        _lifecycle == AppLifecycleState.resumed;
    if (animate && !_drift.isAnimating) {
      // repeat starts at the preserved value, excluding time spent offstage or
      // in the background instead of jumping forward when the ticker unmutes.
      _drift.repeat();
    } else if (!animate && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drift.dispose();
    _ribbon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preset == BlizzardParticlePreset.envelope) {
      return IgnorePointer(
        child: ExcludeSemantics(
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(painter: _BlizzardEnvelopeSnowPainter(_drift), willChange: !_reduced),
                ),
                AnimatedBuilder(
                  animation: _drift,
                  child: Image.asset('assets/images/blizzard_wave_envelope.png', fit: BoxFit.contain),
                  builder: (context, child) {
                    final phase = _reduced ? 0.0 : math.sin(_drift.value * math.pi * 2);
                    return Transform.translate(
                      offset: Offset(phase * 3, phase * 2),
                      child: Transform.rotate(angle: phase * math.pi / 90, child: child),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
    final effective = _reduced && widget.preset == BlizzardParticlePreset.hero
        ? BlizzardParticlePreset.staticHero
        : widget.preset;
    final showsRibbon = effective == BlizzardParticlePreset.hero || effective == BlizzardParticlePreset.staticHero;
    if (!showsRibbon) _ribbon.dispose();
    final scene = RepaintBoundary(
      child: CustomPaint(
        painter: BlizzardScenePainter(preset: effective),
        isComplex: effective != BlizzardParticlePreset.off,
        size: Size.infinite,
      ),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ClipRect(
          child: showsRibbon
              ? ColoredBox(
                  color: BlizzardPalette.background,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      scene,
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Cache the cloth and digit atlas outside paint.
                          // Frames deform a small mesh and move cached glyphs.
                          _ribbon.prepare(constraints.biggest, MediaQuery.devicePixelRatioOf(context));
                          return RepaintBoundary(
                            child: CustomPaint(painter: BlizzardRibbonPainter(_drift, _ribbon), willChange: true),
                          );
                        },
                      ),
                      if (effective == BlizzardParticlePreset.hero)
                        RepaintBoundary(child: CustomPaint(painter: _BlizzardSnowPainter(_drift), willChange: true)),
                    ],
                  ),
                )
              : scene,
        ),
      ),
    );
  }
}

class _BlizzardEnvelopeSnowPainter extends CustomPainter {
  _BlizzardEnvelopeSnowPainter(this.drift) : super(repaint: drift);

  final Animation<double> drift;
  static final _seeds = _snowSeeds();

  static List<({double x, double y, double phase, double radius})> _snowSeeds() {
    final random = math.Random(0xE11E10FE);
    return List.generate(
      520,
      (_) => (
        x: random.nextDouble(),
        y: random.nextDouble(),
        phase: random.nextDouble() * math.pi * 2,
        radius: random.nextDouble(),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    final angle = drift.value * math.pi * 2;
    for (var i = 0; i < _seeds.length; i++) {
      final layer = i < 330 ? 0 : (i < 470 ? 1 : 2);
      final seed = _seeds[i];
      final travel = (seed.y + drift.value * (layer + 1)) % 1;
      final y = -0.035 + travel * 1.07;
      final gust = math.sin(angle * 5 + seed.phase) + math.sin(angle * 11 - seed.phase * 0.7) * 0.34;
      final x = (seed.x + travel * (0.1 + layer * 0.055) + gust * (0.018 + layer * 0.013)) % 1;
      final wrapFade = math.min(travel / 0.055, (1 - travel) / 0.055).clamp(0.0, 1.0);
      final horizontalFade = math.min(x / 0.025, (1 - x) / 0.025).clamp(0.0, 1.0);
      // The action label occupies the lower center of this exact envelope.
      // Keep that strip quiet while snow remains visible through the button.
      final labelQuiet = y > 0.82 && x > 0.18 && x < 0.82 ? 0.12 : 1.0;
      final opacity = wrapFade * horizontalFade * labelQuiet;
      if (opacity == 0) continue;

      final position = Offset(x * size.width, y * size.height);
      if (layer == 2) {
        paint
          ..color = BlizzardPalette.particleNear.withValues(alpha: 0.16 * opacity)
          ..strokeWidth = 0.75 + seed.radius * 0.55;
        canvas.drawLine(position - Offset(5 + gust.abs() * 3, 2.5 + seed.radius * 2), position, paint);
        paint.color = BlizzardPalette.particleNear.withValues(alpha: 0.045 * opacity);
        canvas.drawCircle(position, 3.2 + seed.radius * 1.5, paint);
      }
      final radius = layer == 0 ? 0.5 : (layer == 1 ? 0.9 : 1.35 + seed.radius * 0.35);
      paint.color = (layer == 2 ? BlizzardPalette.particleNear : BlizzardPalette.particleFar).withValues(
        alpha: (layer == 0 ? 0.18 : (layer == 1 ? 0.3 : 0.5)) * opacity,
      );
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlizzardEnvelopeSnowPainter oldDelegate) => oldDelegate.drift != drift;
}

class BlizzardScenePainter extends CustomPainter {
  const BlizzardScenePainter({required this.preset});
  final BlizzardParticlePreset preset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = BlizzardPalette.background);
    if (preset == BlizzardParticlePreset.off) return;
    final paint = Paint();
    if (preset == BlizzardParticlePreset.hero || preset == BlizzardParticlePreset.staticHero) return;
    // Sparse, quiet ambient points retain depth without crossing readable text.
    const count = 80;
    for (var i = 0; i < count; i++) {
      final x = ((i * 293) % 769) / 769;
      final y = ((i * 137) % 547) / 547;
      if (y < 0.14 || y > 0.78 || (y > 0.48 && x > 0.2 && x < 0.8)) continue;
      final near = i % 11 == 0;
      paint.color = (near ? BlizzardPalette.particleNear : BlizzardPalette.particleFar).withValues(
        alpha: near ? 0.1 : 0.05,
      );
      canvas.drawCircle(Offset(x * size.width, y * size.height), near ? 0.85 : 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BlizzardScenePainter oldDelegate) => oldDelegate.preset != preset;
}

/// The transparent dot cloth keeps the reference's folds. It is independent of
/// the background, so highlights illuminate particles instead of a rectangle.
class _RibbonTexture {
  ui.Image? image;
  ui.Image? numerals;
  ui.ImageShader? shader;
  Size? sceneSize;
  double? pixelRatio;
  Rect bounds = Rect.zero;
  int generation = 0;

  void prepare(Size size, double ratio) {
    final resolution = ratio.clamp(1.0, 3.0);
    if (sceneSize == size && pixelRatio == resolution && image != null) return;
    dispose();
    if (size.isEmpty || !size.isFinite) return;
    sceneSize = size;
    pixelRatio = resolution;
    bounds = Rect.fromLTWH(size.width * 0.1, size.height * 0.15, size.width * 0.8, size.height * 0.43);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(resolution)
      ..translate(-bounds.left, -bounds.top);
    final paint = Paint();
    const columns = 216;
    const rows = 96;
    for (var row = 0; row < rows; row++) {
      final v = row / (rows - 1);
      for (var column = 0; column < columns; column++) {
        final u = column / (columns - 1);
        final taper = math.pow(math.sin(u * math.pi), 0.55).toDouble();
        final fold = math.sin(u * math.pi * 2 - v * 1.8 + 1.4);
        final x = 0.13 + 0.74 * u + math.sin(v * math.pi * 2) * 0.02 * taper;
        final y =
            0.385 -
            math.sin(u * math.pi) * 0.035 +
            fold * 0.045 * taper +
            (v - 0.5) * 0.23 * taper -
            math.sin(u * math.pi) * math.sin(v * math.pi * 2) * 0.025;
        final edge = math.pow(math.sin(u * math.pi) * math.sin(v * math.pi), 0.3).toDouble();
        final depth = 0.5 + 0.5 * math.cos(u * math.pi * 2 - v * 2.8);
        final crest = math.exp(-math.pow((u - 0.36) / 0.18, 2) - math.pow((v - 0.14) / 0.18, 2));
        final fade = math.min((y - 0.18) / 0.035, (0.54 - y) / 0.065).clamp(0.0, 1.0);
        paint.color = Colors.white.withValues(alpha: (0.7 + depth * 0.3 + crest * 0.2).clamp(0.0, 1.0) * edge * fade);
        canvas.drawCircle(Offset(x * size.width, y * size.height), 0.36 + depth * 0.08 + crest * 0.16, paint);
      }
    }
    final picture = recorder.endRecording();
    try {
      image = picture.toImageSync((bounds.width * resolution).ceil(), (bounds.height * resolution).ceil());
      shader = ui.ImageShader(image!, TileMode.decal, TileMode.decal, Matrix4.identity().storage);
      numerals = _numeralAtlas(resolution);
      generation++;
    } finally {
      picture.dispose();
    }
  }

  static ui.Image _numeralAtlas(double resolution) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(resolution);
    final text = TextPainter(textDirection: TextDirection.ltr);
    try {
      for (var digit = 0; digit < 10; digit++) {
        text.text = TextSpan(
          text: '$digit',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        );
        text.layout();
        text.paint(canvas, Offset(digit * 14 + (14 - text.width) / 2, (18 - text.height) / 2));
      }
    } finally {
      text.dispose();
    }
    final picture = recorder.endRecording();
    try {
      return picture.toImageSync((140 * resolution).ceil(), (18 * resolution).ceil());
    } finally {
      picture.dispose();
    }
  }

  void dispose() {
    shader?.dispose();
    image?.dispose();
    numerals?.dispose();
    shader = null;
    image = null;
    numerals = null;
    sceneSize = null;
    pixelRatio = null;
  }
}

class BlizzardRibbonPainter extends CustomPainter {
  BlizzardRibbonPainter(this.drift, this._texture) : _generation = _texture.generation, super(repaint: drift) {
    final image = _texture.image;
    if (image == null) return;
    for (var row = 0; row <= _rows; row++) {
      for (var column = 0; column <= _columns; column++) {
        final index = row * (_columns + 1) + column;
        _coordinates[index * 2] = image.width * column / _columns;
        _coordinates[index * 2 + 1] = image.height * row / _rows;
      }
    }
  }
  final Animation<double> drift;
  final _RibbonTexture _texture;
  final int _generation;
  static const _columns = 24;
  static const _rows = 12;
  final _positions = Float32List((_columns + 1) * (_rows + 1) * 2);
  final _coordinates = Float32List((_columns + 1) * (_rows + 1) * 2);
  final _colors = Int32List((_columns + 1) * (_rows + 1));
  static final _indices = _meshIndices();
  static const _numeralCount = 96;
  final _glyphTransforms = Float32List(_numeralCount * 4);
  final _glyphRects = Float32List(_numeralCount * 4);
  final _glyphColors = Int32List(_numeralCount);

  static Uint16List _meshIndices() {
    final indices = Uint16List(_columns * _rows * 6);
    var triangle = 0;
    for (var row = 0; row < _rows; row++) {
      for (var column = 0; column < _columns; column++) {
        final top = row * (_columns + 1) + column;
        final bottom = top + _columns + 1;
        for (final vertex in [top, bottom, top + 1, top + 1, bottom, bottom + 1]) {
          indices[triangle++] = vertex;
        }
      }
    }
    return indices;
  }

  @visibleForTesting
  ui.Image? get debugTexture => _texture.image;

  @visibleForTesting
  ui.Image? get debugNumeralAtlas => _texture.numerals;

  @override
  void paint(Canvas canvas, Size size) {
    final image = _texture.image;
    if (image == null) return;
    final angle = drift.value * math.pi * 2;
    final bounds = _texture.bounds;
    final glowCenter = Offset(size.width * (0.38 + math.sin(angle * 4) * 0.06), size.height * 0.29);
    final glow = Paint()
      ..shader = ui.Gradient.radial(glowCenter, size.width * 0.38, [
        BlizzardPalette.accent.withValues(alpha: 0.06 + 0.02 * math.sin(angle * 6)),
        BlizzardPalette.accent.withValues(alpha: 0),
      ]);
    canvas.drawRect(Offset.zero & size, glow);
    glow.shader!.dispose();
    canvas.save();
    for (var row = 0; row <= _rows; row++) {
      final v = row / _rows;
      for (var column = 0; column <= _columns; column++) {
        final u = column / _columns;
        final index = row * (_columns + 1) + column;
        final edge = math.sin(u * math.pi);
        final calmCenter = 0.45 + (u - 0.5).abs() * 1.1;
        final swell = math.sin(u * math.pi * 2 - angle * 3 + v * 0.8) * 18 * calmCenter;
        final fold = math.sin(u * math.pi * 4 + angle * 8 + v * 3) * 7;
        _positions[index * 2] = bounds.left + bounds.width * u + math.sin(v * math.pi * 2 + angle * 4 - u) * 11 * edge;
        _positions[index * 2 + 1] = bounds.top + bounds.height * v + (swell + fold) * edge;
        final beam = math.pow((1 + math.cos(u * math.pi * 2 - angle * 6 + v * 0.8)) / 2, 5).toDouble();
        final counterLight = math.pow((1 + math.sin(u * math.pi * 2 + angle * 4 - v)) / 2, 8).toDouble();
        final crest = math.pow((1 + math.cos((u - 0.32) * math.pi * 2 + math.sin(angle * 4) * 0.45)) / 2, 4).toDouble();
        final lit = Color.lerp(
          BlizzardPalette.ribbonShade,
          BlizzardPalette.ribbonCrest,
          (crest * 0.8 + beam * 0.2).clamp(0.0, 1.0),
        )!;
        final y = _positions[index * 2 + 1] / size.height;
        final topFade = ((y - 0.2) / 0.03).clamp(0.0, 1.0);
        final lowerFade = ((0.54 - y) / 0.05).clamp(0.0, 1.0);
        _colors[index] = lit
            .withValues(
              alpha: (0.55 + crest * 0.42 + beam * 0.3 + counterLight * 0.1).clamp(0.0, 1.0) * topFade * lowerFade,
            )
            .toARGB32();
      }
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      colors: _colors,
      textureCoordinates: _coordinates,
      indices: _indices,
    );
    try {
      canvas.drawVertices(vertices, BlendMode.modulate, Paint()..shader = _texture.shader);
    } finally {
      vertices.dispose();
      canvas.restore();
    }
    _paintNumerals(canvas, size, angle);
  }

  void _paintNumerals(Canvas canvas, Size size, double angle) {
    final atlas = _texture.numerals;
    if (atlas == null) return;
    final cellWidth = atlas.width / 10;
    final cellHeight = atlas.height.toDouble();
    for (var i = 0; i < _numeralCount; i++) {
      final stream = i % 2;
      final phase = (i ~/ 2) / (_numeralCount / 2);
      final theta = phase * math.pi * 2 + angle * (stream == 0 ? 4 : -6) + stream * math.pi;
      final depth = (1 + math.sin(theta)) / 2;
      final scatter = math.sin(i * 17.3) * 0.018;
      final x = 0.5 + math.cos(theta) * (0.34 + scatter);
      final y = 0.335 + math.sin(theta) * 0.085 + math.sin(theta * 2 + angle * 2) * 0.025 + scatter + stream * 0.016;
      final rotation = math.atan2(
        (0.085 * math.cos(theta) + 0.05 * math.cos(theta * 2 + angle * 2)) * size.height,
        -0.34 * math.sin(theta) * size.width,
      );
      final scale = (0.62 + depth * 0.34) / _texture.pixelRatio!;
      final cosine = math.cos(rotation) * scale;
      final sine = math.sin(rotation) * scale;
      final offset = i * 4;
      _glyphTransforms[offset] = cosine;
      _glyphTransforms[offset + 1] = sine;
      _glyphTransforms[offset + 2] = x * size.width - cosine * cellWidth / 2 + sine * cellHeight / 2;
      _glyphTransforms[offset + 3] = y * size.height - sine * cellWidth / 2 - cosine * cellHeight / 2;
      final digit = (i * 7) % 10;
      _glyphRects[offset] = digit * cellWidth;
      _glyphRects[offset + 1] = 0;
      _glyphRects[offset + 2] = (digit + 1) * cellWidth;
      _glyphRects[offset + 3] = cellHeight;
      final edge = math.min(x / 0.06, (1 - x) / 0.06).clamp(0.0, 1.0);
      _glyphColors[i] = Color.lerp(
        BlizzardPalette.accent,
        BlizzardPalette.particleNear,
        depth,
      )!.withValues(alpha: (0.07 + depth * 0.1) * edge).toARGB32();
    }
    // All 96 rotating glyphs share one cached image and one draw call. They are
    // decorative digits, not measurements, addresses, or connection feedback.
    canvas.drawRawAtlas(atlas, _glyphTransforms, _glyphRects, _glyphColors, BlendMode.modulate, null, Paint());
  }

  @override
  bool shouldRepaint(covariant BlizzardRibbonPainter oldDelegate) =>
      oldDelegate.drift != drift || oldDelegate._generation != _generation;
}

class _BlizzardSnowPainter extends CustomPainter {
  _BlizzardSnowPainter(this.drift) : super(repaint: drift);
  final Animation<double> drift;
  // Stable irregular seeds avoid visible rows/constellations in the near snow.
  static final _seeds = _snowSeeds();
  static List<({double x, double y, double phase, double radius})> _snowSeeds() {
    final random = math.Random(0xB117A2D);
    return List.generate(
      450,
      (_) => (
        x: random.nextDouble(),
        y: random.nextDouble(),
        phase: random.nextDouble() * math.pi * 2,
        radius: random.nextDouble(),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final angle = drift.value * math.pi * 2;
    for (var i = 0; i < 450; i++) {
      final layer = i < 300 ? 0 : (i < 420 ? 1 : 2);
      final seed = _seeds[i];
      final travel = (seed.y + drift.value * (layer + 1)) % 1;
      final y = 0.14 + travel * 0.64;
      final gust = math.sin(angle * 6 + seed.phase);
      final x =
          (seed.x +
              travel * 0.22 +
              gust * (0.025 + layer * 0.012) +
              math.sin(travel * math.pi * 2 + seed.phase) * 0.018) %
          1;
      // Fade at the wrap and around the existing status/latency quiet zone.
      // These are decorative flakes, unrelated to connection or traffic state.
      final edge = math.min(travel / 0.055, (1 - travel) / 0.055).clamp(0.0, 1.0);
      final center = math.min((x - 0.18) / 0.05, (0.82 - x) / 0.05).clamp(0.0, 1.0);
      final lower = ((y - 0.44) / 0.04).clamp(0.0, 1.0);
      final horizontalEdge = math.min(x / 0.025, (1 - x) / 0.025).clamp(0.0, 1.0);
      final opacity = edge * horizontalEdge * (1 - center * lower);
      if (opacity == 0) continue;
      final position = Offset(x * size.width, y * size.height);
      if (layer == 2) {
        paint
          ..color = BlizzardPalette.particleNear.withValues(alpha: 0.08 * opacity)
          ..strokeWidth = 0.7
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(position - Offset(gust * 4, 3), position, paint);
      }
      final radius = layer == 0 ? 0.45 : (layer == 1 ? 0.8 : 1.15 + seed.radius * 0.24);
      if (layer == 2) {
        paint.color = BlizzardPalette.particleNear.withValues(alpha: 0.028 * opacity);
        canvas.drawCircle(position, radius * 2.8, paint);
      }
      paint.color = (layer == 2 ? BlizzardPalette.particleNear : BlizzardPalette.particleFar).withValues(
        alpha: (layer == 0 ? 0.1 : (layer == 1 ? 0.2 : 0.36)) * opacity,
      );
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlizzardSnowPainter oldDelegate) => oldDelegate.drift != drift;
}
