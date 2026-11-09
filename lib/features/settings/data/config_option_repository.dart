import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/core/utils/json_converters.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/features/settings/model/config_option_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConfigOptions {
  static final serviceMode = PreferencesNotifier.create<ServiceMode, String>(
    "service-mode",
    ServiceMode.defaultMode,
    // a mode this build does not offer (system proxy, saved before the Mac App Store build) is
    // the default again
    mapFrom: (value) => ServiceMode.choices.firstWhere((e) => e.key == value, orElse: () => ServiceMode.defaultMode),
    mapTo: (value) => value.key,
  );

  static final balancerStrategy = PreferencesNotifier.create<BalancerStrategy, String>(
    "balancer-strategy",
    BalancerStrategy.roundRobin,
    mapFrom: (value) => BalancerStrategy.values.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  static final defaultProxy = PreferencesNotifier.create<DefaultProxy, String>(
    "default-proxy",
    DefaultProxy.balance,
    mapFrom: (value) => DefaultProxy.values.firstWhere((e) => e.key == value, orElse: () => DefaultProxy.balance),
    mapTo: (value) => value.key,
  );

  static final region = PreferencesNotifier.create<Region, String>(
    "region",
    Region.other,
    mapFrom: Region.values.byName,
    mapTo: (value) => value.name,
  );
  static final useSystemTlsEngine = PreferencesNotifier.create<bool, bool>("use-system-tls-engine", true);
  // static final blockAds = PreferencesNotifier.create<bool, bool>("block-ads", false);
  static final logLevel = PreferencesNotifier.create<LogLevel, String>(
    "log-level",
    LogLevel.warn,
    mapFrom: LogLevel.values.byName,
    mapTo: (value) => value.name,
  );

  static final resolveDestination = PreferencesNotifier.create<bool, bool>("resolve-destination", false);

  static final ipv6Mode = PreferencesNotifier.create<IPv6Mode, String>(
    "ipv6-mode",
    IPv6Mode.ipv4Only,
    mapFrom: IPv6Mode.fromKey,
    mapTo: (value) => value.key,
  );

  static final remoteDnsAddress = PreferencesNotifier.create<String, String>(
    "remote-dns-address",
    "tcp://8.8.8.8",
    possibleValues: List.of([
      "local",
      // "udp://223.5.5.5",
      // "udp://1.1.1.1",
      // "udp://1.1.1.2",
      "tcp://8.8.8.8",
      "tcp://1.1.1.1",
      "https://1.1.1.1/dns-query",
      "https://dns.cloudflare.com/dns-query",
      "tcp://4.4.2.2",
    ]),
    validator: (value) => value.isNotBlank,
  );

  static final remoteDnsDomainStrategy = PreferencesNotifier.create<DomainStrategy, String>(
    "remote-dns-domain-strategy",
    DomainStrategy.auto,
    mapFrom: (value) => DomainStrategy.values.firstWhere((e) => e.key == value),
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
      "https://dns.cloudflare.com/dns-query",
      "4.4.2.2",
      "8.8.8.8",
    ]),
    defaultValueFunction: (ref) => ref.read(region) == Region.cn ? "223.5.5.5" : "1.1.1.1",
    validator: (value) => value.isNotBlank,
  );

  static final directDnsDomainStrategy = PreferencesNotifier.create<DomainStrategy, String>(
    "direct-dns-domain-strategy",
    DomainStrategy.auto,
    mapFrom: (value) => DomainStrategy.values.firstWhere((e) => e.key == value),
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
  static final redirectPort = PreferencesNotifier.create<int, int>(
    "redirect-port",
    12336,
    validator: (value) => isPort(value.toString()),
  );
  static final directPort = PreferencesNotifier.create<int, int>(
    "direct-port",
    12337,
    validator: (value) => isPort(value.toString()),
  );

  static final enableMixedPort = PreferencesNotifier.create<bool, bool>("enable-mixed-port", true);
  // the transparent ports serve setups made by hand (a Linux gateway, pf rules): off until asked for
  static final enableTproxyPort = PreferencesNotifier.create<bool, bool>("enable-tproxy-port", false);
  static final enableRedirectPort = PreferencesNotifier.create<bool, bool>("enable-redirect-port", false);
  static final enableDirectPort = PreferencesNotifier.create<bool, bool>("enable-direct-port", false);

  static final tunImplementation = PreferencesNotifier.create<TunImplementation, String>(
    "tun-implementation",
    TunImplementation.sing15,
    mapFrom: TunImplementation.values.byName,
    mapTo: (value) => value.name,
  );

  static final mtu = PreferencesNotifier.create<int, int>("mtu", 9000);

  static final strictRoute = PreferencesNotifier.create<bool, bool>("strict-route", true);

  static final connectionTestUrl = PreferencesNotifier.create<String, String>(
    "connection-test-url",
    "http://captive.apple.com/hotspot-detect.html",
    possibleValues: List.of([
      "http://connectivitycheck.gstatic.com/generate_204",
      "http://www.gstatic.com/generate_204",
      "https://www.gstatic.com/generate_204",
      "https://redirector.googlevideo.com/generate_204",
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

  /// How many megabytes an upload test sends through each proxy.
  static final uploadTestSize = PreferencesNotifier.create<int, int>("upload-test-size", 1);

  /// How many proxies a speed test of the list tests, the fastest by their ping; 0 for all of them.
  static final uploadTestLimit = PreferencesNotifier.create<int, int>("upload-test-limit", 20);

  /// Whether a speed test measures download or upload.
  static final speedTestDirection = PreferencesNotifier.create<SpeedTestDirection, String>(
    "speed-test-direction",
    SpeedTestDirection.upload,
    mapFrom: (value) =>
        SpeedTestDirection.values.firstWhere((e) => e.name == value, orElse: () => SpeedTestDirection.upload),
    mapTo: (value) => value.name,
  );

  static final enableClashApi = PreferencesNotifier.create<bool, bool>("enable-clash-api", true);

  static final clashApiPort = PreferencesNotifier.create<int, int>(
    "clash-api-port",
    16756,
    validator: (value) => isPort(value.toString()),
  );

  // static final bypassLan = PreferencesNotifier.create<bool, bool>("bypass-lan", false);

  static final allowConnectionFromLan = PreferencesNotifier.create<bool, bool>("allow-connection-from-lan", false);

  static final lanSharingPassword = PreferencesNotifier.create<String, String>("lan_sharing_password", "");

  /// The port the local network uses while the VPN is shared, apart from this device's own (the
  /// mixed port), always asking for the secret.
  static final lanSharingPort = PreferencesNotifier.create<int, int>(
    "lan-sharing-port",
    12338,
    validator: (value) => isPort(value.toString()),
  );

  /// Whether the local port asks for the secret too; off by default, as browsers can not send a
  /// SOCKS5 password. Never as the system proxy, which can not pass one.
  static final localProxyAuth = PreferencesNotifier.create<bool, bool>("local-proxy-auth", false);

  /// Whether the local port stays open in VPN mode, where every app already goes through the VPN.
  static final localProxyInVpn = PreferencesNotifier.create<bool, bool>("local-proxy-in-vpn", false);

  /// Whether picking proxy mode no longer shows how apps are pointed at it; the home page's Manual
  /// tab still does.
  static final hideLocalProxyOnPick = PreferencesNotifier.create<bool, bool>("hide-local-proxy-on-pick", false);

  static final enableFakeDns = PreferencesNotifier.create<bool, bool>("enable-fake-dns", false);

  // static final enableDnsRouting = PreferencesNotifier.create<bool, bool>("enable-dns-routing", true);

  static final independentDnsCache = PreferencesNotifier.create<bool, bool>("independent-dns-cache", true);

  static final enableTlsFragment = PreferencesNotifier.create<bool, bool>("enable-tls-fragment", false);

  static final fragmentPackets = PreferencesNotifier.create<String, String>(
    "fragment-packets",
    "tlshello",
    possibleValues: ["tlshello", "1-1", "1-2", "1-3", "1-4", "1-5"],
  );

  static final tlsFragmentSize = PreferencesNotifier.create<OptionalRange, String>(
    "tls-fragment-size",
    const OptionalRange(min: 10, max: 30),
    mapFrom: OptionalRange.parse,
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  static final tlsFragmentSleep = PreferencesNotifier.create<OptionalRange, String>(
    "tls-fragment-sleep",
    const OptionalRange(min: 2, max: 8),
    mapFrom: OptionalRange.parse,
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  static final enableTlsMixedSniCase = PreferencesNotifier.create<bool, bool>("enable-tls-mixed-sni-case", false);

  static final enableTlsPadding = PreferencesNotifier.create<bool, bool>("enable-tls-padding", false);

  static final tlsPaddingSize = PreferencesNotifier.create<OptionalRange, String>(
    "tls-padding-size",
    const OptionalRange(min: 1, max: 1500),
    mapFrom: OptionalRange.parse,
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  static final enableMux = PreferencesNotifier.create<bool, bool>("enable-mux", false);

  static final muxPadding = PreferencesNotifier.create<bool, bool>("mux-padding", false);

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

  static final chainStatus = PreferencesNotifier.create<ChainStatus, String>(
    "chain-status",
    ChainStatus.off,
    mapFrom: ChainStatus.values.byName,
    mapTo: (value) => value.name,
  );

  static final extraSecurityPsiphonRegion = PreferencesNotifier.create<PsiphonRegion, String>(
    "extra-security-psiphon-region",
    PsiphonRegion.auto,
    mapFrom: PsiphonRegion.values.byName,
    mapTo: (value) => value.name,
  );

  static final extraSecurityPsiphonConduitPairingId = PreferencesNotifier.create<String, String>(
    "extra-security-psiphon-conduit-pairing-id",
    "",
  );

  static final unblockerPsiphonRegion = PreferencesNotifier.create<PsiphonRegion, String>(
    "unblocker-psiphon-region",
    PsiphonRegion.auto,
    mapFrom: PsiphonRegion.values.byName,
    mapTo: (value) => value.name,
  );

  static final unblockerPsiphonConduitPairingId = PreferencesNotifier.create<String, String>(
    "unblocker-psiphon-conduit-pairing-id",
    "",
  );

  static final extraSecurityMode = PreferencesNotifier.create<ChainMode, String>(
    "extra-security-mode",
    ChainMode.warp,
    mapFrom: (value) => ChainMode.fromStored(value, ChainMode.warp),
    mapTo: (value) => value.name,
  );

  static final unblockerMode = PreferencesNotifier.create<ChainMode, String>(
    "unblocker-mode",
    ChainMode.psiphon,
    mapFrom: (value) => ChainMode.fromStored(value, ChainMode.psiphon),
    mapTo: (value) => value.name,
  );

  static final extraSecurityProfileId = PreferencesNotifier.create<String?, String?>(
    "extra-security-profile-id",
    null,
    mapFrom: (value) => value,
    mapTo: (value) => value,
  );
  static final unblockerProfileId = PreferencesNotifier.create<String?, String?>(
    "unblocker-profile-id",
    null,
    mapFrom: (value) => value,
    mapTo: (value) => value,
  );

  static final extraSecurityWarpLicenseKey = PreferencesNotifier.create<String, String>(
    "extra-security-warp-license-key",
    "",
  );

  static final extraSecurityWarpTunnel = PreferencesNotifier.create<WarpTunnel, String>(
    "extra-security-warp-tunnel",
    WarpTunnel.auto,
    mapFrom: (value) => WarpTunnel.values.asNameMap()[value] ?? WarpTunnel.auto,
    mapTo: (value) => value.name,
  );

  static final extraSecurityWarpMtu = PreferencesNotifier.create<int, int>("extra-security-warp-mtu", 0);

  static final unblockerWarpLicenseKey = PreferencesNotifier.create<String, String>("unblocker-warp-license-key", "");

  static final unblockerWarpTunnel = PreferencesNotifier.create<WarpTunnel, String>(
    "unblocker-warp-tunnel",
    WarpTunnel.auto,
    mapFrom: (value) => WarpTunnel.values.asNameMap()[value] ?? WarpTunnel.auto,
    mapTo: (value) => value.name,
  );

  // The unblocker's WARP is all auto by default: the scanner finds an endpoint that answers, and
  // with no noise set it also finds the noise that gets through, remembered per network. A value
  // set here is used as given. The clean IP and port are the custom endpoint's; an older clean IP
  // that also chose the source is moved to the source (PreferencesVersion3Migration).
  static final unblockerWarpEndpoint = _warpEndpoint("unblocker-warp-endpoint", WarpEndpointSource.scan);

  static final unblockerWarpCleanIp = PreferencesNotifier.create<String, String>("unblocker-warp-clean-ip", "");

  static final unblockerWarpMtu = PreferencesNotifier.create<int, int>("unblocker-warp-mtu", 0);

  static final unblockerWarpScanner = _warpBlock(
    "unblocker-warp-scanner",
    const SingboxWarpScannerOption(),
    SingboxWarpScannerOption.fromJson,
    (value) => value.toJson(),
  );

  static final unblockerWarpMasque = _warpBlock(
    "unblocker-warp-masque",
    const SingboxWarpMasqueOption(),
    SingboxWarpMasqueOption.fromJson,
    (value) => value.toJson(),
  );

  static final unblockerWarpAwg = _warpBlock(
    "unblocker-warp-awg",
    const SingboxWarpAwgOption(),
    SingboxWarpAwgOption.fromJson,
    (value) => value.toJson(),
  );

  static final unblockerWarpPort = PreferencesNotifier.create<int, int>(
    "unblocker-warp-port",
    0,
    validator: (value) => isPort(value.toString()),
  );

  static final unblockerWarpNoise = PreferencesNotifier.create<OptionalRange, String>(
    "unblocker-warp-noise",
    const OptionalRange(),
    mapFrom: (value) => OptionalRange.parse(value, allowEmpty: true),
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  static final unblockerWarpNoiseMode = PreferencesNotifier.create<String, String>("unblocker-warp-noise-mode", "");

  static final unblockerWarpNoiseDelay = PreferencesNotifier.create<OptionalRange, String>(
    "unblocker-warp-noise-delay",
    const OptionalRange(),
    mapFrom: (value) => OptionalRange.parse(value, allowEmpty: true),
    mapTo: const OptionalRangeJsonConverter().toJson,
  );
  static final unblockerWarpNoiseSize = PreferencesNotifier.create<OptionalRange, String>(
    "unblocker-warp-noise-size",
    const OptionalRange(),
    mapFrom: (value) => OptionalRange.parse(value, allowEmpty: true),
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  /// The WARP settings of each hop, so one panel edits either.
  // Extra security is a privacy layer behind the user's pick, not a way past filtering: the tunnel,
  // the licence and the MTU are all it offers. It takes the endpoint Cloudflare assigned (scanning
  // through a proxy only measures the proxy) and the core's MASQUE and AmneziaWG defaults.
  static final extraSecurityWarp = WarpHopPreferences(
    detour: true,
    tunnel: extraSecurityWarpTunnel,
    licenseKey: extraSecurityWarpLicenseKey,
    mtu: extraSecurityWarpMtu,
  );

  static final unblockerWarp = WarpHopPreferences(
    detour: false,
    tunnel: unblockerWarpTunnel,
    licenseKey: unblockerWarpLicenseKey,
    endpoint: unblockerWarpEndpoint,
    cleanIp: unblockerWarpCleanIp,
    cleanPort: unblockerWarpPort,
    mtu: unblockerWarpMtu,
    scanner: unblockerWarpScanner,
    masque: unblockerWarpMasque,
    awg: unblockerWarpAwg,
    noise: unblockerWarpNoise,
    noiseMode: unblockerWarpNoiseMode,
    noiseSize: unblockerWarpNoiseSize,
    noiseDelay: unblockerWarpNoiseDelay,
  );

  static final hasExperimentalFeatures = Provider.autoDispose<bool>((ref) {
    // final mode = ref.watch(serviceMode);
    // if (PlatformUtils.isDesktop && mode == ServiceMode.tun) {
    //   return true;
    // }
    // if (ref.watch(enableTlsFragment) || ref.watch(enableTlsMixedSniCase) || ref.watch(enableTlsPadding) || ref.watch(enableMux) || ref.watch(enableWarp) || ref.watch(bypassLan) || ref.watch(allowConnectionFromLan)) {
    //   return true;
    // }

    return false;
  });

  /// preferences to exclude from share and export
  static final privatePreferencesKeys = {
    "extra-security.warp.license-key",
    "unblocker.warp.license-key",
    "lan-sharing-password",
  };

  static final Map<String, StateNotifierProvider<PreferencesNotifier, dynamic>> preferences = {
    "region": region,
    "balancer-strategy": balancerStrategy,
    "default-proxy": defaultProxy,
    // "block-ads": blockAds,
    "use-system-tls-engine": useSystemTlsEngine,
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
    "direct-port": directPort,
    "redirect-port": redirectPort,
    "enable-mixed-port": enableMixedPort,
    "enable-tproxy-port": enableTproxyPort,
    "enable-direct-port": enableDirectPort,
    "enable-redirect-port": enableRedirectPort,
    "tun-implementation": tunImplementation,
    "mtu": mtu,
    "strict-route": strictRoute,
    "connection-test-url": connectionTestUrl,
    "url-test-interval": urlTestInterval,
    "upload-test-size": uploadTestSize,
    "upload-test-limit": uploadTestLimit,
    "speed-test-direction": speedTestDirection,
    "clash-api-port": clashApiPort,
    // "bypass-lan": bypassLan,
    "allow-connection-from-lan": allowConnectionFromLan,
    "lan-sharing-password": lanSharingPassword,
    "lan-sharing-port": lanSharingPort,
    "local-proxy-auth": localProxyAuth,
    "local-proxy-in-vpn": localProxyInVpn,
    // "enable-dns-routing": enableDnsRouting,

    // mux
    // "mux.enable": enableMux,
    // "mux.padding": muxPadding,
    // "mux.max-streams": muxMaxStreams,
    // "mux.protocol": muxProtocol,

    // tls-tricks
    "tls-tricks.enable-fragment": enableTlsFragment,
    "tls-tricks.fragment-packets": fragmentPackets,
    "tls-tricks.fragment-size": tlsFragmentSize,
    "tls-tricks.fragment-sleep": tlsFragmentSleep,
    "tls-tricks.mixed-sni-case": enableTlsMixedSniCase,
    "tls-tricks.enable-padding": enableTlsPadding,
    "tls-tricks.padding-size": tlsPaddingSize,

    // EXTRA-SECURITY
    // warp
    "extra-security.warp.license-key": extraSecurityWarpLicenseKey,
    "extra-security.warp.tunnel": extraSecurityWarpTunnel,
    "extra-security.warp.mtu": extraSecurityWarpMtu,
    // psiphon
    "extra-security.psiphon.region": extraSecurityPsiphonRegion,
    "extra-security.psiphon.conduit-pairing-id": extraSecurityPsiphonConduitPairingId,
    // profile
    "extra-security.profile.id": extraSecurityProfileId,

    // UNBLOCKER
    // warp
    "unblocker.warp.license-key": unblockerWarpLicenseKey,
    "unblocker.warp.tunnel": unblockerWarpTunnel,
    "unblocker.warp.endpoint": unblockerWarpEndpoint,
    "unblocker.warp.clean-ip": unblockerWarpCleanIp,
    "unblocker.warp.clean-port": unblockerWarpPort,
    "unblocker.warp.noise": unblockerWarpNoise,
    "unblocker.warp.noise-size": unblockerWarpNoiseSize,
    "unblocker.warp.noise-mode": unblockerWarpNoiseMode,
    "unblocker.warp.noise-delay": unblockerWarpNoiseDelay,
    "unblocker.warp.mtu": unblockerWarpMtu,
    "unblocker.warp.scanner": unblockerWarpScanner,
    "unblocker.warp.masque": unblockerWarpMasque,
    "unblocker.warp.awg": unblockerWarpAwg,
    // psiphon
    "unblocker.psiphon.region": unblockerPsiphonRegion,
    "unblocker.psiphon.conduit-pairing-id": unblockerPsiphonConduitPairingId,
    // profile
    "unblocker.profile.id": unblockerProfileId,
  };

  static final singboxConfigOptions = Provider<SingboxConfigOption>((ref) {
    // final region = ref.watch(Preferences.region);
    // final rules = <SingboxRule>[];
    // final rules = switch (region) {
    //   Region.ir => [
    //       const SingboxRule(
    //         domains: "domain:.ir,geosite:ir",
    //         ip: "geoip:ir",
    //         outbound: RuleOutbound.bypass,
    //       ),
    //     ],
    //   Region.cn => [
    //       const SingboxRule(
    //         domains: "domain:.cn,geosite:cn",
    //         ip: "geoip:cn",
    //         outbound: RuleOutbound.bypass,
    //       ),
    //     ],
    //   Region.ru => [
    //       const SingboxRule(
    //         domains: "domain:.ru",
    //         ip: "geoip:ru",
    //         outbound: RuleOutbound.bypass,
    //       ),
    //     ],
    //   Region.af => [
    //       const SingboxRule(
    //         domains: "domain:.af,geosite:af",
    //         ip: "geoip:af",
    //         outbound: RuleOutbound.bypass,
    //       ),
    //     ],
    //   Region.id => [
    //       const SingboxRule(
    //         domains: "domain:.id,geosite:id",
    //         ip: "geoip:id",
    //         outbound: RuleOutbound.bypass,
    //       ),
    //     ],
    //   _ => <SingboxRule>[],
    // };

    final mode = ref.watch(serviceMode);
    // final reg = ref.watch(Preferences.region.notifier).raw();
    return SingboxConfigOption(
      region: ref.watch(region).name,
      balancerStrategy: ref.watch(balancerStrategy),
      defaultProxy: ref.watch(defaultProxy),
      // blockAds: ref.watch(blockAds),
      useSystemTlsEngine: ref.watch(useSystemTlsEngine),
      executeConfigAsIs: false,
      logLevel: ref.watch(logLevel),
      resolveDestination: ref.watch(resolveDestination),
      ipv6Mode: ref.watch(ipv6Mode),
      remoteDnsAddress: ref.watch(remoteDnsAddress),
      remoteDnsDomainStrategy: ref.watch(remoteDnsDomainStrategy),
      directDnsAddress: ref.watch(directDnsAddress),
      directDnsDomainStrategy: ref.watch(directDnsDomainStrategy),
      mixedPort: ref.watch(mixedPort),
      tproxyPort: ref.watch(tproxyPort),
      directPort: ref.watch(directPort),
      redirectPort: ref.watch(redirectPort),
      enableMixedPort: ref.watch(enableMixedPort),
      enableTproxyPort: ref.watch(enableTproxyPort),
      enableDirectPort: ref.watch(enableDirectPort),
      enableRedirectPort: ref.watch(enableRedirectPort),
      tunImplementation: ref.watch(tunImplementation),
      mtu: ref.watch(mtu),
      strictRoute: ref.watch(strictRoute),
      connectionTestUrl: ref.watch(connectionTestUrl),
      urlTestInterval: ref.watch(urlTestInterval),
      enableClashApi: ref.watch(enableClashApi),
      clashApiPort: ref.watch(clashApiPort),
      enableTun: mode == ServiceMode.tun || mode == ServiceMode.router,
      routerMode: mode == ServiceMode.router,
      // enableTunService: mode == false, //ServiceMode.tunService,
      setSystemProxy: mode == ServiceMode.systemProxy,
      // bypassLan: ref.watch(bypassLan),
      allowConnectionFromLan: ref.watch(allowConnectionFromLan),
      lanSharingPassword: ref.watch(lanSharingPassword),
      lanSharingPort: ref.watch(lanSharingPort),
      localProxyAuth: ref.watch(localProxyAuth),
      localProxyInVpn: ref.watch(localProxyInVpn),
      enableFakeDns: ref.watch(enableFakeDns),
      // enableDnsRouting: ref.watch(enableDnsRouting),
      independentDnsCache: ref.watch(independentDnsCache),
      // mux: SingboxMuxOption(
      //   enable: ref.watch(enableMux),
      //   padding: ref.watch(muxPadding),
      //   maxStreams: ref.watch(muxMaxStreams),
      //   protocol: ref.watch(muxProtocol),
      // ),
      tlsTricks: SingboxTlsTricks(
        enableFragment: ref.watch(enableTlsFragment),
        fragmentSize: ref.watch(tlsFragmentSize),
        fragmentSleep: ref.watch(tlsFragmentSleep),
        mixedSniCase: ref.watch(enableTlsMixedSniCase),
        enablePadding: ref.watch(enableTlsPadding),
        paddingSize: ref.watch(tlsPaddingSize),
      ),
      chainStatus: ref.watch(chainStatus),
      extraSecurity: SingboxExtraSecurityOption(
        mode: ref.watch(extraSecurityMode).coreKey(ref.watch(extraSecurityWarpTunnel)),
        warp: SingboxExtraSecurityWarpOption(
          licenseKey: ref.watch(extraSecurityWarpLicenseKey),
          mtu: ref.watch(extraSecurityWarpMtu),
        ),
        psiphon: SingboxExtraSecurityPsiphonOption(
          region: ref.watch(extraSecurityPsiphonRegion),
          conduitPairingId: ref.watch(extraSecurityPsiphonConduitPairingId),
        ),
        profile: SingboxExtraSecurityProfileOption(id: ref.watch(extraSecurityProfileId)),
      ),
      unblocker: SingboxUnblockerOption(
        mode: ref.watch(unblockerMode).coreKey(ref.watch(unblockerWarpTunnel)),
        warp: SingboxUnblockerWarpOption(
          licenseKey: ref.watch(unblockerWarpLicenseKey),
          endpoint: ref.watch(unblockerWarpEndpoint),
          cleanIp: ref.watch(unblockerWarpCleanIp),
          cleanPort: ref.watch(unblockerWarpPort),
          mtu: ref.watch(unblockerWarpMtu),
          scanner: ref.watch(unblockerWarpScanner).orNull,
          masque: ref.watch(unblockerWarpMasque).orNull,
          awg: ref.watch(unblockerWarpAwg).orNull,
          noise: ref.watch(unblockerWarpNoise),
          noiseMode: ref.watch(unblockerWarpNoiseMode),
          noiseSize: ref.watch(unblockerWarpNoiseSize),
          noiseDelay: ref.watch(unblockerWarpNoiseDelay),
        ),
        psiphon: SingboxUnblockerPsiphonOption(
          region: ref.watch(unblockerPsiphonRegion),
          conduitPairingId: ref.watch(unblockerPsiphonConduitPairingId),
        ),
        profile: SingboxUnblockerProfileOption(id: ref.watch(unblockerProfileId)),
      ),
      routeRule: RouteRule(rules: ref.watch(rulesNotifierProvider)).toProto3Json()! as Map<String, dynamic>,
    );
  });
}

class ConfigOptionRepository with ExceptionHandler, InfraLogger {
  ConfigOptionRepository({required this.preferences, required SingboxConfigOption Function() getConfigOptions})
    : _getConfigOptions = getConfigOptions;

  final SharedPreferences preferences;
  final SingboxConfigOption Function() _getConfigOptions;

  Either<ConfigOptionFailure, SingboxConfigOption> fullOptions() =>
      Either.tryCatch(() => _getConfigOptions(), ConfigOptionFailure.unexpected);

  /// The settings as the core gets them: the user's own, with the profile's override (its headers
  /// and the user's per-profile choices) on top, except what extra security rules out.
  Either<ConfigOptionFailure, SingboxConfigOption> fullOptionsOverrided(String? profileOverride) =>
      Either.tryCatch(() => _getConfigOptions(), ConfigOptionFailure.unexpected).flatMap(
        (options) => Either.tryCatch(() {
          final own = options.toJson();
          final merged = ProfileParser.applyProfileOverride(options.toJson(), profileOverride);
          return SingboxConfigOption.fromJson(keepOwnDnsBehindExtraSecurity(own, merged));
        }, ConfigOptionFailure.unexpected),
      );

  /// Behind extra security the remote DNS answers through the hop, which a profile's own resolver
  /// was never meant for. So whenever extra security is on when connecting, from the user's
  /// settings or from the profile itself, the profile's remote DNS is not applied and the user's
  /// own stays; the core adds DoH through the profile alone as the group's last resort.
  @visibleForTesting
  static Map<String, dynamic> keepOwnDnsBehindExtraSecurity(Map<String, dynamic> own, Map<String, dynamic> merged) {
    if (merged['chain-status'] != ChainStatus.extraSecurity.key) return merged;
    return {...merged, 'remote-dns-address': own['remote-dns-address']};
  }
}

typedef _Preference<T, P> = StateNotifierProvider<PreferencesNotifier<T, P>, T>;

_Preference<WarpEndpointSource, String> _warpEndpoint(String key, WarpEndpointSource byDefault) =>
    PreferencesNotifier.create<WarpEndpointSource, String>(
      key,
      byDefault,
      mapFrom: (value) => WarpEndpointSource.values.asNameMap()[value] ?? byDefault,
      mapTo: (value) => value.name,
    );

/// A WARP block kept as its JSON, so each field the core reads is editable without a preference
/// of its own. A value that no longer reads (an older build's) is the default again, not an error.
_Preference<T, String> _warpBlock<T>(
  String key,
  T byDefault,
  T Function(Map<String, dynamic>) fromJson,
  Map<String, dynamic> Function(T) toJson,
) => PreferencesNotifier.create<T, String>(
  key,
  byDefault,
  mapFrom: (value) {
    if (value.isEmpty) return byDefault;
    try {
      return fromJson((jsonDecode(value) as Map).cast<String, dynamic>());
    } catch (_) {
      return byDefault;
    }
  },
  mapTo: (value) => jsonEncode(toJson(value)),
);

/// The WARP settings of one chain hop, for the panel that edits them. [detour]: the hop dials
/// through the user's pick (extra security), so it never scans. The scanner and noise belong to
/// the unblocker alone.
class WarpHopPreferences {
  const WarpHopPreferences({
    required this.detour,
    required this.tunnel,
    required this.licenseKey,
    required this.mtu,
    this.endpoint,
    this.cleanIp,
    this.cleanPort,
    this.masque,
    this.awg,
    this.scanner,
    this.noise,
    this.noiseMode,
    this.noiseSize,
    this.noiseDelay,
  });

  final bool detour;
  final _Preference<WarpTunnel, String> tunnel;
  final _Preference<String, String> licenseKey;
  final _Preference<int, int> mtu;
  // null: the hop does not offer it, and the core's default applies
  final _Preference<WarpEndpointSource, String>? endpoint;
  final _Preference<String, String>? cleanIp;
  final _Preference<int, int>? cleanPort;
  final _Preference<SingboxWarpMasqueOption, String>? masque;
  final _Preference<SingboxWarpAwgOption, String>? awg;
  final _Preference<SingboxWarpScannerOption, String>? scanner;
  final _Preference<OptionalRange, String>? noise;
  final _Preference<String, String>? noiseMode;
  final _Preference<OptionalRange, String>? noiseSize;
  final _Preference<OptionalRange, String>? noiseDelay;
}
