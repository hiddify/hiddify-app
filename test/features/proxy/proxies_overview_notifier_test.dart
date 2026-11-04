import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The core's side: the test sends each proxy list the core would stream.
class _Repository implements ProxyRepository {
  final updates = StreamController<Either<ProxyFailure, OutboundGroup?>>.broadcast();
  bool selectFails = false;
  final tested = <String>[];

  @override
  Stream<Either<ProxyFailure, OutboundGroup?>> watchProxies() => updates.stream;

  @override
  TaskEither<ProxyFailure, Unit> selectProxy(String groupTag, String outboundTag) =>
      selectFails ? TaskEither.left(const ProxyFailure.unexpected()) : TaskEither.right(unit);

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) {
    tested.add(groupTag);
    return TaskEither.right(unit);
  }

  final uploaded = <(String, int)>[];

  @override
  TaskEither<ProxyFailure, Unit> uploadTest(String tag, int bytes) {
    uploaded.add((tag, bytes));
    return TaskEither.right(unit);
  }

  final downloaded = <(String, int)>[];
  int cleared = 0;

  @override
  TaskEither<ProxyFailure, Unit> clearSpeedTests() {
    cleared++;
    return TaskEither.right(unit);
  }

  @override
  TaskEither<ProxyFailure, Unit> downloadTest(String tag, int bytes) {
    downloaded.add((tag, bytes));
    return TaskEither.right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Notifications extends InAppNotificationController {
  final errors = <String>[];

  @override
  void showErrorToast(String message) => errors.add(message);
}

/// A proxy as the core reports it; [testedAt] is the second its ping was measured. The core sends
/// the ping again as sort_delay, which the list sorts by.
OutboundInfo proxy(String tag, int delay, {int testedAt = 1, bool group = false}) => OutboundInfo(
  tag: tag,
  isGroup: group,
  urlTestDelay: delay,
  sortDelay: delay,
  urlTestTime: Timestamp.fromDateTime(DateTime.fromMillisecondsSinceEpoch(testedAt * 1000, isUtc: true)),
);

void main() {
  late _Repository repository;
  late _Notifications notifications;
  late ProviderContainer container;

  Future<void> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'haptic_feedback': false});
    repository = _Repository();
    notifications = _Notifications();
    container = ProviderContainer(
      overrides: [
        serviceRunningProvider.overrideWithValue(true),
        proxyRepositoryProvider.overrideWithValue(repository),
        inAppNotificationControllerProvider.overrideWithValue(notifications),
        translationsProvider.overrideWith((ref) => AppLocale.en.build()),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(sharedPreferencesProvider.future));
    await tester.runAsync(() => container.read(translationsProvider.future));
    // the page listens while it is open
    container.listen(proxiesOverviewNotifierProvider, (_, _) {});
    await tester.pump();
  }

  ProxiesOverviewNotifier notifier() => container.read(proxiesOverviewNotifierProvider.notifier);

  List<String> rows() => [
    for (final item in container.read(proxiesOverviewNotifierProvider).requireValue!.items) item.tag,
  ];

  /// The rows the page shows after the core streams [items], with [selected] picked (the first by default).
  Future<List<String>> stream(WidgetTester tester, List<OutboundInfo> items, {String? selected}) async {
    repository.updates.add(right(OutboundGroup(tag: 'select', selected: selected ?? items.first.tag, items: items)));
    await tester.pump();
    return rows();
  }

  testWidgets('a failed selection tells the user', (tester) async {
    await open(tester);
    await stream(tester, [proxy('a', 300), proxy('b', 100)]);
    repository.selectFails = true;
    await notifier().changeProxy('select', 'b');
    expect(notifications.errors, [container.read(translationsProvider).requireValue.pages.proxies.switchFailed]);
    expect(container.read(proxiesOverviewNotifierProvider).requireValue!.selected, 'a');
  });

  testWidgets('the picked proxy stays in its row while the rest re-sorts', (tester) async {
    await open(tester);
    expect(await stream(tester, [proxy('a', 100), proxy('b', 200), proxy('c', 300)]), ['a', 'b', 'c']);
    await notifier().changeProxy('select', 'b');
    // its new ping would send it to the end
    expect(await stream(tester, [proxy('a', 100), proxy('b', 900), proxy('c', 300)], selected: 'b'), ['a', 'b', 'c']);
    // the others still sort
    expect(await stream(tester, [proxy('a', 500), proxy('b', 900), proxy('c', 300)], selected: 'b'), ['c', 'b', 'a']);
  });

  testWidgets('the row is free again once another proxy is selected elsewhere', (tester) async {
    await open(tester);
    await stream(tester, [proxy('a', 100), proxy('b', 200), proxy('c', 300)]);
    await notifier().changeProxy('select', 'b');
    expect(await stream(tester, [proxy('a', 100), proxy('b', 900), proxy('c', 300)], selected: 'a'), ['a', 'c', 'b']);
  });

  testWidgets('picking lowest pins the lowest row, not the proxy lowest picks', (tester) async {
    await open(tester);
    final before = [
      proxy('balance', 200, group: true),
      proxy('lowest', 300, group: true),
      proxy('a', 100),
      proxy('b', 150),
    ];
    expect(await stream(tester, before), ['balance', 'lowest', 'a', 'b']);
    await notifier().changeProxy('select', 'lowest');
    // lowest's new ping would move it up; a and b, among them lowest's pick, still re-sort
    final after = [
      proxy('balance', 200, group: true),
      proxy('lowest', 50, group: true),
      proxy('a', 400),
      proxy('b', 150),
    ];
    expect(await stream(tester, after, selected: 'lowest'), ['balance', 'lowest', 'b', 'a']);
  });

  group('proxy row', () {
    /// One row of the page, for [info].
    Future<void> row(WidgetTester tester, OutboundInfo info) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: ProxyTile(info, selected: false, onTap: () {})),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }

    // the ping's own tap area, inside the row's
    Finder ping() => find.descendant(of: find.byType(ListTile), matching: find.byType(InkWell)).last;

    testWidgets('a tap on the ping tests only that proxy', (tester) async {
      await open(tester);
      await stream(tester, [proxy('a', 300), proxy('b', 100)]);
      await row(tester, proxy('b', 100));
      await tester.tap(ping());
      await tester.pump();
      expect(repository.tested, ['b']);
    });

    testWidgets("a long press on the ping tests the proxy's upload speed", (tester) async {
      await open(tester);
      await row(tester, proxy('a', 182));
      await tester.longPress(ping());
      await tester.pump(const Duration(milliseconds: 500));
      expect(repository.uploaded, [('a', 1 << 20)]);
      expect(repository.tested, isEmpty);
    });

    testWidgets('the signal style switch keeps the choice', (tester) async {
      await open(tester);
      await row(tester, proxy('a', 182));
      expect(find.text('182'), findsOneWidget);
      await tester.runAsync(() => container.read(proxyPingStyleNotifierProvider.notifier).toggle());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(container.read(proxyPingStyleNotifierProvider), ProxyPingStyle.signal);
      expect(find.text('182'), findsNothing);
      final saved = await tester.runAsync(SharedPreferences.getInstance);
      expect(saved!.getString('proxies_ping_style'), 'signal');
    });

    testWidgets('a proxy that gave up says so; a waiting one shows its status, not the core mark', (tester) async {
      await open(tester);
      final t = container.read(translationsProvider).requireValue;
      await row(tester, OutboundInfo(tag: 'd', type: 'DNSTT ❌ Failed', status: Status.FAILED));
      expect(find.text(t.pages.proxies.status.failed), findsOneWidget);
      await row(tester, OutboundInfo(tag: 'w', type: 'WARP ⏳ Connecting...', status: Status.CONNECTING));
      expect(find.text('WARP'), findsOneWidget);
      expect(find.textContaining(t.pages.proxies.status.connecting), findsOneWidget);
      expect(find.textContaining('⏳'), findsNothing);
    });
  });

  testWidgets('a speed test of a short list tests its group, with the megabytes of the settings', (tester) async {
    await open(tester);
    await stream(tester, [proxy('lowest', 100, group: true), proxy('a', 100), proxy('b', 200)]);
    await tester.runAsync(() => container.read(ConfigOptions.uploadTestSize.notifier).update(2));
    await notifier().speedTestAll();
    expect(repository.uploaded, [('select', 2 << 20)]);
  });

  testWidgets('a speed test of a long list tests only the fastest, one by one, the way it is set', (tester) async {
    await open(tester);
    await stream(tester, [proxy('a', 300), proxy('b', 100), proxy('c', 200), proxy('d', 65535)]);
    await tester.runAsync(() async {
      await container.read(ConfigOptions.uploadTestLimit.notifier).update(2);
      await container.read(ConfigOptions.speedTestDirection.notifier).update(SpeedTestDirection.download);
    });
    await notifier().speedTestAll();
    expect(repository.downloaded, [('b', 1 << 20), ('c', 1 << 20)]);
    expect(repository.uploaded, isEmpty);
  });

  testWidgets('a speed test set to all of them tests the group', (tester) async {
    await open(tester);
    await stream(tester, [proxy('a', 300), proxy('b', 100), proxy('c', 200)]);
    await tester.runAsync(() => container.read(ConfigOptions.uploadTestLimit.notifier).update(0));
    await notifier().speedTestAll();
    expect(repository.uploaded, [('select', 1 << 20)]);
  });

  test('the fastest proxies are those that answered, by their ping', () {
    final proxies = [
      proxy('slow', 900),
      proxy('dead', 65535),
      proxy('fast', 80),
      proxy('untested', 0),
      proxy('mid', 300),
    ];
    expect(fastestProxies(proxies, 2), ['fast', 'mid']);
    expect(fastestProxies(proxies, 10), ['fast', 'mid', 'slow']);
  });

  test('by upload speed: this run first, then the cached, then by download, then by ping', () {
    OutboundInfo speeds(String tag, int up, int down, int delay, {bool cached = false}) => OutboundInfo(
      tag: tag,
      uploadSpeed: Int64(up),
      uploadSpeedCached: cached,
      downloadSpeed: Int64(down),
      urlTestDelay: delay,
    );
    final proxies = [
      speeds('untested', 0, 0, 90),
      speeds('cached, fastest', 900, 0, 50, cached: true),
      speeds('slow up', 100, 900, 50),
      speeds('fast up, slow down', 500, 100, 300),
      speeds('fast up, fast down, slow ping', 500, 800, 400),
      speeds('fast up, fast down, fast ping', 500, 800, 120),
      speeds('cached, slower', 300, 0, 50, cached: true),
      speeds('failed up', -1, 900, 40),
    ]..sort((a, b) => compareBySpeeds(a, b, uploadFirst: true));
    expect(proxies.map((e) => e.tag), [
      // this run's uploads, the fastest first
      'fast up, fast down, fast ping',
      'fast up, fast down, slow ping',
      'fast up, slow down',
      'slow up',
      // then the earlier runs', the fastest first
      'cached, fastest',
      'cached, slower',
      // no upload: by download, then ping
      'failed up',
      'untested',
    ]);
    // by download: equal downloads go by upload, a failed one after a measured one
    proxies.sort((a, b) => compareBySpeeds(a, b, uploadFirst: false));
    expect(proxies.take(2).map((e) => e.tag), ['slow up', 'failed up']);
  });
}
