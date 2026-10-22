import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';

const _canvas = ValueKey('snow-canvas');

Widget _scene({
  BlizzardParticlePreset preset = BlizzardParticlePreset.hero,
  MediaQueryData media = const MediaQueryData(),
  bool visible = true,
  double width = 393,
  double height = 852,
  bool opaqueControl = false,
  Alignment controlAlignment = Alignment.center,
  VoidCallback? onTap,
}) => MediaQuery(
  data: media,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: RepaintBoundary(
          key: _canvas,
          child: TickerMode(
            enabled: visible,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: BlizzardScene(preset: preset)),
                if (onTap != null || opaqueControl)
                  Align(
                    alignment: controlAlignment,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap,
                      child: SizedBox(
                        key: const ValueKey('control'),
                        width: 148,
                        height: 148,
                        child: ColoredBox(color: opaqueControl ? const Color(0xFF102235) : Colors.transparent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<Uint8List> _pixels(WidgetTester tester, {double pixelRatio = 1}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_canvas));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData();
      return Uint8List.fromList(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }))!;
}

Future<void> _mount(WidgetTester tester, Widget scene) async {
  await tester.binding.setSurfaceSize(const Size(393, 852));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(scene);
}

List<double> _ribbonLightProfile(Uint8List pixels) {
  final weights = List<double>.filled(3, 0);
  for (var y = 170; y < 430; y++) {
    for (var x = 24; x < 369; x++) {
      final pixel = (y * 393 + x) * 4;
      if (pixels[pixel + 2] > 95 && pixels[pixel + 1] > 65) {
        weights[((x - 24) * 3 ~/ 345)] += pixels[pixel + 2] - 95;
      }
    }
  }
  return weights;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('hero visibly moves without changing control geometry or intercepting a tap', (tester) async {
    var taps = 0;
    await _mount(tester, _scene(onTap: () => taps++));
    await tester.pump();
    final initial = await _pixels(tester);
    final control = tester.getRect(find.byKey(const ValueKey('control')));
    await tester.pump(const Duration(seconds: 2));
    expect(listEquals(await _pixels(tester), initial), isFalse, reason: 'The actual rendered snowfall must move');
    expect(tester.getRect(find.byKey(const ValueKey('control'))), control);
    await tester.tap(find.byKey(const ValueKey('control')));
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'Disposal must release the ambient clock');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ribbon has a visible luminous surface and flowing light within two seconds', (tester) async {
    await _mount(tester, _scene());
    await tester.pump();
    final before = _ribbonLightProfile(await _pixels(tester));
    expect(before.reduce((a, b) => a + b), greaterThan(3000), reason: 'The ribbon must be visibly luminous');
    await tester.pump(const Duration(seconds: 2));
    final after = _ribbonLightProfile(await _pixels(tester));
    final totalBefore = before.reduce((a, b) => a + b);
    final totalAfter = after.reduce((a, b) => a + b);
    final change = List.generate(3, (i) => (before[i] / totalBefore - after[i] / totalAfter).abs());
    expect(change.reduce((a, b) => a + b), greaterThan(0.15), reason: 'Light must travel along the ribbon');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ambient light fades smoothly into the status area without a horizontal cutoff', (tester) async {
    await _mount(tester, _scene(height: 700));
    await tester.pump();
    final pixels = await _pixels(tester);
    double blueAt(int row) {
      var total = 0;
      for (var x = 120; x < 273; x++) {
        total += pixels[(row * 393 + x) * 4 + 2];
      }
      return total / 153;
    }

    expect((blueAt(384) - blueAt(386)).abs(), lessThan(1), reason: 'Glow must dissolve rather than end at a clip edge');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a broad luminous ribbon remains visible above an opaque connection control', (tester) async {
    await _mount(
      tester,
      _scene(
        height: 614,
        opaqueControl: true,
        controlAlignment: const Alignment(0, -0.26),
        media: const MediaQueryData(devicePixelRatio: 2),
      ),
    );
    await tester.pump();
    for (var phase = 0; phase < 3; phase++) {
      final pixels = await _pixels(tester, pixelRatio: 2);
      var lit = 0;
      final columns = <int>{};
      for (var y = 280; y < 560; y++) {
        for (var x = 24; x < 762; x++) {
          final pixel = (y * 786 + x) * 4;
          if (pixels[pixel + 2] > 95 && pixels[pixel + 1] > 65) {
            lit++;
          }
          if (pixels[pixel + 2] > 60 && pixels[pixel + 1] > 40) {
            columns.add(x ~/ 2);
          }
        }
      }
      expect(lit, greaterThan(1200), reason: 'The visible upper ribbon must have substance, not just hidden dots');
      expect(
        columns.length,
        greaterThan(260),
        reason: 'The contained reference halo must remain broad outside the button',
      );
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the reference crest is dense icy cyan rather than a pale gray cloth', (tester) async {
    await _mount(
      tester,
      _scene(
        height: 614,
        opaqueControl: true,
        controlAlignment: const Alignment(0, -0.26),
        media: const MediaQueryData(devicePixelRatio: 2),
      ),
    );
    await tester.pump();
    final pixels = await _pixels(tester, pixelRatio: 2);
    var icy = 0;
    var crest = 0;
    for (var y = 320; y < 640; y++) {
      for (var x = 104; x < 368; x++) {
        final pixel = (y * 786 + x) * 4;
        if (pixels[pixel + 2] > 100 && pixels[pixel + 1] > 70 && pixels[pixel + 2] - pixels[pixel] > 65) icy++;
        if (y < 390 && x > 176 && pixels[pixel + 2] > 160 && pixels[pixel + 1] > 110) crest++;
      }
    }
    expect(icy, greaterThan(1000), reason: 'A dense cyan crest must be visible above/left of the control');
    expect(crest, greaterThan(150), reason: 'The upper-left fold must carry the bright reference highlight');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the rendered ribbon, numerals and snow close their shared loop at the starting phase', (tester) async {
    await _mount(tester, _scene());
    await tester.pump();
    final initial = await _pixels(tester);
    await tester.pump(BlizzardMetrics.waveDuration);
    expect(
      listEquals(await _pixels(tester), initial),
      isTrue,
      reason: 'Every decorative layer must close the same loop',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ribbon reuses its cropped texture while deforming and releases it on appearance changes', (
    tester,
  ) async {
    await _mount(tester, _scene());
    await tester.pump();
    BlizzardRibbonPainter ribbon() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<BlizzardRibbonPainter>()
        .single;
    final texture = ribbon().debugTexture!;
    final numerals = ribbon().debugNumeralAtlas!;
    expect(texture.width * texture.height, lessThan(393 * 852), reason: 'Only the ribbon region is rasterized');
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(ribbon().debugTexture, same(texture));
      expect(texture.debugDisposed, isFalse);
      expect(ribbon().debugNumeralAtlas, same(numerals));
      expect(numerals.debugDisposed, isFalse);
    }
    await _mount(tester, _scene(width: 320));
    final resized = ribbon().debugTexture!;
    expect(resized, isNot(same(texture)));
    expect(texture.debugDisposed, isTrue);
    expect(numerals.debugDisposed, isTrue);
    final resizedNumerals = ribbon().debugNumeralAtlas!;
    await _mount(tester, _scene(width: 320, media: const MediaQueryData(devicePixelRatio: 2)));
    final sharper = ribbon().debugTexture!;
    expect(sharper.width, greaterThan(resized.width));
    expect(resized.debugDisposed, isTrue);
    expect(resizedNumerals.debugDisposed, isTrue);
    final sharperNumerals = ribbon().debugNumeralAtlas!;
    await _mount(tester, _scene(media: const MediaQueryData(disableAnimations: true)));
    expect(sharper.debugDisposed, isTrue);
    expect(sharperNumerals.debugDisposed, isTrue);
    await _mount(tester, _scene());
    final restored = ribbon().debugTexture!;
    final restoredNumerals = ribbon().debugNumeralAtlas!;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(restored.debugDisposed, isTrue);
    expect(restoredNumerals.debugDisposed, isTrue);
  });

  for (final preset in [BlizzardParticlePreset.quiet, BlizzardParticlePreset.off]) {
    testWidgets('$preset stays static and schedules no animation frames', (tester) async {
      await _mount(tester, _scene(preset: preset));
      await tester.pump();
      final initial = await _pixels(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(listEquals(await _pixels(tester), initial), isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  for (final media in [
    const MediaQueryData(disableAnimations: true),
    const MediaQueryData(accessibleNavigation: true),
    const MediaQueryData(highContrast: true),
  ]) {
    testWidgets('accessibility switches stop active snowfall immediately: $media', (tester) async {
      await _mount(tester, _scene());
      await tester.pump(const Duration(seconds: 2));
      await _mount(tester, _scene(media: media));
      await tester.pump();
      final reduced = await _pixels(tester);
      expect(
        _ribbonLightProfile(reduced).reduce((a, b) => a + b),
        greaterThan(3000),
        reason: 'Reduce Motion keeps the approved static wave instead of removing it',
      );
      await tester.pump(const Duration(seconds: 2));
      expect(listEquals(await _pixels(tester), reduced), isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await _mount(tester, _scene());
      await tester.pump();
      final resumed = await _pixels(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(listEquals(await _pixels(tester), resumed), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('hidden tab stops the clock, retains the frame and resumes without a time jump', (tester) async {
    await _mount(tester, _scene());
    await tester.pump(const Duration(seconds: 2));
    await _mount(tester, _scene(visible: false));
    await tester.pump();
    final hidden = await _pixels(tester);
    await tester.pump(const Duration(minutes: 1));
    expect(listEquals(await _pixels(tester), hidden), isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await _mount(tester, _scene());
    await tester.pump();
    expect(
      listEquals(await _pixels(tester), hidden),
      isTrue,
      reason: 'Resume from the frozen phase, not elapsed wall time',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(listEquals(await _pixels(tester), hidden), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final lifecycle in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
    testWidgets('lifecycle $lifecycle pauses and resumes snowfall without a time jump', (tester) async {
      await _mount(tester, _scene());
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      await tester.pump();
      final paused = await _pixels(tester);
      await tester.pump(const Duration(minutes: 1));
      expect(listEquals(await _pixels(tester), paused), isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(listEquals(await _pixels(tester), paused), isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(listEquals(await _pixels(tester), paused), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
