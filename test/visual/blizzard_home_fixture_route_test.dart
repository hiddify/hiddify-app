import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/router/adaptive_layout/blizzard_dock.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';

import '../support/home_fixture.dart';

void main() {
  testWidgets('proxy navigation stays in the Home shell and back returns Home', (tester) async {
    final fixture = await mountHomeFixture(tester, proxiesChild: const Scaffold(body: Text('fixture proxies')));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(ActiveProxyFooter), findsOneWidget);
    _expectProductionNavigationChrome();

    await tester.tap(find.byType(ActiveProxyFooter));
    await tester.pumpAndSettle();

    expect(find.text('fixture proxies'), findsOneWidget);
    expect(fixture.router.canPop(), isTrue);
    _expectProductionNavigationChrome();

    fixture.router.pop();
    await tester.pumpAndSettle();

    expect(find.text('fixture proxies'), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(ActiveProxyFooter), findsOneWidget);
    _expectProductionNavigationChrome();

    await fixture.close(tester);
  });
}

void _expectProductionNavigationChrome() {
  final blizzardDock = find.byType(BlizzardDock).evaluate().length;
  final legacyNavigationBar = find.byType(NavigationBar).evaluate().length;
  expect(
    blizzardDock + legacyNavigationBar,
    1,
    reason: 'The proxy page must remain inside the real adaptive shell; eligible iOS renders BlizzardDock.',
  );
}
