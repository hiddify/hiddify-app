import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_mobile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hello/hello_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Directories extends AppDirectories {
  @override
  Future<Directories> build() async => (baseDir: Directory('.'), workingDir: Directory('.'), tempDir: Directory('.'));
}

class _HelloService extends HelloServiceBase {
  @override
  Future<HelloResponse> sayHello(ServiceCall call, HelloRequest request) async => HelloResponse(message: 'ready');

  @override
  Stream<HelloResponse> sayHelloStream(ServiceCall call, Stream<HelloRequest> request) => const Stream.empty();
}

class _BackgroundCore extends CoreServiceBase {
  final events = StreamController<CoreInfoResponse>.broadcast();
  final startEntered = Completer<void>();
  final statusListening = Completer<void>();
  Future<CoreInfoResponse> Function()? onStart;

  @override
  Stream<CoreInfoResponse> coreInfoListener(ServiceCall call, Empty request) {
    if (!statusListening.isCompleted) statusListening.complete();
    return events.stream;
  }

  @override
  Future<CoreInfoResponse> start(ServiceCall call, StartRequest request) async {
    if (!startEntered.isCompleted) startEntered.complete();
    return await onStart?.call() ?? CoreInfoResponse(messageType: MessageType.EMPTY);
  }

  @override
  Stream<LogMessage> logListener(ServiceCall call, LogRequest request) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MobileCore extends CoreInterfaceMobile {
  CoreStatus? snapshot = const CoreStatus.starting();
  Completer<CoreStatus?>? pendingSnapshot;
  Future<CoreStatus> Function()? onSetupBackground;
  int snapshotReads = 0;
  Object? refreshError;
  bool systemStatusSupported = true;

  @override
  bool get supportsSystemStatus => systemStatusSupported;

  @override
  Future<CoreStatus?> getSystemStatus() async {
    snapshotReads++;
    if (snapshotReads > 1) {
      if (refreshError case final error?) throw error;
    }
    return pendingSnapshot != null ? await pendingSnapshot!.future : snapshot;
  }

  @override
  Future<CoreStatus> setupBackground(String path, String name) async =>
      await onSetupBackground?.call() ?? const CoreStatus.started();
}

class _MobileService extends HiddifyCoreService {
  _MobileService(super.ref, this.mobileCore);

  final CoreInterfaceMobile mobileCore;

  @override
  CoreInterface get core => mobileCore;
}

class _NativeStatusHarness {
  _NativeStatusHarness() {
    messenger.setMockStreamHandler(
      statusChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          listenCount++;
          sink = events;
          if (!listening.isCompleted) listening.complete();
        },
      ),
    );
    messenger.setMockStreamHandler(alertsChannel, MockStreamHandler.inline(onListen: (arguments, events) {}));
  }

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final listening = Completer<void>();
  late MockStreamHandlerEventSink sink;
  int listenCount = 0;

  static const statusChannel = EventChannel('${CoreInterfaceMobile.channelPrefix}/service.status', JSONMethodCodec());
  static const alertsChannel = EventChannel('${CoreInterfaceMobile.channelPrefix}/service.alerts', JSONMethodCodec());

  void send(String status) => sink.success({'status': status});

  void close() {
    messenger.setMockStreamHandler(statusChannel, null);
    messenger.setMockStreamHandler(alertsChannel, null);
  }
}

Future<void> _waitUntil(bool Function() condition, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) throw TestFailure(reason ?? 'condition was not reached before timeout');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _sendGrpcUntil(_BackgroundCore background, CoreInfoResponse event, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    background.events.add(event);
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('gRPC status event was not observed before timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWithValue(Environment.prod),
      sharedPreferencesProvider.overrideWith((ref) => preferences),
      appDirectoriesProvider.overrideWith(_Directories.new),
    ],
  );
  await container.read(sharedPreferencesProvider.future);
  await container.read(appDirectoriesProvider.future);
  return container;
}

Future<Server> _serveHello() async {
  final server = Server.create(services: [_HelloService(), _BackgroundCore()]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portFront);
  return server;
}

Future<Server> _serveBackground(_BackgroundCore service) async {
  final server = Server.create(services: [service]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: CoreInterfaceMobile.portBack);
  return server;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('watchStatus follows late native stopped and started events after background gRPC is unavailable', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    await expectLater(
      Socket.connect(
        InternetAddress.loopbackIPv4,
        CoreInterfaceMobile.portBack,
        timeout: const Duration(milliseconds: 300),
      ),
      throwsA(isA<SocketException>()),
    );
    final service = container.read(Provider((ref) => _MobileService(ref, _MobileCore())));
    StreamSubscription<CoreStatus>? statusSubscription;
    addTearDown(() async {
      await statusSubscription?.cancel();
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    final setup = await service.setup().run();
    expect(setup.isRight(), isTrue, reason: setup.toString());
    await native.listening.future.timeout(const Duration(seconds: 3));

    final observed = <CoreStatus>[];
    statusSubscription = service.watchStatus().listen(observed.add);
    await _waitUntil(() => observed.contains(const CoreStatus.starting()));
    await _waitUntil(() => !service.subscriptions.containsKey('bgStatusListener'));
    native.send('Stopped');
    native.send('Started');

    await _waitUntil(() => observed.length >= 3, reason: 'native status events did not reach watchStatus: $observed');
    expect(observed.take(3), [const CoreStatus.starting(), const CoreStatus.stopped(), const CoreStatus.started()]);
  });

  test('a live native event wins over a delayed system snapshot', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final core = _MobileCore()..pendingSnapshot = Completer<CoreStatus?>();
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    service.currentState = const CoreStatus.started();
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    final setup = service.setup().run();
    await native.listening.future.timeout(const Duration(seconds: 3));
    native.send('Stopped');
    try {
      await _waitUntil(
        () => service.currentState == const CoreStatus.stopped(),
        reason: 'live native stopped was not processed while the snapshot was pending',
      );
    } finally {
      core.pendingSnapshot!.complete(const CoreStatus.starting());
    }
    expect((await setup).isRight(), isTrue);

    expect(service.currentState, const CoreStatus.stopped());
    expect(service.statusController.value, const CoreStatus.stopped());
  });

  test('repeated setup keeps one native status subscription', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final service = container.read(Provider((ref) => _MobileService(ref, _MobileCore())));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));
    expect((await service.setup().run()).isRight(), isTrue);

    expect(native.listenCount, 1);
  });

  test('native stopped cannot be overwritten by a late gRPC started event', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final service = container.read(Provider((ref) => _MobileService(ref, _MobileCore())));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));
    await background.statusListening.future.timeout(const Duration(seconds: 3));
    native.send('Stopped');
    await _waitUntil(() => service.currentState == const CoreStatus.stopped());
    background.events.add(CoreInfoResponse(coreState: CoreStates.STARTED));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(service.currentState, const CoreStatus.stopped());
  });

  test('native started cannot be overwritten by a stale empty gRPC stopped event', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final core = _MobileCore()..snapshot = const CoreStatus.started();
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      if (!background.events.isClosed) await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));
    await background.statusListening.future.timeout(const Duration(seconds: 3));
    native.send('Stopped');
    await _waitUntil(() => service.currentState == const CoreStatus.stopped());
    native.send('Started');
    await _waitUntil(() => service.currentState == const CoreStatus.started());
    background.events.add(CoreInfoResponse(coreState: CoreStates.STOPPED, messageType: MessageType.EMPTY));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(service.currentState, const CoreStatus.started());
    expect(service.statusController.value, const CoreStatus.started());
    await background.events.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(service.currentState, const CoreStatus.started());
    expect(service.statusController.value, const CoreStatus.started());
  });

  test('a stopped gRPC status with an alert remains visible after native started', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final core = _MobileCore()..snapshot = const CoreStatus.started();
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));
    await background.statusListening.future.timeout(const Duration(seconds: 3));
    native.send('Stopped');
    await _waitUntil(() => service.currentState == const CoreStatus.stopped());
    native.send('Started');
    await _waitUntil(() => service.currentState == const CoreStatus.started());
    background.events.add(
      CoreInfoResponse(
        coreState: CoreStates.STOPPED,
        messageType: MessageType.START_SERVICE,
        message: 'fixture failure',
      ),
    );
    await _waitUntil(() => service.currentState is CoreStopped);

    expect(service.currentState, const CoreStatus.stopped(alert: CoreAlert.startService, message: 'fixture failure'));
  });

  test('app start gates early native events until the start RPC succeeds', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final setupBackground = Completer<CoreStatus>();
    final startResponse = Completer<CoreInfoResponse>();
    background.onStart = () => startResponse.future;
    final core = _MobileCore()
      ..snapshot = const CoreStatus.stopped()
      ..onSetupBackground = () => setupBackground.future;
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));
    final started = service.start('/fixture/config.json', 'Fixture', false).run();
    await _waitUntil(() => service.currentState == const CoreStatus.starting());
    native.send('Stopped');
    native.send('Started');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(service.currentState, const CoreStatus.starting());

    setupBackground.complete(const CoreStatus.started());
    await background.startEntered.future.timeout(const Duration(seconds: 3));
    expect(service.currentState, const CoreStatus.starting());
    startResponse.complete(CoreInfoResponse(messageType: MessageType.EMPTY));
    expect((await started).isRight(), isTrue);
    expect(service.currentState, const CoreStatus.started());
  });

  test('app start failure discards early native started and publishes stopped', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    background.onStart = () => throw const GrpcError.unavailable('fixture unavailable');
    final core = _MobileCore()..snapshot = const CoreStatus.stopped();
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));
    final started = service.start('/fixture/config.json', 'Fixture', false).run();
    await _waitUntil(() => service.currentState == const CoreStatus.starting());
    native.send('Started');

    expect((await started).isLeft(), isTrue);
    expect(service.currentState, const CoreStatus.stopped());
  });

  test('app start refreshes system status after RPC when no native event arrives', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final core = _MobileCore()..snapshot = const CoreStatus.stopped();
    background.onStart = () async {
      core.snapshot = const CoreStatus.started();
      return CoreInfoResponse(messageType: MessageType.EMPTY);
    };
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));

    expect((await service.start('/fixture/config.json', 'Fixture', false).run()).isRight(), isTrue);
    expect(service.currentState, const CoreStatus.started());
    expect(service.statusController.value, const CoreStatus.started());
  });

  test('app start keeps a core failure that arrives before the start RPC completes', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final setupBackground = Completer<CoreStatus>();
    final startResponse = Completer<CoreInfoResponse>();
    background.onStart = () => startResponse.future;
    final core = _MobileCore()
      ..snapshot = const CoreStatus.stopped()
      ..onSetupBackground = () => setupBackground.future;
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      if (!startResponse.isCompleted) startResponse.complete(CoreInfoResponse(messageType: MessageType.EMPTY));
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));
    await background.statusListening.future.timeout(const Duration(seconds: 3));
    final started = service.start('/fixture/config.json', 'Fixture', false).run();
    await _waitUntil(() => service.currentState == const CoreStatus.starting());
    native.send('Started');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    const failure = CoreStatus.stopped(alert: CoreAlert.startService, message: 'fixture failure during start');
    await _sendGrpcUntil(
      background,
      CoreInfoResponse(
        coreState: CoreStates.STOPPED,
        messageType: MessageType.START_SERVICE,
        message: 'fixture failure during start',
      ),
      () => service.currentState == failure,
    );

    setupBackground.complete(const CoreStatus.started());
    await background.startEntered.future.timeout(const Duration(seconds: 3));
    startResponse.complete(CoreInfoResponse(messageType: MessageType.EMPTY));
    final result = await started;
    expect(result.isRight(), isTrue, reason: result.toString());
    expect(service.currentState, failure);
    expect(service.statusController.value, failure);
  });

  test('non-iOS app start retains the latest gRPC state after a transient core failure', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final startResponse = Completer<CoreInfoResponse>();
    background.onStart = () => startResponse.future;
    final core = _MobileCore()..systemStatusSupported = false;
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      if (!startResponse.isCompleted) startResponse.complete(CoreInfoResponse(messageType: MessageType.EMPTY));
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    final started = service.start('/fixture/config.json', 'Fixture', false).run();
    await background.startEntered.future.timeout(const Duration(seconds: 3));
    const failure = CoreStatus.stopped(alert: CoreAlert.startService, message: 'fixture transient failure');
    await _sendGrpcUntil(
      background,
      CoreInfoResponse(
        coreState: CoreStates.STOPPED,
        messageType: MessageType.START_SERVICE,
        message: 'fixture transient failure',
      ),
      () => service.currentState == failure,
    );
    await _sendGrpcUntil(
      background,
      CoreInfoResponse(coreState: CoreStates.STARTED),
      () => service.currentState == const CoreStatus.started(),
    );
    startResponse.complete(CoreInfoResponse(messageType: MessageType.EMPTY));
    expect((await started).isRight(), isTrue);
    expect(service.statusController.value, const CoreStatus.started());
    expect(service.currentState, const CoreStatus.started());
  });

  test('app start surfaces a final system refresh failure', () async {
    final native = _NativeStatusHarness();
    final container = await _container();
    final helloServer = await _serveHello();
    final background = _BackgroundCore();
    final backgroundServer = await _serveBackground(background);
    final core = _MobileCore()
      ..snapshot = const CoreStatus.stopped()
      ..refreshError = StateError('fixture refresh failure');
    final service = container.read(Provider((ref) => _MobileService(ref, core)));
    addTearDown(() async {
      await service.stopListenSingle('fg');
      await service.stopListenSingle('bg');
      await service.statusController.close();
      await service.logController.close();
      await background.events.close();
      await backgroundServer.shutdown();
      await helloServer.shutdown();
      native.close();
      container.dispose();
    });

    expect((await service.setup().run()).isRight(), isTrue);
    await native.listening.future.timeout(const Duration(seconds: 3));

    expect((await service.start('/fixture/config.json', 'Fixture', false).run()).isRight(), isTrue);
    expect(service.statusController.hasError, isTrue);
  });
}
