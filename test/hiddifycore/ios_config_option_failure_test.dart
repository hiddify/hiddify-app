import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/log/model/log_level.dart' as config_log_level;
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final class _SettingsEndpoint extends CoreServiceBase {
  _SettingsEndpoint({required this.unavailable});

  final bool unavailable;
  final received = <String>[];
  int calls = 0;

  @override
  Future<CoreInfoResponse> changeHiddifySettings(ServiceCall call, ChangeHiddifySettingsRequest request) async {
    calls++;
    if (unavailable) throw const GrpcError.unavailable('synthetic unavailable');
    received.add(request.hiddifySettingsJson);
    return CoreInfoResponse(messageType: MessageType.EMPTY);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ExternalCore extends CoreInterface {
  _ExternalCore({required this.ios, required CoreClient foreground, required CoreClient background}) {
    fgClient = foreground;
    bgClient = background;
  }

  final bool ios;

  @override
  bool get supportsSystemStatus => ios;
}

final class _Service extends HiddifyCoreService {
  _Service(super.ref, this.external);

  final CoreInterface external;

  @override
  CoreInterface get core => external;
}

final class _Fixture {
  _Fixture._(
    this.container,
    this.service,
    this.foreground,
    this.background,
    this.foregroundChannel,
    this.backgroundChannel,
    this.foregroundServer,
    this.backgroundServer,
  );

  static Future<_Fixture> create({
    required bool ios,
    required bool foregroundUnavailable,
    required bool backgroundUnavailable,
  }) async {
    final foreground = _SettingsEndpoint(unavailable: foregroundUnavailable);
    final background = _SettingsEndpoint(unavailable: backgroundUnavailable);
    final foregroundServer = Server.create(services: [foreground]);
    final backgroundServer = Server.create(services: [background]);
    await foregroundServer.serve(address: InternetAddress.loopbackIPv4, port: 0);
    await backgroundServer.serve(address: InternetAddress.loopbackIPv4, port: 0);
    final foregroundChannel = ClientChannel(
      InternetAddress.loopbackIPv4,
      port: foregroundServer.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    final backgroundChannel = ClientChannel(
      InternetAddress.loopbackIPv4,
      port: backgroundServer.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    final external = _ExternalCore(
      ios: ios,
      foreground: CoreClient(foregroundChannel),
      background: CoreClient(backgroundChannel),
    );
    final container = ProviderContainer();
    final service = container.read(Provider((ref) => _Service(ref, external)));
    return _Fixture._(
      container,
      service,
      foreground,
      background,
      foregroundChannel,
      backgroundChannel,
      foregroundServer,
      backgroundServer,
    );
  }

  final ProviderContainer container;
  final HiddifyCoreService service;
  final _SettingsEndpoint foreground;
  final _SettingsEndpoint background;
  final ClientChannel foregroundChannel;
  final ClientChannel backgroundChannel;
  final Server foregroundServer;
  final Server backgroundServer;

  Future<void> dispose() async {
    container.dispose();
    await service.statusController.close();
    await service.logController.close();
    await foregroundChannel.terminate();
    await backgroundChannel.terminate();
    await foregroundServer.shutdown();
    await backgroundServer.shutdown();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS rejects unavailable foreground settings instead of treating them as background absence', () async {
    final fixture = await _Fixture.create(ios: true, foregroundUnavailable: true, backgroundUnavailable: false);
    addTearDown(fixture.dispose);

    final result = await fixture.service.changeOptions(_options()).run();

    expect(result.isLeft(), isTrue);
    expect(fixture.foreground.calls, 1);
    expect(fixture.background.received, isEmpty);
  });

  test('iOS tolerates unavailable background settings before the tunnel starts', () async {
    final fixture = await _Fixture.create(ios: true, foregroundUnavailable: false, backgroundUnavailable: true);
    addTearDown(fixture.dispose);

    final result = await fixture.service.changeOptions(_options()).run();

    expect(result.isRight(), isTrue);
    expect(fixture.foreground.received, hasLength(1));
    expect(fixture.background.calls, 1);
    expect(fixture.background.received, isEmpty);
  });

  test('iOS sends identical settings to available foreground and background cores', () async {
    final fixture = await _Fixture.create(ios: true, foregroundUnavailable: false, backgroundUnavailable: false);
    addTearDown(fixture.dispose);
    final options = _options();
    final encoded = jsonEncode(options.toJson());

    final result = await fixture.service.changeOptions(options).run();

    expect(result.isRight(), isTrue);
    expect(fixture.foreground.calls, 1);
    expect(fixture.background.calls, 1);
    expect(fixture.foreground.received, [encoded]);
    expect(fixture.background.received, [encoded]);
  });

  test('non-iOS preserves unavailable foreground tolerance', () async {
    final fixture = await _Fixture.create(ios: false, foregroundUnavailable: true, backgroundUnavailable: false);
    addTearDown(fixture.dispose);

    final result = await fixture.service.changeOptions(_options()).run();

    expect(result.isRight(), isTrue);
    expect(fixture.foreground.calls, 1);
    expect(fixture.background.calls, 0);
    expect(fixture.background.received, isEmpty);
  });
}

SingboxConfigOption _options() {
  const range = OptionalRange();
  const warp = SingboxWarpOption(
    enable: false,
    mode: WarpDetourMode.proxyOverWarp,
    wireguardConfig: '',
    licenseKey: '',
    accountId: '',
    accessToken: '',
    cleanIp: '',
    cleanPort: 0,
    noise: range,
    noiseSize: range,
    noiseDelay: range,
    noiseMode: '',
  );
  const tls = SingboxTlsTricks(
    enableFragment: false,
    fragmentSize: range,
    fragmentSleep: range,
    mixedSniCase: false,
    enablePadding: false,
    paddingSize: range,
  );
  return SingboxConfigOption(
    region: 'synthetic',
    balancerStrategy: BalancerStrategy.roundRobin,
    blockAds: false,
    useXrayCoreWhenPossible: false,
    executeConfigAsIs: false,
    logLevel: config_log_level.LogLevel.warn,
    resolveDestination: false,
    ipv6Mode: IPv6Mode.disable,
    remoteDnsAddress: 'https://dns.example.invalid/dns-query',
    remoteDnsDomainStrategy: DomainStrategy.auto,
    directDnsAddress: 'https://direct-dns.example.invalid/dns-query',
    directDnsDomainStrategy: DomainStrategy.auto,
    mixedPort: 1234,
    tproxyPort: 1235,
    directPort: 1236,
    redirectPort: 1237,
    tunImplementation: TunImplementation.mixed,
    mtu: 1500,
    strictRoute: false,
    connectionTestUrl: 'https://probe.example.invalid/',
    urlTestInterval: const Duration(minutes: 1),
    enableClashApi: false,
    clashApiPort: 9090,
    enableTun: true,
    setSystemProxy: false,
    bypassLan: false,
    allowConnectionFromLan: false,
    enableFakeDns: false,
    independentDnsCache: false,
    rules: const [],
    tlsTricks: tls,
    warp: warp,
    warp2: warp,
  );
}
