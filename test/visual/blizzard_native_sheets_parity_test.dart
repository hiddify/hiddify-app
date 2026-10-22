import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/widgets/quick_settings_modal.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/features/profile/add/add_profile_modal.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/overview/profiles_modal.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

import '../support/home_fixture.dart';

Widget _applied(Widget child) => Builder(
  builder: (context) => Theme(data: BlizzardTheme.from(Theme.of(context)), child: child),
);

void main() {
  testWidgets('Add Profile keeps complete wrapping labels and grows for large text at 320pt', (tester) async {
    final fixture = await mountHomeFixture(
      tester,
      width: 320,
      scale: 2,
      locale: AppLocale.ru,
      child: _applied(const AddProfileOptions()),
    );

    for (final label in ['Сканировать QR', 'Буфер обмена', 'Вручную']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, isNull, reason: '$label must remain complete instead of ellipsizing');
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
    expect(tester.getSize(find.byKey(const ValueKey('add_by_qr_code_button'))).height, greaterThan(115));
    expect(find.byIcon(Icons.qr_code_scanner_outlined), findsOneWidget);
    expect(find.byIcon(Icons.content_paste_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('Quick Settings expands rectangular cells and uses the current locale copy', (tester) async {
    final fixture = await mountHomeFixture(tester, locale: AppLocale.fa, child: _applied(const QuickSettingsModal()));

    final translations = AppLocale.fa.buildSync();
    expect(find.text(translations.pages.home.quickSettings), findsOneWidget);
    final segmented = tester.widget<SegmentedButton<ServiceMode>>(find.byType(SegmentedButton<ServiceMode>));
    expect(segmented.expandedInsets, EdgeInsets.zero);
    final shape = segmented.style!.shape!.resolve(<WidgetState>{})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.zero);
    expect(tester.getSize(find.byType(SegmentedButton<ServiceMode>)).width, 361);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('Profiles sheet uses the inset 96pt tile, vertical menu and inline quota', (tester) async {
    final profile = ProfileEntity.remote(
      id: 'sheet-profile',
      active: true,
      name: 'Akonit Premium',
      url: 'https://example.invalid/sub',
      lastUpdate: DateTime.utc(2026),
      subInfo: SubscriptionInfo(
        upload: 0,
        download: 0,
        total: 12 * 1099511627776,
        expire: DateTime.now().toUtc().add(const Duration(days: 169, hours: 12)),
      ),
    );
    final profiles = TileProfilesSpy()..profiles = [profile];
    final fixture = await mountHomeFixture(
      tester,
      locale: AppLocale.ru,
      child: _applied(const ProfilesModal()),
      extraOverrides: [profilesNotifierProvider.overrideWith(() => profiles)],
    );

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.padding, const EdgeInsets.fromLTRB(32, 8, 32, 18));
    final card = find.descendant(of: find.byType(ProfilesModal), matching: find.byType(Card));
    expect(tester.getSize(card).height, 96);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data?.replaceAll(RegExp('[\u2066\u2069]'), '') == '∞ GiB · осталось 169 дней',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('Profile sheet padding stays 8pt without changing multiline Home geometry', (tester) async {
    final profile = ProfileEntity.local(
      id: 'multiline-profile',
      active: true,
      name: 'A deliberately long active profile name that wraps onto two lines',
      lastUpdate: DateTime.utc(2026),
    );
    final homeFixture = await mountHomeFixture(
      tester,
      width: 180,
      scale: 2,
      child: Center(
        child: SizedBox(width: 180, child: _applied(ProfileTile(profile: profile, isMain: true))),
      ),
    );

    Finder contentPadding() => find.descendant(
      of: find.byType(ProfileTile),
      matching: find.byWidgetPredicate((widget) => widget is Padding && widget.child is Column),
    );
    final homePadding = tester.widget<Padding>(contentPadding());
    final homeCard = find.descendant(of: find.byType(ProfileTile), matching: find.byType(Card));
    final homeTitle = find.text(profile.name);
    expect(homePadding.padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 4));
    expect(tester.getSize(homeTitle).height, greaterThan(48), reason: 'fixture must exercise multiline large text');
    expect(
      tester.getSize(homeCard).height,
      closeTo(tester.getSize(homeTitle).height + 8, 0.01),
      reason: 'Home intrinsic height must retain its original 4pt top and bottom inset',
    );
    expect(tester.takeException(), isNull);
    await homeFixture.close(tester);

    final sheetFixture = await mountHomeFixture(
      tester,
      width: 180,
      scale: 2,
      child: Center(
        child: SizedBox(width: 180, child: _applied(ProfileTile(profile: profile))),
      ),
    );
    final sheetPadding = tester.widget<Padding>(contentPadding());
    expect(sheetPadding.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
    expect(tester.takeException(), isNull);
    await sheetFixture.close(tester);
  });
}
