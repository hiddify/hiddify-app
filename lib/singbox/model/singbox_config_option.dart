import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/utils/json_converters.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

part 'singbox_config_option.freezed.dart';
part 'singbox_config_option.g.dart';

@freezed
class SingboxConfigOption with _$SingboxConfigOption {
  const SingboxConfigOption._();

  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxConfigOption({
    required String region,
    required BalancerStrategy balancerStrategy,
    @Default(DefaultProxy.balance) DefaultProxy defaultProxy,
    // required bool blockAds,
    required bool useXrayCoreWhenPossible,
    @Default(true) bool useSystemTlsEngine,
    required bool executeConfigAsIs,
    required LogLevel logLevel,
    required bool resolveDestination,
    required IPv6Mode ipv6Mode,
    required String remoteDnsAddress,
    required DomainStrategy remoteDnsDomainStrategy,
    required String directDnsAddress,
    required DomainStrategy directDnsDomainStrategy,
    required int mixedPort,
    required int tproxyPort,
    required int directPort,
    required int redirectPort,
    required bool enableMixedPort,
    required bool enableTproxyPort,
    required bool enableDirectPort,
    required bool enableRedirectPort,
    required TunImplementation tunImplementation,
    required int mtu,
    required bool strictRoute,
    required String connectionTestUrl,

    /// Subscription `ipinfo-url` override — custom ipapi-compatible geolocation endpoint.
    String? ipinfoUrl,

    /// The profile's `keep-top`: how many of its proxies the core keeps running, the fastest; -1
    /// for all of them.
    @Default(-1) int keepTop,

    /// The profile's proxies the user chose to run, and only them (`keep-tags`).
    @Default(<String>[]) List<String> keepTags,
    @IntervalInSecondsConverter() required Duration urlTestInterval,
    required bool enableClashApi,
    required int clashApiPort,
    required bool enableTun,
    // required bool enableTunService,
    required bool setSystemProxy,
    // required bool bypassLan,
    required bool allowConnectionFromLan,
    required String lanSharingPassword,
    required int lanSharingPort,
    required bool localProxyAuth,
    required bool localProxyInVpn,
    required bool enableFakeDns,
    // required bool enableDnsRouting,
    required bool independentDnsCache,
    required Map<String, dynamic> routeRule,
    // required SingboxMuxOption mux,
    required SingboxTlsTricks tlsTricks,
    required ChainStatus chainStatus,
    required SingboxExtraSecurityOption extraSecurity,
    required SingboxUnblockerOption unblocker,
  }) = _SingboxConfigOption;

  String format() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  factory SingboxConfigOption.fromJson(Map<String, dynamic> json) => _$SingboxConfigOptionFromJson(json);
}

@freezed
class SingboxExtraSecurityOption with _$SingboxExtraSecurityOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxExtraSecurityOption({
    // the core's key (ChainMode.coreKey): a WARP hop's names its tunnel
    required String mode,
    required SingboxExtraSecurityWarpOption warp,
    required SingboxExtraSecurityPsiphonOption psiphon,
    required SingboxExtraSecurityProfileOption profile,
  }) = _SingboxExtraSecurityOption;

  factory SingboxExtraSecurityOption.fromJson(Map<String, dynamic> json) => _$SingboxExtraSecurityOptionFromJson(json);
}

@freezed
class SingboxUnblockerOption with _$SingboxUnblockerOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxUnblockerOption({
    // the core's key (ChainMode.coreKey): a WARP hop's names its tunnel
    required String mode,
    required SingboxUnblockerWarpOption warp,
    required SingboxUnblockerPsiphonOption psiphon,
    required SingboxUnblockerProfileOption profile,
  }) = _SingboxUnblockerOption;

  factory SingboxUnblockerOption.fromJson(Map<String, dynamic> json) => _$SingboxUnblockerOptionFromJson(json);
}

/// The endpoint scan of a WARP hop. Zero and empty keep the scanner's own defaults.
@freezed
class SingboxWarpScannerOption with _$SingboxWarpScannerOption {
  const SingboxWarpScannerOption._();

  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxWarpScannerOption({
    // tries the noise presets until one gets through, and remembers it for the network
    @Default(true) bool searchNoise,
    // milliseconds
    @Default(0) int maxRtt,
    @Default(0) int timeout,
    @Default(0) int count,
    @Default(0) int concurrency,
    // empty: the tunnel's own ports and Cloudflare's ranges
    @Default(<int>[]) List<int> ports,
    @Default(<String>[]) List<String> cidrs,
  }) = _SingboxWarpScannerOption;

  /// Null when it changes nothing, so the core keeps its own defaults.
  SingboxWarpScannerOption? get orNull => this == const SingboxWarpScannerOption() ? null : this;

  factory SingboxWarpScannerOption.fromJson(Map<String, dynamic> json) => _$SingboxWarpScannerOptionFromJson(json);
}

/// The MASQUE tunnel of a WARP hop (the masque and auto tunnels).
@freezed
class SingboxWarpMasqueOption with _$SingboxWarpMasqueOption {
  const SingboxWarpMasqueOption._();

  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxWarpMasqueOption({
    // auto (HTTP/3, falling back to HTTP/2), h3 or h2; a hop behind a detour runs h2 anyway
    @Default('auto') String vhttp,
    @Default('') String serverName,
    @Default(false) bool useIpv6,
    // seconds
    @Default(0) int udpTimeout,
    @Default(0) int udpKeepalive,
    @Default(0) int udpInitialPacketSize,
    @Default(0) int reconnectDelay,
    @Default(false) bool tlsInsecure,
    @Default(false) bool tlsFragment,
    // milliseconds
    @Default(0) int tlsFragmentFallbackDelay,
    @Default(false) bool tlsRecordFragment,
    @Default(false) bool echEnabled,
    @Default('') String echConfig,
    @Default('') String echQueryServerName,
  }) = _SingboxWarpMasqueOption;

  /// Null when it changes nothing, so the core keeps its own defaults.
  SingboxWarpMasqueOption? get orNull => this == const SingboxWarpMasqueOption() ? null : this;

  factory SingboxWarpMasqueOption.fromJson(Map<String, dynamic> json) => _$SingboxWarpMasqueOptionFromJson(json);
}

/// The AmneziaWG tunnel of a WARP hop (the awg and auto tunnels). All zero keeps the core's preset.
@freezed
class SingboxWarpAwgOption with _$SingboxWarpAwgOption {
  const SingboxWarpAwgOption._();

  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxWarpAwgOption({
    @Default(0) int jc,
    @Default(0) int jmin,
    @Default(0) int jmax,
    @Default(0) int s1,
    @Default(0) int s2,
    @Default(0) int s3,
    @Default(0) int s4,
    @Default('') String h1,
    @Default('') String h2,
    @Default('') String h3,
    @Default('') String h4,
    @Default('') String i1,
    @Default('') String i2,
    @Default('') String i3,
    @Default('') String i4,
    @Default('') String i5,
  }) = _SingboxWarpAwgOption;

  /// Null when it changes nothing, so the core keeps its own preset.
  SingboxWarpAwgOption? get orNull => this == const SingboxWarpAwgOption() ? null : this;

  factory SingboxWarpAwgOption.fromJson(Map<String, dynamic> json) => _$SingboxWarpAwgOptionFromJson(json);
}

@freezed
class SingboxExtraSecurityWarpOption with _$SingboxExtraSecurityWarpOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxExtraSecurityWarpOption({
    required String licenseKey,
    // extra security dials through the user's pick, so it never scans (see WarpEndpointSource.of)
    @Default(WarpEndpointSource.profile) WarpEndpointSource endpoint,
    @Default('') String cleanIp,
    @Default(0) int cleanPort,
    // 0: the tunnel's own, smaller inside another proxy
    @Default(0) int mtu,
    SingboxWarpMasqueOption? masque,
    SingboxWarpAwgOption? awg,
  }) = _SingboxExtraSecurityWarpOption;

  factory SingboxExtraSecurityWarpOption.fromJson(Map<String, dynamic> json) =>
      _$SingboxExtraSecurityWarpOptionFromJson(json);
}

@freezed
class SingboxUnblockerWarpOption with _$SingboxUnblockerWarpOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxUnblockerWarpOption({
    required String licenseKey,
    @Default(WarpEndpointSource.scan) WarpEndpointSource endpoint,
    required String cleanIp,
    required int cleanPort,
    // 0: the tunnel's own
    @Default(0) int mtu,
    SingboxWarpScannerOption? scanner,
    SingboxWarpMasqueOption? masque,
    SingboxWarpAwgOption? awg,
    @OptionalRangeJsonConverter() required OptionalRange noise,
    @OptionalRangeJsonConverter() required OptionalRange noiseSize,
    @OptionalRangeJsonConverter() required OptionalRange noiseDelay,
    required String noiseMode,
  }) = _SingboxUnblockerWarpOption;

  factory SingboxUnblockerWarpOption.fromJson(Map<String, dynamic> json) => _$SingboxUnblockerWarpOptionFromJson(json);
}

@freezed
class SingboxExtraSecurityPsiphonOption with _$SingboxExtraSecurityPsiphonOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxExtraSecurityPsiphonOption({required PsiphonRegion region, required String conduitPairingId}) =
      _SingboxExtraSecurityPsiphonOption;

  factory SingboxExtraSecurityPsiphonOption.fromJson(Map<String, dynamic> json) =>
      _$SingboxExtraSecurityPsiphonOptionFromJson(json);
}

@freezed
class SingboxUnblockerPsiphonOption with _$SingboxUnblockerPsiphonOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxUnblockerPsiphonOption({required PsiphonRegion region, required String conduitPairingId}) =
      _SingboxUnblockerPsiphonOption;

  factory SingboxUnblockerPsiphonOption.fromJson(Map<String, dynamic> json) =>
      _$SingboxUnblockerPsiphonOptionFromJson(json);
}

@freezed
class SingboxExtraSecurityProfileOption with _$SingboxExtraSecurityProfileOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxExtraSecurityProfileOption({required String? id}) = _SingboxExtraSecurityProfileOption;

  factory SingboxExtraSecurityProfileOption.fromJson(Map<String, dynamic> json) =>
      _$SingboxExtraSecurityProfileOptionFromJson(json);
}

@freezed
class SingboxUnblockerProfileOption with _$SingboxUnblockerProfileOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxUnblockerProfileOption({required String? id}) = _SingboxUnblockerProfileOption;

  factory SingboxUnblockerProfileOption.fromJson(Map<String, dynamic> json) =>
      _$SingboxUnblockerProfileOptionFromJson(json);
}

// @freezed
// class SingboxMuxOption with _$SingboxMuxOption {
//   @JsonSerializable(fieldRename: FieldRename.kebab)
//   const factory SingboxMuxOption({
//     required bool enable,
//     required bool padding,
//     required int maxStreams,
//     required MuxProtocol protocol,
//   }) = _SingboxMuxOption;

//   factory SingboxMuxOption.fromJson(Map<String, dynamic> json) => _$SingboxMuxOptionFromJson(json);
// }

@freezed
class SingboxTlsTricks with _$SingboxTlsTricks {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxTlsTricks({
    required bool enableFragment,
    @OptionalRangeJsonConverter() required OptionalRange fragmentSize,
    @OptionalRangeJsonConverter() required OptionalRange fragmentSleep,
    required bool mixedSniCase,
    required bool enablePadding,
    @OptionalRangeJsonConverter() required OptionalRange paddingSize,
  }) = _SingboxTlsTricks;

  factory SingboxTlsTricks.fromJson(Map<String, dynamic> json) => _$SingboxTlsTricksFromJson(json);
}
