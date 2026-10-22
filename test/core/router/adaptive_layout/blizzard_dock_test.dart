import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/router/adaptive_layout/blizzard_dock.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';

void main() {
  testWidgets('dock accommodates live text scaling throughout the transition', (tester) async {
    final scale = ValueNotifier<double>(1);
    addTearDown(scale.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: BlizzardTheme.from(ThemeData.dark()),
        home: ValueListenableBuilder<double>(
          valueListenable: scale,
          builder: (context, value, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(value)),
            child: Scaffold(
              bottomNavigationBar: BlizzardDock(
                actions: [
                  ShellRouteAction(Icons.home_rounded, 'Home'),
                  ShellRouteAction(Icons.settings_rounded, 'Settings'),
                ],
                selectedIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    scale.value = 2;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock reports the tapped destination without expanding the scaffold footer', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: BlizzardDock(
            actions: [
              ShellRouteAction(Icons.power_settings_new_rounded, 'Home'),
              ShellRouteAction(Icons.settings_rounded, 'Settings'),
            ],
            selectedIndex: 0,
            onDestinationSelected: selected.add,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(BlizzardDock)).height, BlizzardMetrics.dockHeight + 12);

    await tester.tap(find.byKey(const ValueKey('blizzard_bottom_dock_tab_1')));
    await tester.pump();

    expect(selected, [1]);
  });
}
