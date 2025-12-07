import 'package:dartx/dartx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/core/utils/json_converters.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/config_option/model/config_option_failure.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_rule.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'config_option_repository.g.dart';

abstract class ConfigOptions {
  static final serviceMode = PreferencesNotifier.create<ServiceMode, String>(
    "service-mode",
    ServiceMode.defaultMode,
    mapFrom: (value) => ServiceMode.choices.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  static final region = PreferencesNotifier.create<Region, String>(
    "region",
    Region.other,
    mapFrom: Region.values.byName,
    mapTo: (value) => value.name,
  );
  static final blockAds = PreferencesNotifier.create<bool, bool>(
    "block-ads",
    false,
  );
  static final logLevel = PreferencesNotifier.create<LogLevel, String>(
    "log-level",
    LogLevel.warn,
    mapFrom: LogLevel.values.byName,
    mapTo: (value) => value.name,
  );

  static final resolveDestination = PreferencesNotifier.create<bool, bool>(
    "resolve-destination",
    false,
  );

  static final ipv6Mode = PreferencesNotifier.create<IPv6Mode, String>(
    "ipv6-mode",
    IPv6Mode.disable,
    mapFrom: (value) => IPv6Mode.values.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  static final remoteDnsAddress = PreferencesNotifier.create<String, String>(
    "remote-dns-address",
    "udp://1.1.1.1",
    possibleValues: List.of([
      "local",
      "udp://223.5.5.5",
      "udp://1.1.1.1",
      "udp://1.1.1.2",
      "tcp://1.1.1.1",
      "https://1.1.1.1/dns-query",
      "https://sky.rethinkdns.com/dns-query",
      "4.4.2.2",
      "8.8.8.8",
    ]),
    validator: (value) => value.isNotBlank,
  );

  static final remoteDnsDomainStrategy =
      PreferencesNotifier.create<DomainStrategy, String>(
        "remote-dns-domain-strategy",
        DomainStrategy.auto,
        mapFrom: (value) =>
            DomainStrategy.values.firstWhere((e) => e.key == value),
        mapTo: (value) => value.key,
      );

  static final directDnsAddress = PreferencesNotifier.create<String, String>(
    "direct-dns-address",
    "udp://1.1.1.1",
    possibleValues: List.of([
      "local",
      "udp://223.5.5.5",
      "udp://1.1.1.1",
      "udp://1.1.1.2",
      "tcp://1.1.1.1",
      "https://1.1.1.1/dns-query",
      "https://sky.rethinkdns.com/dns-query",
      "4.4.2.2",
      "8.8.8.8",
    ]),
    defaultValueFunction: (ref) =>
        ref.read(region) == Region.cn ? "223.5.5.5" : "1.1.1.1",
    validator: (value) => value.isNotBlank,
  );

  static final directDnsDomainStrategy =
      PreferencesNotifier.create<DomainStrategy, String>(
        "direct-dns-domain-strategy",
        DomainStrategy.auto,
        mapFrom: (value) =>
            DomainStrategy.values.firstWhere((e) => e.key == value),
        mapTo: (value) => value.key,
      );

  static final mixedPort = PreferencesNotifier.create<int, int>(
    "mixed-port",
    12334,
    validator: (value) => isPort(value.toString()),
  );

  static final tproxyPort = PreferencesNotifier.create<int, int>(
    "tproxy-port",
    12335,
    validator: (value) => isPort(value.toString()),
  );

  static final localDnsPort = PreferencesNotifier.create<int, int>(
    "local-dns-port",
    16450,
    validator: (value) => isPort(value.toString()),
  );

  static final tunImplementation =
      PreferencesNotifier.create<TunImplementation, String>(
        "tun-implementation",
        TunImplementation.gvisor,
        mapFrom: TunImplementation.values.byName,
        mapTo: (value) => value.name,
      );

  static final mtu = PreferencesNotifier.create<int, int>("mtu", 9000);

  static final strictRoute = PreferencesNotifier.create<bool, bool>(
    "strict-route",
    true,
  );

  static final connectionTestUrl = PreferencesNotifier.create<String, String>(
    "connection-test-url",
    "https://www.gstatic.com/generate_204",
    possibleValues: List.of([
      "https://www.gstatic.com/generate_204",
      "http://connectivitycheck.gstatic.com/generate_204",
      "http://www.gstatic.com/generate_204",
      "http://cp.cloudflare.com",
      "http://kernel.org",
      "http://detectportal.firefox.com",
      "http://captive.apple.com/hotspot-detect.html",
      "https://1.1.1.1",
      "http://1.1.1.1",
    ]),
    validator: (value) => value.isNotBlank && isUrl(value),
  );

  static final urlTestInterval = PreferencesNotifier.create<Duration, int>(
    "url-test-interval",
    const Duration(minutes: 10),
    mapFrom: const IntervalInSecondsConverter().fromJson,
    mapTo: const IntervalInSecondsConverter().toJson,
  );

  static final enableClashApi = PreferencesNotifier.create<bool, bool>(
    "enable-clash-api",
    true,
  );

  static final clashApiPort = PreferencesNotifier.create<int, int>(
    "clash-api-port",
    16756,
    validator: (value) => isPort(value.toString()),
  );

  static final clashApiSecret = PreferencesNotifier.create<String, String>(
    "clash-api-secret",
    "",
  );

  static final clashApiHost = PreferencesNotifier.create<String, String>(
    "clash-api-host",
    "127.0.0.1",
  );

  static final bypassLan = PreferencesNotifier.create<bool, bool>(
    "bypass-lan",
    false,
  );

  static final allowConnectionFromLan = PreferencesNotifier.create<bool, bool>(
    "allow-connection-from-lan",
    false,
  );

  static final enableFakeDns = PreferencesNotifier.create<bool, bool>(
    "enable-fake-dns",
    false,
  );

  static final enableDnsRouting = PreferencesNotifier.create<bool, bool>(
    "enable-dns-routing",
    true,
  );

  static final independentDnsCache = PreferencesNotifier.create<bool, bool>(
    "independent-dns-cache",
    true,
  );

  static final enableTlsFragment = PreferencesNotifier.create<bool, bool>(
    "enable-tls-fragment",
    false,
  );

  static final tlsFragmentSize =
      PreferencesNotifier.create<OptionalRange, String>(
        "tls-fragment-size",
        const OptionalRange(min: 10, max: 30),
        mapFrom: OptionalRange.parse,
        mapTo: const OptionalRangeJsonConverter().toJson,
      );

  static final tlsFragmentSleep =
      PreferencesNotifier.create<OptionalRange, String>(
        "tls-fragment-sleep",
        const OptionalRange(min: 2, max: 8),
        mapFrom: OptionalRange.parse,
        mapTo: const OptionalRangeJsonConverter().toJson,
      );

  static final enableTlsMixedSniCase = PreferencesNotifier.create<bool, bool>(
    "enable-tls-mixed-sni-case",
    false,
  );

  static final enableTlsPadding = PreferencesNotifier.create<bool, bool>(
    "enable-tls-padding",
    false,
  );

  static final tlsPaddingSize =
      PreferencesNotifier.create<OptionalRange, String>(
        "tls-padding-size",
        const OptionalRange(min: 1, max: 1500),
        mapFrom: OptionalRange.parse,
        mapTo: const OptionalRangeJsonConverter().toJson,
      );

  static final enableTlsEch = PreferencesNotifier.create<bool, bool>(
    "enable-tls-ech",
    false,
  );

  static final tlsEchConfig = PreferencesNotifier.create<String, String>(
    "tls-ech-config",
    "",
  );

  static final tlsEchConfigPath = PreferencesNotifier.create<String, String>(
    "tls-ech-config-path",
    "",
  );

  static final enableTlsReality = PreferencesNotifier.create<bool, bool>(
    "enable-tls-reality",
    false,
  );

  static final tlsRealityPublicKey = PreferencesNotifier.create<String, String>(
    "tls-reality-public-key",
    "",
  );

  static final tlsRealityShortId = PreferencesNotifier.create<String, String>(
    "tls-reality-short-id",
    "",
  );

  static final enableMux = PreferencesNotifier.create<bool, bool>(
    "enable-mux",
    false,
  );

  static final muxPadding = PreferencesNotifier.create<bool, bool>(
    "mux-padding",
    false,
  );

  static final muxMaxStreams = PreferencesNotifier.create<int, int>(
    "mux-max-streams",
    8,
    validator: (value) => value > 0,
  );

  static final muxProtocol = PreferencesNotifier.create<MuxProtocol, String>(
    "mux-protocol",
    MuxProtocol.h2mux,
    mapFrom: MuxProtocol.values.byName,
    mapTo: (value) => value.name,
  );

  static final enableWarp = PreferencesNotifier.create<bool, bool>(
    "enable-warp",
    false,
  );

  static final warpDetourMode =
      PreferencesNotifier.create<WarpDetourMode, String>(
        "warp-detour-mode",
        WarpDetourMode.proxyOverWarp,
        mapFrom: WarpDetourMode.values.byName,
        mapTo: (value) => value.name,
      );

  static final warpLicenseKey = PreferencesNotifier.create<String, String>(
    "warp-license-key",
    "",
  );
  static final warp2LicenseKey = PreferencesNotifier.create<String, String>(
    "warp2s-license-key",
    "",
  );

  static final warpAccountId = PreferencesNotifier.create<String, String>(
    "warp-account-id",
    "",
  );
  static final warp2AccountId = PreferencesNotifier.create<String, String>(
    "warp2-account-id",
    "",
  );

  static final warpAccessToken = PreferencesNotifier.create<String, String>(
    "warp-access-token",
    "",
  );
  static final warp2AccessToken = PreferencesNotifier.create<String, String>(
    "warp2-access-token",
    "",
  );

  static final warpCleanIp = PreferencesNotifier.create<String, String>(
    "warp-clean-ip",
    "auto",
  );

  static final warpPort = PreferencesNotifier.create<int, int>(
    "warp-port",
    0,
    validator: (value) => isPort(value.toString()),
  );

  static final warpNoise = PreferencesNotifier.create<OptionalRange, String>(
    "warp-noise",
    const OptionalRange(min: 1, max: 3),
    mapFrom: (value) => OptionalRange.parse(value, allowEmpty: true),
    mapTo: const OptionalRangeJsonConverter().toJson,
  );
  static final warpNoiseMode = PreferencesNotifier.create<String, String>(
    "warp-noise-mode",
    "m4",
  );

  static final warpNoiseDelay =
      PreferencesNotifier.create<OptionalRange, String>(
        "warp-noise-delay",
        const OptionalRange(min: 10, max: 30),
        mapFrom: (value) => OptionalRange.parse(value, allowEmpty: true),
        mapTo: const OptionalRangeJsonConverter().toJson,
      );
  static final warpNoiseSize =
      PreferencesNotifier.create<OptionalRange, String>(
        "warp-noise-size",
        const OptionalRange(min: 10, max: 30),
        mapFrom: (value) => OptionalRange.parse(value, allowEmpty: true),
        mapTo: const OptionalRangeJsonConverter().toJson,
      );

  static final warpWireguardConfig = PreferencesNotifier.create<String, String>(
    "warp-wireguard-config",
    "",
  );
  static final warp2WireguardConfig =
      PreferencesNotifier.create<String, String>("warp2-wireguard-config", "");

  static final enableMasque = PreferencesNotifier.create<bool, bool>(
    "masque.enable",
    false,
  );
  static final masqueServer = PreferencesNotifier.create<String, String>(
    "masque.server",
    "",
  );
  static final masquePort = PreferencesNotifier.create<int, int>(
    "masque.port",
    443,
    validator: (value) => isPort(value.toString()),
  );
  static final masqueServerName = PreferencesNotifier.create<String, String>(
    "masque.server-name",
    "",
  );
  static final masqueAuth = PreferencesNotifier.create<String, String>(
    "masque.auth",
    "",
  );

  /// preferences to exclude from share and export
  static final privatePreferencesKeys = {
    "warp.license-key",
    "warp.access-token",
    "warp.account-id",
    "warp.wireguard-config",
    "warp2.license-key",
    "warp2.access-token",
    "warp2.account-id",
    "warp2.wireguard-config",
    "masque.auth",
  };

  static final Map<
    String,
    NotifierProvider<PreferencesNotifier<dynamic, dynamic>, dynamic>
  >
  preferences = {
    "region": region,
    "block-ads": blockAds,
    "service-mode": serviceMode,
    "log-level": logLevel,
    "resolve-destination": resolveDestination,
    "ipv6-mode": ipv6Mode,
    "remote-dns-address": remoteDnsAddress,
    "remote-dns-domain-strategy": remoteDnsDomainStrategy,
    "direct-dns-address": directDnsAddress,
    "direct-dns-domain-strategy": directDnsDomainStrategy,
    "mixed-port": mixedPort,
    "tproxy-port": tproxyPort,
    "local-dns-port": localDnsPort,
    "tun-implementation": tunImplementation,
    "mtu": mtu,
    "strict-route": strictRoute,
    "connection-test-url": connectionTestUrl,
    "url-test-interval": urlTestInterval,
    "clash-api-port": clashApiPort,
    "bypass-lan": bypassLan,
    "allow-connection-from-lan": allowConnectionFromLan,
    "enable-dns-routing": enableDnsRouting,

    // mux
    "mux.enable": enableMux,
    "mux.padding": muxPadding,
    "mux.max-streams": muxMaxStreams,
    "mux.protocol": muxProtocol,

    // tls-tricks
    "tls-tricks.enable-fragment": enableTlsFragment,
    "tls-tricks.fragment-size": tlsFragmentSize,
    "tls-tricks.fragment-sleep": tlsFragmentSleep,
    "tls-tricks.mixed-sni-case": enableTlsMixedSniCase,
    "tls-tricks.enable-padding": enableTlsPadding,
    "tls-tricks.padding-size": tlsPaddingSize,
    "tls-tricks.enable-ech": enableTlsEch,
    "tls-tricks.ech-config": tlsEchConfig,
    "tls-tricks.ech-config-path": tlsEchConfigPath,
    "tls-tricks.enable-reality": enableTlsReality,
    "tls-tricks.reality-public-key": tlsRealityPublicKey,
    "tls-tricks.reality-short-id": tlsRealityShortId,

    // warp
    "warp.enable": enableWarp,
    "warp.mode": warpDetourMode,
    "warp.license-key": warpLicenseKey,
    "warp.account-id": warpAccountId,
    "warp.access-token": warpAccessToken,
    "warp.clean-ip": warpCleanIp,
    "warp.clean-port": warpPort,
    "warp.noise": warpNoise,
    "warp.noise-size": warpNoiseSize,
    "warp.noise-mode": warpNoiseMode,
    "warp.noise-delay": warpNoiseDelay,
    "warp.wireguard-config": warpWireguardConfig,
    "warp2.license-key": warp2LicenseKey,
    "warp2.account-id": warp2AccountId,
    "warp2.access-token": warp2AccessToken,
    "warp2.wireguard-config": warp2WireguardConfig,
    // masque
    "masque.enable": enableMasque,
    "masque.server": masqueServer,
    "masque.port": masquePort,
    "masque.server-name": masqueServerName,
    "masque.auth": masqueAuth,
  };
}

@riverpod
bool hasExperimentalFeatures(Ref ref) {
  return false;
}

@riverpod
Future<SingboxConfigOption> singboxConfigOption(Ref ref) async {
  final rules = <SingboxRule>[];
  final mode = ref.watch(ConfigOptions.serviceMode);

  return SingboxConfigOption(
    region: ref.watch(ConfigOptions.region).name,
    blockAds: ref.watch(ConfigOptions.blockAds),
    executeConfigAsIs: false,
    logLevel: ref.watch(ConfigOptions.logLevel),
    resolveDestination: ref.watch(ConfigOptions.resolveDestination),
    ipv6Mode: ref.watch(ConfigOptions.ipv6Mode),
    remoteDnsAddress: ref.watch(ConfigOptions.remoteDnsAddress),
    remoteDnsDomainStrategy: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
    directDnsAddress: ref.watch(ConfigOptions.directDnsAddress),
    directDnsDomainStrategy: ref.watch(ConfigOptions.directDnsDomainStrategy),
    mixedPort: ref.watch(ConfigOptions.mixedPort),
    tproxyPort: ref.watch(ConfigOptions.tproxyPort),
    localDnsPort: ref.watch(ConfigOptions.localDnsPort),
    tunImplementation: ref.watch(ConfigOptions.tunImplementation),
    mtu: ref.watch(ConfigOptions.mtu),
    strictRoute: ref.watch(ConfigOptions.strictRoute),
    connectionTestUrl: ref.watch(ConfigOptions.connectionTestUrl),
    urlTestInterval: ref.watch(ConfigOptions.urlTestInterval),
    enableClashApi: ref.watch(ConfigOptions.enableClashApi),
    clashApiPort: ref.watch(ConfigOptions.clashApiPort),
    clashApiSecret: ref.watch(ConfigOptions.clashApiSecret),
    clashApiHost: ref.watch(ConfigOptions.clashApiHost),
    enableTun: mode == ServiceMode.tun,
    enableTunService: mode == ServiceMode.tunService,
    setSystemProxy: mode == ServiceMode.systemProxy,
    bypassLan: ref.watch(ConfigOptions.bypassLan),
    allowConnectionFromLan: ref.watch(ConfigOptions.allowConnectionFromLan),
    enableFakeDns: ref.watch(ConfigOptions.enableFakeDns),
    enableDnsRouting: ref.watch(ConfigOptions.enableDnsRouting),
    independentDnsCache: ref.watch(ConfigOptions.independentDnsCache),
    mux: SingboxMuxOption(
      enable: ref.watch(ConfigOptions.enableMux),
      padding: ref.watch(ConfigOptions.muxPadding),
      maxStreams: ref.watch(ConfigOptions.muxMaxStreams),
      protocol: ref.watch(ConfigOptions.muxProtocol),
    ),
    tlsTricks: SingboxTlsTricks(
      enableFragment: ref.watch(ConfigOptions.enableTlsFragment),
      fragmentSize: ref.watch(ConfigOptions.tlsFragmentSize),
      fragmentSleep: ref.watch(ConfigOptions.tlsFragmentSleep),
      mixedSniCase: ref.watch(ConfigOptions.enableTlsMixedSniCase),
      enablePadding: ref.watch(ConfigOptions.enableTlsPadding),
      paddingSize: ref.watch(ConfigOptions.tlsPaddingSize),
      enableEch: ref.watch(ConfigOptions.enableTlsEch),
      echConfig: ref.watch(ConfigOptions.tlsEchConfig),
      echConfigPath: ref.watch(ConfigOptions.tlsEchConfigPath),
      enableReality: ref.watch(ConfigOptions.enableTlsReality),
      realityPublicKey: ref.watch(ConfigOptions.tlsRealityPublicKey),
      realityShortId: ref.watch(ConfigOptions.tlsRealityShortId),
    ),
    warp: SingboxWarpOption(
      enable: ref.watch(ConfigOptions.enableWarp),
      mode: ref.watch(ConfigOptions.warpDetourMode),
      wireguardConfig: ref.watch(ConfigOptions.warpWireguardConfig),
      licenseKey: ref.watch(ConfigOptions.warpLicenseKey),
      accountId: ref.watch(ConfigOptions.warpAccountId),
      accessToken: ref.watch(ConfigOptions.warpAccessToken),
      cleanIp: ref.watch(ConfigOptions.warpCleanIp),
      cleanPort: ref.watch(ConfigOptions.warpPort),
      noise: ref.watch(ConfigOptions.warpNoise),
      noiseMode: ref.watch(ConfigOptions.warpNoiseMode),
      noiseSize: ref.watch(ConfigOptions.warpNoiseSize),
      noiseDelay: ref.watch(ConfigOptions.warpNoiseDelay),
    ),
    warp2: SingboxWarpOption(
      enable: ref.watch(ConfigOptions.enableWarp),
      mode: ref.watch(ConfigOptions.warpDetourMode),
      wireguardConfig: ref.watch(ConfigOptions.warp2WireguardConfig),
      licenseKey: ref.watch(ConfigOptions.warp2LicenseKey),
      accountId: ref.watch(ConfigOptions.warp2AccountId),
      accessToken: ref.watch(ConfigOptions.warp2AccessToken),
      cleanIp: ref.watch(ConfigOptions.warpCleanIp),
      cleanPort: ref.watch(ConfigOptions.warpPort),
      noise: ref.watch(ConfigOptions.warpNoise),
      noiseMode: ref.watch(ConfigOptions.warpNoiseMode),
      noiseSize: ref.watch(ConfigOptions.warpNoiseSize),
      noiseDelay: ref.watch(ConfigOptions.warpNoiseDelay),
    ),
    masque: SingboxMasqueOption(
      enable: ref.watch(ConfigOptions.enableMasque),
      server: ref.watch(ConfigOptions.masqueServer),
      port: ref.watch(ConfigOptions.masquePort),
      serverName: ref.watch(ConfigOptions.masqueServerName),
      auth: ref.watch(ConfigOptions.masqueAuth),
      alpn: const ["h3"],
    ),
    geoRulesBaseUrl: "https://raw.githubusercontent.com/hiddify/hiddify-geo",
    rules: rules,
  );
}

class ConfigOptionRepository with ExceptionHandler, InfraLogger {
  ConfigOptionRepository({
    required this.preferences,
    required this.getConfigOptions,
  });

  final SharedPreferences preferences;
  final Future<SingboxConfigOption> Function() getConfigOptions;

  TaskEither<ConfigOptionFailure, SingboxConfigOption>
  getFullSingboxConfigOption() {
    return exceptionHandler(() async {
      return right(await getConfigOptions());
    }, ConfigOptionUnexpectedFailure.new);
  }
}
