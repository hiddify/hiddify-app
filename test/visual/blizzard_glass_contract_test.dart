import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_glass.dart';

const _canvas = ValueKey('glass-canvas');

Widget _fixture({
  MediaQueryData media = const MediaQueryData(),
  bool active = true,
  bool lens = false,
  VoidCallback? onTap,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: media,
    child: Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: RepaintBoundary(
          key: _canvas,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ColoredBox(color: Color(0xFFB03535))),
                  Expanded(child: ColoredBox(color: Color(0xFF35B075))),
                ],
              ),
              Center(
                child: SizedBox(
                  width: 148,
                  height: 148,
                  child: BlizzardGlass(
                    active: active,
                    radius: 44,
                    lens: lens,
                    child: GestureDetector(
                      onTap: onTap,
                      child: const ColoredBox(key: ValueKey('glass-control'), color: Colors.transparent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

Future<Uint8List> _pixels(WidgetTester tester) async => (await tester.runAsync(() async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_canvas));
  final image = await boundary.toImage();
  try {
    return Uint8List.fromList((await image.toByteData())!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}))!;

void main() {
  testWidgets('deep reference glass still transmits background color through its tint', (tester) async {
    await tester.pumpWidget(_fixture(lens: true));
    final pixels = await _pixels(tester);
    const left = (120 * 240 + 85) * 4;
    const right = (120 * 240 + 155) * 4;
    expect(pixels[left] - pixels[left + 1], greaterThan(25));
    expect(pixels[right + 1] - pixels[right], greaterThan(25));
    expect(tester.getSize(find.byKey(const ValueKey('glass-control'))), const Size(148, 148));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('clear glass transmits background colors and keeps one unchanged hit target', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_fixture(onTap: () => taps++));
    final pixels = await _pixels(tester);
    const left = (120 * 240 + 85) * 4;
    const right = (120 * 240 + 155) * 4;
    expect(pixels[left] - pixels[left + 1], greaterThan(40));
    expect(pixels[right + 1] - pixels[right], greaterThan(40));
    expect(tester.getSize(find.byKey(const ValueKey('glass-control'))), const Size(148, 148));
    await tester.tap(find.byKey(const ValueKey('glass-control')));
    expect(taps, 1);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'Glass uses the scene, not another ambient ticker');
    expect(tester.takeException(), isNull);
  });

  for (final media in [
    const MediaQueryData(highContrast: true),
  ]) {
    testWidgets('glass has an opaque unfiltered accessible fallback: $media', (tester) async {
      await tester.pumpWidget(_fixture(media: media));
      final pixels = await _pixels(tester);
      const left = (120 * 240 + 85) * 4;
      const right = (120 * 240 + 155) * 4;
      expect(pixels.sublist(left, left + 4), pixels.sublist(right, right + 4));
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.getSize(find.byKey(const ValueKey('glass-control'))), const Size(148, 148));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  for (final media in [
    const MediaQueryData(accessibleNavigation: true),
    const MediaQueryData(disableAnimations: true),
  ]) {
    testWidgets('motion preferences keep background transmission without a ticker: $media', (tester) async {
      await tester.pumpWidget(_fixture(media: media));
      final pixels = await _pixels(tester);
      const left = (120 * 240 + 85) * 4;
      const right = (120 * 240 + 155) * 4;
      expect(pixels[left] - pixels[left + 1], greaterThan(40));
      expect(pixels[right + 1] - pixels[right], greaterThan(40));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('inactive glass leaves the underlying legacy control untouched', (tester) async {
    await tester.pumpWidget(_fixture(active: false));
    final pixels = await _pixels(tester);
    const left = (120 * 240 + 85) * 4;
    expect(pixels.sublist(left, left + 4), [176, 53, 53, 255]);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
