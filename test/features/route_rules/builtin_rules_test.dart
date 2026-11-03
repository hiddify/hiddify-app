import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/overview/sections/routing_options_page.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The rules file lives in [dir], as in the app's base directory.
class _Directories extends AppDirectories {
  _Directories(this.dir);

  final Directory dir;

  @override
  Future<Directories> build() async => (baseDir: dir, workingDir: dir, tempDir: dir);
}

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('builtin_rules_test');
    file = File('${dir.path}/route_rule.proto');
  });
  tearDown(() async {
    // a save the page started may still hold the file open
    for (var attempt = 0; ; attempt++) {
      try {
        return dir.deleteSync(recursive: true);
      } on FileSystemException {
        if (attempt == 50) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
  });

  /// The app's providers with [region] saved. The rules stay alive, as the config options keep them in the app.
  Future<ProviderContainer> open({Region region = Region.ir}) async {
    SharedPreferences.setMockInitialValues({'region': region.name});
    final container = ProviderContainer(
      overrides: [
        appDirectoriesProvider.overrideWith(() => _Directories(dir)),
        translationsProvider.overrideWith((ref) => AppLocale.en.build()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appDirectoriesProvider.future);
    await container.read(sharedPreferencesProvider.future);
    await container.read(translationsProvider.future);
    container.listen(rulesNotifierProvider, (_, _) {});
    return container;
  }

  void save(List<Rule> rules) {
    for (final (index, rule) in rules.indexed) {
      rule.listOrder = index;
    }
    file.writeAsBytesSync(RouteRule(rules: rules).writeToBuffer());
  }

  Rule custom(String name, {bool enabled = true}) =>
      Rule(name: name, enabled: enabled, outbound: Outbound.proxy, domains: ['$name.example']);

  Rule builtin(BuiltinRule builtin, {required bool enabled}) => builtin.rule..enabled = enabled;

  /// Each rule as its name and switch, such as "builtin:bypassLan on".
  List<String> describe(List<Rule> rules) => [for (final rule in rules) '${rule.name} ${rule.enabled ? 'on' : 'off'}'];

  List<String> current(ProviderContainer container) {
    final rules = container.read(rulesNotifierProvider);
    expect([for (final rule in rules) rule.listOrder], List.generate(rules.length, (index) => index));
    return describe(rules);
  }

  void expectSaved(ProviderContainer container) =>
      expect(file.readAsBytesSync(), RouteRule(rules: container.read(rulesNotifierProvider)).writeToBuffer());

  /// The notifier saves the list after a region change without being awaited, so this waits for that save.
  Future<void> changeRegion(ProviderContainer container, Region region) async {
    if (file.existsSync()) file.setLastModifiedSync(DateTime(2000));
    await container.read(ConfigOptions.region.notifier).update(region);
    final expected = RouteRule(rules: container.read(rulesNotifierProvider)).writeToBuffer();
    for (var i = 0; i < 200; i++) {
      if (file.existsSync() && file.lastModifiedSync().year > 2000 && listEquals(file.readAsBytesSync(), expected)) {
        // the content is in; give the write time to close the file
        return Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('the list was not saved after the region change');
  }

  const defaults = [
    'builtin:bypassLan on',
    'builtin:systemDirect off',
    'builtin:blockAds off',
    'builtin:bypassRegion on',
  ];

  group('a new list', () {
    test('holds the built-in rules in their default order and state', () async {
      final container = await open();
      expect(current(container), defaults);
      expect(file.existsSync(), isFalse);
    });

    test('leaves the region rule out while the region is Other', () async {
      final container = await open(region: Region.other);
      expect(current(container), ['builtin:bypassLan on', 'builtin:systemDirect off', 'builtin:blockAds off']);
    });
  });

  group('a saved list', () {
    test('keeps its order and switches', () async {
      save([
        custom('a'),
        builtin(BuiltinRule.bypassRegion, enabled: false),
        builtin(BuiltinRule.bypassLan, enabled: false),
        custom('b', enabled: false),
        builtin(BuiltinRule.systemDirect, enabled: false),
        builtin(BuiltinRule.blockAds, enabled: true),
      ]);
      final container = await open();
      expect(current(container), [
        'a on',
        'builtin:bypassRegion off',
        'builtin:bypassLan off',
        'b off',
        'builtin:systemDirect off',
        'builtin:blockAds on',
      ]);
    });

    test("takes each built-in rule's content from the app", () async {
      save([
        Rule(name: 'builtin:bypassLan', enabled: true, outbound: Outbound.proxy, ipCidrs: ['1.2.3.4/32']),
        // saved under the name the rule had when it only held Apple's services
        Rule(name: 'builtin:appleDirect', outbound: Outbound.block, domainSuffixes: ['example.com']),
        Rule(name: 'builtin:blockAds', enabled: true, outbound: Outbound.direct, domains: ['example.com']),
        Rule(name: 'builtin:bypassRegion', outbound: Outbound.block, ruleSets: ['https://example.com/x.srs']),
      ]);
      final container = await open();
      for (final rule in container.read(rulesNotifierProvider)) {
        final expected = BuiltinRule.of(rule)!.rule
          ..enabled = rule.enabled
          ..listOrder = rule.listOrder;
        expect(rule, expected, reason: rule.name);
      }
      expect(current(container), [
        'builtin:bypassLan on',
        'builtin:systemDirect off',
        'builtin:blockAds on',
        'builtin:bypassRegion off',
      ]);
    });

    test('gets the built-in rules it lacks first, in their default state', () async {
      save([custom('a'), builtin(BuiltinRule.blockAds, enabled: true)]);
      final container = await open();
      expect(current(container), [
        'builtin:bypassLan on',
        'builtin:systemDirect off',
        'builtin:bypassRegion on',
        'a on',
        'builtin:blockAds on',
      ]);
    });

    test('keeps a built-in rule saved twice once, at its first place', () async {
      save([
        builtin(BuiltinRule.blockAds, enabled: true),
        custom('a'),
        builtin(BuiltinRule.blockAds, enabled: false),
        builtin(BuiltinRule.bypassLan, enabled: true),
        builtin(BuiltinRule.bypassRegion, enabled: true),
        builtin(BuiltinRule.systemDirect, enabled: true),
      ]);
      final container = await open();
      expect(current(container), [
        'builtin:blockAds on',
        'a on',
        'builtin:bypassLan on',
        'builtin:bypassRegion on',
        'builtin:systemDirect on',
      ]);
    });

    test('drops the region rule while the region is Other', () async {
      save([
        custom('a'),
        builtin(BuiltinRule.bypassRegion, enabled: true),
        builtin(BuiltinRule.bypassLan, enabled: true),
        builtin(BuiltinRule.blockAds, enabled: false),
        builtin(BuiltinRule.systemDirect, enabled: true),
      ]);
      final container = await open(region: Region.other);
      expect(current(container), ['a on', 'builtin:bypassLan on', 'builtin:blockAds off', 'builtin:systemDirect on']);
    });
  });

  group('a region change', () {
    Future<ProviderContainer> openSaved() {
      save([
        custom('a'),
        builtin(BuiltinRule.bypassRegion, enabled: false),
        builtin(BuiltinRule.bypassLan, enabled: true),
        builtin(BuiltinRule.blockAds, enabled: false),
        builtin(BuiltinRule.systemDirect, enabled: true),
      ]);
      return open();
    }

    test('to Other takes the region rule out, and back puts it first, turned on', () async {
      final container = await openSaved();

      await changeRegion(container, Region.other);
      expect(current(container), ['a on', 'builtin:bypassLan on', 'builtin:blockAds off', 'builtin:systemDirect on']);

      await changeRegion(container, Region.cn);
      expect(current(container), [
        'builtin:bypassRegion on',
        'a on',
        'builtin:bypassLan on',
        'builtin:blockAds off',
        'builtin:systemDirect on',
      ]);
    });

    test("between regions keeps the region rule's place and switch", () async {
      final container = await openSaved();
      await changeRegion(container, Region.cn);
      expect(current(container), [
        'a on',
        'builtin:bypassRegion off',
        'builtin:bypassLan on',
        'builtin:blockAds off',
        'builtin:systemDirect on',
      ]);
    });

    test('on a list never saved keeps the default order', () async {
      final container = await open(region: Region.other);
      await changeRegion(container, Region.ir);
      expect(current(container), defaults);
    });
  });

  group('the user', () {
    test('adds a new rule first, turned on', () async {
      final container = await open();
      await container
          .read(rulesNotifierProvider.notifier)
          .addRule(Rule(name: 'new', outbound: Outbound.direct, domains: ['new.example']));
      expect(current(container), ['new on', ...defaults]);
      expectSaved(container);
    });

    test("switches and moves a built-in rule, and the list keeps it", () async {
      final container = await open();
      final notifier = container.read(rulesNotifierProvider.notifier);
      await notifier.updateEnabled(true, 2);
      await notifier.reorder(2, 0);
      final expected = [
        'builtin:blockAds on',
        'builtin:bypassLan on',
        'builtin:systemDirect off',
        'builtin:bypassRegion on',
      ];
      expect(current(container), expected);

      expect(current(await open()), expected);
    });

    test('resets to the default list', () async {
      save([
        custom('a'),
        builtin(BuiltinRule.blockAds, enabled: true),
        builtin(BuiltinRule.bypassRegion, enabled: false),
        builtin(BuiltinRule.bypassLan, enabled: false),
      ]);
      final container = await open();
      await container.read(rulesNotifierProvider.notifier).resetRules();
      expect(current(container), defaults);

      expect(current(await open()), defaults);
    });

    test('imports a list, which gets the built-in rules with their app content', () async {
      final container = await open();
      final imported = RouteRule(
        rules: [
          custom('a'),
          Rule(
            name: 'builtin:blockAds',
            enabled: true,
            outbound: Outbound.proxy,
            ruleSets: ['https://example.com/x.srs'],
          ),
        ],
      );
      await container
          .read(rulesNotifierProvider.notifier)
          .importRules(base64.encode(utf8.encode(jsonEncode(imported.writeToJson()))));
      expect(current(container), [
        'builtin:bypassLan on',
        'builtin:systemDirect off',
        'builtin:bypassRegion on',
        'a on',
        'builtin:blockAds on',
      ]);
      final blockAds = container.read(rulesNotifierProvider).last;
      expect(blockAds.outbound, Outbound.block);
      expect(blockAds.ruleSets, BuiltinRule.blockAds.rule.ruleSets);
      expectSaved(container);
    });
  });

  test('the core gets each built-in rule in the shape it reads', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = await open();
    final json = RouteRule(rules: container.read(rulesNotifierProvider)).toProto3Json()! as Map<String, dynamic>;
    const geo = 'https://raw.githubusercontent.com/hiddify/hiddify-geo/rule-set';
    expect(json, {
      'rules': [
        {
          'list_order': 0,
          'enabled': true,
          'name': 'builtin:bypassLan',
          'outbound': 'direct',
          'ip_cidr': [
            '10.0.0.0/8',
            '172.16.0.0/12',
            '192.168.0.0/16',
            '127.0.0.0/8',
            '169.254.0.0/16',
            '224.0.0.0/4',
            '0.0.0.0/32',
            'fc00::/7',
            'fe80::/10',
            '::1/128',
            'ff00::/8',
            '::/128',
          ],
        },
        {
          'list_order': 1,
          'enabled': false,
          'name': 'builtin:systemDirect',
          'outbound': 'direct',
          'rule_set': ['https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-apple.srs'],
          'domain_suffix': [
            'apple.com',
            'icloud.com',
            'icloud-content.com',
            'apple-dns.net',
            'cdn-apple.com',
            'mzstatic.com',
            'aaplimg.com',
            'itunes.com',
            'apple-cloudkit.com',
            'apple-mapkit.com',
            'testflight.apple.com',
          ],
        },
        {
          'list_order': 2,
          'enabled': false,
          'name': 'builtin:blockAds',
          'outbound': 'block',
          'rule_set': [
            '$geo/block/geosite-category-ads-all.srs',
            '$geo/block/geosite-malware.srs',
            '$geo/block/geosite-phishing.srs',
            '$geo/block/geosite-cryptominers.srs',
            '$geo/block/geoip-malware.srs',
            '$geo/block/geoip-phishing.srs',
          ],
        },
        {
          'list_order': 3,
          'enabled': true,
          'name': 'builtin:bypassRegion',
          'outbound': 'direct',
          'rule_set': ['$geo/country/geosite-{region}.srs', '$geo/country/geoip-{region}.srs'],
        },
      ],
    });
  });

  test("the system's services rule follows the platform", () async {
    final t = await AppLocale.en.build();
    const geosite = 'https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set';
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final expected = {
      TargetPlatform.iOS: ('Apple services', ['$geosite/geosite-apple.srs']),
      TargetPlatform.macOS: ('Apple services', ['$geosite/geosite-apple.srs']),
      TargetPlatform.windows: ('Microsoft services', ['$geosite/geosite-microsoft.srs']),
      TargetPlatform.android: ('Android services', ['$geosite/geosite-android.srs', '$geosite/geosite-googlefcm.srs']),
      TargetPlatform.linux: (
        'Linux updates',
        [
          '$geosite/geosite-ubuntu.srs',
          '$geosite/geosite-debian.srs',
          '$geosite/geosite-fedora.srs',
          '$geosite/geosite-archlinux.srs',
        ],
      ),
    };
    for (final MapEntry(key: platform, value: (name, ruleSets)) in expected.entries) {
      debugDefaultTargetPlatformOverride = platform;
      final rule = BuiltinRule.systemDirect.rule;
      expect(BuiltinRule.systemDirect.present(t, Region.ir), name, reason: platform.name);
      expect(rule.name, 'builtin:systemDirect', reason: platform.name);
      expect(rule.outbound, Outbound.direct, reason: platform.name);
      expect(rule.ruleSets, ruleSets, reason: platform.name);
      expect(rule.domainSuffixes, isNotEmpty, reason: platform.name);
    }
  });

  group('the routing page', () {
    Future<ProviderContainer> show(WidgetTester tester) async {
      // tall enough for every rule, so none is left unbuilt below the fold
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = (await tester.runAsync(open))!;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const RoutingOptionsPage(routeRule: null),
            routes: [
              GoRoute(
                path: 'rule/:orderId',
                name: 'rule',
                builder: (context, state) => Text('rule page ${state.pathParameters['orderId']}'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    final lock = find.byIcon(Icons.lock_outline_rounded);

    testWidgets('marks each built-in rule and names the region rule after the region', (tester) async {
      await show(tester);
      expect(lock, findsNWidgets(4));
      expect(find.text('Bypass LAN'), findsOneWidget);
      expect(find.text('Android services'), findsOneWidget);
      expect(find.text('Ads and malware'), findsOneWidget);
      expect(find.text('Sites in Iran'), findsOneWidget);
    });

    testWidgets('opens a built-in rule on a tap, to be read', (tester) async {
      await show(tester);
      await tester.tap(find.text('Ads and malware'));
      await tester.pumpAndSettle();
      expect(find.text('rule page 2'), findsOneWidget);
    });

    testWidgets('offers to duplicate a built-in rule on a long press, not to delete it', (tester) async {
      await show(tester);
      await tester.longPress(find.text('Bypass LAN'));
      await tester.pumpAndSettle();
      expect(find.text('Duplicate rule'), findsOneWidget);
      expect(find.text('Delete rule'), findsNothing);
    });

    testWidgets("switches a built-in rule from its row's switch", (tester) async {
      final container = await show(tester);
      final row = find.ancestor(of: find.text('Sites in Iran'), matching: find.byType(ListTile));
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(container.read(rulesNotifierProvider).last.enabled, isFalse);
    });

    testWidgets('follows the region chip: Other hides the region rule, another region brings it back', (tester) async {
      await show(tester);

      await tester.tap(find.text('Region'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sites in'), findsNothing);
      expect(lock, findsNWidgets(3));

      await tester.tap(find.text('Region'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('China').last);
      await tester.pumpAndSettle();
      expect(find.text('Sites in China'), findsOneWidget);
      expect(lock, findsNWidgets(4));
    });
  });
}
