import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';

void main() {
  late Server server;
  late ClientChannel channel;

  Future<void> serve(List<CoreInfoResponse> afterStart, {CoreInfoResponse? before}) async {
    server = Server.create(services: [_Core(afterStart, before: before)]);
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

  // Start is answered as soon as it is queued; a start that fails afterwards (its port in use) was a
  // connect that worked, with no core behind it.
  test('a start that fails after its answer is a failure', () async {
    await serve([
      CoreInfoResponse(coreState: CoreStates.STARTING),
      CoreInfoResponse(coreState: CoreStates.STOPPED, messageType: MessageType.START_SERVICE, message: 'port in use'),
    ]);
    final outcome = await startAndConfirm(CoreClient(channel), StartRequest(configPath: 'p'));
    expect(outcome.coreState, CoreStates.STOPPED);
    expect(outcome.messageType, MessageType.START_SERVICE);
    expect(outcome.message, 'port in use');
  });

  test('a start that comes up is waited for', () async {
    await serve([CoreInfoResponse(coreState: CoreStates.STARTING), CoreInfoResponse(coreState: CoreStates.WAITING)]);
    final outcome = await startAndConfirm(CoreClient(channel), StartRequest(configPath: 'p'));
    expect(outcome.coreState, CoreStates.WAITING);
    expect(outcome.messageType, MessageType.EMPTY);
  });

  // a new listener is told the state before the start: that STOPPED is not the start's outcome
  test('the STOPPED a listener is told first is not the outcome', () async {
    await serve([
      CoreInfoResponse(coreState: CoreStates.STARTING),
      CoreInfoResponse(coreState: CoreStates.STARTED),
    ], before: CoreInfoResponse(coreState: CoreStates.STOPPED, messageType: MessageType.START_SERVICE));
    final outcome = await startAndConfirm(CoreClient(channel), StartRequest(configPath: 'p'));
    expect(outcome.coreState, CoreStates.STARTED);
  });
}

/// A core whose status stream first tells [before], and after a Start the [afterStart] states.
class _Core extends Service {
  _Core(this.afterStart, {this.before}) {
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
    $addMethod(
      ServiceMethod<Empty, CoreInfoResponse>(
        'CoreInfoListener',
        _listen,
        false,
        true,
        Empty.fromBuffer,
        (response) => response.writeToBuffer(),
      ),
    );
  }

  final List<CoreInfoResponse> afterStart;
  final CoreInfoResponse? before;
  final _states = StreamController<CoreInfoResponse>.broadcast();

  @override
  String get $name => 'hcore.Core';

  Future<CoreInfoResponse> _start(ServiceCall call, Future<StartRequest> request) async {
    await request;
    // answered at once; the outcome follows on the status stream
    Timer(const Duration(milliseconds: 50), () => afterStart.forEach(_states.add));
    return CoreInfoResponse(messageType: MessageType.EMPTY);
  }

  Stream<CoreInfoResponse> _listen(ServiceCall call, Future<Empty> request) async* {
    await request;
    if (before != null) yield before!;
    yield* _states.stream;
  }
}
