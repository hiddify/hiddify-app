import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/adaptive_layout/my_adaptive_layout.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// The desktop sidebar must reach screen readers (#2097). Every page route
// builds a modal barrier with BlockSemantics, which drops everything painted
// before it up to the nearest semantics container: without one around the
// branch pages, the whole navigation rail vanished from the semantics tree.
void main() {
  Future<void> pumpShell(WidgetTester tester, {required Size size, required bool mobile}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    StatefulShellBranch branch(String path) => StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(
            body: Center(
              child: ElevatedButton(onPressed: () {}, child: Text('page $path')),
            ),
          ),
          routes: [
            GoRoute(
              path: 'sub',
              builder: (_, _) => const Scaffold(body: Text('sub page')),
            ),
          ],
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) =>
              MyAdaptiveLayout(navigationShell: shell, isMobileBreakpoint: mobile, showProfilesAction: false),
          branches: [
            branch('/home'),
            branch('/settings'),
            if (!mobile) ...[branch('/logs'), branch('/about')],
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(overrides: [translationsProvider.overrideWith((ref) => AppLocale.en.build())]);
    addTearDown(container.dispose);
    await container.read(translationsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The semantics node of a navigation destination: the one whose label holds
  // the page title, and which can be tapped.
  SemanticsFinder destination(String title) => find.semantics.byPredicate(
    (node) => node.label.contains(title) && node.getSemanticsData().hasAction(SemanticsAction.tap),
    describeMatch: (_) => 'destination "$title"',
  );

  testWidgets('sidebar destinations are in the semantics tree', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, size: const Size(700, 800), mobile: false);

    for (final title in ['Home', 'Settings', 'Logs', 'About']) {
      expect(destination(title), findsOne, reason: '$title is missing from the semantics tree');
    }
    final selected = destination('Home').evaluate().single;
    expect(selected.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
    // the page content stays reachable too
    expect(find.semantics.byLabel('page /home'), findsOne);
    handle.dispose();
  });

  testWidgets('sidebar stays in the semantics tree on a sub-page', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, size: const Size(700, 800), mobile: false);
    GoRouter.of(tester.element(find.text('page /home'))).go('/settings/sub');
    await tester.pumpAndSettle();

    expect(destination('Settings'), findsOne);
    expect(destination('Settings').evaluate().single.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
    expect(find.semantics.byLabel('sub page'), findsOne);
    handle.dispose();
  });

  testWidgets('bottom navigation bar destinations are in the semantics tree', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, size: const Size(400, 800), mobile: true);

    for (final title in ['Home', 'Settings']) {
      expect(destination(title), findsOne);
    }
    handle.dispose();
  });
}
