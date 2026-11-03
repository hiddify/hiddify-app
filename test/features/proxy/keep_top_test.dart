import 'dart:convert';

import 'package:flutter/material.dart';
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

  Future<int?> answer(WidgetTester tester, Future<void> Function() act) async {
    int? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => AppLocale.en.buildSync())],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showDialog<int>(
                context: context,
                builder: (_) => const KeepTopDialog(count: 50, keep: 10),
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

  testWidgets('the dialog keeps the count the user picks', (tester) async {
    final result = await answer(tester, () async {
      expect(find.text('30'), findsOneWidget);
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep the 20 fastest'));
    });
    expect(result, 20);
  });

  testWidgets('the dialog can run them all', (tester) async {
    expect(await answer(tester, () => tester.tap(find.text('Use all 50'))), -1);
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
