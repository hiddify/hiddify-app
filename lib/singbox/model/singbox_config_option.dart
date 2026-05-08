import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/utils/json_converters.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_rule.dart';

part 'singbox_config_option.freezed.dart';
part 'singbox_config_option.g.dart';

@freezed
class SingboxConfigOption with _$SingboxConfigOption {
  const SingboxConfigOption._();

  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxConfigOption({
    required String region,
    required BalancerStrategy balancerStrategy,
    required bool blockAds,
    required bool useXrayCoreWhenPossible,
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
    required TunImplementation tunImplementation,
    required int mtu,
    required bool strictRoute,
    required String connectionTestUrl,
    @IntervalInSecondsConverter() required Duration urlTestInterval,
    required bool enableClashApi,
    required int clashApiPort,
    required bool enableTun,
    // required bool enableTunService,
    required bool setSystemProxy,
    required bool bypassLan,
    required bool allowConnectionFromLan,
    required bool enableFakeDns,
    // required bool enableDnsRouting,
    required bool independentDnsCache,
    required List<SingboxRule> rules,
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
    required ChainMode mode,
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
    required ChainMode mode,
    required SingboxUnblockerWarpOption warp,
    required SingboxUnblockerPsiphonOption psiphon,
    required SingboxUnblockerProfileOption profile,
  }) = _SingboxUnblockerOption;

  factory SingboxUnblockerOption.fromJson(Map<String, dynamic> json) => _$SingboxUnblockerOptionFromJson(json);
}

@freezed
class SingboxExtraSecurityWarpOption with _$SingboxExtraSecurityWarpOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxExtraSecurityWarpOption({required String licenseKey}) = _SingboxExtraSecurityWarpOption;

  factory SingboxExtraSecurityWarpOption.fromJson(Map<String, dynamic> json) =>
      _$SingboxExtraSecurityWarpOptionFromJson(json);
}

@freezed
class SingboxUnblockerWarpOption with _$SingboxUnblockerWarpOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxUnblockerWarpOption({
    required String licenseKey,
    required String cleanIp,
    required int cleanPort,
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
  const factory SingboxExtraSecurityPsiphonOption({required PsiphonRegion region}) = _SingboxExtraSecurityPsiphonOption;

  factory SingboxExtraSecurityPsiphonOption.fromJson(Map<String, dynamic> json) =>
      _$SingboxExtraSecurityPsiphonOptionFromJson(json);
}

@freezed
class SingboxUnblockerPsiphonOption with _$SingboxUnblockerPsiphonOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxUnblockerPsiphonOption({required PsiphonRegion region}) = _SingboxUnblockerPsiphonOption;

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
