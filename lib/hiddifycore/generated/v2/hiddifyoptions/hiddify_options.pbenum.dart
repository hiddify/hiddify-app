///
//  Generated code. Do not modify.
//  source: v2/hiddifyoptions/hiddify_options.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DomainStrategy extends $pb.ProtobufEnum {
  static const DomainStrategy as_is = DomainStrategy._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'as_is');
  static const DomainStrategy prefer_ipv4 = DomainStrategy._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'prefer_ipv4');
  static const DomainStrategy prefer_ipv6 = DomainStrategy._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'prefer_ipv6');
  static const DomainStrategy ipv4_only = DomainStrategy._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ipv4_only');
  static const DomainStrategy ipv6_only = DomainStrategy._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ipv6_only');

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

