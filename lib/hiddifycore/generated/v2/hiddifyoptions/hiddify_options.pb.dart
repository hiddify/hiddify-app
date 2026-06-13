// This is a generated file - do not edit.
//
// Generated from v2/hiddifyoptions/hiddify_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'hiddify_options.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'hiddify_options.pbenum.dart';

/// *
///  HiddifyOptions defines the configuration options for the Hiddify application.
class HiddifyOptions extends $pb.GeneratedMessage {
  factory HiddifyOptions({
    $core.bool? enableFullConfig,
    $core.String? logLevel,
    $core.String? logFile,
    $core.bool? enableClashApi,
    $core.int? clashApiPort,
    $core.String? webSecret,
    $core.String? region,
    $core.bool? blockAds,
    $core.bool? useXrayCoreWhenPossible,
    $core.Iterable<Rule>? rules,
    WarpOptions? warp,
    WarpOptions? warp2,
    MuxOptions? mux,
    TLSTricks? tlsTricks,
    DNSOptions? dnsOptions,
    InboundOptions? inboundOptions,
    URLTestOptions? urlTestOptions,
    RouteOptions? routeOptions,
  }) {
    final result = create();
    if (enableFullConfig != null) result.enableFullConfig = enableFullConfig;
    if (logLevel != null) result.logLevel = logLevel;
    if (logFile != null) result.logFile = logFile;
    if (enableClashApi != null) result.enableClashApi = enableClashApi;
    if (clashApiPort != null) result.clashApiPort = clashApiPort;
    if (webSecret != null) result.webSecret = webSecret;
    if (region != null) result.region = region;
    if (blockAds != null) result.blockAds = blockAds;
    if (useXrayCoreWhenPossible != null)
      result.useXrayCoreWhenPossible = useXrayCoreWhenPossible;
    if (rules != null) result.rules.addAll(rules);
    if (warp != null) result.warp = warp;
    if (warp2 != null) result.warp2 = warp2;
    if (mux != null) result.mux = mux;
    if (tlsTricks != null) result.tlsTricks = tlsTricks;
    if (dnsOptions != null) result.dnsOptions = dnsOptions;
    if (inboundOptions != null) result.inboundOptions = inboundOptions;
    if (urlTestOptions != null) result.urlTestOptions = urlTestOptions;
    if (routeOptions != null) result.routeOptions = routeOptions;
    return result;
  }

  HiddifyOptions._();

  factory HiddifyOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HiddifyOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HiddifyOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enableFullConfig')
    ..aOS(2, _omitFieldNames ? '' : 'logLevel')
    ..aOS(3, _omitFieldNames ? '' : 'logFile')
    ..aOB(4, _omitFieldNames ? '' : 'enableClashApi')
    ..aI(5, _omitFieldNames ? '' : 'clashApiPort',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'webSecret')
    ..aOS(7, _omitFieldNames ? '' : 'region')
    ..aOB(8, _omitFieldNames ? '' : 'blockAds')
    ..aOB(9, _omitFieldNames ? '' : 'useXrayCoreWhenPossible')
    ..pPM<Rule>(10, _omitFieldNames ? '' : 'rules', subBuilder: Rule.create)
    ..aOM<WarpOptions>(11, _omitFieldNames ? '' : 'warp',
        subBuilder: WarpOptions.create)
    ..aOM<WarpOptions>(12, _omitFieldNames ? '' : 'warp2',
        subBuilder: WarpOptions.create)
    ..aOM<MuxOptions>(13, _omitFieldNames ? '' : 'mux',
        subBuilder: MuxOptions.create)
    ..aOM<TLSTricks>(14, _omitFieldNames ? '' : 'tlsTricks',
        subBuilder: TLSTricks.create)
    ..aOM<DNSOptions>(15, _omitFieldNames ? '' : 'dnsOptions',
        subBuilder: DNSOptions.create)
    ..aOM<InboundOptions>(16, _omitFieldNames ? '' : 'inboundOptions',
        subBuilder: InboundOptions.create)
    ..aOM<URLTestOptions>(17, _omitFieldNames ? '' : 'urlTestOptions',
        subBuilder: URLTestOptions.create)
    ..aOM<RouteOptions>(18, _omitFieldNames ? '' : 'routeOptions',
        subBuilder: RouteOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HiddifyOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HiddifyOptions copyWith(void Function(HiddifyOptions) updates) =>
      super.copyWith((message) => updates(message as HiddifyOptions))
          as HiddifyOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HiddifyOptions create() => HiddifyOptions._();
  @$core.override
  HiddifyOptions createEmptyInstance() => create();
  static $pb.PbList<HiddifyOptions> createRepeated() =>
      $pb.PbList<HiddifyOptions>();
  @$core.pragma('dart2js:noInline')
  static HiddifyOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HiddifyOptions>(create);
  static HiddifyOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enableFullConfig => $_getBF(0);
  @$pb.TagNumber(1)
  set enableFullConfig($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnableFullConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnableFullConfig() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get logLevel => $_getSZ(1);
  @$pb.TagNumber(2)
  set logLevel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLogLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLogLevel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get logFile => $_getSZ(2);
  @$pb.TagNumber(3)
  set logFile($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLogFile() => $_has(2);
  @$pb.TagNumber(3)
  void clearLogFile() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enableClashApi => $_getBF(3);
  @$pb.TagNumber(4)
  set enableClashApi($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnableClashApi() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnableClashApi() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get clashApiPort => $_getIZ(4);
  @$pb.TagNumber(5)
  set clashApiPort($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClashApiPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearClashApiPort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get webSecret => $_getSZ(5);
  @$pb.TagNumber(6)
  set webSecret($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWebSecret() => $_has(5);
  @$pb.TagNumber(6)
  void clearWebSecret() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get region => $_getSZ(6);
  @$pb.TagNumber(7)
  set region($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRegion() => $_has(6);
  @$pb.TagNumber(7)
  void clearRegion() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get blockAds => $_getBF(7);
  @$pb.TagNumber(8)
  set blockAds($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBlockAds() => $_has(7);
  @$pb.TagNumber(8)
  void clearBlockAds() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get useXrayCoreWhenPossible => $_getBF(8);
  @$pb.TagNumber(9)
  set useXrayCoreWhenPossible($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUseXrayCoreWhenPossible() => $_has(8);
  @$pb.TagNumber(9)
  void clearUseXrayCoreWhenPossible() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<Rule> get rules => $_getList(9);

  @$pb.TagNumber(11)
  WarpOptions get warp => $_getN(10);
  @$pb.TagNumber(11)
  set warp(WarpOptions value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasWarp() => $_has(10);
  @$pb.TagNumber(11)
  void clearWarp() => $_clearField(11);
  @$pb.TagNumber(11)
  WarpOptions ensureWarp() => $_ensure(10);

  @$pb.TagNumber(12)
  WarpOptions get warp2 => $_getN(11);
  @$pb.TagNumber(12)
  set warp2(WarpOptions value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasWarp2() => $_has(11);
  @$pb.TagNumber(12)
  void clearWarp2() => $_clearField(12);
  @$pb.TagNumber(12)
  WarpOptions ensureWarp2() => $_ensure(11);

  @$pb.TagNumber(13)
  MuxOptions get mux => $_getN(12);
  @$pb.TagNumber(13)
  set mux(MuxOptions value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasMux() => $_has(12);
  @$pb.TagNumber(13)
  void clearMux() => $_clearField(13);
  @$pb.TagNumber(13)
  MuxOptions ensureMux() => $_ensure(12);

  @$pb.TagNumber(14)
  TLSTricks get tlsTricks => $_getN(13);
  @$pb.TagNumber(14)
  set tlsTricks(TLSTricks value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasTlsTricks() => $_has(13);
  @$pb.TagNumber(14)
  void clearTlsTricks() => $_clearField(14);
  @$pb.TagNumber(14)
  TLSTricks ensureTlsTricks() => $_ensure(13);

  @$pb.TagNumber(15)
  DNSOptions get dnsOptions => $_getN(14);
  @$pb.TagNumber(15)
  set dnsOptions(DNSOptions value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasDnsOptions() => $_has(14);
  @$pb.TagNumber(15)
  void clearDnsOptions() => $_clearField(15);
  @$pb.TagNumber(15)
  DNSOptions ensureDnsOptions() => $_ensure(14);

  @$pb.TagNumber(16)
  InboundOptions get inboundOptions => $_getN(15);
  @$pb.TagNumber(16)
  set inboundOptions(InboundOptions value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasInboundOptions() => $_has(15);
  @$pb.TagNumber(16)
  void clearInboundOptions() => $_clearField(16);
  @$pb.TagNumber(16)
  InboundOptions ensureInboundOptions() => $_ensure(15);

  @$pb.TagNumber(17)
  URLTestOptions get urlTestOptions => $_getN(16);
  @$pb.TagNumber(17)
  set urlTestOptions(URLTestOptions value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasUrlTestOptions() => $_has(16);
  @$pb.TagNumber(17)
  void clearUrlTestOptions() => $_clearField(17);
  @$pb.TagNumber(17)
  URLTestOptions ensureUrlTestOptions() => $_ensure(16);

  @$pb.TagNumber(18)
  RouteOptions get routeOptions => $_getN(17);
  @$pb.TagNumber(18)
  set routeOptions(RouteOptions value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasRouteOptions() => $_has(17);
  @$pb.TagNumber(18)
  void clearRouteOptions() => $_clearField(18);
  @$pb.TagNumber(18)
  RouteOptions ensureRouteOptions() => $_ensure(17);
}

/// *
///  IntRange defines a range of integers for various configurations.
///  It includes the starting and ending values of the range.
class IntRange extends $pb.GeneratedMessage {
  factory IntRange({
    $core.int? from,
    $core.int? to,
  }) {
    final result = create();
    if (from != null) result.from = from;
    if (to != null) result.to = to;
    return result;
  }

  IntRange._();

  factory IntRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IntRange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IntRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'from')
    ..aI(2, _omitFieldNames ? '' : 'to')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntRange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntRange copyWith(void Function(IntRange) updates) =>
      super.copyWith((message) => updates(message as IntRange)) as IntRange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IntRange create() => IntRange._();
  @$core.override
  IntRange createEmptyInstance() => create();
  static $pb.PbList<IntRange> createRepeated() => $pb.PbList<IntRange>();
  @$core.pragma('dart2js:noInline')
  static IntRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IntRange>(create);
  static IntRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get from => $_getIZ(0);
  @$pb.TagNumber(1)
  set from($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrom() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get to => $_getIZ(1);
  @$pb.TagNumber(2)
  set to($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTo() => $_clearField(2);
}

/// *
///  DNSOptions defines DNS-related configuration options.
class DNSOptions extends $pb.GeneratedMessage {
  factory DNSOptions({
    $core.String? remoteDnsAddress,
    DomainStrategy? remoteDnsDomainStrategy,
    $core.String? directDnsAddress,
    DomainStrategy? directDnsDomainStrategy,
    $core.bool? independentDnsCache,
    $core.bool? enableFakeDns,
    $core.bool? enableDnsRouting,
  }) {
    final result = create();
    if (remoteDnsAddress != null) result.remoteDnsAddress = remoteDnsAddress;
    if (remoteDnsDomainStrategy != null)
      result.remoteDnsDomainStrategy = remoteDnsDomainStrategy;
    if (directDnsAddress != null) result.directDnsAddress = directDnsAddress;
    if (directDnsDomainStrategy != null)
      result.directDnsDomainStrategy = directDnsDomainStrategy;
    if (independentDnsCache != null)
      result.independentDnsCache = independentDnsCache;
    if (enableFakeDns != null) result.enableFakeDns = enableFakeDns;
    if (enableDnsRouting != null) result.enableDnsRouting = enableDnsRouting;
    return result;
  }

  DNSOptions._();

  factory DNSOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DNSOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DNSOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'remoteDnsAddress')
    ..aE<DomainStrategy>(2, _omitFieldNames ? '' : 'remoteDnsDomainStrategy',
        enumValues: DomainStrategy.values)
    ..aOS(3, _omitFieldNames ? '' : 'directDnsAddress')
    ..aE<DomainStrategy>(4, _omitFieldNames ? '' : 'directDnsDomainStrategy',
        enumValues: DomainStrategy.values)
    ..aOB(5, _omitFieldNames ? '' : 'independentDnsCache')
    ..aOB(6, _omitFieldNames ? '' : 'enableFakeDns')
    ..aOB(7, _omitFieldNames ? '' : 'enableDnsRouting')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DNSOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DNSOptions copyWith(void Function(DNSOptions) updates) =>
      super.copyWith((message) => updates(message as DNSOptions)) as DNSOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DNSOptions create() => DNSOptions._();
  @$core.override
  DNSOptions createEmptyInstance() => create();
  static $pb.PbList<DNSOptions> createRepeated() => $pb.PbList<DNSOptions>();
  @$core.pragma('dart2js:noInline')
  static DNSOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DNSOptions>(create);
  static DNSOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get remoteDnsAddress => $_getSZ(0);
  @$pb.TagNumber(1)
  set remoteDnsAddress($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRemoteDnsAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearRemoteDnsAddress() => $_clearField(1);

  @$pb.TagNumber(2)
  DomainStrategy get remoteDnsDomainStrategy => $_getN(1);
  @$pb.TagNumber(2)
  set remoteDnsDomainStrategy(DomainStrategy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRemoteDnsDomainStrategy() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemoteDnsDomainStrategy() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get directDnsAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set directDnsAddress($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDirectDnsAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearDirectDnsAddress() => $_clearField(3);

  @$pb.TagNumber(4)
  DomainStrategy get directDnsDomainStrategy => $_getN(3);
  @$pb.TagNumber(4)
  set directDnsDomainStrategy(DomainStrategy value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDirectDnsDomainStrategy() => $_has(3);
  @$pb.TagNumber(4)
  void clearDirectDnsDomainStrategy() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get independentDnsCache => $_getBF(4);
  @$pb.TagNumber(5)
  set independentDnsCache($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIndependentDnsCache() => $_has(4);
  @$pb.TagNumber(5)
  void clearIndependentDnsCache() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enableFakeDns => $_getBF(5);
  @$pb.TagNumber(6)
  set enableFakeDns($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnableFakeDns() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnableFakeDns() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get enableDnsRouting => $_getBF(6);
  @$pb.TagNumber(7)
  set enableDnsRouting($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEnableDnsRouting() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnableDnsRouting() => $_clearField(7);
}

/// *
///  InboundOptions defines the configuration options for inbound connections.
class InboundOptions extends $pb.GeneratedMessage {
  factory InboundOptions({
    $core.bool? enableTun,
    $core.bool? enableTunService,
    $core.bool? setSystemProxy,
    $core.int? mixedPort,
    $core.int? tproxyPort,
    $core.int? directPort,
    $core.int? mtu,
    $core.bool? strictRoute,
    $core.String? tunStack,
    $core.int? redirectPort,
  }) {
    final result = create();
    if (enableTun != null) result.enableTun = enableTun;
    if (enableTunService != null) result.enableTunService = enableTunService;
    if (setSystemProxy != null) result.setSystemProxy = setSystemProxy;
    if (mixedPort != null) result.mixedPort = mixedPort;
    if (tproxyPort != null) result.tproxyPort = tproxyPort;
    if (directPort != null) result.directPort = directPort;
    if (mtu != null) result.mtu = mtu;
    if (strictRoute != null) result.strictRoute = strictRoute;
    if (tunStack != null) result.tunStack = tunStack;
    if (redirectPort != null) result.redirectPort = redirectPort;
    return result;
  }

  InboundOptions._();

  factory InboundOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InboundOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InboundOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enableTun')
    ..aOB(2, _omitFieldNames ? '' : 'enableTunService')
    ..aOB(3, _omitFieldNames ? '' : 'setSystemProxy')
    ..aI(4, _omitFieldNames ? '' : 'mixedPort', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'tproxyPort', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'directPort', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'mtu', fieldType: $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'strictRoute')
    ..aOS(9, _omitFieldNames ? '' : 'tunStack')
    ..aI(10, _omitFieldNames ? '' : 'redirectPort',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InboundOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InboundOptions copyWith(void Function(InboundOptions) updates) =>
      super.copyWith((message) => updates(message as InboundOptions))
          as InboundOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InboundOptions create() => InboundOptions._();
  @$core.override
  InboundOptions createEmptyInstance() => create();
  static $pb.PbList<InboundOptions> createRepeated() =>
      $pb.PbList<InboundOptions>();
  @$core.pragma('dart2js:noInline')
  static InboundOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InboundOptions>(create);
  static InboundOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enableTun => $_getBF(0);
  @$pb.TagNumber(1)
  set enableTun($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnableTun() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnableTun() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enableTunService => $_getBF(1);
  @$pb.TagNumber(2)
  set enableTunService($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnableTunService() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnableTunService() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get setSystemProxy => $_getBF(2);
  @$pb.TagNumber(3)
  set setSystemProxy($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSetSystemProxy() => $_has(2);
  @$pb.TagNumber(3)
  void clearSetSystemProxy() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get mixedPort => $_getIZ(3);
  @$pb.TagNumber(4)
  set mixedPort($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMixedPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearMixedPort() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get tproxyPort => $_getIZ(4);
  @$pb.TagNumber(5)
  set tproxyPort($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTproxyPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearTproxyPort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get directPort => $_getIZ(5);
  @$pb.TagNumber(6)
  set directPort($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDirectPort() => $_has(5);
  @$pb.TagNumber(6)
  void clearDirectPort() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get mtu => $_getIZ(6);
  @$pb.TagNumber(7)
  set mtu($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMtu() => $_has(6);
  @$pb.TagNumber(7)
  void clearMtu() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get strictRoute => $_getBF(7);
  @$pb.TagNumber(8)
  set strictRoute($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasStrictRoute() => $_has(7);
  @$pb.TagNumber(8)
  void clearStrictRoute() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get tunStack => $_getSZ(8);
  @$pb.TagNumber(9)
  set tunStack($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTunStack() => $_has(8);
  @$pb.TagNumber(9)
  void clearTunStack() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get redirectPort => $_getIZ(9);
  @$pb.TagNumber(10)
  set redirectPort($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRedirectPort() => $_has(9);
  @$pb.TagNumber(10)
  void clearRedirectPort() => $_clearField(10);
}

/// *
///  URLTestOptions defines the configuration options for URL testing.
class URLTestOptions extends $pb.GeneratedMessage {
  factory URLTestOptions({
    $core.String? connectionTestUrl,
    $fixnum.Int64? urlTestInterval,
  }) {
    final result = create();
    if (connectionTestUrl != null) result.connectionTestUrl = connectionTestUrl;
    if (urlTestInterval != null) result.urlTestInterval = urlTestInterval;
    return result;
  }

  URLTestOptions._();

  factory URLTestOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory URLTestOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'URLTestOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'connectionTestUrl')
    ..aInt64(2, _omitFieldNames ? '' : 'urlTestInterval')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  URLTestOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  URLTestOptions copyWith(void Function(URLTestOptions) updates) =>
      super.copyWith((message) => updates(message as URLTestOptions))
          as URLTestOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static URLTestOptions create() => URLTestOptions._();
  @$core.override
  URLTestOptions createEmptyInstance() => create();
  static $pb.PbList<URLTestOptions> createRepeated() =>
      $pb.PbList<URLTestOptions>();
  @$core.pragma('dart2js:noInline')
  static URLTestOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<URLTestOptions>(create);
  static URLTestOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionTestUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionTestUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionTestUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionTestUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get urlTestInterval => $_getI64(1);
  @$pb.TagNumber(2)
  set urlTestInterval($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUrlTestInterval() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrlTestInterval() => $_clearField(2);
}

/// *
///  RouteOptions defines options related to traffic routing.
class RouteOptions extends $pb.GeneratedMessage {
  factory RouteOptions({
    $core.bool? resolveDestination,
    DomainStrategy? ipv6Mode,
    $core.bool? bypassLan,
    $core.bool? allowConnectionFromLan,
  }) {
    final result = create();
    if (resolveDestination != null)
      result.resolveDestination = resolveDestination;
    if (ipv6Mode != null) result.ipv6Mode = ipv6Mode;
    if (bypassLan != null) result.bypassLan = bypassLan;
    if (allowConnectionFromLan != null)
      result.allowConnectionFromLan = allowConnectionFromLan;
    return result;
  }

  RouteOptions._();

  factory RouteOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RouteOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RouteOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'resolveDestination')
    ..aE<DomainStrategy>(2, _omitFieldNames ? '' : 'ipv6Mode',
        enumValues: DomainStrategy.values)
    ..aOB(3, _omitFieldNames ? '' : 'bypassLan')
    ..aOB(4, _omitFieldNames ? '' : 'allowConnectionFromLan')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteOptions copyWith(void Function(RouteOptions) updates) =>
      super.copyWith((message) => updates(message as RouteOptions))
          as RouteOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RouteOptions create() => RouteOptions._();
  @$core.override
  RouteOptions createEmptyInstance() => create();
  static $pb.PbList<RouteOptions> createRepeated() =>
      $pb.PbList<RouteOptions>();
  @$core.pragma('dart2js:noInline')
  static RouteOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RouteOptions>(create);
  static RouteOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get resolveDestination => $_getBF(0);
  @$pb.TagNumber(1)
  set resolveDestination($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResolveDestination() => $_has(0);
  @$pb.TagNumber(1)
  void clearResolveDestination() => $_clearField(1);

  @$pb.TagNumber(2)
  DomainStrategy get ipv6Mode => $_getN(1);
  @$pb.TagNumber(2)
  set ipv6Mode(DomainStrategy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasIpv6Mode() => $_has(1);
  @$pb.TagNumber(2)
  void clearIpv6Mode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get bypassLan => $_getBF(2);
  @$pb.TagNumber(3)
  set bypassLan($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBypassLan() => $_has(2);
  @$pb.TagNumber(3)
  void clearBypassLan() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get allowConnectionFromLan => $_getBF(3);
  @$pb.TagNumber(4)
  set allowConnectionFromLan($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAllowConnectionFromLan() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowConnectionFromLan() => $_clearField(4);
}

/// *
///  TLSTricks defines options for TLS tricks to obfuscate traffic.
class TLSTricks extends $pb.GeneratedMessage {
  factory TLSTricks({
    $core.bool? enableFragment,
    IntRange? fragmentSize,
    IntRange? fragmentSleep,
    $core.bool? mixedSniCase,
    $core.bool? enablePadding,
    IntRange? paddingSize,
  }) {
    final result = create();
    if (enableFragment != null) result.enableFragment = enableFragment;
    if (fragmentSize != null) result.fragmentSize = fragmentSize;
    if (fragmentSleep != null) result.fragmentSleep = fragmentSleep;
    if (mixedSniCase != null) result.mixedSniCase = mixedSniCase;
    if (enablePadding != null) result.enablePadding = enablePadding;
    if (paddingSize != null) result.paddingSize = paddingSize;
    return result;
  }

  TLSTricks._();

  factory TLSTricks.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TLSTricks.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TLSTricks',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enableFragment')
    ..aOM<IntRange>(2, _omitFieldNames ? '' : 'fragmentSize',
        subBuilder: IntRange.create)
    ..aOM<IntRange>(3, _omitFieldNames ? '' : 'fragmentSleep',
        subBuilder: IntRange.create)
    ..aOB(4, _omitFieldNames ? '' : 'mixedSniCase')
    ..aOB(5, _omitFieldNames ? '' : 'enablePadding')
    ..aOM<IntRange>(6, _omitFieldNames ? '' : 'paddingSize',
        subBuilder: IntRange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TLSTricks clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TLSTricks copyWith(void Function(TLSTricks) updates) =>
      super.copyWith((message) => updates(message as TLSTricks)) as TLSTricks;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TLSTricks create() => TLSTricks._();
  @$core.override
  TLSTricks createEmptyInstance() => create();
  static $pb.PbList<TLSTricks> createRepeated() => $pb.PbList<TLSTricks>();
  @$core.pragma('dart2js:noInline')
  static TLSTricks getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TLSTricks>(create);
  static TLSTricks? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enableFragment => $_getBF(0);
  @$pb.TagNumber(1)
  set enableFragment($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnableFragment() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnableFragment() => $_clearField(1);

  @$pb.TagNumber(2)
  IntRange get fragmentSize => $_getN(1);
  @$pb.TagNumber(2)
  set fragmentSize(IntRange value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFragmentSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearFragmentSize() => $_clearField(2);
  @$pb.TagNumber(2)
  IntRange ensureFragmentSize() => $_ensure(1);

  @$pb.TagNumber(3)
  IntRange get fragmentSleep => $_getN(2);
  @$pb.TagNumber(3)
  set fragmentSleep(IntRange value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFragmentSleep() => $_has(2);
  @$pb.TagNumber(3)
  void clearFragmentSleep() => $_clearField(3);
  @$pb.TagNumber(3)
  IntRange ensureFragmentSleep() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get mixedSniCase => $_getBF(3);
  @$pb.TagNumber(4)
  set mixedSniCase($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMixedSniCase() => $_has(3);
  @$pb.TagNumber(4)
  void clearMixedSniCase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enablePadding => $_getBF(4);
  @$pb.TagNumber(5)
  set enablePadding($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnablePadding() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnablePadding() => $_clearField(5);

  @$pb.TagNumber(6)
  IntRange get paddingSize => $_getN(5);
  @$pb.TagNumber(6)
  set paddingSize(IntRange value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPaddingSize() => $_has(5);
  @$pb.TagNumber(6)
  void clearPaddingSize() => $_clearField(6);
  @$pb.TagNumber(6)
  IntRange ensurePaddingSize() => $_ensure(5);
}

/// *
///  MuxOptions defines options for multiplexing connections.
class MuxOptions extends $pb.GeneratedMessage {
  factory MuxOptions({
    $core.bool? enable,
    $core.bool? padding,
    $core.int? maxStreams,
    $core.String? protocol,
  }) {
    final result = create();
    if (enable != null) result.enable = enable;
    if (padding != null) result.padding = padding;
    if (maxStreams != null) result.maxStreams = maxStreams;
    if (protocol != null) result.protocol = protocol;
    return result;
  }

  MuxOptions._();

  factory MuxOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MuxOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MuxOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enable')
    ..aOB(2, _omitFieldNames ? '' : 'padding')
    ..aI(3, _omitFieldNames ? '' : 'maxStreams')
    ..aOS(4, _omitFieldNames ? '' : 'protocol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MuxOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MuxOptions copyWith(void Function(MuxOptions) updates) =>
      super.copyWith((message) => updates(message as MuxOptions)) as MuxOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MuxOptions create() => MuxOptions._();
  @$core.override
  MuxOptions createEmptyInstance() => create();
  static $pb.PbList<MuxOptions> createRepeated() => $pb.PbList<MuxOptions>();
  @$core.pragma('dart2js:noInline')
  static MuxOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MuxOptions>(create);
  static MuxOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enable => $_getBF(0);
  @$pb.TagNumber(1)
  set enable($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnable() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnable() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get padding => $_getBF(1);
  @$pb.TagNumber(2)
  set padding($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPadding() => $_has(1);
  @$pb.TagNumber(2)
  void clearPadding() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get maxStreams => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxStreams($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxStreams() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxStreams() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get protocol => $_getSZ(3);
  @$pb.TagNumber(4)
  set protocol($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProtocol() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtocol() => $_clearField(4);
}

/// *
///  WarpOptions defines configuration options for Warp.
class WarpOptions extends $pb.GeneratedMessage {
  factory WarpOptions({
    $core.String? id,
    $core.bool? enableWarp,
    $core.String? mode,
    WarpWireguardConfig? wireguardConfig,
    $core.String? fakePackets,
    IntRange? fakePacketSize,
    IntRange? fakePacketDelay,
    $core.String? fakePacketMode,
    $core.String? cleanIp,
    $core.int? cleanPort,
    WarpAccount? account,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (enableWarp != null) result.enableWarp = enableWarp;
    if (mode != null) result.mode = mode;
    if (wireguardConfig != null) result.wireguardConfig = wireguardConfig;
    if (fakePackets != null) result.fakePackets = fakePackets;
    if (fakePacketSize != null) result.fakePacketSize = fakePacketSize;
    if (fakePacketDelay != null) result.fakePacketDelay = fakePacketDelay;
    if (fakePacketMode != null) result.fakePacketMode = fakePacketMode;
    if (cleanIp != null) result.cleanIp = cleanIp;
    if (cleanPort != null) result.cleanPort = cleanPort;
    if (account != null) result.account = account;
    return result;
  }

  WarpOptions._();

  factory WarpOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WarpOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WarpOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'enableWarp')
    ..aOS(3, _omitFieldNames ? '' : 'mode')
    ..aOM<WarpWireguardConfig>(5, _omitFieldNames ? '' : 'wireguardConfig',
        subBuilder: WarpWireguardConfig.create)
    ..aOS(6, _omitFieldNames ? '' : 'fakePackets')
    ..aOM<IntRange>(7, _omitFieldNames ? '' : 'fakePacketSize',
        subBuilder: IntRange.create)
    ..aOM<IntRange>(8, _omitFieldNames ? '' : 'fakePacketDelay',
        subBuilder: IntRange.create)
    ..aOS(9, _omitFieldNames ? '' : 'fakePacketMode')
    ..aOS(10, _omitFieldNames ? '' : 'cleanIp')
    ..aI(11, _omitFieldNames ? '' : 'cleanPort', fieldType: $pb.PbFieldType.OU3)
    ..aOM<WarpAccount>(12, _omitFieldNames ? '' : 'account',
        subBuilder: WarpAccount.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarpOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarpOptions copyWith(void Function(WarpOptions) updates) =>
      super.copyWith((message) => updates(message as WarpOptions))
          as WarpOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpOptions create() => WarpOptions._();
  @$core.override
  WarpOptions createEmptyInstance() => create();
  static $pb.PbList<WarpOptions> createRepeated() => $pb.PbList<WarpOptions>();
  @$core.pragma('dart2js:noInline')
  static WarpOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WarpOptions>(create);
  static WarpOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enableWarp => $_getBF(1);
  @$pb.TagNumber(2)
  set enableWarp($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnableWarp() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnableWarp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get mode => $_getSZ(2);
  @$pb.TagNumber(3)
  set mode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => $_clearField(3);

  @$pb.TagNumber(5)
  WarpWireguardConfig get wireguardConfig => $_getN(3);
  @$pb.TagNumber(5)
  set wireguardConfig(WarpWireguardConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasWireguardConfig() => $_has(3);
  @$pb.TagNumber(5)
  void clearWireguardConfig() => $_clearField(5);
  @$pb.TagNumber(5)
  WarpWireguardConfig ensureWireguardConfig() => $_ensure(3);

  @$pb.TagNumber(6)
  $core.String get fakePackets => $_getSZ(4);
  @$pb.TagNumber(6)
  set fakePackets($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasFakePackets() => $_has(4);
  @$pb.TagNumber(6)
  void clearFakePackets() => $_clearField(6);

  @$pb.TagNumber(7)
  IntRange get fakePacketSize => $_getN(5);
  @$pb.TagNumber(7)
  set fakePacketSize(IntRange value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasFakePacketSize() => $_has(5);
  @$pb.TagNumber(7)
  void clearFakePacketSize() => $_clearField(7);
  @$pb.TagNumber(7)
  IntRange ensureFakePacketSize() => $_ensure(5);

  @$pb.TagNumber(8)
  IntRange get fakePacketDelay => $_getN(6);
  @$pb.TagNumber(8)
  set fakePacketDelay(IntRange value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasFakePacketDelay() => $_has(6);
  @$pb.TagNumber(8)
  void clearFakePacketDelay() => $_clearField(8);
  @$pb.TagNumber(8)
  IntRange ensureFakePacketDelay() => $_ensure(6);

  @$pb.TagNumber(9)
  $core.String get fakePacketMode => $_getSZ(7);
  @$pb.TagNumber(9)
  set fakePacketMode($core.String value) => $_setString(7, value);
  @$pb.TagNumber(9)
  $core.bool hasFakePacketMode() => $_has(7);
  @$pb.TagNumber(9)
  void clearFakePacketMode() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get cleanIp => $_getSZ(8);
  @$pb.TagNumber(10)
  set cleanIp($core.String value) => $_setString(8, value);
  @$pb.TagNumber(10)
  $core.bool hasCleanIp() => $_has(8);
  @$pb.TagNumber(10)
  void clearCleanIp() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get cleanPort => $_getIZ(9);
  @$pb.TagNumber(11)
  set cleanPort($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(11)
  $core.bool hasCleanPort() => $_has(9);
  @$pb.TagNumber(11)
  void clearCleanPort() => $_clearField(11);

  @$pb.TagNumber(12)
  WarpAccount get account => $_getN(10);
  @$pb.TagNumber(12)
  set account(WarpAccount value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasAccount() => $_has(10);
  @$pb.TagNumber(12)
  void clearAccount() => $_clearField(12);
  @$pb.TagNumber(12)
  WarpAccount ensureAccount() => $_ensure(10);
}

/// *
///  WarpAccount defines account details for Warp.
class WarpAccount extends $pb.GeneratedMessage {
  factory WarpAccount({
    $core.String? accountId,
    $core.String? accessToken,
  }) {
    final result = create();
    if (accountId != null) result.accountId = accountId;
    if (accessToken != null) result.accessToken = accessToken;
    return result;
  }

  WarpAccount._();

  factory WarpAccount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WarpAccount.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WarpAccount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'accountId')
    ..aOS(2, _omitFieldNames ? '' : 'accessToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarpAccount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarpAccount copyWith(void Function(WarpAccount) updates) =>
      super.copyWith((message) => updates(message as WarpAccount))
          as WarpAccount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpAccount create() => WarpAccount._();
  @$core.override
  WarpAccount createEmptyInstance() => create();
  static $pb.PbList<WarpAccount> createRepeated() => $pb.PbList<WarpAccount>();
  @$core.pragma('dart2js:noInline')
  static WarpAccount getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WarpAccount>(create);
  static WarpAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get accountId => $_getSZ(0);
  @$pb.TagNumber(1)
  set accountId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccountId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get accessToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set accessToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccessToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessToken() => $_clearField(2);
}

/// *
///  WarpWireguardConfig defines the configuration details for WireGuard.
class WarpWireguardConfig extends $pb.GeneratedMessage {
  factory WarpWireguardConfig({
    $core.String? privateKey,
    $core.String? localAddressIpv4,
    $core.String? localAddressIpv6,
    $core.String? peerPublicKey,
    $core.String? clientId,
  }) {
    final result = create();
    if (privateKey != null) result.privateKey = privateKey;
    if (localAddressIpv4 != null) result.localAddressIpv4 = localAddressIpv4;
    if (localAddressIpv6 != null) result.localAddressIpv6 = localAddressIpv6;
    if (peerPublicKey != null) result.peerPublicKey = peerPublicKey;
    if (clientId != null) result.clientId = clientId;
    return result;
  }

  WarpWireguardConfig._();

  factory WarpWireguardConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WarpWireguardConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WarpWireguardConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'privateKey')
    ..aOS(2, _omitFieldNames ? '' : 'localAddressIpv4')
    ..aOS(3, _omitFieldNames ? '' : 'localAddressIpv6')
    ..aOS(4, _omitFieldNames ? '' : 'peerPublicKey')
    ..aOS(5, _omitFieldNames ? '' : 'clientId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarpWireguardConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarpWireguardConfig copyWith(void Function(WarpWireguardConfig) updates) =>
      super.copyWith((message) => updates(message as WarpWireguardConfig))
          as WarpWireguardConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpWireguardConfig create() => WarpWireguardConfig._();
  @$core.override
  WarpWireguardConfig createEmptyInstance() => create();
  static $pb.PbList<WarpWireguardConfig> createRepeated() =>
      $pb.PbList<WarpWireguardConfig>();
  @$core.pragma('dart2js:noInline')
  static WarpWireguardConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WarpWireguardConfig>(create);
  static WarpWireguardConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get privateKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set privateKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrivateKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrivateKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get localAddressIpv4 => $_getSZ(1);
  @$pb.TagNumber(2)
  set localAddressIpv4($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocalAddressIpv4() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalAddressIpv4() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get localAddressIpv6 => $_getSZ(2);
  @$pb.TagNumber(3)
  set localAddressIpv6($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocalAddressIpv6() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalAddressIpv6() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get peerPublicKey => $_getSZ(3);
  @$pb.TagNumber(4)
  set peerPublicKey($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPeerPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearPeerPublicKey() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get clientId => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClientId() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientId() => $_clearField(5);
}

/// *
///  Rule defines routing rules for managing traffic.
class Rule extends $pb.GeneratedMessage {
  factory Rule({
    $core.String? ruleSetUrl,
    $core.String? domains,
    $core.String? ip,
    $core.String? port,
    $core.String? network,
    $core.String? protocol,
    $core.String? outbound,
  }) {
    final result = create();
    if (ruleSetUrl != null) result.ruleSetUrl = ruleSetUrl;
    if (domains != null) result.domains = domains;
    if (ip != null) result.ip = ip;
    if (port != null) result.port = port;
    if (network != null) result.network = network;
    if (protocol != null) result.protocol = protocol;
    if (outbound != null) result.outbound = outbound;
    return result;
  }

  Rule._();

  factory Rule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Rule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Rule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ruleSetUrl')
    ..aOS(2, _omitFieldNames ? '' : 'domains')
    ..aOS(3, _omitFieldNames ? '' : 'ip')
    ..aOS(4, _omitFieldNames ? '' : 'port')
    ..aOS(5, _omitFieldNames ? '' : 'network')
    ..aOS(6, _omitFieldNames ? '' : 'protocol')
    ..aOS(7, _omitFieldNames ? '' : 'outbound')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Rule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Rule copyWith(void Function(Rule) updates) =>
      super.copyWith((message) => updates(message as Rule)) as Rule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Rule create() => Rule._();
  @$core.override
  Rule createEmptyInstance() => create();
  static $pb.PbList<Rule> createRepeated() => $pb.PbList<Rule>();
  @$core.pragma('dart2js:noInline')
  static Rule getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Rule>(create);
  static Rule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ruleSetUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set ruleSetUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRuleSetUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearRuleSetUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get domains => $_getSZ(1);
  @$pb.TagNumber(2)
  set domains($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDomains() => $_has(1);
  @$pb.TagNumber(2)
  void clearDomains() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get ip => $_getSZ(2);
  @$pb.TagNumber(3)
  set ip($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIp() => $_has(2);
  @$pb.TagNumber(3)
  void clearIp() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get port => $_getSZ(3);
  @$pb.TagNumber(4)
  set port($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearPort() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get network => $_getSZ(4);
  @$pb.TagNumber(5)
  set network($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNetwork() => $_has(4);
  @$pb.TagNumber(5)
  void clearNetwork() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get protocol => $_getSZ(5);
  @$pb.TagNumber(6)
  set protocol($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProtocol() => $_has(5);
  @$pb.TagNumber(6)
  void clearProtocol() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get outbound => $_getSZ(6);
  @$pb.TagNumber(7)
  set outbound($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasOutbound() => $_has(6);
  @$pb.TagNumber(7)
  void clearOutbound() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
