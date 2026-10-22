import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/utils.dart';

import '../support/home_fixture.dart';

Widget _applied(Widget child) => Builder(
  builder: (context) => Theme(data: BlizzardTheme.from(Theme.of(context)), child: child),
);

void main() {
  testWidgets('v3 Home matches the plain header, connected status, and latency copy', (tester) async {
    final proxy = _ProxySpy(OutboundInfo(tag: 'fi', tagDisplay: 'Финляндия', type: 'VLESS', urlTestDelay: 84));
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.ru,
      child: _applied(const HomePage()),
      extraOverrides: [activeProxyNotifierProvider.overrideWith(() => proxy)],
    );

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.power_settings_new_rounded)),
      findsNothing,
    );
    expect(find.text('VPN подключён'), findsOneWidget);
    expect(find.text('Подключено'), findsNothing);
    expect(find.text('Задержка 84 мс'), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);

    await tester.tap(find.text('Задержка 84 мс'));
    await tester.pump();
    expect(proxy.urlTests, ['']);
    expect(find.byType(AppVersionLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('v3 active server uses selected metadata and keeps its info action', (tester) async {
    final proxy = _ProxySpy(
      OutboundInfo(
        tag: 'fi',
        tagDisplay: 'Финляндия',
        groupSelectedTagDisplay: 'Вьюга 1G',
        type: 'VLESS',
        urlTestDelay: 84,
        ipinfo: IpInfo(ip: '192.0.2.84', countryCode: 'FI', org: 'Synthetic'),
      ),
    );
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.ru,
      child: Center(child: SizedBox(width: 353, child: _applied(const ActiveProxyFooter()))),
      extraOverrides: [activeProxyNotifierProvider.overrideWith(() => proxy)],
    );

    expect(find.text('Финляндия'), findsOneWidget);
    expect(find.text('Вьюга 1G · VLESS'), findsOneWidget);
    expect(find.textContaining('192.0.2.84'), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);

    final infoAction = find.descendant(
      of: find.byType(ActiveProxyFooter),
      matching: find.byWidgetPredicate((widget) => widget is InkWell && widget.onTap != null),
    );
    expect(infoAction, findsNWidgets(2));
    await tester.tap(infoAction.last);
    await tester.pump();
    expect(proxy.urlTests, ['']);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('v3 active profile is plain, inline, and keeps update and details actions', (tester) async {
    final subInfo = SubscriptionInfo(
      upload: 0,
      download: 0,
      total: 12 * 1099511627776,
      expire: DateTime.now().toUtc().add(const Duration(days: 169, hours: 12)),
    );
    final profile = ProfileEntity.remote(
      id: 'v3-profile',
      active: true,
      name: 'Akonit Premium',
      url: 'https://example.invalid/sub',
      lastUpdate: DateTime.utc(2026),
      subInfo: subInfo,
    );
    final update = TileUpdateSpy();
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.ru,
      child: Center(
        child: SizedBox(width: 353, child: _applied(ProfileTile(profile: profile, isMain: true))),
      ),
      extraOverrides: [updateProfileNotifierProvider('v3-profile').overrideWith(() => update)],
    );

    final card = find.descendant(of: find.byType(ProfileTile), matching: find.byType(Card));
    final title = find.text('Akonit Premium');
    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.getRect(title).left - tester.getRect(card).left, closeTo(16, 0.01));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data?.replaceAll(RegExp('[\u2066\u2069]'), '') == '∞ GiB · осталось 169 дней',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    expect(find.byIcon(Icons.update_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.update_rounded));
    await tester.pump();
    expect(update.calls, ['update:v3-profile']);
    final detailsAction = find.descendant(
      of: find.byType(ProfileTile),
      matching: find.byWidgetPredicate((widget) => widget is InkWell && widget.onTap != null),
    );
    expect(detailsAction, findsNWidgets(2));
    expect(
      tester.getRect(detailsAction.first).contains(tester.getCenter(find.byIcon(Icons.arrow_forward_ios))),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('v3 inline profile isolates traffic LTR and keeps complete semantics in RTL', (tester) async {
    final semantics = tester.ensureSemantics();
    final subInfo = SubscriptionInfo(
      upload: 0,
      download: 0,
      total: 12 * 1099511627776,
      expire: DateTime.now().toUtc().add(const Duration(days: 169, hours: 12)),
    );
    final profile = ProfileEntity.remote(
      id: 'v3-profile-rtl',
      active: true,
      name: 'Akonit Premium',
      url: 'https://example.invalid/sub',
      lastUpdate: DateTime.utc(2026),
      subInfo: subInfo,
    );
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.fa,
      child: Center(
        child: SizedBox(width: 353, child: _applied(ProfileTile(profile: profile, isMain: true))),
      ),
    );

    final inlineText = tester.widget<Text>(
      find.byWidgetPredicate((widget) => widget is Text && widget.data?.contains('∞ GiB') == true),
    );
    expect(inlineText.data, startsWith('\u2066∞ GiB\u2069'));
    final t = AppLocale.fa.buildSync();
    final trafficSemantics = t.components.subscriptionInfo.remainingTrafficSemanticLabel(
      consumed: subInfo.consumption.sizeGB(),
      total: subInfo.total.sizeGB(),
    );
    final remainingSemantics = t.components.subscriptionInfo.remainingDuration(duration: subInfo.remaining.inDays);
    expect(
      find.bySemanticsLabel(RegExp('${RegExp.escape(trafficSemantics)}.*${RegExp.escape(remainingSemantics)}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
    semantics.dispose();
  });
}

class _ProxySpy extends ActiveProxyNotifier {
  _ProxySpy(this.proxy);

  final OutboundInfo proxy;
  final urlTests = <String>[];

  @override
  Stream<OutboundInfo> build() => Stream.value(proxy);

  @override
  Future<void> urlTest(String? groupTag) async {
    urlTests.add(groupTag ?? '');
  }
}
