import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../support/home_fixture.dart';
import '../support/surface_fixtures.dart';

Widget _applied(Widget child) => Builder(
  builder: (context) => Theme(data: BlizzardTheme.from(Theme.of(context)), child: child),
);

OutboundInfo _server({
  required String tag,
  required String country,
  required String selectedServer,
  required int delay,
}) => OutboundInfo(
  tag: tag,
  tagDisplay: country,
  groupSelectedTagDisplay: selectedServer,
  type: 'VLESS',
  urlTestDelay: delay,
  ipinfo: IpInfo(countryCode: tag.toUpperCase()),
);

void main() {
  testWidgets('server page presents profile count, grouped rows, ISO badges, and actual subtitles', (tester) async {
    final group = OutboundGroup(
      tag: 'select',
      selected: 'fi',
      items: [
        _server(tag: 'fi', country: 'Финляндия', selectedServer: 'Вьюга 1G', delay: 84),
        _server(tag: 'de', country: 'Германия', selectedServer: 'Хёллентэлер', delay: 85),
        ...List.generate(
          8,
          (index) => _server(
            tag: 's${index + 3}',
            country: 'Страна ${index + 3}',
            selectedServer: 'Сервер ${index + 3}',
            delay: 86 + index,
          ),
        ),
      ],
    );
    final profile = ProfileEntity.local(
      id: 'akonit',
      active: true,
      name: 'Akonit Premium',
      lastUpdate: DateTime.utc(2026),
    );
    final proxies = _ServerProxies(AsyncData(group));
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.ru,
      profile: profile,
      child: _applied(const ProxiesOverviewPage()),
      extraOverrides: [proxiesOverviewNotifierProvider.overrideWith(() => proxies)],
    );

    expect(find.text('Серверы'), findsOneWidget);
    expect(find.text('Akonit Premium · 10 серверов'), findsOneWidget);
    expect(find.byKey(const ValueKey('servers_back_button')), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.widget<Scaffold>(find.byType(Scaffold).last).floatingActionButton, isNull);

    final first = find.byWidgetPredicate((widget) => widget is ProxyTile && widget.proxy.tag == 'fi');
    final second = find.byWidgetPredicate((widget) => widget is ProxyTile && widget.proxy.tag == 'de');
    expect(find.descendant(of: first, matching: find.text('FI')), findsOneWidget);
    expect(find.descendant(of: first, matching: find.text('Вьюга 1G · VLESS')), findsOneWidget);
    expect(find.descendant(of: second, matching: find.text('Хёллентэлер · VLESS')), findsOneWidget);
    expect(tester.getRect(second).top, closeTo(tester.getRect(first).bottom, 0.01));
    final delayButton = find.byKey(const ValueKey('servers_test_delay_button'));
    final gridScrollable = find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(delayButton, 80, scrollable: gridScrollable);
    await tester.drag(gridScrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getSize(delayButton).width, closeTo(353, 0.01));
    expect(delayButton.hitTestable(), findsOneWidget);
    await tester.tap(delayButton);
    await tester.pump();
    expect(proxies.delayTests, ['select']);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('server page remains overflow-free at 320 points and large text', (tester) async {
    final group = OutboundGroup(
      tag: 'select',
      selected: 'fi',
      items: [
        _server(
          tag: 'fi',
          country: 'Очень длинное название страны',
          selectedServer: 'Очень длинное фактическое название сервера',
          delay: 84,
        ),
      ],
    );
    final fixture = await mountHomeFixture(
      tester,
      width: 320,
      scale: 1.3,
      locale: AppLocale.ru,
      child: _applied(const ProxiesOverviewPage()),
      extraOverrides: [proxiesOverviewNotifierProvider.overrideWith(() => SurfaceProxies(AsyncData(group)))],
    );

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Очень длинное название страны'), findsOneWidget);
    expect(find.text('Очень длинное фактическое название сервера · VLESS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('Home server card uses a 40 point ISO badge and actual selected server subtitle', (tester) async {
    final semantics = tester.ensureSemantics();
    final proxy = OutboundInfo(
      tag: 'fi',
      tagDisplay: 'Финляндия',
      groupSelectedTagDisplay: 'Вьюга 1G',
      type: 'VLESS',
      urlTestDelay: 84,
      ipinfo: IpInfo(countryCode: 'fi', org: 'Synthetic'),
    );
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.ru,
      child: _applied(const Center(child: SizedBox(width: 353, child: ActiveProxyFooter()))),
      extraOverrides: [activeProxyNotifierProvider.overrideWith(() => _ActiveProxyFixture(proxy))],
    );

    final badge = find.byKey(const ValueKey('country_iso_badge'));
    expect(badge, findsOneWidget);
    expect(tester.getSize(badge), const Size.square(40));
    expect(find.text('FI'), findsOneWidget);
    expect(find.text('Вьюга 1G · VLESS'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('FI')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await fixture.close(tester);
  });
}

class _ActiveProxyFixture extends ActiveProxyNotifier {
  _ActiveProxyFixture(this.proxy);

  final OutboundInfo proxy;

  @override
  Stream<OutboundInfo> build() => Stream.value(proxy);
}

class _ServerProxies extends SurfaceProxies {
  _ServerProxies(super.initial);

  final delayTests = <String>[];

  @override
  Future<void> urlTest(String groupTag) async {
    delayTests.add(groupTag);
  }
}
