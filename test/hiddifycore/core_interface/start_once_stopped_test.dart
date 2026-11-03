import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';

void main() {
  late Server server;
  late ClientChannel channel;
  late _Core core;

  Future<void> serve(int stillStopping) async {
    core = _Core(stillStopping);
    server = Server.create(services: [core]);
    await server.serve(address: '127.0.0.1', port: 0);
    channel = ClientChannel(
      '127.0.0.1',
      port: server.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
  }

  tearDown(() async {
    await channel.shutdown();
    await server.shutdown();
  });

  test('a start sent while the core still stops is sent again until it starts', () async {
    await serve(2);
    final response = await startOnceStopped(CoreClient(channel), StartRequest(configPath: 'p'));
    expect(response.messageType, MessageType.EMPTY);
    expect(core.starts, 3);
  });

  test('a core that never stops is given up on, with its answer', () async {
    await serve(1000);
    final response = await startOnceStopped(
      CoreClient(channel),
      StartRequest(configPath: 'p'),
      patience: const Duration(milliseconds: 400),
    );
    expect(response.messageType, MessageType.INSTANCE_NOT_STOPPED);
    expect(core.starts, lessThan(10));
  });
}

/// A core that refuses [stillStopping] starts, as one still stopping does, then starts.
class _Core extends Service {
  _Core(this.stillStopping) {
    $addMethod(
      ServiceMethod<StartRequest, CoreInfoResponse>(
        'Start',
        _start,
        false,
        false,
        StartRequest.fromBuffer,
        (response) => response.writeToBuffer(),
      ),
    );
  }

  final int stillStopping;
  int starts = 0;

  @override
  String get $name => 'hcore.Core';

  Future<CoreInfoResponse> _start(ServiceCall call, Future<StartRequest> request) async {
    await request;
    starts++;
    return starts <= stillStopping
        ? CoreInfoResponse(messageType: MessageType.INSTANCE_NOT_STOPPED)
        : CoreInfoResponse(messageType: MessageType.EMPTY);
  }
}
