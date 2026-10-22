import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';

import '../support/home_fixture.dart';

void main() {
  test('v3 metrics keep the approved native material geometry', () {
    expect(BlizzardMetrics.dockWidth, 320);
    expect(BlizzardMetrics.dockHeight, 64);
    expect(BlizzardRadii.dock, 32);
    expect(BlizzardMetrics.dockTabWidth, 152);
    expect(BlizzardMetrics.dockTabHeight, 52);
    expect(BlizzardMetrics.connectionStatusHeight, 98);
    expect(BlizzardMetrics.connectionControlGroupHeight, 210);
    expect(BlizzardMetrics.waveSize, const Size(353, 260));
    expect(BlizzardMetrics.waveDuration, const Duration(seconds: 12));
  });

  testWidgets('v3 Home follows the shared anchors and preserves the real surfaces', (tester) async {
    final fixture = await mountHomeFixture(tester);

    final status = find.byKey(const ValueKey('blizzard_home_status_slot'));
    final wave = find.byKey(const ValueKey('blizzard_home_wave_envelope'));
    final group = find.byKey(const ValueKey('blizzard_home_control_group'));
    final action = find.byKey(const ValueKey('blizzard_home_action_label'));
    final button = find.byKey(const ValueKey('home_connection_button'));
    final dock = find.byKey(const ValueKey('blizzard_bottom_dock'));
    final selectedTab = find.byKey(const ValueKey('blizzard_bottom_dock_tab_0'));
    final settingsTab = find.byKey(const ValueKey('blizzard_bottom_dock_tab_1'));

    expect(tester.getSize(status), const Size(353, 98));
    expect(tester.getSize(wave), BlizzardMetrics.waveSize);
    expect(tester.getSize(group), const Size(353, 210));
    expect(tester.getSize(button), const Size(148, 148));
    expect(tester.getRect(action).top - tester.getRect(button).bottom, closeTo(16, 0.01));
    expect(tester.getRect(wave).top - tester.getRect(status).top, closeTo(76, 0.01));
    expect(tester.getRect(group).top - tester.getRect(status).top, closeTo(116, 0.01));

    expect(tester.getSize(dock), const Size(320, 64));
    expect(tester.getSize(selectedTab), const Size(152, 52));
    expect(tester.getSize(settingsTab), const Size(152, 52));
    expect(tester.widget<Icon>(find.descendant(of: selectedTab, matching: find.byType(Icon))).icon, Icons.home_rounded);

    final footer = tester.getRect(find.byType(ActiveProxyFooter));
    final profile = tester.getRect(find.byType(ProfileTile));
    expect(tester.getRect(group).bottom, lessThan(footer.top));
    expect(footer.bottom, lessThan(profile.top));
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  }, skip: !Platform.isIOS);

  for (final viewport in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets('v3 Home remains reachable at ${viewport.width}x${viewport.height}', (tester) async {
      final fixture = await mountHomeFixture(
        tester,
        width: viewport.width,
        height: viewport.height,
        scale: 1.3,
        disableAnimations: true,
      );
      expect(find.byKey(const ValueKey('home_connection_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('blizzard_home_action_label')), findsOneWidget);
      expect(find.byKey(const ValueKey('blizzard_bottom_dock')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    }, skip: !Platform.isIOS);
  }
  testWidgets('v3 hero expands text slots for large accessibility text', (tester) async {
    final fixture = await mountHomeFixture(tester, width: 320, height: 568, scale: 2, disableAnimations: true);
    expect(tester.getSize(find.byKey(const ValueKey('blizzard_home_status_slot'))).height, greaterThan(98));
    expect(tester.getSize(find.byKey(const ValueKey('blizzard_home_action_label'))).height, greaterThan(22));
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  }, skip: !Platform.isIOS);
}
