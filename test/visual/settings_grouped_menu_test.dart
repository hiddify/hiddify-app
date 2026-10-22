import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/features/settings/overview/settings_page.dart';

import '../support/home_fixture.dart';

class _ResetTunnelSpy extends ResetTunnelNotifier {
  int calls = 0;

  @override
  Future<void> build() async {}

  @override
  Future<void> run() async {
    calls++;
  }
}

void main() {
  testWidgets('Blizzard settings renders the Pencil menu groups and 48px accessible rows', (tester) async {
    final reset = _ResetTunnelSpy();
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.ru,
      child: const BlizzardSettingsMenu(),
      extraOverrides: [resetTunnelNotifierProvider.overrideWith(() => reset)],
    );

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.padding, const EdgeInsets.symmetric(horizontal: 20, vertical: 16));

    final headings = <String>['Приложение', 'Подключение', 'Диагностика'];
    for (final heading in headings) {
      expect(find.text(heading), findsOneWidget);
    }

    final groups = <Key>[
      const ValueKey('settings-group-application'),
      const ValueKey('settings-group-connection'),
      const ValueKey('settings-group-diagnostics'),
    ];
    final groupHeights = <double>[96, 240, 48];
    for (var index = 0; index < groups.length; index++) {
      final key = groups[index];
      final group = find.byKey(key);
      expect(group, findsOneWidget);
      expect(tester.getSize(group), Size(353, groupHeights[index]));
      expect(tester.widget<Material>(group).borderRadius, BorderRadius.circular(18));
    }

    final applicationHeading = tester.widget<Text>(find.text('Приложение'));
    expect(applicationHeading.style?.fontSize, 13);
    expect(applicationHeading.style?.height, 1.3);

    final rows = <String>['Общие', 'О программе', 'Маршрутизация', 'DNS', 'Входящие', 'Трюки TLS', 'WARP', 'Логи'];
    for (final label in rows) {
      final tile = find.ancestor(of: find.text(label), matching: find.byType(ListTile)).first;
      expect(tester.getSize(tile).height, 48, reason: label);
      expect(tester.widget<ListTile>(tile).onTap, isNotNull, reason: label);
    }

    final firstTitle = tester.getRect(find.text('Приложение'));
    final firstGroup = tester.getRect(find.byKey(groups.first));
    expect(firstGroup.top - firstTitle.bottom, closeTo(8, .01));
    final secondTitle = tester.getRect(find.text('Подключение'));
    expect(secondTitle.top - firstGroup.bottom, closeTo(16, .01));

    final resetAction = find.byKey(const ValueKey('settings-reset-tunnel'));
    expect(resetAction, findsOneWidget);
    expect(tester.getSize(resetAction), const Size(353, 48));
    expect(tester.widget<Material>(resetAction).borderRadius, BorderRadius.circular(16));
    final resetTile = tester.widget<ListTile>(find.descendant(of: resetAction, matching: find.byType(ListTile)));
    expect(resetTile.leading, isNull);
    expect(resetTile.contentPadding, const EdgeInsets.symmetric(horizontal: 14));
    final resetText = tester.widget<Text>(find.text('Сбросить профиль VPN'));
    expect(resetText.style?.fontSize, 17);
    expect(resetText.style?.color, const Color(0xFFF7AAAA));
    final diagnosticsGroup = tester.getRect(find.byKey(groups.last));
    expect(tester.getRect(resetAction).top - diagnosticsGroup.bottom, closeTo(16, .01));

    final dividers = groups.fold<int>(
      0,
      (count, key) => count + find.descendant(of: find.byKey(key), matching: find.byType(Divider)).evaluate().length,
    );
    expect(dividers, 5);
    await tester.tap(find.text('Сбросить профиль VPN'));
    await tester.pump();
    expect(reset.calls, 1);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('legacy settings keeps the ungrouped presentation', (tester) async {
    final fixture = await mountHomeFixture(tester, child: SettingsPage());

    expect(find.byKey(const ValueKey('settings-group-application')), findsNothing);
    expect(find.text('Application'), findsNothing);
    expect(find.text('General'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('Blizzard settings rows grow for large text without clipping', (tester) async {
    final fixture = await mountHomeFixture(tester, locale: AppLocale.ru, scale: 2, child: const BlizzardSettingsMenu());

    final generalTile = find.ancestor(of: find.text('Общие'), matching: find.byType(ListTile)).first;
    expect(tester.getSize(generalTile).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });
}
