import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_mobile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello_service.pbgrpc.dart';

class _IosCore extends CoreInterfaceMobile {
  _IosCore({Duration deadline = const Duration(milliseconds: 150)}) : super(iosSetupDeadline: deadline);

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

class _FailureHello extends HelloServiceBase {
  _FailureHello(this.stage);
  final String stage;
  int calls = 0;

  @override
  Future<HelloResponse> sayHello(ServiceCall call, HelloRequest request) {
    calls++;
    if (stage != 'firstHello' && calls == 1) {
      return Future.error(const GrpcError.unavailable('synthetic unavailable'));
    }
    return Future.error(const GrpcError.permissionDenied('synthetic private RPC detail'));
  }

  @override
  Stream<HelloResponse> sayHelloStream(ServiceCall call, Stream<HelloRequest> requests) => const Stream.empty();
}

class _RejectingHello extends HelloServiceBase {
  _RejectingHello(this.status, {this.rejectFirst = false});
  final int status;
  final bool rejectFirst;
  int calls = 0;

  @override
  Future<HelloResponse> sayHello(ServiceCall call, HelloRequest request) async {
    calls++;
    throw GrpcError.custom(rejectFirst && calls == 1 ? StatusCode.unavailable : status, 'private synthetic detail');
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

  test('iOS setup reaches a native server started after the first connection is refused', () async {
    final hello = _ControlledHello(rejectFirst: false)..release.complete();
    final server = Server.create(services: [hello]);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, MockStreamHandler.inline(onListen: (_, _) {}));
    messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, MockStreamHandler.inline(onListen: (_, _) {}));
    final methods = <String>[];
    messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, (call) async {
      methods.add(call.method);
      expect(call.method, 'setup');
      await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
      return true;
    });
    addTearDown(() async {
      await server.shutdown();
      messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, null);
      messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, null);
      messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, null);
    });
    final core = _IosCore(deadline: const Duration(seconds: 5));
    final dir = Directory.systemTemp;

    expect(await core.setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3), isEmpty);
    expect(methods, ['setup']);
    expect(hello.calls, 1, reason: 'Only the post-native Hello can reach the initially absent server.');
    expect(core.isInitialized(), isTrue);
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

  for (final scenario in ['firstHello', 'secondHello', 'nativeSetup', 'vpnPreferences']) {
    test('iOS setup preserves closed failure stage: $scenario', () async {
      final hello = _FailureHello(scenario);
      final server = Server.create(services: [hello]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, MockStreamHandler.inline(onListen: (_, _) {}));
      messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, MockStreamHandler.inline(onListen: (_, _) {}));
      var nativeCalls = 0;
      messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, (call) async {
        expect(call.method, 'setup');
        nativeCalls++;
        if (scenario == 'vpnPreferences') {
          throw PlatformException(code: 'SETUP', message: 'synthetic private preferences detail');
        }
        if (scenario == 'nativeSetup') {
          throw PlatformException(code: '12345', message: 'synthetic private native detail');
        }
        return true;
      });
      addTearDown(() async {
        await server.shutdown();
        messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, null);
        messenger.setMockStreamHandler(CoreInterfaceMobile.statusChannel, null);
        messenger.setMockStreamHandler(CoreInterfaceMobile.alertsChannel, null);
      });
      final core = _IosCore(deadline: const Duration(seconds: 5));
      final dir = Directory.systemTemp;
      Object? failure;
      try {
        await core.setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3);
      } catch (error) {
        failure = error;
      }
      expect(failure, isA<IosCoreSetupException>());
      final expectedStage = scenario == 'vpnPreferences' ? 'nativeSetup' : scenario;
      expect((failure! as IosCoreSetupException).stage.name, expectedStage);
      expect(
        failure.toString(),
        contains(expectedStage),
        reason: 'Safe failure must identify the rejected setup boundary',
      );
      expect(failure.toString(), isNot(contains('private')));
      expect(failure.toString(), isNot(contains('12345')));
      expect((failure as IosCoreSetupException).code.name, switch (scenario) {
        'vpnPreferences' => 'vpnPreferencesFailed',
        'nativeSetup' => 'nativeSetupFailed',
        _ => 'helloFailed',
      });
      expect(nativeCalls, scenario == 'firstHello' ? 0 : 1);
      expect(hello.calls, scenario == 'secondHello' ? 2 : 1);
      expect(core.isInitialized(), false);
    });
  }

  test('setup diagnostic status accepts canonical codes only', () {
    for (final code in [-1, 0, 7, 16, 17, 999]) {
      final error = IosCoreSetupException(IosCoreSetupCode.helloFailed, grpcStatusCode: code);
      expect(error.grpcStatusCode, code >= 0 && code <= 16 ? code : isNull);
    }
  });

  for (final status in [StatusCode.unavailable, StatusCode.unimplemented, StatusCode.permissionDenied]) {
    test('second Hello retains status $status and reachable loopback without publishing clients', () async {
      final hello = _RejectingHello(status, rejectFirst: true);
      final server = Server.create(services: [hello]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
      final methods = <String>[];
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, (call) async {
        methods.add(call.method);
        return true;
      });
      addTearDown(() async {
        await server.shutdown();
        messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, null);
      });
      final core = _IosCore();
      final dir = Directory.systemTemp;
      try {
        await core.setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3);
        fail('Expected second Hello rejection');
      } on IosCoreSetupException catch (error) {
        expect(error.stage, IosCoreSetupStage.secondHello);
        expect(error.grpcStatusCode, status);
        expect(error.foregroundListenerReachable, isTrue);
        expect(error.toString(), isNot(contains('private')));
      }
      expect(hello.calls, 2);
      expect(core.isInitialized(), isFalse);
      expect(methods, ['setup']);
    });
  }

  test('second Hello retains unavailable and unreachable loopback after native server close', () async {
    final hello = _RejectingHello(StatusCode.unavailable);
    final server = Server.create(services: [hello]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
    final methods = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, (call) async {
      methods.add(call.method);
      await server.shutdown();
      return true;
    });
    addTearDown(() async {
      await server.shutdown();
      messenger.setMockMethodCallHandler(CoreInterfaceMobile.methodChannel, null);
    });
    final core = _IosCore();
    final dir = Directory.systemTemp;
    try {
      await core.setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3);
      fail('Expected unavailable second Hello');
    } on IosCoreSetupException catch (error) {
      expect(error.stage, IosCoreSetupStage.secondHello);
      expect(error.grpcStatusCode, StatusCode.unavailable);
      expect(error.foregroundListenerReachable, isFalse);
    }
    expect(core.isInitialized(), isFalse);
    expect(methods, ['setup']);
  });

  test('first Hello status has no post-native loopback observation', () async {
    final hello = _RejectingHello(StatusCode.permissionDenied);
    final server = Server.create(services: [hello]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
    addTearDown(server.shutdown);
    final core = _IosCore();
    final dir = Directory.systemTemp;
    try {
      await core.setup((baseDir: dir, workingDir: dir, tempDir: dir), false, 3);
      fail('Expected first Hello rejection');
    } on IosCoreSetupException catch (error) {
      expect(error.stage, IosCoreSetupStage.firstHello);
      expect(error.grpcStatusCode, StatusCode.permissionDenied);
      expect(error.foregroundListenerReachable, isNull);
    }
    expect(core.isInitialized(), isFalse);
  });
}
