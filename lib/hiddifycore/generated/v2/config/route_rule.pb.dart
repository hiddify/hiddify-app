///
//  Generated code. Do not modify.
//  source: v2/config/route_rule.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'route_rule.pbenum.dart';

export 'route_rule.pbenum.dart';

class RouteRule extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RouteRule', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'config'), createEmptyInstance: create)
    ..pc<Rule>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rules', $pb.PbFieldType.PM, subBuilder: Rule.create)
    ..hasRequiredFields = false
  ;

  RouteRule._() : super();
  factory RouteRule({
    $core.Iterable<Rule>? rules,
  }) {
    final _result = create();
    if (rules != null) {
      _result.rules.addAll(rules);
    }
    return _result;
  }
  factory RouteRule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RouteRule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RouteRule clone() => RouteRule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RouteRule copyWith(void Function(RouteRule) updates) => super.copyWith((message) => updates(message as RouteRule)) as RouteRule; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RouteRule create() => RouteRule._();
  RouteRule createEmptyInstance() => create();
  static $pb.PbList<RouteRule> createRepeated() => $pb.PbList<RouteRule>();
  @$core.pragma('dart2js:noInline')
  static RouteRule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RouteRule>(create);
  static RouteRule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Rule> get rules => $_getList(0);
}

class Rule extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Rule', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'config'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'list_order', $pb.PbFieldType.OU3)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enabled')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..e<Outbound>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outbound', $pb.PbFieldType.OE, defaultOrMaker: Outbound.proxy, valueOf: Outbound.valueOf, enumValues: Outbound.values)
    ..pPS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rule_set', protoName: 'rule_sets')
    ..pPS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'package_name', protoName: 'package_names')
    ..pPS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'process_name', protoName: 'process_names')
    ..pPS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'process_path', protoName: 'process_paths')
    ..e<Network>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'network', $pb.PbFieldType.OE, defaultOrMaker: Network.all, valueOf: Network.valueOf, enumValues: Network.values)
    ..pPS(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'port_range', protoName: 'port_ranges')
    ..pPS(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'source_port_range', protoName: 'source_port_ranges')
    ..pc<Protocol>(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'protocol', $pb.PbFieldType.KE, protoName: 'protocols', valueOf: Protocol.valueOf, enumValues: Protocol.values, defaultEnumValue: Protocol.tls)
    ..pPS(13, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ip_cidr', protoName: 'ip_cidrs')
    ..pPS(14, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'source_ip_cidr', protoName: 'source_ip_cidrs')
    ..pPS(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'domain', protoName: 'domains')
    ..pPS(16, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'domain_suffix', protoName: 'domain_suffixes')
    ..pPS(17, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'domain_keyword', protoName: 'domain_keywords')
    ..pPS(18, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'domain_regex', protoName: 'domain_regexes')
    ..hasRequiredFields = false
  ;

  Rule._() : super();
  factory Rule({
    $core.int? listOrder,
    $core.bool? enabled,
    $core.String? name,
    Outbound? outbound,
    $core.Iterable<$core.String>? ruleSets,
    $core.Iterable<$core.String>? packageNames,
    $core.Iterable<$core.String>? processNames,
    $core.Iterable<$core.String>? processPaths,
    Network? network,
    $core.Iterable<$core.String>? portRanges,
    $core.Iterable<$core.String>? sourcePortRanges,
    $core.Iterable<Protocol>? protocols,
    $core.Iterable<$core.String>? ipCidrs,
    $core.Iterable<$core.String>? sourceIpCidrs,
    $core.Iterable<$core.String>? domains,
    $core.Iterable<$core.String>? domainSuffixes,
    $core.Iterable<$core.String>? domainKeywords,
    $core.Iterable<$core.String>? domainRegexes,
  }) {
    final _result = create();
    if (listOrder != null) {
      _result.listOrder = listOrder;
    }
    if (enabled != null) {
      _result.enabled = enabled;
    }
    if (name != null) {
      _result.name = name;
    }
    if (outbound != null) {
      _result.outbound = outbound;
    }
    if (ruleSets != null) {
      _result.ruleSets.addAll(ruleSets);
    }
    if (packageNames != null) {
      _result.packageNames.addAll(packageNames);
    }
    if (processNames != null) {
      _result.processNames.addAll(processNames);
    }
    if (processPaths != null) {
      _result.processPaths.addAll(processPaths);
    }
    if (network != null) {
      _result.network = network;
    }
    if (portRanges != null) {
      _result.portRanges.addAll(portRanges);
    }
    if (sourcePortRanges != null) {
      _result.sourcePortRanges.addAll(sourcePortRanges);
    }
    if (protocols != null) {
      _result.protocols.addAll(protocols);
    }
    if (ipCidrs != null) {
      _result.ipCidrs.addAll(ipCidrs);
    }
    if (sourceIpCidrs != null) {
      _result.sourceIpCidrs.addAll(sourceIpCidrs);
    }
    if (domains != null) {
      _result.domains.addAll(domains);
    }
    if (domainSuffixes != null) {
      _result.domainSuffixes.addAll(domainSuffixes);
    }
    if (domainKeywords != null) {
      _result.domainKeywords.addAll(domainKeywords);
    }
    if (domainRegexes != null) {
      _result.domainRegexes.addAll(domainRegexes);
    }
    return _result;
  }
  factory Rule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Rule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Rule clone() => Rule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Rule copyWith(void Function(Rule) updates) => super.copyWith((message) => updates(message as Rule)) as Rule; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Rule create() => Rule._();
  Rule createEmptyInstance() => create();
  static $pb.PbList<Rule> createRepeated() => $pb.PbList<Rule>();
  @$core.pragma('dart2js:noInline')
  static Rule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Rule>(create);
  static Rule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get listOrder => $_getIZ(0);
  @$pb.TagNumber(1)
  set listOrder($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasListOrder() => $_has(0);
  @$pb.TagNumber(1)
  void clearListOrder() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  Outbound get outbound => $_getN(3);
  @$pb.TagNumber(4)
  set outbound(Outbound v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasOutbound() => $_has(3);
  @$pb.TagNumber(4)
  void clearOutbound() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.String> get ruleSets => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$core.String> get packageNames => $_getList(5);

  @$pb.TagNumber(7)
  $core.List<$core.String> get processNames => $_getList(6);

  @$pb.TagNumber(8)
  $core.List<$core.String> get processPaths => $_getList(7);

  @$pb.TagNumber(9)
  Network get network => $_getN(8);
  @$pb.TagNumber(9)
  set network(Network v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasNetwork() => $_has(8);
  @$pb.TagNumber(9)
  void clearNetwork() => clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.String> get portRanges => $_getList(9);

  @$pb.TagNumber(11)
  $core.List<$core.String> get sourcePortRanges => $_getList(10);

  @$pb.TagNumber(12)
  $core.List<Protocol> get protocols => $_getList(11);

  @$pb.TagNumber(13)
  $core.List<$core.String> get ipCidrs => $_getList(12);

  @$pb.TagNumber(14)
  $core.List<$core.String> get sourceIpCidrs => $_getList(13);

  @$pb.TagNumber(15)
  $core.List<$core.String> get domains => $_getList(14);

  @$pb.TagNumber(16)
  $core.List<$core.String> get domainSuffixes => $_getList(15);

  @$pb.TagNumber(17)
  $core.List<$core.String> get domainKeywords => $_getList(16);

  @$pb.TagNumber(18)
  $core.List<$core.String> get domainRegexes => $_getList(17);
}

