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

import 'package:protobuf/protobuf.dart' as $pb;

/// *
///  DomainStrategy defines the strategies for IP address preference when resolving domain names.
class DomainStrategy extends $pb.ProtobufEnum {
  static const DomainStrategy as_is = DomainStrategy._(0, _omitEnumNames ? '' : 'as_is');
  static const DomainStrategy prefer_ipv4 = DomainStrategy._(1, _omitEnumNames ? '' : 'prefer_ipv4');
  static const DomainStrategy prefer_ipv6 = DomainStrategy._(2, _omitEnumNames ? '' : 'prefer_ipv6');
  static const DomainStrategy ipv4_only = DomainStrategy._(3, _omitEnumNames ? '' : 'ipv4_only');
  static const DomainStrategy ipv6_only = DomainStrategy._(4, _omitEnumNames ? '' : 'ipv6_only');

  static const $core.List<DomainStrategy> values = <DomainStrategy> [
    as_is,
    prefer_ipv4,
    prefer_ipv6,
    ipv4_only,
    ipv6_only,
  ];

  static final $core.Map<$core.int, DomainStrategy> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DomainStrategy? valueOf($core.int value) => _byValue[value];

  const DomainStrategy._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
