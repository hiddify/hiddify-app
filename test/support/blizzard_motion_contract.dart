import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/router/adaptive_layout/blizzard_dock.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'blizzard_visual_fixture.dart';

bool _instant(Iterable<Duration> durations) => durations.isNotEmpty && durations.every((d) => d == Duration.zero);

List<Duration> _connectionDurations(WidgetTester tester, {required bool blizzard}) {
  final descendants = find.descendant(of: find.byType(ConnectionButton), matching: find.byWidgetPredicate((_) => true));
  final widgets = tester.widgetList(descendants).toList();
  final effects = widgets.whereType<Animate>().toList();
  final labels = widgets.whereType<AnimatedText>().toList();
  final tweens = widgets.whereType<TweenAnimationBuilder>().toList();
  expect(effects, hasLength(2), reason: 'Both scale and blur must be inspected');
  expect(tweens, hasLength(1));
  if (blizzard) {
    expect(labels, isEmpty, reason: 'The Blizzard hero intentionally paints stable status and action Text widgets');
    expect(find.byKey(const ValueKey('blizzard_home_action_label')), findsOneWidget);
  } else {
    final platform = Theme.of(tester.element(find.byType(ConnectionButton))).platform;
    expect(
      labels,
      platform == TargetPlatform.iOS ? isEmpty : hasLength(1),
      reason: 'Legacy iOS uses plain Text while other legacy platforms retain AnimatedText',
    );
  }
  return [...effects.map((w) => w.duration), ...labels.map((w) => w.duration), ...tweens.map((w) => w.duration)];
}

double _connectionScale(WidgetTester tester) {
  final values = tester
      .widgetList<Transform>(
        find.ancestor(of: find.byKey(const ValueKey('home_connection_button')), matching: find.byType(Transform)),
      )
      .where((widget) => (widget.transform.entry(0, 0) - widget.transform.entry(1, 1)).abs() < .000001)
      .map((widget) => widget.transform.entry(0, 0))
      .where((value) => value >= 0 && value <= 1)
      .toList();
  expect(values, isNotEmpty, reason: 'The actual connection scale transform must be present');
  return values.reduce((minimum, value) => value < minimum ? value : minimum);
}

Finder _dockTab(int index) => find.byKey(ValueKey('blizzard_bottom_dock_tab_$index'));

AnimatedContainer _dockTabContainer(WidgetTester tester, int index) =>
    tester.widget<AnimatedContainer>(find.descendant(of: _dockTab(index), matching: find.byType(AnimatedContainer)));

// NavigationIndicator has an independent framework-owned 100 ms opacity
// transition even with NavigationBar.animationDuration == zero. The app-owned
// duration controls its spatial selection animation, measured here directly.
List<double> _destinationProgress(WidgetTester tester) => tester
    .widgetList<Transform>(find.descendant(of: find.byType(NavigationIndicator), matching: find.byType(Transform)))
    .map((widget) => widget.transform.entry(0, 0))
    .toList();

Color? _renderedDockTabColor(WidgetTester tester, int index) {
  final decorations = tester
      .widgetList<DecoratedBox>(find.descendant(of: _dockTab(index), matching: find.byType(DecoratedBox)))
      .map((widget) => widget.decoration)
      .whereType<BoxDecoration>()
      .where((decoration) => decoration.borderRadius == BorderRadius.circular(BlizzardRadii.tab))
      .toList();
  expect(decorations, hasLength(1), reason: 'The rendered AnimatedContainer tab decoration must be measurable');
  return decorations.single.color;
}

Future<void> _verifyConnectionMotion(
  WidgetTester tester,
  VisualFixture fixture, {
  required bool blizzard,
  required bool instant,
}) async {
  expect(_instant(_connectionDurations(tester, blizzard: blizzard)), instant);
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
  final immediate = _connectionScale(tester);
  await tester.tap(button);
  await tester.pump();
  expect(fixture.events, ['toggle'], reason: 'Connecting must retain its no-op callback');
  await tester.pump(const Duration(seconds: 1));
  final settled = _connectionScale(tester);
  expect(settled, closeTo(.88, .001));
  if (instant) {
    expect(immediate, settled, reason: 'Reduced-motion scale reaches its final geometry on the first frame');
  } else {
    expect(immediate, isNot(settled), reason: 'Normal animation is a sensitivity control for geometry sampling');
  }
  expect(_instant(_connectionDurations(tester, blizzard: blizzard)), instant);
}

Future<void> _verifyBlizzardDockMotion(
  WidgetTester tester, {
  required bool instant,
  VoidCallback? verifySelection,
}) async {
  expect(find.byType(BlizzardDock), findsOneWidget);
  final dock = find.byKey(const ValueKey('blizzard_bottom_dock'));
  final dockRect = tester.getRect(dock);
  final tabRects = [tester.getRect(_dockTab(0)), tester.getRect(_dockTab(1))];
  expect(dockRect.size, const Size(320, 64));
  expect(tabRects.map((rect) => rect.size), everyElement(const Size(152, 52)));
  expect(_dockTabContainer(tester, 0).duration == Duration.zero, instant);
  expect(_dockTabContainer(tester, 1).duration == Duration.zero, instant);
  final initialColors = [_renderedDockTabColor(tester, 0), _renderedDockTabColor(tester, 1)];
  await tester.tap(_dockTab(1));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  final immediateColors = [_renderedDockTabColor(tester, 0), _renderedDockTabColor(tester, 1)];
  verifySelection?.call();
  await tester.pump(const Duration(seconds: 1));
  final settledColors = [_renderedDockTabColor(tester, 0), _renderedDockTabColor(tester, 1)];
  expect(settledColors, initialColors.reversed.toList(), reason: 'Selection paint must move to the tapped tab');
  expect(tester.getRect(dock), dockRect);
  expect([tester.getRect(_dockTab(0)), tester.getRect(_dockTab(1))], tabRects);
  if (instant) {
    expect(immediateColors, settledColors);
  } else {
    expect(immediateColors, isNot(settledColors));
  }
}

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
    testWidgets('host sampler reads the actual Blizzard hero durations reduced=$reduced', (tester) async {
      final fixture = await mountVisualFixture(
        tester,
        disableAnimations: reduced,
        child: Builder(
          builder: (context) => Theme(
            data: BlizzardTheme.from(Theme.of(context)),
            child: const Center(child: ConnectionButton()),
          ),
        ),
      );
      await _verifyConnectionMotion(tester, fixture, blizzard: true, instant: reduced);
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
    testWidgets('host sampler reads the actual Blizzard dock transition reduced=$reduced', (tester) async {
      final selected = ValueNotifier(0);
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              bottomNavigationBar: ValueListenableBuilder<int>(
                valueListenable: selected,
                builder: (context, value, _) => BlizzardDock(
                  actions: [
                    ShellRouteAction(Icons.home_rounded, 'Home'),
                    ShellRouteAction(Icons.settings_rounded, 'Settings'),
                  ],
                  selectedIndex: value,
                  onDestinationSelected: (index) => selected.value = index,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _verifyBlizzardDockMotion(tester, instant: reduced);
      expect(tester.takeException(), isNull);
    });
  }
  for (final reduced in [false, true]) {
    testWidgets('actual connection and dock motion contract reduced=$reduced', (tester) async {
      final fixture = await mountVisualFixture(tester, disableAnimations: reduced);
      final eligible = expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393);
      final instant = eligible && reduced;
      await _verifyConnectionMotion(tester, fixture, blizzard: eligible, instant: instant);
      if (eligible) {
        await _verifyBlizzardDockMotion(
          tester,
          instant: instant,
          verifySelection: () => expect(find.text('settings'), findsOneWidget),
        );
      } else {
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
      }
      expect(fixture.events, ['toggle']);
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
  }
}
