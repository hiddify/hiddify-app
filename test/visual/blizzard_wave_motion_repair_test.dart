import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';

const _canvas = ValueKey('wave-motion-canvas');
const _size = Size(353, 260);

Future<void> _mount(WidgetTester tester, {bool reduceMotion = false}) async {
  await tester.binding.setSurfaceSize(_size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: _canvas,
          child: SizedBox(width: 353, height: 260, child: BlizzardScene(preset: BlizzardParticlePreset.envelope)),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.getSize(find.byKey(_canvas)), _size);
}

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_canvas));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      expect(image.width, _size.width);
      expect(image.height, _size.height);
      final data = await image.toByteData();
      return Uint8List.fromList(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }))!;
}

int _changedCutoutPixels(Uint8List before, Uint8List after) {
  var changed = 0;
  // Read-only alpha inspection of the 3x source asset confirms this center
  // cutout stays at alpha <= 2/255 with 24 source pixels of clearance.
  for (var y = 108; y < 158; y++) {
    for (var x = 148; x < 205; x++) {
      final offset = (y * _size.width.toInt() + x) * 4;
      final delta =
          (before[offset] - after[offset]).abs() +
          (before[offset + 1] - after[offset + 1]).abs() +
          (before[offset + 2] - after[offset + 2]).abs();
      if (delta > 8) changed++;
    }
  }
  return changed;
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized().handleAppLifecycleStateChanged(AppLifecycleState.resumed));

  testWidgets('envelope animates snow in transparent space rather than only moving the PNG', (tester) async {
    await _mount(tester);
    final before = await _pixels(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final after = await _pixels(tester);

    expect(
      _changedCutoutPixels(before, after),
      greaterThan(40),
      reason: 'A rigid PNG transform cannot change pixels far inside the source alpha cutouts',
    );
  });

  testWidgets('envelope freezes for Reduce Motion', (tester) async {
    await _mount(tester, reduceMotion: true);
    final frozen = await _pixels(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(listEquals(await _pixels(tester), frozen), isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('snow does not jump when the shared twelve-second clock wraps', (tester) async {
    await _mount(tester);
    await tester.pump(const Duration(milliseconds: 11999));
    final beforeWrap = await _pixels(tester);
    await tester.pump(const Duration(milliseconds: 2));
    final afterWrap = await _pixels(tester);
    await tester.pump(const Duration(milliseconds: 2));
    final ordinaryStep = await _pixels(tester);
    expect(
      _changedCutoutPixels(beforeWrap, afterWrap),
      lessThanOrEqualTo(_changedCutoutPixels(afterWrap, ordinaryStep) * 2 + 8),
      reason: 'Motion across the seam must stay comparable to an ordinary two-millisecond step',
    );
  });

  testWidgets('envelope freezes in background and resumes from the retained frame', (tester) async {
    await _mount(tester);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
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
  });
}
