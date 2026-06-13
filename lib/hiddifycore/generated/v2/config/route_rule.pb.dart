// This is a generated file - do not edit.
//
// Generated from v2/config/route_rule.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'route_rule.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'route_rule.pbenum.dart';

class RouteRule extends $pb.GeneratedMessage {
  factory RouteRule({
    $core.Iterable<Rule>? rules,
  }) {
    final result = create();
    if (rules != null) result.rules.addAll(rules);
    return result;
  }

  RouteRule._();

  factory RouteRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RouteRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RouteRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'config'),
      createEmptyInstance: create)
    ..pPM<Rule>(1, _omitFieldNames ? '' : 'rules', subBuilder: Rule.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RouteRule copyWith(void Function(RouteRule) updates) =>
      super.copyWith((message) => updates(message as RouteRule)) as RouteRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RouteRule create() => RouteRule._();
  @$core.override
  RouteRule createEmptyInstance() => create();
  static $pb.PbList<RouteRule> createRepeated() => $pb.PbList<RouteRule>();
  @$core.pragma('dart2js:noInline')
  static RouteRule getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RouteRule>(create);
  static RouteRule? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Rule> get rules => $_getList(0);
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
    final result = create();
    if (listOrder != null) result.listOrder = listOrder;
    if (enabled != null) result.enabled = enabled;
    if (name != null) result.name = name;
    if (outbound != null) result.outbound = outbound;
    if (ruleSets != null) result.ruleSets.addAll(ruleSets);
    if (packageNames != null) result.packageNames.addAll(packageNames);
    if (processNames != null) result.processNames.addAll(processNames);
    if (processPaths != null) result.processPaths.addAll(processPaths);
    if (network != null) result.network = network;
    if (portRanges != null) result.portRanges.addAll(portRanges);
    if (sourcePortRanges != null)
      result.sourcePortRanges.addAll(sourcePortRanges);
    if (protocols != null) result.protocols.addAll(protocols);
    if (ipCidrs != null) result.ipCidrs.addAll(ipCidrs);
    if (sourceIpCidrs != null) result.sourceIpCidrs.addAll(sourceIpCidrs);
    if (domains != null) result.domains.addAll(domains);
    if (domainSuffixes != null) result.domainSuffixes.addAll(domainSuffixes);
    if (domainKeywords != null) result.domainKeywords.addAll(domainKeywords);
    if (domainRegexes != null) result.domainRegexes.addAll(domainRegexes);
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
      package: const $pb.PackageName(_omitMessageNames ? '' : 'config'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'list_order', fieldType: $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<Outbound>(4, _omitFieldNames ? '' : 'outbound',
        enumValues: Outbound.values)
    ..pPS(5, _omitFieldNames ? '' : 'rule_set', protoName: 'rule_sets')
    ..pPS(6, _omitFieldNames ? '' : 'package_name', protoName: 'package_names')
    ..pPS(7, _omitFieldNames ? '' : 'process_name', protoName: 'process_names')
    ..pPS(8, _omitFieldNames ? '' : 'process_path', protoName: 'process_paths')
    ..aE<Network>(9, _omitFieldNames ? '' : 'network',
        enumValues: Network.values)
    ..pPS(10, _omitFieldNames ? '' : 'port_range', protoName: 'port_ranges')
    ..pPS(11, _omitFieldNames ? '' : 'source_port_range',
        protoName: 'source_port_ranges')
    ..pc<Protocol>(12, _omitFieldNames ? '' : 'protocol', $pb.PbFieldType.KE,
        protoName: 'protocols',
        valueOf: Protocol.valueOf,
        enumValues: Protocol.values,
        defaultEnumValue: Protocol.tls)
    ..pPS(13, _omitFieldNames ? '' : 'ip_cidr', protoName: 'ip_cidrs')
    ..pPS(14, _omitFieldNames ? '' : 'source_ip_cidr',
        protoName: 'source_ip_cidrs')
    ..pPS(15, _omitFieldNames ? '' : 'domain', protoName: 'domains')
    ..pPS(16, _omitFieldNames ? '' : 'domain_suffix',
        protoName: 'domain_suffixes')
    ..pPS(17, _omitFieldNames ? '' : 'domain_keyword',
        protoName: 'domain_keywords')
    ..pPS(18, _omitFieldNames ? '' : 'domain_regex',
        protoName: 'domain_regexes')
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
  $core.int get listOrder => $_getIZ(0);
  @$pb.TagNumber(1)
  set listOrder($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasListOrder() => $_has(0);
  @$pb.TagNumber(1)
  void clearListOrder() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  Outbound get outbound => $_getN(3);
  @$pb.TagNumber(4)
  set outbound(Outbound value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOutbound() => $_has(3);
  @$pb.TagNumber(4)
  void clearOutbound() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get ruleSets => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get packageNames => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get processNames => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get processPaths => $_getList(7);

  @$pb.TagNumber(9)
  Network get network => $_getN(8);
  @$pb.TagNumber(9)
  set network(Network value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasNetwork() => $_has(8);
  @$pb.TagNumber(9)
  void clearNetwork() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get portRanges => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get sourcePortRanges => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<Protocol> get protocols => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get ipCidrs => $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<$core.String> get sourceIpCidrs => $_getList(13);

  @$pb.TagNumber(15)
  $pb.PbList<$core.String> get domains => $_getList(14);

  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get domainSuffixes => $_getList(15);

  @$pb.TagNumber(17)
  $pb.PbList<$core.String> get domainKeywords => $_getList(16);

  @$pb.TagNumber(18)
  $pb.PbList<$core.String> get domainRegexes => $_getList(17);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
