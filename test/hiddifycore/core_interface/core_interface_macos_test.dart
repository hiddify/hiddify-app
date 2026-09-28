import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_macos.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('com.hiddify.app/macos-vpn');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> operations;
  late Server server;
  late ClientChannel channel;
  CoreInterfaceMacOS? core;

  setUp(() async {
    operations = [];
    server = Server.create(services: [_ForegroundService(operations)]);
    await server.serve(address: '127.0.0.1', port: 0);
    channel = ClientChannel(
      '127.0.0.1',
      port: server.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    messenger.setMockMethodCallHandler(methods, (call) {
      operations.add('native.${call.method}');
      return Future<Object?>.value({'available': true, 'status': 'disconnected'});
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(methods, null);
    await core?.dispose();
    core = null;
    await channel.shutdown();
    await server.shutdown();
  });

  test('stop disables a saved disconnected VPN before stopping the foreground core', () async {
    core = CoreInterfaceMacOS.withForegroundClient(CoreClient(channel), {'available': true, 'status': 'disconnected'});
    expect(core!.persistsAfterAppExit, isFalse);

    expect(await core!.stop(), isTrue);

    expect(operations, ['native.stop', 'foreground.stop']);
    expect(await core!.managedStatus.first, const CoreStatus.stopped());
  });

  test('stop remains available in Debug builds without the VPN extension', () async {
    core = CoreInterfaceMacOS.withForegroundClient(CoreClient(channel), {'available': false, 'status': 'disconnected'});

    expect(await core!.stop(), isTrue);

    expect(operations, ['foreground.stop']);
  });

  test('a native stop failure is propagated before stopping the foreground core', () async {
    core = CoreInterfaceMacOS.withForegroundClient(CoreClient(channel), {'available': true, 'status': 'disconnected'});
    messenger.setMockMethodCallHandler(methods, (call) {
      operations.add('native.${call.method}');
      return Future<Object?>.error(PlatformException(code: 'MACOS_VPN', message: 'Unable to save VPN preferences.'));
    });

    await expectLater(core!.stop(), throwsA(isA<PlatformException>()));

    expect(operations, ['native.stop']);
  });
}

class _ForegroundService extends Service {
  _ForegroundService(this.operations) {
    $addMethod(
      ServiceMethod<Empty, CoreInfoResponse>(
        'Stop',
        _stop,
        false,
        false,
        Empty.fromBuffer,
        (response) => response.writeToBuffer(),
      ),
    );
  }

  final List<String> operations;

  @override
  String get $name => 'hcore.Core';

  Future<CoreInfoResponse> _stop(ServiceCall call, Future<Empty> request) async {
    await request;
    operations.add('foreground.stop');
    return CoreInfoResponse(messageType: MessageType.ALREADY_STOPPED);
  }
}
