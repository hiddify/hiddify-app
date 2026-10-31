import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/grpc_stream_cancel.dart';

/// A core whose log stream never ends and keeps sending, like the real one at trace level.
class _ChattyCore extends CoreServiceBase {
  @override
  Stream<LogMessage> logListener(ServiceCall call, LogRequest request) async* {
    final line = 'x' * 1000;
    while (!call.isCanceled) {
      yield LogMessage(message: line);
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<CoreInfoResponse> stop(ServiceCall call, Empty request) async =>
      CoreInfoResponse(coreState: CoreStates.STOPPING);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late Server server;
  late ClientChannel channel;
  late CoreClient client;

  setUp(() async {
    server = Server.create(services: [_ChattyCore()]);
    await server.serve(address: '127.0.0.1', port: 0);
    channel = ClientChannel(
      '127.0.0.1',
      port: server.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    client = CoreClient(channel);
  });

  tearDown(() async {
    await channel.terminate();
    await server.shutdown();
  });

  // The macOS proxy-mode hang: the app re-listened to the log stream twice in a row on every
  // connect, cancelling the first subscription before its call was ready. That call stayed open
  // unread, its data filled the connection's 64 KB window, and Stop then never got an answer.
  test('a stream cancelled before it is ready does not stall the channel', () async {
    for (var i = 0; i < 3; i++) {
      final subscription = client.logListener(LogRequest()).cancelOnUnsubscribe.listen((_) {});
      await subscription.cancel();
    }
    // time for an orphaned stream, if any, to fill the window
    await Future<void>.delayed(const Duration(seconds: 1));

    final response = await client.stop(Empty()).timeout(const Duration(seconds: 3));
    expect(response.coreState, CoreStates.STOPPING);
  });

  test('a stream that is read stays usable', () async {
    final messages = await client.logListener(LogRequest()).cancelOnUnsubscribe.take(200).toList();
    expect(messages, hasLength(200));
    final response = await client.stop(Empty()).timeout(const Duration(seconds: 3));
    expect(response.coreState, CoreStates.STOPPING);
  });
}
