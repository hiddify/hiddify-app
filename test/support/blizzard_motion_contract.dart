import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'blizzard_visual_fixture.dart';

bool _instant(Iterable<Duration> durations) => durations.isNotEmpty && durations.every((d) => d == Duration.zero);

List<Duration> _connectionDurations(WidgetTester tester) {
  final descendants = find.descendant(of: find.byType(ConnectionButton), matching: find.byWidgetPredicate((_) => true));
  final widgets = tester.widgetList(descendants).toList();
  final effects = widgets.whereType<Animate>().toList();
  final labels = widgets.whereType<AnimatedText>().toList();
  final tweens = widgets.whereType<TweenAnimationBuilder>().toList();
  expect(effects, hasLength(2), reason: 'Both scale and blur must be inspected');
  expect(labels, hasLength(1));
  expect(tweens, hasLength(1));
  return [...effects.map((w) => w.duration), ...labels.map((w) => w.duration), ...tweens.map((w) => w.duration)];
}

List<double> _scaleValues(WidgetTester tester) => tester
    .widgetList<Transform>(find.descendant(of: find.byType(ConnectionButton), matching: find.byType(Transform)))
    .map((w) => w.transform.entry(0, 0))
    .toList();

// NavigationIndicator has an independent framework-owned 100 ms opacity
// transition even with NavigationBar.animationDuration == zero. The app-owned
// duration controls its spatial selection animation, measured here directly.
List<double> _destinationProgress(WidgetTester tester) => tester
    .widgetList<Transform>(find.descendant(of: find.byType(NavigationIndicator), matching: find.byType(Transform)))
    .map((widget) => widget.transform.entry(0, 0))
    .toList();

void registerBlizzardMotionContracts() {
  test('instant motion assertion rejects a deliberate nonzero duration', () {
    expect(_instant([Duration.zero, Duration.zero]), isTrue);
    expect(_instant([Duration.zero, const Duration(milliseconds: 200)]), isFalse);
    expect(_instant([]), isFalse);
  });
  testWidgets('actual scene suppresses particles for each accessibility setting', (tester) async {
    for (final media in [
      const MediaQueryData(),
      const MediaQueryData(disableAnimations: true),
      const MediaQueryData(accessibleNavigation: true),
      const MediaQueryData(highContrast: true),
    ]) {
      await tester.pumpWidget(
        MediaQuery(
          data: media,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(width: 393, height: 852, child: BlizzardScene(preset: BlizzardParticlePreset.hero)),
          ),
        ),
      );
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<BlizzardScenePainter>()
          .toList();
      expect(painters, hasLength(1));
      expect(
        painters.single.preset,
        media.disableAnimations || media.accessibleNavigation || media.highContrast
            ? BlizzardParticlePreset.staticHero
            : BlizzardParticlePreset.hero,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final reduced in [false, true]) {
    testWidgets('actual connection and dock motion contract reduced=$reduced', (tester) async {
      final fixture = await mountVisualFixture(tester, disableAnimations: reduced);
      final eligible = expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393);
      final instant = eligible && reduced;
      expect(_instant(_connectionDurations(tester)), instant);
      final button = find.byKey(const ValueKey('home_connection_button'));
      await tester.tap(button);
      await tester.pump();
      expect(fixture.events, ['toggle']);
      final notifier = fixture.container.read(connectionNotifierProvider.notifier);
      // Exercise the real consumer rebuild while isolating the native engine.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      notifier.state = const AsyncData(Connecting());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final immediate = _scaleValues(tester);
      await tester.tap(button);
      await tester.pump();
      expect(fixture.events, ['toggle'], reason: 'Connecting must retain its no-op callback');
      await tester.pump(const Duration(seconds: 1));
      final settled = _scaleValues(tester);
      expect(settled.any((value) => (value - .88).abs() < .001), isTrue);
      if (instant) {
        expect(immediate, settled, reason: 'Reduced-motion scale reaches its final geometry on the first frame');
      } else {
        expect(immediate, isNot(settled), reason: 'Normal animation is a sensitivity control for geometry sampling');
      }
      expect(_instant(_connectionDurations(tester)), instant);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.animationDuration == Duration.zero, instant);
      nav.onDestinationSelected!(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
      final dockRect = tester.getRect(find.byType(NavigationBar));
      final destinationProgress = _destinationProgress(tester);
      expect(destinationProgress, isNotEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getRect(find.byType(NavigationBar)), dockRect);
      if (instant) {
        expect(destinationProgress, _destinationProgress(tester));
      } else {
        expect(destinationProgress, isNot(_destinationProgress(tester)));
      }
      expect(fixture.events, ['toggle']);
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
  }
}
