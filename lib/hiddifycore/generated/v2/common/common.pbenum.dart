//
//  Generated code. Do not modify.
//  source: v2/common/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ResponseCode extends $pb.ProtobufEnum {
  static const ResponseCode OK = ResponseCode._(0, _omitEnumNames ? '' : 'OK');
  static const ResponseCode FAILED = ResponseCode._(1, _omitEnumNames ? '' : 'FAILED');
  static const ResponseCode AUTH_NEED = ResponseCode._(2, _omitEnumNames ? '' : 'AUTH_NEED');

  static const $core.List<ResponseCode> values = <ResponseCode>[
    OK,
    FAILED,
    AUTH_NEED,
  ];

  static final $core.Map<$core.int, ResponseCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ResponseCode? valueOf($core.int value) => _byValue[value];

  const ResponseCode._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
