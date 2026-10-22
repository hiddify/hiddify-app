import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_glass.dart';

void main() {
  testWidgets('native dock retains a visible rim over a quiet dark backdrop without owning taps', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, (_) async => null);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, null),
    );
    var taps = 0;
    const capture = ValueKey('optical-capture');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: capture,
            child: ColoredBox(
              color: const Color(0xFF06121D),
              child: SizedBox(
                width: 320,
                height: 64,
                child: BlizzardGlass(
                  active: true,
                  radius: 32,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(UiKitView), findsOneWidget);
    await tester.tap(find.byType(BlizzardGlass));
    expect(taps, 1);
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!;
    });
    int red(int x, int y) => pixels!.getUint8((y * 320 + x) * 4);
    expect(red(160, 1), greaterThan(red(160, 32) + 20), reason: 'The rim must remain visible on a uniform dark scene.');
    expect(
      red(160, 8),
      greaterThan(red(160, 56) + 8),
      reason: 'The regular material needs a restrained top highlight.',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}
