import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late Server server;
  late ClientChannel channel;
  late ProviderContainer container;
  late HiddifyCoreService service;
  late _Interface core;
  late _Server api;

  setUp(() async {
    api = _Server();
    server = Server.create(services: [api]);
    await server.serve(address: '127.0.0.1', port: 0);
    channel = ClientChannel(
      '127.0.0.1',
      port: server.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    core = _Interface()..bgClient = CoreClient(channel);
    container = ProviderContainer();
    service = container.read(Provider((ref) => HiddifyCoreService(ref, core: core)));
  });

  tearDown(() async {
    await service.statusController.close();
    container.dispose();
    await channel.shutdown();
    await server.shutdown();
  });

  test('successful hot reload refreshes once', () async {
    expect((await service.reload('B.json', 'B', false).run()).isRight(), isTrue);
    expect(core.refreshes, 1);
    expect(api.restarts, 0);
  });

  test('notification failure does not fail reload or trigger restart', () async {
    core.failRefresh = true;
    expect((await service.reload('B.json', 'B', false).run()).isRight(), isTrue);
    expect(core.refreshes, 1);
    expect(api.restarts, 0);
  });

  test('restart fallback refreshes only after a running outcome', () async {
    api.reloadResult = MessageType.HOT_RELOAD_FAILED;
    api.restartOutcome = () => service.statusController.add(const CoreStatus.waiting());
    expect((await service.reload('B.json', 'B', false).run()).isRight(), isTrue);
    expect(api.restarts, 1);
    expect(core.refreshes, 1);
  });

  test('failed restart does not refresh', () async {
    api.restartOutcome = () {
      service.statusController.add(const CoreStatus.starting());
      service.statusController.add(const CoreStatus.stopped(alert: CoreAlert.startService, message: 'failed'));
    };
    expect((await service.restart('B.json', 'B', false).run()).isLeft(), isTrue);
    expect(core.refreshes, 0);
  });

  test('stop during hot reload suppresses its late refresh', () async {
    final accepted = Completer<void>();
    final release = Completer<void>();
    api.beforeReloadReply = () async {
      accepted.complete();
      await release.future;
    };
    final reload = service.reload('B.json', 'B', false).run();
    await accepted.future;
    await service.stop().run();
    release.complete();
    await reload;
    expect(core.refreshes, 0);
  });

  test('cancelled restart does not refresh', () async {
    api.restartOutcome = () => unawaited(service.stop().run());
    await service.restart('B.json', 'B', false).run();
    expect(core.refreshes, 0);
  });
}

class _Interface extends CoreInterface {
  int refreshes = 0;
  bool failRefresh = false;
  @override
  Stream<CoreStatus>? get managedStatus => const Stream.empty();
  @override
  Future<bool> stop() async => true;
  @override
  Future<void> refreshServiceNotification() async {
    refreshes++;
    if (failRefresh) throw StateError('notification unavailable');
  }
}

class _Server extends Service {
  _Server() {
    $addMethod(
      ServiceMethod<StartRequest, CoreInfoResponse>(
        'HotReload',
        _reload,
        false,
        false,
        StartRequest.fromBuffer,
        (r) => r.writeToBuffer(),
      ),
    );
    $addMethod(
      ServiceMethod<StartRequest, CoreInfoResponse>(
        'Restart',
        _restart,
        false,
        false,
        StartRequest.fromBuffer,
        (r) => r.writeToBuffer(),
      ),
    );
  }
  MessageType reloadResult = MessageType.EMPTY;
  Future<void> Function()? beforeReloadReply;
  void Function()? restartOutcome;
  int restarts = 0;
  @override
  String get $name => 'hcore.Core';
  Future<CoreInfoResponse> _reload(ServiceCall call, Future<StartRequest> request) async {
    await request;
    await beforeReloadReply?.call();
    return CoreInfoResponse(messageType: reloadResult, coreState: CoreStates.WAITING);
  }

  Future<CoreInfoResponse> _restart(ServiceCall call, Future<StartRequest> request) async {
    await request;
    restarts++;
    restartOutcome?.call();
    return CoreInfoResponse(messageType: MessageType.EMPTY, coreState: CoreStates.STARTING);
  }
}
