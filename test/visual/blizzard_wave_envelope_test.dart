import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';

void main() {
  testWidgets('enveloping wave renders the approved transparent design asset', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 353, height: 260, child: BlizzardScene(preset: BlizzardParticlePreset.envelope)),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/images/blizzard_wave_envelope.png');
    expect(find.byType(IgnorePointer), findsOneWidget);
    expect(find.byType(ExcludeSemantics), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('envelope pauses in background and resumes from its retained phase', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 353, height: 260, child: BlizzardScene(preset: BlizzardParticlePreset.envelope)),
        ),
      ),
    );
    List<double> transform() => tester.widget<Transform>(find.byType(Transform).first).transform.storage.toList();
    await tester.pump();
    final first = transform();
    await tester.pump(const Duration(seconds: 2));
    expect(transform(), isNot(first));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final paused = transform();
    await tester.pump(const Duration(minutes: 1));
    expect(transform(), paused);
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(transform(), paused);
    await tester.pump(const Duration(seconds: 2));
    expect(transform(), isNot(paused));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final media in [
    const MediaQueryData(disableAnimations: true),
    const MediaQueryData(accessibleNavigation: true),
    const MediaQueryData(highContrast: true),
  ]) {
    testWidgets('envelope stays centered without animation for $media', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: media,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(width: 353, height: 260, child: BlizzardScene(preset: BlizzardParticlePreset.envelope)),
          ),
        ),
      );
      await tester.pump();
      final transforms = tester
          .widgetList<Transform>(find.byType(Transform))
          .map((t) => t.transform.storage.toList())
          .toList();
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widgetList<Transform>(find.byType(Transform)).map((t) => t.transform.storage.toList()).toList(),
        transforms,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
