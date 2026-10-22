import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_glass.dart';

void main() {
  for (final media in [
    const MediaQueryData(disableAnimations: true),
    const MediaQueryData(accessibleNavigation: true),
  ]) {
    testWidgets('motion preferences retain native glass: $media', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: media,
            child: const BlizzardGlass(active: true, radius: 32, child: SizedBox(width: 320, height: 64)),
          ),
        ),
      );
      expect(find.byType(UiKitView), findsOneWidget,
          reason: 'Reduced motion and screen-reader navigation do not request reduced transparency');
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    });
  }
  testWidgets('native glass is decoration below the only Flutter action and semantics node', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 148,
              height: 148,
              child: BlizzardGlass(
                active: true,
                radius: 44,
                lens: true,
                child: Semantics(
                  button: true,
                  label: 'Connect',
                  child: GestureDetector(onTap: () => taps++, behavior: HitTestBehavior.opaque),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final native = tester.widget<UiKitView>(find.byType(UiKitView));
    expect(native.viewType, 'app.blizzard/native-liquid-glass');
    expect(native.creationParams, {'radius': 44.0, 'lens': true});
    expect(native.creationParamsCodec, isA<StandardMessageCodec>());
    expect(find.bySemanticsLabel('Connect'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Connect'));
    expect(taps, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('accessible appearance keeps an opaque Flutter fallback and no platform view', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: BlizzardGlass(active: true, radius: 32, child: SizedBox(width: 320, height: 64)),
        ),
      ),
    );
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(ColoredBox), findsWidgets);
    debugDefaultTargetPlatformOverride = null;
  });
}
