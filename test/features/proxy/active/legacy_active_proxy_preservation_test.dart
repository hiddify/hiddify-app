import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/model/ip_info_entity.dart' as oldipinfo;
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('non-iOS preservation: empty active-proxy list becomes AsyncData with the protobuf default', () async {
    final repository = _ProbeProxyRepository(Stream.value(right(<OutboundGroup>[])));
    final container = await _createContainer(repository);
    addTearDown(container.dispose);

    final value = await container.read(activeProxyNotifierProvider.future);

    expect(container.read(activeProxyNotifierProvider), isA<AsyncData<OutboundInfo>>());
    _expectDefaultOutbound(value);
  });

  test('non-iOS preservation: active-proxy failure is mapped to the same protobuf default data', () async {
    final repository = _ProbeProxyRepository(Stream.value(left(const ProxyUnexpectedFailure())));
    final container = await _createContainer(repository);
    addTearDown(container.dispose);

    final value = await container.read(activeProxyNotifierProvider.future);

    expect(container.read(activeProxyNotifierProvider), isA<AsyncData<OutboundInfo>>());
    _expectDefaultOutbound(value);
  });

  test('non-iOS preservation: urlTest returns before the pending repository request completes', () async {
    final repository = _ProbeProxyRepository(
      Stream.value(
        right([
          OutboundGroup(
            items: [OutboundInfo(tag: 'active', tagDisplay: 'Active', type: 'vless', urlTestDelay: 42)],
          ),
        ]),
      ),
    )..urlTestGate = Completer<Unit>();
    final container = await _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(activeProxyNotifierProvider.future);
    final notifier = container.read(activeProxyNotifierProvider.notifier);
    var returned = false;

    final returnedFuture = notifier.urlTest('');
    await returnedFuture;
    returned = true;
    await repository.urlTestStarted.future.timeout(const Duration(seconds: 1));

    expect(returned, isTrue);
    expect(repository.urlTestGroups, ['']);
    expect(repository.urlTestGate!.isCompleted, isFalse);

    repository.urlTestGate!.complete(unit);
    await repository.urlTestFinished.future.timeout(const Duration(seconds: 1));
  });
}

Future<ProviderContainer> _createContainer(_ProbeProxyRepository repository) async {
  SharedPreferences.setMockInitialValues({'haptic_feedback': false});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      iosActiveProxyMeasurementEnabledProvider.overrideWithValue(false),
      sharedPreferencesProvider.overrideWith((ref) => Future.value(preferences)),
      serviceRunningProvider.overrideWith((ref) => true),
      proxyRepositoryProvider.overrideWithValue(repository),
    ],
  );
  await container.read(sharedPreferencesProvider.future);
  return container;
}

void _expectDefaultOutbound(OutboundInfo value) {
  expect(value.tag, isEmpty);
  expect(value.tagDisplay, isEmpty);
  expect(value.type, isEmpty);
  expect(value.host, isEmpty);
  expect(value.urlTestDelay, 0);
  expect(value.ipinfo.ip, isEmpty);
  expect(value.ipinfo.countryCode, isEmpty);
  expect(value.ipinfo.org, isEmpty);
}

class _ProbeProxyRepository implements ProxyRepository {
  _ProbeProxyRepository(this.activeProxies);

  final Stream<Either<ProxyFailure, List<OutboundGroup>>> activeProxies;
  final urlTestStarted = Completer<void>();
  final urlTestFinished = Completer<void>();
  final urlTestGroups = <String>[];
  Completer<Unit>? urlTestGate;

  @override
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies() => activeProxies;

  @override
  Stream<Either<ProxyFailure, OutboundGroup?>> watchProxies() => const Stream.empty();

  @override
  TaskEither<ProxyFailure, oldipinfo.IpInfo> getCurrentIpInfo(CancelToken cancelToken) =>
      TaskEither.left(const UnknownIp());

  @override
  TaskEither<ProxyFailure, Unit> selectProxy(String groupTag, String outboundTag) => TaskEither.of(unit);

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) {
    urlTestGroups.add(groupTag);
    return TaskEither.tryCatch(() async {
      if (!urlTestStarted.isCompleted) urlTestStarted.complete();
      final result = await urlTestGate!.future;
      if (!urlTestFinished.isCompleted) urlTestFinished.complete();
      return result;
    }, ProxyUnexpectedFailure.new);
  }
}
