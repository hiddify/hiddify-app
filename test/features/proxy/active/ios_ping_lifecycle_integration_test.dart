import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('presentation retains ping while real measurement cancels and refreshes only after core readiness', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final repository = _Repository();
    final t = (await tester.runAsync(() => AppLocale.ru.build()))!;
    final container = ProviderContainer(
      overrides: [
        translationsProvider.overrideWith((ref) => t),
        serviceRunningProvider.overrideWith((ref) => true),
        iosActiveProxyMeasurementEnabledProvider.overrideWithValue(true),
        proxyRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await repository.events.close();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: IosActiveProxyDelayIndicator())),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repository.requests, 1);
    repository.emit(84);
    await tester.pump();
    await tester.pump();
    expect(find.text('84 ms'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await tester.pump();
    final old = container.read(iosActiveProxyMeasurementProvider);
    expect(old.state.phase, IosProxyMeasurementPhase.idle);
    expect(old.state.proxy, isNull);
    expect(old.canRefresh, false);
    expect(find.text('84 ms'), findsOneWidget);
    expect(find.text(t.common.unknown), findsNothing);

    repository.emit(999);
    await tester.pump();
    expect(find.text('999 ms'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text(t.pages.proxies.delay.updating), findsOneWidget);
    expect(find.text('84 ms'), findsNothing);
    expect(repository.requests, 1);

    container.read(coreRestartSignalProvider.notifier).restart();
    await tester.pump();
    await tester.pump();
    expect(repository.requests, 2);
    expect(find.text(t.common.unknown), findsNothing);
    repository.emit(95);
    await tester.pump();
    await tester.pump();
    expect(find.text('95 ms'), findsOneWidget);
    expect(find.text(t.pages.proxies.delay.updating), findsNothing);
    await tester.pump(const Duration(microseconds: 1));
    expect(tester.takeException(), isNull);
  });
}

class _Repository implements ProxyRepository {
  final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast();
  int requests = 0;

  void emit(int delay) => events.add(
    right([
      OutboundGroup(
        items: [
          OutboundInfo(
            tag: 'synthetic-fixed-server',
            urlTestDelay: delay,
            urlTestTime: Timestamp.fromDateTime(DateTime.now().add(Duration(seconds: requests))),
          ),
        ],
      ),
    ]),
  );

  @override
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies() => events.stream;

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) => TaskEither(() async {
    requests++;
    return right(unit);
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
