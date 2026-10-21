import 'dart:async';

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
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The core's side: the test sends each proxy list the core would stream.
class _Repository implements ProxyRepository {
  final updates = StreamController<Either<ProxyFailure, OutboundGroup?>>.broadcast();
  bool selectFails = false;

  @override
  Stream<Either<ProxyFailure, OutboundGroup?>> watchProxies() => updates.stream;

  @override
  TaskEither<ProxyFailure, Unit> selectProxy(String groupTag, String outboundTag) =>
      selectFails ? TaskEither.left(const ProxyFailure.unexpected()) : TaskEither.right(unit);

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) => TaskEither.right(unit);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Notifications extends InAppNotificationController {
  final errors = <String>[];

  @override
  void showErrorToast(String message) => errors.add(message);
}

/// A proxy as the core reports it; [testedAt] is the second its ping was measured.
OutboundInfo proxy(String tag, int delay, {int testedAt = 1, bool group = false}) => OutboundInfo(
  tag: tag,
  isGroup: group,
  urlTestDelay: delay,
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
}
