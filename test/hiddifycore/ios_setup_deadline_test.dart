import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_mobile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello_service.pbgrpc.dart';

class _IosCore extends CoreInterfaceMobile {
  _IosCore() : super(iosSetupDeadline: const Duration(milliseconds: 150));

  @override
  bool get supportsSystemStatus => true;
}

class _ControlledHello extends HelloServiceBase {
  _ControlledHello({required this.rejectFirst});
  final bool rejectFirst;
  final accepted = Completer<void>();
  final release = Completer<void>();
  int calls = 0;

  @override
  Future<HelloResponse> sayHello(ServiceCall call, HelloRequest request) async {
    calls++;
    if (rejectFirst && calls == 1) throw const GrpcError.unavailable('synthetic unavailable');
    if (!accepted.isCompleted) accepted.complete();
    await release.future;
    return HelloResponse(message: 'synthetic ready');
  }

  @override
  Stream<HelloResponse> sayHelloStream(ServiceCall call, Stream<HelloRequest> requests) => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in ['first Hello stalls', 'second Hello stalls', 'native setup stalls']) {
    test('iOS setup terminates safely when $scenario without changing VPN', () async {
      final hello = _ControlledHello(rejectFirst: scenario != 'first Hello stalls');
      final server = Server.create(services: [hello]);
      // Binding fails if occupied; never interrupt an existing foreground core.
      await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, MockStreamHandler.inline(onListen: (_, _) {}));
      messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, MockStreamHandler.inline(onListen: (_, _) {}));
      final methods = <String>[];
      final nativeEntered = Completer<void>();
      final releaseNative = Completer<void>();
      messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, (call) async {
        methods.add(call.method);
        if (call.method == 'setup' && scenario == 'native setup stalls') {
          nativeEntered.complete();
          await releaseNative.future;
        }
        return true;
      });
      final core = _IosCore();
      final dir = Directory.systemTemp;
      var completed = false;
      Object? failure;
      final pending = core
          .setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3)
          .then<void>(
            (_) => completed = true,
            onError: (Object error, StackTrace _) {
              failure = error;
              completed = true;
            },
          );
      addTearDown(() async {
        if (!releaseNative.isCompleted) releaseNative.complete();
        if (!hello.release.isCompleted) hello.release.complete();
        await pending.timeout(const Duration(seconds: 3));
        await server.shutdown();
        messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, null);
        messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, null);
        messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, null);
      });

      final entered = scenario == 'native setup stalls' ? nativeEntered.future : hello.accepted.future;
      await entered.timeout(const Duration(seconds: 3));
      // The server/native callback has accepted the operation and deliberately
      // remains unanswered: this exercises a stall, not connection refusal.
      await Future.any<void>([pending, Future<void>.delayed(const Duration(seconds: 5))]);
      expect(methods.where((method) => ['start', 'stop', 'reset'].contains(method)), isEmpty);
      expect(
        completed,
        isTrue,
        reason: 'An accepted but unanswered setup operation must not retain the launch splash.',
      );
      expect(failure, isA<IosCoreSetupException>());
      expect(
        (failure! as IosCoreSetupException).code,
        scenario == 'native setup stalls' ? IosCoreSetupCode.nativeSetupTimedOut : IosCoreSetupCode.helloTimedOut,
      );
      expect(core.isInitialized(), isFalse);
      if (scenario == 'first Hello stalls') expect(methods, isEmpty);
      if (scenario == 'native setup stalls') {
        releaseNative.complete();
        hello.release.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(core.isInitialized(), isFalse, reason: 'Late native completion must not publish clients.');
      }
    });
  }

  test('retry and concurrent setup coalesce an unresolved native setup', () async {
    final hello = _ControlledHello(rejectFirst: true);
    final server = Server.create(services: [hello]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, MockStreamHandler.inline(onListen: (_, _) {}));
    messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, MockStreamHandler.inline(onListen: (_, _) {}));
    final entered = Completer<void>();
    final release = Completer<void>();
    final methods = <String>[];
    messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, (call) async {
      methods.add(call.method);
      if (!entered.isCompleted) entered.complete();
      await release.future;
      return true;
    });
    final core = _IosCore();
    final dir = Directory.systemTemp;
    Future<Object?> setup() async {
      try {
        return await core.setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3);
      } catch (error) {
        return error;
      }
    }

    final first = setup();
    final attempts = <Future<Object?>>[first];
    addTearDown(() async {
      if (!release.isCompleted) release.complete();
      if (!hello.release.isCompleted) hello.release.complete();
      await Future.wait(attempts).timeout(const Duration(seconds: 3));
      await server.shutdown();
      messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, null);
      messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, null);
      messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, null);
    });
    await entered.future.timeout(const Duration(seconds: 3));
    final concurrent = setup();
    attempts.add(concurrent);
    final firstOutcome = await Future.any<Object?>([first, Future<Object?>.delayed(const Duration(seconds: 5))]);
    expect(firstOutcome, isNotNull, reason: 'Initial setup must terminate while native callback stays pending.');
    final retry = setup();
    attempts.add(retry);
    await Future.any<Object?>([retry, Future<Object?>.delayed(const Duration(seconds: 5))]);
    expect(methods, ['setup']);
    expect(core.isInitialized(), isFalse);
    release.complete();
    hello.release.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(core.isInitialized(), isFalse);
    expect(await setup(), '');
    expect(core.isInitialized(), isTrue);
    expect(methods, ['setup'], reason: 'Recovery reuses the settled native setup.');
  });

  test('non-iOS setup retains legacy unbounded Hello behavior', () async {
    final hello = _ControlledHello(rejectFirst: false);
    final server = Server.create(services: [hello]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, MockStreamHandler.inline(onListen: (_, _) {}));
    messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, MockStreamHandler.inline(onListen: (_, _) {}));
    final core = CoreInterfaceMobile(iosSetupDeadline: const Duration(milliseconds: 50));
    final dir = Directory.systemTemp;
    var completed = false;
    final pending = core.setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3).then((_) => completed = true);
    addTearDown(() async {
      if (!hello.release.isCompleted) hello.release.complete();
      await pending.timeout(const Duration(seconds: 3));
      await server.shutdown();
      messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, null);
      messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, null);
    });
    await hello.accepted.future.timeout(const Duration(seconds: 3));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(completed, isFalse);
    hello.release.complete();
    await pending;
    expect(core.isInitialized(), isTrue);
  });
}
