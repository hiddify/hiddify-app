import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart' as common;
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS-capable urlTest enforces the 15-second gRPC deadline', () async {
    final probe = await _RunningProbe.open(supportsSystemStatus: true);
    addTearDown(probe.close);

    final request = probe.service.urlTest('synthetic').run();
    await probe.server.entered.future.timeout(const Duration(seconds: 3));
    final observed = await _observe(request, const Duration(seconds: 16));

    if (observed is _ProbeTimeout) {
      await probe.releaseAndDrain(request);
      fail('urlTest remained pending beyond the intended 15-second iOS deadline');
    }
    expect(observed, isA<GrpcError>());
    expect((observed! as GrpcError).code, StatusCode.deadlineExceeded);
  });

  test('non-iOS urlTest remains pending until the server releases it', () async {
    final probe = await _RunningProbe.open(supportsSystemStatus: false);
    addTearDown(probe.close);

    final request = probe.service.urlTest('synthetic').run();
    await probe.server.entered.future.timeout(const Duration(seconds: 3));
    final observed = await _observe(request, const Duration(milliseconds: 50));

    expect(observed, isA<_ProbeTimeout>());
    probe.server.release.complete();
    final result = await request;
    expect(result, isA<Right<String, Unit>>());
  });
}

Future<Object?> _observe(Future<Either<String, Unit>> request, Duration timeout) {
  final settled = request.then<Object?>((result) => result, onError: (Object error, StackTrace stackTrace) => error);
  return Future.any<Object?>([settled, Future<Object?>.delayed(timeout, _ProbeTimeout.new)]);
}

class _ProbeTimeout {
  const _ProbeTimeout();
}

class _HoldingUrlTestServer extends CoreServiceBase {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<common.Response> urlTest(ServiceCall call, UrlTestRequest request) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return common.Response(code: common.ResponseCode.OK);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProbeCore extends CoreInterface {
  _ProbeCore(this.client, {required this.systemStatusSupported}) {
    fgClient = client;
    bgClient = client;
  }

  final CoreClient client;
  final bool systemStatusSupported;

  @override
  bool get supportsSystemStatus => systemStatusSupported;
}

class _ProbeService extends HiddifyCoreService {
  _ProbeService(super.ref, this.probeCore);

  final CoreInterface probeCore;

  @override
  CoreInterface get core => probeCore;
}

class _RunningProbe {
  _RunningProbe({required this.container, required this.server, required this.channel, required this.service});

  final ProviderContainer container;
  final _HoldingUrlTestServer server;
  final ClientChannel channel;
  final _ProbeService service;

  static Future<_RunningProbe> open({required bool supportsSystemStatus}) async {
    final server = _HoldingUrlTestServer();
    final grpcServer = Server.create(services: [server]);
    await grpcServer.serve(address: InternetAddress.loopbackIPv4, port: 0);
    final channel = ClientChannel(
      '127.0.0.1',
      port: grpcServer.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    final core = _ProbeCore(CoreClient(channel), systemStatusSupported: supportsSystemStatus);
    final container = ProviderContainer();
    final service = _ProbeService(container.read(_refProvider), core);
    return _RunningProbe(container: container, server: server, channel: channel, service: service)
      .._grpcServer = grpcServer;
  }

  late final Server _grpcServer;

  Future<void> releaseAndDrain(Future<Either<String, Unit>> request) async {
    if (!server.release.isCompleted) server.release.complete();
    try {
      await request;
    } catch (_) {
      // The expected deadline error has already been observed by the test.
    }
  }

  Future<void> close() async {
    if (!server.release.isCompleted) server.release.complete();
    await service.statusController.close();
    await service.logController.close();
    await channel.shutdown();
    await _grpcServer.shutdown();
    container.dispose();
  }
}
