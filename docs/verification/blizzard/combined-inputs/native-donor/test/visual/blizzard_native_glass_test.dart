import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_glass.dart';

void main() {
  testWidgets('changing glass geometry recreates the native surface with current arguments', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final creations = <Map<Object?, Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
      if (call.method == 'create') creations.add(Map<Object?, Object?>.from(call.arguments as Map));
      return null;
    });
    try {
      Widget fixture(double radius, bool lens) => Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Center(
            child: SizedBox(
              width: 148,
              height: 148,
              child: BlizzardGlass(active: true, radius: radius, lens: lens, child: const SizedBox.expand()),
            ),
          ),
        ),
      );
      await tester.pumpWidget(fixture(44, true));
      await tester.pump();
      await tester.pumpWidget(fixture(33, false));
      await tester.pump();
      expect(creations, hasLength(2));
      final bytes = creations.last['params']! as Uint8List;
      final args = const StandardMessageCodec().decodeMessage(ByteData.sublistView(bytes));
      expect(args, {'radius': 33.0, 'lens': false});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    }
  });

  testWidgets('iOS uses the registered native glass surface without stealing the action', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final creations = <Map<Object?, Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
      if (call.method == 'create') creations.add(Map<Object?, Object?>.from(call.arguments as Map));
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, null),
    );
    var taps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Center(
            child: SizedBox(
              width: 148,
              height: 148,
              child: BlizzardGlass(
                active: true,
                radius: 44,
                lens: true,
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const ColoredBox(key: ValueKey('native-glass-action'), color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(UiKitView), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    final view = tester.widget<UiKitView>(find.byType(UiKitView));
    expect(view.viewType, 'app.blizzard/native-liquid-glass');
    expect(view.creationParams, {'radius': 44.0, 'lens': true});
    expect(creations.single['viewType'], 'app.blizzard/native-liquid-glass');
    expect(tester.getSize(find.byKey(const ValueKey('native-glass-action'))), const Size(148, 148));
    await tester.tap(find.byKey(const ValueKey('native-glass-action')));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
