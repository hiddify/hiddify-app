//
//  Generated code. Do not modify.
//  source: v2/config/route_rule.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'route_rule.pbenum.dart';

export 'route_rule.pbenum.dart';

class RouteRule extends $pb.GeneratedMessage {
  factory RouteRule({
    $core.Iterable<Rule>? rules,
  }) {
    final $result = create();
    if (rules != null) {
      $result.rules.addAll(rules);
    }
    return $result;
  }
  RouteRule._() : super();
  factory RouteRule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RouteRule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RouteRule', package: const $pb.PackageName(_omitMessageNames ? '' : 'config'), createEmptyInstance: create)
    ..pc<Rule>(1, _omitFieldNames ? '' : 'rules', $pb.PbFieldType.PM, subBuilder: Rule.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RouteRule clone() => RouteRule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RouteRule copyWith(void Function(RouteRule) updates) => super.copyWith((message) => updates(message as RouteRule)) as RouteRule;

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
    final $result = create();
    if (listOrder != null) {
      $result.listOrder = listOrder;
    }
    if (enabled != null) {
      $result.enabled = enabled;
    }
    if (name != null) {
      $result.name = name;
    }
    if (outbound != null) {
      $result.outbound = outbound;
    }
    if (ruleSets != null) {
      $result.ruleSets.addAll(ruleSets);
    }
    if (packageNames != null) {
      $result.packageNames.addAll(packageNames);
    }
    if (processNames != null) {
      $result.processNames.addAll(processNames);
    }
    if (processPaths != null) {
      $result.processPaths.addAll(processPaths);
    }
    if (network != null) {
      $result.network = network;
    }
    if (portRanges != null) {
      $result.portRanges.addAll(portRanges);
    }
    if (sourcePortRanges != null) {
      $result.sourcePortRanges.addAll(sourcePortRanges);
    }
    if (protocols != null) {
      $result.protocols.addAll(protocols);
    }
    if (ipCidrs != null) {
      $result.ipCidrs.addAll(ipCidrs);
    }
    if (sourceIpCidrs != null) {
      $result.sourceIpCidrs.addAll(sourceIpCidrs);
    }
    if (domains != null) {
      $result.domains.addAll(domains);
    }
    if (domainSuffixes != null) {
      $result.domainSuffixes.addAll(domainSuffixes);
    }
    if (domainKeywords != null) {
      $result.domainKeywords.addAll(domainKeywords);
    }
    if (domainRegexes != null) {
      $result.domainRegexes.addAll(domainRegexes);
    }
    return $result;
  }
  Rule._() : super();
  factory Rule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Rule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Rule', package: const $pb.PackageName(_omitMessageNames ? '' : 'config'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'list_order', $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..e<Outbound>(4, _omitFieldNames ? '' : 'outbound', $pb.PbFieldType.OE, defaultOrMaker: Outbound.proxy, valueOf: Outbound.valueOf, enumValues: Outbound.values)
    ..pPS(5, _omitFieldNames ? '' : 'rule_set', protoName: 'rule_sets')
    ..pPS(6, _omitFieldNames ? '' : 'package_name', protoName: 'package_names')
    ..pPS(7, _omitFieldNames ? '' : 'process_name', protoName: 'process_names')
    ..pPS(8, _omitFieldNames ? '' : 'process_path', protoName: 'process_paths')
    ..e<Network>(9, _omitFieldNames ? '' : 'network', $pb.PbFieldType.OE, defaultOrMaker: Network.all, valueOf: Network.valueOf, enumValues: Network.values)
    ..pPS(10, _omitFieldNames ? '' : 'port_range', protoName: 'port_ranges')
    ..pPS(11, _omitFieldNames ? '' : 'source_port_range', protoName: 'source_port_ranges')
    ..pc<Protocol>(12, _omitFieldNames ? '' : 'protocol', $pb.PbFieldType.KE, protoName: 'protocols', valueOf: Protocol.valueOf, enumValues: Protocol.values, defaultEnumValue: Protocol.tls)
    ..pPS(13, _omitFieldNames ? '' : 'ip_cidr', protoName: 'ip_cidrs')
    ..pPS(14, _omitFieldNames ? '' : 'source_ip_cidr', protoName: 'source_ip_cidrs')
    ..pPS(15, _omitFieldNames ? '' : 'domain', protoName: 'domains')
    ..pPS(16, _omitFieldNames ? '' : 'domain_suffix', protoName: 'domain_suffixes')
    ..pPS(17, _omitFieldNames ? '' : 'domain_keyword', protoName: 'domain_keywords')
    ..pPS(18, _omitFieldNames ? '' : 'domain_regex', protoName: 'domain_regexes')
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


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
