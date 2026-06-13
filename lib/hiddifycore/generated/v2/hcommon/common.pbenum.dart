// This is a generated file - do not edit.
//
// Generated from v2/hcommon/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ResponseCode extends $pb.ProtobufEnum {
  static const ResponseCode OK = ResponseCode._(0, _omitEnumNames ? '' : 'OK');
  static const ResponseCode FAILED =
      ResponseCode._(1, _omitEnumNames ? '' : 'FAILED');
  static const ResponseCode AUTH_NEED =
      ResponseCode._(2, _omitEnumNames ? '' : 'AUTH_NEED');

  static const $core.List<ResponseCode> values = <ResponseCode>[
    OK,
    FAILED,
    AUTH_NEED,
  ];

  static final $core.List<ResponseCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ResponseCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ResponseCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
