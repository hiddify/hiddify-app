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
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Directories extends AppDirectories {
  @override
  Future<Directories> build() async => (baseDir: Directory('.'), workingDir: Directory('.'), tempDir: Directory('.'));
}

class _SystemCore extends CoreInterface {
  _SystemCore() {
    fgClient = CoreClient(channel);
    bgClient = fgClient;
  }

  final channel = ClientChannel('fixture.invalid');
  CoreStatus? systemStatus;
  Object? snapshotError;
  Object? startError;
  Completer<CoreStatus?>? pendingSnapshot;
  int snapshotReads = 0;

  @override
  Future<CoreStatus?> getSystemStatus() async {
    snapshotReads++;
    if (snapshotError case final error?) throw error;
    return pendingSnapshot != null ? await pendingSnapshot!.future : systemStatus;
  }

  @override
  Future<CoreStatus> setupBackground(String path, String name) async {
    if (startError case final error?) throw error;
    return const CoreStatus.started();
  }
}

// Only external platform/gRPC boundaries are substituted; setup/start and
// status publication below execute the production HiddifyCoreService.
class _Service extends HiddifyCoreService {
  _Service(super.ref, this.systemCore);
  final _SystemCore systemCore;
  final listenerStates = <CoreStatus>[];
  Completer<void>? pendingClose;
  final closeEntered = Completer<void>();
  bool listenerActive = false;

  @override
  CoreInterface get core => systemCore;

  @override
  Future<void> startListeningLogs(String key, CoreClient cc) async {}

  @override
  Future<void> startListeningStatus(String key, CoreClient cc) async {
    listenerStates.add(currentState);
    listenerActive = true;
  }

  @override
  Future<void> closeFront() async {
    if (pendingClose == null) return super.closeFront();
    closeEntered.complete();
    await pendingClose!.future;
    listenerActive = false;
  }
}

class _StatusServer extends CoreServiceBase {
  final events = StreamController<CoreInfoResponse>();
  final entered = Completer<void>();

  @override
  Stream<CoreInfoResponse> coreInfoListener(ServiceCall call, Empty request) {
    entered.complete();
    return events.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late _SystemCore core;
  late _Service service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    core = _SystemCore();
    final provider = Provider<_Service>((ref) => _Service(ref, core));
    container = ProviderContainer(
      overrides: [
        environmentProvider.overrideWithValue(Environment.prod),
        sharedPreferencesProvider.overrideWith((ref) => preferences),
        appDirectoriesProvider.overrideWith(_Directories.new),
      ],
    );
    await container.read(sharedPreferencesProvider.future);
    await container.read(appDirectoriesProvider.future);
    service = container.read(provider);
  });

  tearDown(() async {
    await service.statusController.close();
    await service.logController.close();
    await core.channel.shutdown();
    container.dispose();
  });

  for (final state in [
    const CoreStatus.stopped(),
    const CoreStatus.started(),
    const CoreStatus.starting(),
    const CoreStatus.stopping(),
  ]) {
    test('resume publishes system $state before starting the core listener', () async {
      service.currentState = state == const CoreStatus.started()
          ? const CoreStatus.stopped()
          : const CoreStatus.started();
      core.systemStatus = state;

      final result = await service.setup().run();

      expect(result.isRight(), isTrue, reason: result.toString());
      expect(core.snapshotReads, 1);
      expect(service.statusController.value, state);
      expect(service.listenerStates, [state]);
    });
  }

  test('cold launch recovers an already connected system tunnel', () async {
    core.systemStatus = const CoreStatus.started();
    await service.setup().run();
    expect(service.statusController.value, const CoreStatus.started());
  });

  test('resume waits for system snapshot instead of publishing stale connected', () async {
    service.currentState = const CoreStatus.started();
    core.pendingSnapshot = Completer<CoreStatus?>();
    final setup = service.setup().run();
    await Future<void>.delayed(Duration.zero);
    expect(service.statusController.hasValue, isFalse);
    core.pendingSnapshot!.complete(const CoreStatus.stopped());
    expect((await setup).isRight(), isTrue);
    expect(service.statusController.value, const CoreStatus.stopped());
  });

  test('failed system refresh reports an error without publishing a fabricated status', () async {
    service.currentState = const CoreStatus.started();
    service.statusController.add(const CoreStatus.started());
    core.snapshotError = PlatformException(code: 'VPN_STATUS');

    final result = await service.setup().run();

    expect(result.isLeft(), isTrue);
    expect(service.currentState, const CoreStatus.started());
    expect(service.statusController.hasError, isTrue);
    await expectLater(service.statusController.stream.first, throwsA(isA<PlatformException>()));
    expect(service.listenerStates, isEmpty);
  });

  test('platforms without a system snapshot keep the existing core status', () async {
    service.currentState = const CoreStatus.started();
    final result = await service.setup().run();
    expect(result.isRight(), isTrue, reason: result.toString());
    expect(service.statusController.value, const CoreStatus.started());
  });

  test('native start rejection returns a connection failure and resets Starting', () async {
    core.startError = PlatformException(code: 'SETUP_CONNECTION', message: 'Synthetic preferences refusal');

    final result = await service.start('/fixture/config.json', 'Fixture', false).run();

    expect(result.isLeft(), isTrue);
    expect(service.currentState, const CoreStatus.stopped());
    expect(service.statusController.value, const CoreStatus.stopped());
  });

  test('resume waits for the previous pause to finish and leaves its new listener active', () async {
    core.systemStatus = const CoreStatus.started();
    service.pendingClose = Completer<void>();
    final paused = service.pause();
    await service.closeEntered.future;
    final resumed = service.resume();
    await Future<void>.delayed(Duration.zero);
    final snapshotReadsDuringClose = core.snapshotReads;
    service.pendingClose!.complete();
    await Future.wait([paused, resumed]);

    expect(snapshotReadsDuringClose, 0, reason: 'the pending close must not overlap the new snapshot/listener');
    expect(service.listenerActive, isTrue);
    expect(service.statusController.value, const CoreStatus.started());
  });

  test('explicitly cancelling a status listener does not mean the system tunnel stopped', () async {
    final statusServer = _StatusServer();
    final server = Server.create(services: [statusServer]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    final channel = ClientChannel(
      '127.0.0.1',
      port: server.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    final real = container.read(Provider((ref) => HiddifyCoreService(ref)));
    addTearDown(() async {
      await real.stopListenSingle('bg');
      await channel.shutdown();
      await server.shutdown();
      await statusServer.events.close();
      await real.statusController.close();
      await real.logController.close();
    });

    await real.startListeningStatus('bg', CoreClient(channel));
    await statusServer.entered.future.timeout(const Duration(seconds: 3));
    statusServer.events.add(CoreInfoResponse(coreState: CoreStates.STARTED));
    await real.statusController.first.timeout(const Duration(seconds: 3));
    expect(real.currentState, const CoreStatus.started());

    await real.stopListenSingle('bg');

    expect(real.currentState, const CoreStatus.started());
    expect(real.statusController.value, const CoreStatus.started());
  });
}
