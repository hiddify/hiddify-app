import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late HiddifyCoreService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final serviceProvider = Provider<HiddifyCoreService>(HiddifyCoreService.new);
    container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWith((ref) => preferences)]);
    await container.read(sharedPreferencesProvider.future);
    service = container.read(serviceProvider);
  });

  tearDown(() async {
    for (final subscription in service.subscriptions.values) {
      await subscription?.cancel();
    }
    await service.logController.close();
    await service.statusController.close();
    container.dispose();
  });

  test("watchLogs emits the initial empty snapshot exactly once", () async {
    final message = LogMessage(message: "first");
    final snapshotsFuture = service.watchLogs("unused").take(2).toList();

    await pumpEventQueue();
    service.logController.add(List<LogMessage>.unmodifiable([message]));

    final snapshots = await snapshotsFuture.timeout(const Duration(seconds: 1));

    expect(snapshots, [
      isEmpty,
      [message],
    ]);
  });

  test("log controller starts with an empty snapshot", () {
    expect(service.logController.value, isEmpty);
  });

  test("watchLogs replays the current cached snapshot", () async {
    final message = LogMessage(message: "cached");
    service.logController.add(List<LogMessage>.unmodifiable([message]));

    final logs = await service.watchLogs("unused").first.timeout(const Duration(seconds: 1));

    expect(logs, [message]);
  });

  test("watchLogs stays alive while core is not initialized", () async {
    final message = LogMessage(message: "later");
    final snapshotsFuture = service.watchLogs("unused").take(2).toList();

    await pumpEventQueue();
    service.logController.add(List<LogMessage>.unmodifiable([message]));

    final snapshots = await snapshotsFuture.timeout(const Duration(seconds: 1));
    expect(snapshots.last, [message]);
  });

  test("clearLogs publishes the cleared snapshot", () async {
    final stale = LogMessage(message: "stale");
    service.logBuffer.add(stale);
    service.logController.add(List<LogMessage>.unmodifiable(service.logBuffer));
    final snapshotsFuture = service.watchLogs("unused").take(2).toList();

    await pumpEventQueue();

    final result = await service.clearLogs().run();
    final snapshots = await snapshotsFuture.timeout(const Duration(seconds: 1));

    expect(result.isRight(), isTrue);
    expect(service.logBuffer, isEmpty);
    expect(service.logController.value, isEmpty);
    expect(snapshots, [
      [stale],
      isEmpty,
    ]);
  });

  test("incoming logs publish immutable snapshots detached from the buffer", () async {
    final incomingLogs = StreamController<LogMessage>();
    addTearDown(incomingLogs.close);
    final client = _FakeCoreClient(incomingLogs.stream);
    final first = LogMessage(message: "first");
    final second = LogMessage(message: "second");
    final firstSnapshot = service.logController.stream.skip(1).first;

    await service.startListeningLogs("test", client);
    incomingLogs.add(first);

    final published = await firstSnapshot.timeout(const Duration(seconds: 1));
    incomingLogs.add(second);
    await pumpEventQueue();

    expect(published, [first]);
    expect(() => published.add(second), throwsUnsupportedError);
  });
}

class _FakeCoreClient extends CoreClient {
  _FakeCoreClient(this.logs) : super(ClientChannel("localhost"));

  final Stream<LogMessage> logs;

  @override
  ResponseStream<LogMessage> logListener(LogRequest request, {CallOptions? options}) {
    return ResponseStream(_FakeClientCall(logs));
  }
}

class _FakeClientCall<R> extends ClientCall<dynamic, R> {
  _FakeClientCall(this.responses)
    : super(
        ClientMethod<dynamic, R>("/test", (_) => const [], (_) => throw UnimplementedError()),
        const Stream.empty(),
        CallOptions(),
      );

  final Stream<R> responses;

  @override
  Stream<R> get response => responses;

  @override
  Future<Map<String, String>> get headers async => const {};

  @override
  Future<Map<String, String>> get trailers async => const {};

  @override
  Future<void> cancel() async {}
}
