import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/adaptive_menu.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('menu near the bottom stays above the navigation bar', (tester) async {
    const navBar = 48.0;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: navBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBar);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 470,
                  right: 0,
                  // the list strips the bottom inset from the anchor's MediaQuery, like the profiles sheet does
                  child: Builder(
                    builder: (context) => MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: AdaptiveMenu(
                        items: [
                          for (final name in ['Pin', 'Update', 'Share', 'Edit', 'Delete'])
                            AdaptiveMenuItem(title: name, onTap: () {}),
                        ],
                        builder: (context, toggle, child) =>
                            IconButton(onPressed: toggle, icon: const Icon(Icons.more_vert)),
                        child: null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(MenuItemButton).last).bottom, lessThanOrEqualTo(800 - navBar));
  });

  testWidgets('menu in a page above a bottom bar opens upward when it does not fit below', (tester) async {
    const navBar = 48.0;
    const bottomBar = 80.0;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: navBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBar);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            // its own Navigator, and so its own Overlay, ends above the bottom bar, like a StatefulShellRoute branch
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Stack(
                  children: [
                    Positioned(
                      top: 480,
                      left: 0,
                      child: AdaptiveMenu(
                        items: [
                          for (final name in ['Round robin', 'Consistent hash', 'Sticky sessions'])
                            AdaptiveMenuItem(title: name, onTap: () {}),
                        ],
                        builder: (context, toggle, child) =>
                            IconButton(onPressed: toggle, icon: const Icon(Icons.arrow_drop_down)),
                        child: null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: const SizedBox(height: bottomBar + navBar),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    final pageBottom = tester.getRect(find.byType(Navigator).last).bottom;
    expect(pageBottom, 800 - bottomBar - navBar);
    expect(tester.getRect(find.byType(MenuItemButton).last).bottom, lessThanOrEqualTo(pageBottom));
    expect(
      tester.getRect(find.byType(MenuItemButton).last).bottom,
      lessThanOrEqualTo(tester.getRect(find.byIcon(Icons.arrow_drop_down)).top),
    );
  });
}
