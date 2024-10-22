//
//  Generated code. Do not modify.
//  source: v2/hiddifyoptions/hiddify_options.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'hiddify_options.pbenum.dart';

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
    final $result = create();
    if (enableFullConfig != null) {
      $result.enableFullConfig = enableFullConfig;
    }
    if (logLevel != null) {
      $result.logLevel = logLevel;
    }
    if (logFile != null) {
      $result.logFile = logFile;
    }
    if (enableClashApi != null) {
      $result.enableClashApi = enableClashApi;
    }
    if (clashApiPort != null) {
      $result.clashApiPort = clashApiPort;
    }
    if (webSecret != null) {
      $result.webSecret = webSecret;
    }
    if (region != null) {
      $result.region = region;
    }
    if (blockAds != null) {
      $result.blockAds = blockAds;
    }
    if (useXrayCoreWhenPossible != null) {
      $result.useXrayCoreWhenPossible = useXrayCoreWhenPossible;
    }
    if (rules != null) {
      $result.rules.addAll(rules);
    }
    if (warp != null) {
      $result.warp = warp;
    }
    if (warp2 != null) {
      $result.warp2 = warp2;
    }
    if (mux != null) {
      $result.mux = mux;
    }
    if (tlsTricks != null) {
      $result.tlsTricks = tlsTricks;
    }
    if (dnsOptions != null) {
      $result.dnsOptions = dnsOptions;
    }
    if (inboundOptions != null) {
      $result.inboundOptions = inboundOptions;
    }
    if (urlTestOptions != null) {
      $result.urlTestOptions = urlTestOptions;
    }
    if (routeOptions != null) {
      $result.routeOptions = routeOptions;
    }
    return $result;
  }
  HiddifyOptions._() : super();
  factory HiddifyOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HiddifyOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HiddifyOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enableFullConfig')
    ..aOS(2, _omitFieldNames ? '' : 'logLevel')
    ..aOS(3, _omitFieldNames ? '' : 'logFile')
    ..aOB(4, _omitFieldNames ? '' : 'enableClashApi')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'clashApiPort', $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'webSecret')
    ..aOS(7, _omitFieldNames ? '' : 'region')
    ..aOB(8, _omitFieldNames ? '' : 'blockAds')
    ..aOB(9, _omitFieldNames ? '' : 'useXrayCoreWhenPossible')
    ..pc<Rule>(10, _omitFieldNames ? '' : 'rules', $pb.PbFieldType.PM, subBuilder: Rule.create)
    ..aOM<WarpOptions>(11, _omitFieldNames ? '' : 'warp', subBuilder: WarpOptions.create)
    ..aOM<WarpOptions>(12, _omitFieldNames ? '' : 'warp2', subBuilder: WarpOptions.create)
    ..aOM<MuxOptions>(13, _omitFieldNames ? '' : 'mux', subBuilder: MuxOptions.create)
    ..aOM<TLSTricks>(14, _omitFieldNames ? '' : 'tlsTricks', subBuilder: TLSTricks.create)
    ..aOM<DNSOptions>(15, _omitFieldNames ? '' : 'dnsOptions', subBuilder: DNSOptions.create)
    ..aOM<InboundOptions>(16, _omitFieldNames ? '' : 'inboundOptions', subBuilder: InboundOptions.create)
    ..aOM<URLTestOptions>(17, _omitFieldNames ? '' : 'urlTestOptions', subBuilder: URLTestOptions.create)
    ..aOM<RouteOptions>(18, _omitFieldNames ? '' : 'routeOptions', subBuilder: RouteOptions.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HiddifyOptions clone() => HiddifyOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HiddifyOptions copyWith(void Function(HiddifyOptions) updates) => super.copyWith((message) => updates(message as HiddifyOptions)) as HiddifyOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HiddifyOptions create() => HiddifyOptions._();
  HiddifyOptions createEmptyInstance() => create();
  static $pb.PbList<HiddifyOptions> createRepeated() => $pb.PbList<HiddifyOptions>();
  @$core.pragma('dart2js:noInline')
  static HiddifyOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HiddifyOptions>(create);
  static HiddifyOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enableFullConfig => $_getBF(0);
  @$pb.TagNumber(1)
  set enableFullConfig($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnableFullConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnableFullConfig() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get logLevel => $_getSZ(1);
  @$pb.TagNumber(2)
  set logLevel($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLogLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLogLevel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get logFile => $_getSZ(2);
  @$pb.TagNumber(3)
  set logFile($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLogFile() => $_has(2);
  @$pb.TagNumber(3)
  void clearLogFile() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enableClashApi => $_getBF(3);
  @$pb.TagNumber(4)
  set enableClashApi($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEnableClashApi() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnableClashApi() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get clashApiPort => $_getIZ(4);
  @$pb.TagNumber(5)
  set clashApiPort($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasClashApiPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearClashApiPort() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get webSecret => $_getSZ(5);
  @$pb.TagNumber(6)
  set webSecret($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasWebSecret() => $_has(5);
  @$pb.TagNumber(6)
  void clearWebSecret() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get region => $_getSZ(6);
  @$pb.TagNumber(7)
  set region($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasRegion() => $_has(6);
  @$pb.TagNumber(7)
  void clearRegion() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get blockAds => $_getBF(7);
  @$pb.TagNumber(8)
  set blockAds($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasBlockAds() => $_has(7);
  @$pb.TagNumber(8)
  void clearBlockAds() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get useXrayCoreWhenPossible => $_getBF(8);
  @$pb.TagNumber(9)
  set useXrayCoreWhenPossible($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasUseXrayCoreWhenPossible() => $_has(8);
  @$pb.TagNumber(9)
  void clearUseXrayCoreWhenPossible() => clearField(9);

  @$pb.TagNumber(10)
  $core.List<Rule> get rules => $_getList(9);

  @$pb.TagNumber(11)
  WarpOptions get warp => $_getN(10);
  @$pb.TagNumber(11)
  set warp(WarpOptions v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasWarp() => $_has(10);
  @$pb.TagNumber(11)
  void clearWarp() => clearField(11);
  @$pb.TagNumber(11)
  WarpOptions ensureWarp() => $_ensure(10);

  @$pb.TagNumber(12)
  WarpOptions get warp2 => $_getN(11);
  @$pb.TagNumber(12)
  set warp2(WarpOptions v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasWarp2() => $_has(11);
  @$pb.TagNumber(12)
  void clearWarp2() => clearField(12);
  @$pb.TagNumber(12)
  WarpOptions ensureWarp2() => $_ensure(11);

  @$pb.TagNumber(13)
  MuxOptions get mux => $_getN(12);
  @$pb.TagNumber(13)
  set mux(MuxOptions v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasMux() => $_has(12);
  @$pb.TagNumber(13)
  void clearMux() => clearField(13);
  @$pb.TagNumber(13)
  MuxOptions ensureMux() => $_ensure(12);

  @$pb.TagNumber(14)
  TLSTricks get tlsTricks => $_getN(13);
  @$pb.TagNumber(14)
  set tlsTricks(TLSTricks v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasTlsTricks() => $_has(13);
  @$pb.TagNumber(14)
  void clearTlsTricks() => clearField(14);
  @$pb.TagNumber(14)
  TLSTricks ensureTlsTricks() => $_ensure(13);

  @$pb.TagNumber(15)
  DNSOptions get dnsOptions => $_getN(14);
  @$pb.TagNumber(15)
  set dnsOptions(DNSOptions v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasDnsOptions() => $_has(14);
  @$pb.TagNumber(15)
  void clearDnsOptions() => clearField(15);
  @$pb.TagNumber(15)
  DNSOptions ensureDnsOptions() => $_ensure(14);

  @$pb.TagNumber(16)
  InboundOptions get inboundOptions => $_getN(15);
  @$pb.TagNumber(16)
  set inboundOptions(InboundOptions v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasInboundOptions() => $_has(15);
  @$pb.TagNumber(16)
  void clearInboundOptions() => clearField(16);
  @$pb.TagNumber(16)
  InboundOptions ensureInboundOptions() => $_ensure(15);

  @$pb.TagNumber(17)
  URLTestOptions get urlTestOptions => $_getN(16);
  @$pb.TagNumber(17)
  set urlTestOptions(URLTestOptions v) { setField(17, v); }
  @$pb.TagNumber(17)
  $core.bool hasUrlTestOptions() => $_has(16);
  @$pb.TagNumber(17)
  void clearUrlTestOptions() => clearField(17);
  @$pb.TagNumber(17)
  URLTestOptions ensureUrlTestOptions() => $_ensure(16);

  @$pb.TagNumber(18)
  RouteOptions get routeOptions => $_getN(17);
  @$pb.TagNumber(18)
  set routeOptions(RouteOptions v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasRouteOptions() => $_has(17);
  @$pb.TagNumber(18)
  void clearRouteOptions() => clearField(18);
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
    final $result = create();
    if (from != null) {
      $result.from = from;
    }
    if (to != null) {
      $result.to = to;
    }
    return $result;
  }
  IntRange._() : super();
  factory IntRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IntRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'IntRange', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'from', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'to', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IntRange clone() => IntRange()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IntRange copyWith(void Function(IntRange) updates) => super.copyWith((message) => updates(message as IntRange)) as IntRange;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IntRange create() => IntRange._();
  IntRange createEmptyInstance() => create();
  static $pb.PbList<IntRange> createRepeated() => $pb.PbList<IntRange>();
  @$core.pragma('dart2js:noInline')
  static IntRange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IntRange>(create);
  static IntRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get from => $_getIZ(0);
  @$pb.TagNumber(1)
  set from($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrom() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get to => $_getIZ(1);
  @$pb.TagNumber(2)
  set to($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTo() => clearField(2);
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
    final $result = create();
    if (remoteDnsAddress != null) {
      $result.remoteDnsAddress = remoteDnsAddress;
    }
    if (remoteDnsDomainStrategy != null) {
      $result.remoteDnsDomainStrategy = remoteDnsDomainStrategy;
    }
    if (directDnsAddress != null) {
      $result.directDnsAddress = directDnsAddress;
    }
    if (directDnsDomainStrategy != null) {
      $result.directDnsDomainStrategy = directDnsDomainStrategy;
    }
    if (independentDnsCache != null) {
      $result.independentDnsCache = independentDnsCache;
    }
    if (enableFakeDns != null) {
      $result.enableFakeDns = enableFakeDns;
    }
    if (enableDnsRouting != null) {
      $result.enableDnsRouting = enableDnsRouting;
    }
    return $result;
  }
  DNSOptions._() : super();
  factory DNSOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DNSOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DNSOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'remoteDnsAddress')
    ..e<DomainStrategy>(2, _omitFieldNames ? '' : 'remoteDnsDomainStrategy', $pb.PbFieldType.OE, defaultOrMaker: DomainStrategy.as_is, valueOf: DomainStrategy.valueOf, enumValues: DomainStrategy.values)
    ..aOS(3, _omitFieldNames ? '' : 'directDnsAddress')
    ..e<DomainStrategy>(4, _omitFieldNames ? '' : 'directDnsDomainStrategy', $pb.PbFieldType.OE, defaultOrMaker: DomainStrategy.as_is, valueOf: DomainStrategy.valueOf, enumValues: DomainStrategy.values)
    ..aOB(5, _omitFieldNames ? '' : 'independentDnsCache')
    ..aOB(6, _omitFieldNames ? '' : 'enableFakeDns')
    ..aOB(7, _omitFieldNames ? '' : 'enableDnsRouting')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DNSOptions clone() => DNSOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DNSOptions copyWith(void Function(DNSOptions) updates) => super.copyWith((message) => updates(message as DNSOptions)) as DNSOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DNSOptions create() => DNSOptions._();
  DNSOptions createEmptyInstance() => create();
  static $pb.PbList<DNSOptions> createRepeated() => $pb.PbList<DNSOptions>();
  @$core.pragma('dart2js:noInline')
  static DNSOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DNSOptions>(create);
  static DNSOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get remoteDnsAddress => $_getSZ(0);
  @$pb.TagNumber(1)
  set remoteDnsAddress($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRemoteDnsAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearRemoteDnsAddress() => clearField(1);

  @$pb.TagNumber(2)
  DomainStrategy get remoteDnsDomainStrategy => $_getN(1);
  @$pb.TagNumber(2)
  set remoteDnsDomainStrategy(DomainStrategy v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRemoteDnsDomainStrategy() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemoteDnsDomainStrategy() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get directDnsAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set directDnsAddress($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDirectDnsAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearDirectDnsAddress() => clearField(3);

  @$pb.TagNumber(4)
  DomainStrategy get directDnsDomainStrategy => $_getN(3);
  @$pb.TagNumber(4)
  set directDnsDomainStrategy(DomainStrategy v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasDirectDnsDomainStrategy() => $_has(3);
  @$pb.TagNumber(4)
  void clearDirectDnsDomainStrategy() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get independentDnsCache => $_getBF(4);
  @$pb.TagNumber(5)
  set independentDnsCache($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIndependentDnsCache() => $_has(4);
  @$pb.TagNumber(5)
  void clearIndependentDnsCache() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enableFakeDns => $_getBF(5);
  @$pb.TagNumber(6)
  set enableFakeDns($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasEnableFakeDns() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnableFakeDns() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get enableDnsRouting => $_getBF(6);
  @$pb.TagNumber(7)
  set enableDnsRouting($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasEnableDnsRouting() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnableDnsRouting() => clearField(7);
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
    $core.int? localDnsPort,
    $core.int? mtu,
    $core.bool? strictRoute,
    $core.String? tunStack,
  }) {
    final $result = create();
    if (enableTun != null) {
      $result.enableTun = enableTun;
    }
    if (enableTunService != null) {
      $result.enableTunService = enableTunService;
    }
    if (setSystemProxy != null) {
      $result.setSystemProxy = setSystemProxy;
    }
    if (mixedPort != null) {
      $result.mixedPort = mixedPort;
    }
    if (tproxyPort != null) {
      $result.tproxyPort = tproxyPort;
    }
    if (localDnsPort != null) {
      $result.localDnsPort = localDnsPort;
    }
    if (mtu != null) {
      $result.mtu = mtu;
    }
    if (strictRoute != null) {
      $result.strictRoute = strictRoute;
    }
    if (tunStack != null) {
      $result.tunStack = tunStack;
    }
    return $result;
  }
  InboundOptions._() : super();
  factory InboundOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InboundOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InboundOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enableTun')
    ..aOB(2, _omitFieldNames ? '' : 'enableTunService')
    ..aOB(3, _omitFieldNames ? '' : 'setSystemProxy')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'mixedPort', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'tproxyPort', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'localDnsPort', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'mtu', $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'strictRoute')
    ..aOS(9, _omitFieldNames ? '' : 'tunStack')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InboundOptions clone() => InboundOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InboundOptions copyWith(void Function(InboundOptions) updates) => super.copyWith((message) => updates(message as InboundOptions)) as InboundOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InboundOptions create() => InboundOptions._();
  InboundOptions createEmptyInstance() => create();
  static $pb.PbList<InboundOptions> createRepeated() => $pb.PbList<InboundOptions>();
  @$core.pragma('dart2js:noInline')
  static InboundOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InboundOptions>(create);
  static InboundOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enableTun => $_getBF(0);
  @$pb.TagNumber(1)
  set enableTun($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnableTun() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnableTun() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enableTunService => $_getBF(1);
  @$pb.TagNumber(2)
  set enableTunService($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEnableTunService() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnableTunService() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get setSystemProxy => $_getBF(2);
  @$pb.TagNumber(3)
  set setSystemProxy($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSetSystemProxy() => $_has(2);
  @$pb.TagNumber(3)
  void clearSetSystemProxy() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get mixedPort => $_getIZ(3);
  @$pb.TagNumber(4)
  set mixedPort($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMixedPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearMixedPort() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get tproxyPort => $_getIZ(4);
  @$pb.TagNumber(5)
  set tproxyPort($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTproxyPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearTproxyPort() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get localDnsPort => $_getIZ(5);
  @$pb.TagNumber(6)
  set localDnsPort($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLocalDnsPort() => $_has(5);
  @$pb.TagNumber(6)
  void clearLocalDnsPort() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get mtu => $_getIZ(6);
  @$pb.TagNumber(7)
  set mtu($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasMtu() => $_has(6);
  @$pb.TagNumber(7)
  void clearMtu() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get strictRoute => $_getBF(7);
  @$pb.TagNumber(8)
  set strictRoute($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasStrictRoute() => $_has(7);
  @$pb.TagNumber(8)
  void clearStrictRoute() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get tunStack => $_getSZ(8);
  @$pb.TagNumber(9)
  set tunStack($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasTunStack() => $_has(8);
  @$pb.TagNumber(9)
  void clearTunStack() => clearField(9);
}

/// *
///  URLTestOptions defines the configuration options for URL testing.
class URLTestOptions extends $pb.GeneratedMessage {
  factory URLTestOptions({
    $core.String? connectionTestUrl,
    $fixnum.Int64? urlTestInterval,
  }) {
    final $result = create();
    if (connectionTestUrl != null) {
      $result.connectionTestUrl = connectionTestUrl;
    }
    if (urlTestInterval != null) {
      $result.urlTestInterval = urlTestInterval;
    }
    return $result;
  }
  URLTestOptions._() : super();
  factory URLTestOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory URLTestOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'URLTestOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'connectionTestUrl')
    ..aInt64(2, _omitFieldNames ? '' : 'urlTestInterval')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  URLTestOptions clone() => URLTestOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  URLTestOptions copyWith(void Function(URLTestOptions) updates) => super.copyWith((message) => updates(message as URLTestOptions)) as URLTestOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static URLTestOptions create() => URLTestOptions._();
  URLTestOptions createEmptyInstance() => create();
  static $pb.PbList<URLTestOptions> createRepeated() => $pb.PbList<URLTestOptions>();
  @$core.pragma('dart2js:noInline')
  static URLTestOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<URLTestOptions>(create);
  static URLTestOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionTestUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionTestUrl($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConnectionTestUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionTestUrl() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get urlTestInterval => $_getI64(1);
  @$pb.TagNumber(2)
  set urlTestInterval($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUrlTestInterval() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrlTestInterval() => clearField(2);
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
    final $result = create();
    if (resolveDestination != null) {
      $result.resolveDestination = resolveDestination;
    }
    if (ipv6Mode != null) {
      $result.ipv6Mode = ipv6Mode;
    }
    if (bypassLan != null) {
      $result.bypassLan = bypassLan;
    }
    if (allowConnectionFromLan != null) {
      $result.allowConnectionFromLan = allowConnectionFromLan;
    }
    return $result;
  }
  RouteOptions._() : super();
  factory RouteOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RouteOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RouteOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'resolveDestination')
    ..e<DomainStrategy>(2, _omitFieldNames ? '' : 'ipv6Mode', $pb.PbFieldType.OE, defaultOrMaker: DomainStrategy.as_is, valueOf: DomainStrategy.valueOf, enumValues: DomainStrategy.values)
    ..aOB(3, _omitFieldNames ? '' : 'bypassLan')
    ..aOB(4, _omitFieldNames ? '' : 'allowConnectionFromLan')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RouteOptions clone() => RouteOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RouteOptions copyWith(void Function(RouteOptions) updates) => super.copyWith((message) => updates(message as RouteOptions)) as RouteOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RouteOptions create() => RouteOptions._();
  RouteOptions createEmptyInstance() => create();
  static $pb.PbList<RouteOptions> createRepeated() => $pb.PbList<RouteOptions>();
  @$core.pragma('dart2js:noInline')
  static RouteOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RouteOptions>(create);
  static RouteOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get resolveDestination => $_getBF(0);
  @$pb.TagNumber(1)
  set resolveDestination($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasResolveDestination() => $_has(0);
  @$pb.TagNumber(1)
  void clearResolveDestination() => clearField(1);

  @$pb.TagNumber(2)
  DomainStrategy get ipv6Mode => $_getN(1);
  @$pb.TagNumber(2)
  set ipv6Mode(DomainStrategy v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasIpv6Mode() => $_has(1);
  @$pb.TagNumber(2)
  void clearIpv6Mode() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get bypassLan => $_getBF(2);
  @$pb.TagNumber(3)
  set bypassLan($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBypassLan() => $_has(2);
  @$pb.TagNumber(3)
  void clearBypassLan() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get allowConnectionFromLan => $_getBF(3);
  @$pb.TagNumber(4)
  set allowConnectionFromLan($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAllowConnectionFromLan() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowConnectionFromLan() => clearField(4);
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
    final $result = create();
    if (enableFragment != null) {
      $result.enableFragment = enableFragment;
    }
    if (fragmentSize != null) {
      $result.fragmentSize = fragmentSize;
    }
    if (fragmentSleep != null) {
      $result.fragmentSleep = fragmentSleep;
    }
    if (mixedSniCase != null) {
      $result.mixedSniCase = mixedSniCase;
    }
    if (enablePadding != null) {
      $result.enablePadding = enablePadding;
    }
    if (paddingSize != null) {
      $result.paddingSize = paddingSize;
    }
    return $result;
  }
  TLSTricks._() : super();
  factory TLSTricks.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TLSTricks.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TLSTricks', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enableFragment')
    ..aOM<IntRange>(2, _omitFieldNames ? '' : 'fragmentSize', subBuilder: IntRange.create)
    ..aOM<IntRange>(3, _omitFieldNames ? '' : 'fragmentSleep', subBuilder: IntRange.create)
    ..aOB(4, _omitFieldNames ? '' : 'mixedSniCase')
    ..aOB(5, _omitFieldNames ? '' : 'enablePadding')
    ..aOM<IntRange>(6, _omitFieldNames ? '' : 'paddingSize', subBuilder: IntRange.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TLSTricks clone() => TLSTricks()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TLSTricks copyWith(void Function(TLSTricks) updates) => super.copyWith((message) => updates(message as TLSTricks)) as TLSTricks;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TLSTricks create() => TLSTricks._();
  TLSTricks createEmptyInstance() => create();
  static $pb.PbList<TLSTricks> createRepeated() => $pb.PbList<TLSTricks>();
  @$core.pragma('dart2js:noInline')
  static TLSTricks getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TLSTricks>(create);
  static TLSTricks? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enableFragment => $_getBF(0);
  @$pb.TagNumber(1)
  set enableFragment($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnableFragment() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnableFragment() => clearField(1);

  @$pb.TagNumber(2)
  IntRange get fragmentSize => $_getN(1);
  @$pb.TagNumber(2)
  set fragmentSize(IntRange v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFragmentSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearFragmentSize() => clearField(2);
  @$pb.TagNumber(2)
  IntRange ensureFragmentSize() => $_ensure(1);

  @$pb.TagNumber(3)
  IntRange get fragmentSleep => $_getN(2);
  @$pb.TagNumber(3)
  set fragmentSleep(IntRange v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFragmentSleep() => $_has(2);
  @$pb.TagNumber(3)
  void clearFragmentSleep() => clearField(3);
  @$pb.TagNumber(3)
  IntRange ensureFragmentSleep() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get mixedSniCase => $_getBF(3);
  @$pb.TagNumber(4)
  set mixedSniCase($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMixedSniCase() => $_has(3);
  @$pb.TagNumber(4)
  void clearMixedSniCase() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enablePadding => $_getBF(4);
  @$pb.TagNumber(5)
  set enablePadding($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEnablePadding() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnablePadding() => clearField(5);

  @$pb.TagNumber(6)
  IntRange get paddingSize => $_getN(5);
  @$pb.TagNumber(6)
  set paddingSize(IntRange v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasPaddingSize() => $_has(5);
  @$pb.TagNumber(6)
  void clearPaddingSize() => clearField(6);
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
    final $result = create();
    if (enable != null) {
      $result.enable = enable;
    }
    if (padding != null) {
      $result.padding = padding;
    }
    if (maxStreams != null) {
      $result.maxStreams = maxStreams;
    }
    if (protocol != null) {
      $result.protocol = protocol;
    }
    return $result;
  }
  MuxOptions._() : super();
  factory MuxOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MuxOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MuxOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enable')
    ..aOB(2, _omitFieldNames ? '' : 'padding')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'maxStreams', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'protocol')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MuxOptions clone() => MuxOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MuxOptions copyWith(void Function(MuxOptions) updates) => super.copyWith((message) => updates(message as MuxOptions)) as MuxOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MuxOptions create() => MuxOptions._();
  MuxOptions createEmptyInstance() => create();
  static $pb.PbList<MuxOptions> createRepeated() => $pb.PbList<MuxOptions>();
  @$core.pragma('dart2js:noInline')
  static MuxOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MuxOptions>(create);
  static MuxOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enable => $_getBF(0);
  @$pb.TagNumber(1)
  set enable($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnable() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnable() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get padding => $_getBF(1);
  @$pb.TagNumber(2)
  set padding($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPadding() => $_has(1);
  @$pb.TagNumber(2)
  void clearPadding() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get maxStreams => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxStreams($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMaxStreams() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxStreams() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get protocol => $_getSZ(3);
  @$pb.TagNumber(4)
  set protocol($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasProtocol() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtocol() => clearField(4);
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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (enableWarp != null) {
      $result.enableWarp = enableWarp;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    if (wireguardConfig != null) {
      $result.wireguardConfig = wireguardConfig;
    }
    if (fakePackets != null) {
      $result.fakePackets = fakePackets;
    }
    if (fakePacketSize != null) {
      $result.fakePacketSize = fakePacketSize;
    }
    if (fakePacketDelay != null) {
      $result.fakePacketDelay = fakePacketDelay;
    }
    if (fakePacketMode != null) {
      $result.fakePacketMode = fakePacketMode;
    }
    if (cleanIp != null) {
      $result.cleanIp = cleanIp;
    }
    if (cleanPort != null) {
      $result.cleanPort = cleanPort;
    }
    if (account != null) {
      $result.account = account;
    }
    return $result;
  }
  WarpOptions._() : super();
  factory WarpOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WarpOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'enableWarp')
    ..aOS(3, _omitFieldNames ? '' : 'mode')
    ..aOM<WarpWireguardConfig>(5, _omitFieldNames ? '' : 'wireguardConfig', subBuilder: WarpWireguardConfig.create)
    ..aOS(6, _omitFieldNames ? '' : 'fakePackets')
    ..aOM<IntRange>(7, _omitFieldNames ? '' : 'fakePacketSize', subBuilder: IntRange.create)
    ..aOM<IntRange>(8, _omitFieldNames ? '' : 'fakePacketDelay', subBuilder: IntRange.create)
    ..aOS(9, _omitFieldNames ? '' : 'fakePacketMode')
    ..aOS(10, _omitFieldNames ? '' : 'cleanIp')
    ..a<$core.int>(11, _omitFieldNames ? '' : 'cleanPort', $pb.PbFieldType.OU3)
    ..aOM<WarpAccount>(12, _omitFieldNames ? '' : 'account', subBuilder: WarpAccount.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpOptions clone() => WarpOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpOptions copyWith(void Function(WarpOptions) updates) => super.copyWith((message) => updates(message as WarpOptions)) as WarpOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpOptions create() => WarpOptions._();
  WarpOptions createEmptyInstance() => create();
  static $pb.PbList<WarpOptions> createRepeated() => $pb.PbList<WarpOptions>();
  @$core.pragma('dart2js:noInline')
  static WarpOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WarpOptions>(create);
  static WarpOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enableWarp => $_getBF(1);
  @$pb.TagNumber(2)
  set enableWarp($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEnableWarp() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnableWarp() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get mode => $_getSZ(2);
  @$pb.TagNumber(3)
  set mode($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => clearField(3);

  @$pb.TagNumber(5)
  WarpWireguardConfig get wireguardConfig => $_getN(3);
  @$pb.TagNumber(5)
  set wireguardConfig(WarpWireguardConfig v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasWireguardConfig() => $_has(3);
  @$pb.TagNumber(5)
  void clearWireguardConfig() => clearField(5);
  @$pb.TagNumber(5)
  WarpWireguardConfig ensureWireguardConfig() => $_ensure(3);

  @$pb.TagNumber(6)
  $core.String get fakePackets => $_getSZ(4);
  @$pb.TagNumber(6)
  set fakePackets($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(6)
  $core.bool hasFakePackets() => $_has(4);
  @$pb.TagNumber(6)
  void clearFakePackets() => clearField(6);

  @$pb.TagNumber(7)
  IntRange get fakePacketSize => $_getN(5);
  @$pb.TagNumber(7)
  set fakePacketSize(IntRange v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasFakePacketSize() => $_has(5);
  @$pb.TagNumber(7)
  void clearFakePacketSize() => clearField(7);
  @$pb.TagNumber(7)
  IntRange ensureFakePacketSize() => $_ensure(5);

  @$pb.TagNumber(8)
  IntRange get fakePacketDelay => $_getN(6);
  @$pb.TagNumber(8)
  set fakePacketDelay(IntRange v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasFakePacketDelay() => $_has(6);
  @$pb.TagNumber(8)
  void clearFakePacketDelay() => clearField(8);
  @$pb.TagNumber(8)
  IntRange ensureFakePacketDelay() => $_ensure(6);

  @$pb.TagNumber(9)
  $core.String get fakePacketMode => $_getSZ(7);
  @$pb.TagNumber(9)
  set fakePacketMode($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(9)
  $core.bool hasFakePacketMode() => $_has(7);
  @$pb.TagNumber(9)
  void clearFakePacketMode() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get cleanIp => $_getSZ(8);
  @$pb.TagNumber(10)
  set cleanIp($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(10)
  $core.bool hasCleanIp() => $_has(8);
  @$pb.TagNumber(10)
  void clearCleanIp() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get cleanPort => $_getIZ(9);
  @$pb.TagNumber(11)
  set cleanPort($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(11)
  $core.bool hasCleanPort() => $_has(9);
  @$pb.TagNumber(11)
  void clearCleanPort() => clearField(11);

  @$pb.TagNumber(12)
  WarpAccount get account => $_getN(10);
  @$pb.TagNumber(12)
  set account(WarpAccount v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasAccount() => $_has(10);
  @$pb.TagNumber(12)
  void clearAccount() => clearField(12);
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
    final $result = create();
    if (accountId != null) {
      $result.accountId = accountId;
    }
    if (accessToken != null) {
      $result.accessToken = accessToken;
    }
    return $result;
  }
  WarpAccount._() : super();
  factory WarpAccount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpAccount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WarpAccount', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'accountId')
    ..aOS(2, _omitFieldNames ? '' : 'accessToken')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpAccount clone() => WarpAccount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpAccount copyWith(void Function(WarpAccount) updates) => super.copyWith((message) => updates(message as WarpAccount)) as WarpAccount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpAccount create() => WarpAccount._();
  WarpAccount createEmptyInstance() => create();
  static $pb.PbList<WarpAccount> createRepeated() => $pb.PbList<WarpAccount>();
  @$core.pragma('dart2js:noInline')
  static WarpAccount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WarpAccount>(create);
  static WarpAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get accountId => $_getSZ(0);
  @$pb.TagNumber(1)
  set accountId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccountId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get accessToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set accessToken($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccessToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessToken() => clearField(2);
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
    final $result = create();
    if (privateKey != null) {
      $result.privateKey = privateKey;
    }
    if (localAddressIpv4 != null) {
      $result.localAddressIpv4 = localAddressIpv4;
    }
    if (localAddressIpv6 != null) {
      $result.localAddressIpv6 = localAddressIpv6;
    }
    if (peerPublicKey != null) {
      $result.peerPublicKey = peerPublicKey;
    }
    if (clientId != null) {
      $result.clientId = clientId;
    }
    return $result;
  }
  WarpWireguardConfig._() : super();
  factory WarpWireguardConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpWireguardConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WarpWireguardConfig', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'privateKey')
    ..aOS(2, _omitFieldNames ? '' : 'localAddressIpv4')
    ..aOS(3, _omitFieldNames ? '' : 'localAddressIpv6')
    ..aOS(4, _omitFieldNames ? '' : 'peerPublicKey')
    ..aOS(5, _omitFieldNames ? '' : 'clientId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpWireguardConfig clone() => WarpWireguardConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpWireguardConfig copyWith(void Function(WarpWireguardConfig) updates) => super.copyWith((message) => updates(message as WarpWireguardConfig)) as WarpWireguardConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpWireguardConfig create() => WarpWireguardConfig._();
  WarpWireguardConfig createEmptyInstance() => create();
  static $pb.PbList<WarpWireguardConfig> createRepeated() => $pb.PbList<WarpWireguardConfig>();
  @$core.pragma('dart2js:noInline')
  static WarpWireguardConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WarpWireguardConfig>(create);
  static WarpWireguardConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get privateKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set privateKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPrivateKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrivateKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get localAddressIpv4 => $_getSZ(1);
  @$pb.TagNumber(2)
  set localAddressIpv4($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLocalAddressIpv4() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalAddressIpv4() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get localAddressIpv6 => $_getSZ(2);
  @$pb.TagNumber(3)
  set localAddressIpv6($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLocalAddressIpv6() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalAddressIpv6() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get peerPublicKey => $_getSZ(3);
  @$pb.TagNumber(4)
  set peerPublicKey($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPeerPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearPeerPublicKey() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get clientId => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasClientId() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientId() => clearField(5);
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
    final $result = create();
    if (ruleSetUrl != null) {
      $result.ruleSetUrl = ruleSetUrl;
    }
    if (domains != null) {
      $result.domains = domains;
    }
    if (ip != null) {
      $result.ip = ip;
    }
    if (port != null) {
      $result.port = port;
    }
    if (network != null) {
      $result.network = network;
    }
    if (protocol != null) {
      $result.protocol = protocol;
    }
    if (outbound != null) {
      $result.outbound = outbound;
    }
    return $result;
  }
  Rule._() : super();
  factory Rule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Rule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Rule', package: const $pb.PackageName(_omitMessageNames ? '' : 'hiddifyoptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ruleSetUrl')
    ..aOS(2, _omitFieldNames ? '' : 'domains')
    ..aOS(3, _omitFieldNames ? '' : 'ip')
    ..aOS(4, _omitFieldNames ? '' : 'port')
    ..aOS(5, _omitFieldNames ? '' : 'network')
    ..aOS(6, _omitFieldNames ? '' : 'protocol')
    ..aOS(7, _omitFieldNames ? '' : 'outbound')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Rule clone() => Rule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Rule copyWith(void Function(Rule) updates) => super.copyWith((message) => updates(message as Rule)) as Rule;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Rule create() => Rule._();
  Rule createEmptyInstance() => create();
  static $pb.PbList<Rule> createRepeated() => $pb.PbList<Rule>();
  @$core.pragma('dart2js:noInline')
  static Rule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Rule>(create);
  static Rule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ruleSetUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set ruleSetUrl($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRuleSetUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearRuleSetUrl() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get domains => $_getSZ(1);
  @$pb.TagNumber(2)
  set domains($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDomains() => $_has(1);
  @$pb.TagNumber(2)
  void clearDomains() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get ip => $_getSZ(2);
  @$pb.TagNumber(3)
  set ip($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIp() => $_has(2);
  @$pb.TagNumber(3)
  void clearIp() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get port => $_getSZ(3);
  @$pb.TagNumber(4)
  set port($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearPort() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get network => $_getSZ(4);
  @$pb.TagNumber(5)
  set network($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasNetwork() => $_has(4);
  @$pb.TagNumber(5)
  void clearNetwork() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get protocol => $_getSZ(5);
  @$pb.TagNumber(6)
  set protocol($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasProtocol() => $_has(5);
  @$pb.TagNumber(6)
  void clearProtocol() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get outbound => $_getSZ(6);
  @$pb.TagNumber(7)
  set outbound($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasOutbound() => $_has(6);
  @$pb.TagNumber(7)
  void clearOutbound() => clearField(7);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
