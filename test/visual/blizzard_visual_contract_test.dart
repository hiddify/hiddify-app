import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import '../support/blizzard_visual_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerBlizzardVisualContracts();
}

void registerBlizzardVisualContracts() {
  for (final mode in AppThemeMode.values) {
    for (final brightness in Brightness.values) {
      for (final width in [393.0, 599.0, 600.0, 840.0]) {
        testWidgets('visual scope ${mode.name}/${brightness.name}/$width', (tester) async {
          final fixture = await mountVisualFixture(tester, mode: mode, systemBrightness: brightness, width: width);
          final enabled = expectsBlizzard(mode, brightness, width);
          final theme = fixture.innerTheme!;
          if (enabled) {
            expect(theme.scaffoldBackgroundColor, const Color(0xFF06121D));
            expect(theme.colorScheme.primary, const Color(0xFF72D1FF));
            expect(theme.colorScheme.onSurface, const Color(0xFFEFF7FD));
            expect(theme.colorScheme.surface, const Color(0xFF102235));
            expect(theme.textTheme.bodyLarge!.fontSize, 17);
          } else {
            final legacy = AppTheme(mode, 'BlizzardFixture');
            final expected = theme.brightness == Brightness.dark ? legacy.darkTheme(null) : legacy.lightTheme(null);
            expect(theme.colorScheme, expected.colorScheme);
            expect(theme.scaffoldBackgroundColor, expected.scaffoldBackgroundColor);
          }
          // Global factory stays legacy; presentation scopes only the eligible child.
          expect(AppTheme(mode, 'BlizzardFixture').darkTheme(null).colorScheme.primary, isNot(const Color(0xFF72D1FF)));
          expect(fixture.events, isEmpty, reason: 'Appearance rebuild must not issue a VPN command');
          expect(tester.takeException(), isNull);
          await fixture.close(tester);
        });
      }
    }
  }
  for (final mode in [AppThemeMode.dark, AppThemeMode.light, AppThemeMode.black]) {
    testWidgets('dock preserves Scaffold safe-area removal for ${mode.name}', (tester) async {
      tester.view.padding = FakeViewPadding(
        top: 62 * tester.view.devicePixelRatio,
        bottom: 34 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetPadding);
      final fixture = await mountVisualFixture(tester, mode: mode);
      final eligible = expectsBlizzard(mode, Brightness.dark, 393);
      final navFinder = find.byType(NavigationBar);
      if (eligible) {
        final dock = find.byKey(const ValueKey('blizzard_bottom_dock'));
        expect(tester.getSize(dock), const Size(320, 64));
        expect(MediaQuery.paddingOf(tester.element(dock)).top, 0);
      } else {
        expect(tester.getSize(navFinder).height, 114);
        final navContext = tester.element(navFinder);
        expect(MediaQuery.paddingOf(navContext).top, 0);
        expect(MediaQuery.paddingOf(navContext).bottom, 34);
      }
      expect(fixture.events, isEmpty);
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
  }
  testWidgets('Blizzard connection geometry and floating dock retain actual actions', (tester) async {
    final fixture = await mountVisualFixture(tester);
    final material = tester.widget<Material>(find.byKey(const ValueKey('home_connection_button')));
    if (expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393)) {
      expect(material.shape, isA<RoundedRectangleBorder>());
      expect((material.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(44));
      expect(tester.getSize(find.byKey(const ValueKey('blizzard_bottom_dock'))), const Size(320, 64));
      expect(fixture.innerTheme!.colorScheme.primary, const Color(0xFF72D1FF));
    } else {
      expect(material.shape, isA<CircleBorder>());
      expect(tester.getSize(find.byKey(const ValueKey('home_connection_button'))), const Size(148, 148));
    }
    await tester.tap(find.byKey(const ValueKey('home_connection_button')));
    await tester.pump();
    expect(fixture.events, ['toggle']);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });
}
