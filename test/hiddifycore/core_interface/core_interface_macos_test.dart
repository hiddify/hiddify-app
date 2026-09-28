import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_macos.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:path/path.dart' as p;

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

  group('VPN resource snapshots', () {
    late Directory workingDirectory;
    late File profile;

    setUp(() async {
      workingDirectory = await Directory.systemTemp.createTemp('hiddify-vpn-resources-');
      profile = File(p.join(workingDirectory.path, 'configs', 'profile.json'));
      await profile.parent.create(recursive: true);
      core = CoreInterfaceMacOS.withForegroundClient(CoreClient(channel), {
        'available': true,
        'status': 'disconnected',
      }, workingDirectory: workingDirectory);
    });

    tearDown(() async {
      await workingDirectory.delete(recursive: true);
    });

    for (final hasProfileRelativeCopy in [false, true]) {
      test('relative certificates use the core working directory (duplicate: $hasProfileRelativeCopy)', () async {
        final certificate = File(p.join(workingDirectory.path, 'certs', 'ca.pem'));
        await certificate.parent.create(recursive: true);
        await certificate.writeAsString('working directory certificate');
        if (hasProfileRelativeCopy) {
          final duplicate = File(p.join(profile.parent.path, 'certs', 'ca.pem'));
          await duplicate.parent.create(recursive: true);
          await duplicate.writeAsString('wrong profile directory certificate');
        }
        await profile.writeAsString(
          jsonEncode({
            'tls': {'certificate_path': 'certs/ca.pem'},
          }),
        );

        final (content, resources) = await core!.snapshotConfiguration(profile.path);
        final document = jsonDecode(content) as Map<String, dynamic>;

        expect(document['tls'], {'certificate_path': 'resources/0-ca.pem'});
        expect(utf8.decode(resources['0-ca.pem']!), 'working directory certificate');
      });
    }

    test('local rule sets and absolute resources retain their path semantics', () async {
      final ruleSet = File(p.join(workingDirectory.path, 'rules', 'local.srs'));
      await ruleSet.parent.create(recursive: true);
      await ruleSet.writeAsBytes([0, 1, 255]);
      final key = File(p.join(workingDirectory.path, 'client.key'));
      await key.writeAsString('absolute client key');
      await profile.writeAsString(
        jsonEncode({
          'route': {
            'rule_set': [
              {'type': 'local', 'path': './rules/local.srs'},
            ],
          },
          'tls': {'key_path': key.path},
        }),
      );

      final (content, resources) = await core!.snapshotConfiguration(profile.path);
      final document = jsonDecode(content) as Map<String, dynamic>;

      expect(document['route'], {
        'rule_set': [
          {'type': 'local', 'path': 'resources/0-local.srs'},
        ],
      });
      expect(document['tls'], {'key_path': 'resources/1-client.key'});
      expect(resources['0-local.srs'], [0, 1, 255]);
      expect(utf8.decode(resources['1-client.key']!), 'absolute client key');
    });

    test('a profile-relative resource cannot substitute for a missing working-directory resource', () async {
      final duplicate = File(p.join(profile.parent.path, 'certs', 'ca.pem'));
      await duplicate.parent.create(recursive: true);
      await duplicate.writeAsString('wrong profile directory certificate');
      await profile.writeAsString(
        jsonEncode({
          'tls': {'certificate_path': 'certs/ca.pem'},
        }),
      );

      await expectLater(
        core!.snapshotConfiguration(profile.path),
        throwsA(
          isA<FileSystemException>().having(
            (error) => error.path,
            'path',
            p.join(workingDirectory.path, 'certs', 'ca.pem'),
          ),
        ),
      );
    });
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
