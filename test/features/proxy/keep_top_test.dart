import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top_widgets.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Map<String, dynamic> _override({Map<String, dynamic>? headers, UserOverride? userOverride}) =>
    jsonDecode(ProfileParser.profileOverride(populatedHeaders: headers, userOverride: userOverride))
        as Map<String, dynamic>;

ProfileEntity _profile({String? header, int? keepTop}) => ProfileEntity.local(
  id: 'id',
  active: true,
  name: 'name',
  lastUpdate: DateTime(2026),
  populatedHeaders: header == null ? null : {'keep-top': header},
  userOverride: UserOverride(keepTop: keepTop),
);

void main() {
  test('counts the proxies the core keeps top of', () {
    final config = jsonEncode({
      'outbounds': [
        {'type': 'vless', 'tag': 'a § 0'},
        {'type': 'trojan', 'tag': 'b § 1'},
        {'type': 'direct', 'tag': 'own direct'},
        {'type': 'socks', 'tag': 'hidden §hide§'},
        {'type': 'selector', 'tag': 'group'},
        {'type': 'urltest', 'tag': 'auto'},
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
        {'type': 'dns', 'tag': 'dns-out'},
      ],
      'endpoints': [
        {'type': 'wireguard', 'tag': 'wg § 2'},
      ],
    });
    expect(countProxies(config), 4);
    expect(countProxies('{}'), 0);
  });

  test('a keep-top header is a count, or -1 for all', () {
    expect(ProfileParser.keepTopHeader('10'), 10);
    expect(ProfileParser.keepTopHeader(' 5 '), 5);
    expect(ProfileParser.keepTopHeader('-1'), -1);
    for (final wrong in [null, '', '0', '-2', 'ten', '1.5']) {
      expect(ProfileParser.keepTopHeader(wrong), isNull, reason: '$wrong');
    }
  });

  test('the core gets the user choice, else the header, else nothing', () {
    expect(_override(headers: {'keep-top': '10'})['keep-top'], 10);
    expect(_override(headers: {'keep-top': '-1'})['keep-top'], -1);
    expect(_override(headers: {'keep-top': 'x'}).containsKey('keep-top'), isFalse);
    expect(_override().containsKey('keep-top'), isFalse);
    expect(_override(headers: {'keep-top': '10'}, userOverride: const UserOverride(keepTop: -1))['keep-top'], -1);
    expect(_override(userOverride: const UserOverride(keepTop: 10))['keep-top'], 10);
  });

  test('the core gets the quick test unless the user turned it off', () {
    expect(_override(userOverride: const UserOverride(keepTop: 10, keepTopQuick: true))['keep-top-quick'], isTrue);
    expect(
      _override(userOverride: const UserOverride(keepTop: 10, keepTopQuick: false)).containsKey('keep-top-quick'),
      isFalse,
    );
    expect(_override(userOverride: const UserOverride(keepTop: 10))['keep-top-quick'], isTrue, reason: 'on by default');
    expect(
      _override(headers: {'keep-top-quick': 'false'})['keep-top-quick'],
      isTrue,
      reason: 'a subscription can not turn it off',
    );
  });

  test("the core gets the countries the user chose, never a subscription's", () {
    expect(
      _override(userOverride: const UserOverride(keepTop: 5, keepTopCountries: ['DE', 'FR']))['keep-top-countries'],
      ['DE', 'FR'],
    );
    expect(_override(userOverride: const UserOverride(keepTop: 5)).containsKey('keep-top-countries'), isFalse);
    expect(_override(headers: {'keep-top-countries': 'DE'}).containsKey('keep-top-countries'), isFalse);
  });

  test('the user is asked only when nobody decided', () {
    expect(_profile().keepTopDecided, isFalse);
    expect(_profile().keepTop, -1);
    expect(_profile(header: '5').keepTopDecided, isTrue);
    expect(_profile(header: '5').keepTop, 5);
    expect(_profile(header: '5', keepTop: -1).keepTop, -1);
    expect(_profile(keepTop: 10).keepTopDecided, isTrue);
    expect(_profile(header: 'x').keepTopDecided, isFalse);
  });

  test('an old user override reads without a choice', () {
    final old = UserOverride.fromStr('{"version":3,"name":"n","adminPreference":"unset"}')!;
    expect(old.keepTop, isNull);
    expect(UserOverride.fromStr(const UserOverride(keepTop: 10).toStr())!.keepTop, 10);
  });

  Future<KeepTopChoice?> answer(
    WidgetTester tester,
    Future<void> Function() act, {
    List<(String, int)> available = const [],
  }) async {
    KeepTopChoice? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => AppLocale.en.buildSync())],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showDialog<KeepTopChoice>(
                context: context,
                builder: (_) => KeepTopDialog(count: 50, keep: 10, available: available),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await act();
    await tester.pumpAndSettle();
    return result;
  }

  // the chevron of the keep button opens the counts
  Future<void> openCounts(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('the dialog keeps the count the user picks', (tester) async {
    final result = await answer(tester, () async {
      await openCounts(tester);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('100'), findsNothing, reason: 'not more than the profile has');
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep the 20 fastest'));
    });
    expect((result?.keep, result?.quick), (20, true));
  });

  testWidgets('the dialog can run them all', (tester) async {
    final result = await answer(tester, () async {
      await openCounts(tester);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use all 50'));
    });
    expect((result?.keep, result?.quick), (-1, true));
  });

  testWidgets('the dialog can keep the ones that answer', (tester) async {
    final result = await answer(tester, () async {
      await openCounts(tester);
      await tester.tap(find.text('Working'));
      // its dots shimmer until the dialog closes
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Keep working ones'));
    });
    expect((result?.keep, result?.quick), (keepTopAnswering, true));
  });

  testWidgets('the dialog keeps the regions the user finds', (tester) async {
    final result = await answer(tester, () async {
      await openCounts(tester);
      await tester.tap(find.text('Region'));
      await tester.pumpAndSettle();
      // the profile's own countries are listed at once, the most proxies first
      expect(find.textContaining('Germany'), findsOneWidget);
      await tester.tap(find.textContaining('Netherlands'));
      await tester.pumpAndSettle();
      // any other country by its name, or "uk"
      final field = find.byType(TextField);
      await tester.enterText(field, 'turk');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Turkey'));
      await tester.pumpAndSettle();
      await tester.enterText(field, 'uk');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('United Kingdom'));
      await tester.pumpAndSettle();
      // ticked again, it is off
      await tester.enterText(field, '');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Netherlands'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Netherlands'));
      await tester.pumpAndSettle();
      // the menus stayed open; closing them, the choice stays
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      if (find.byType(TextField).evaluate().isNotEmpty) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.textContaining('Keep the 10 fastest'));
    }, available: const [('DE', 12), ('FR', 7), ('NL', 4)]);
    expect(result?.countries, unorderedEquals(['TR', 'GB']));
  });

  testWidgets('the dialog hands over to choosing by hand', (tester) async {
    final result = await answer(tester, () async {
      await tester.ensureVisible(find.text('Choose the proxies yourself'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose the proxies yourself'));
    });
    expect(result?.keep, KeepTopDialog.pickByHand);
  });

  testWidgets('the quick test can be turned off', (tester) async {
    final result = await answer(tester, () async {
      await tester.ensureVisible(find.text('Quick test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quick test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep the 10 fastest'));
    });
    expect((result?.keep, result?.quick), (10, false));
  });

  test('speeds read in Mbps: three decimals below 1, one below 10, none above', () {
    String mbps(double megabits) => formatMbps((megabits * 1e6 / 8).round());
    expect(mbps(.04), '0.040');
    expect(mbps(.5), '0.500');
    expect(mbps(.0004), '0.000');
    expect(mbps(3.25), '3.3');
    expect(mbps(42.9), '43');
  });
}
