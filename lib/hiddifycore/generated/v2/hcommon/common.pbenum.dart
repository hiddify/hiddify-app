///
//  Generated code. Do not modify.
//  source: v2/hcommon/common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ResponseCode extends $pb.ProtobufEnum {
  static const ResponseCode OK = ResponseCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OK');
  static const ResponseCode FAILED = ResponseCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FAILED');
  static const ResponseCode AUTH_NEED = ResponseCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AUTH_NEED');

  static const $core.List<ResponseCode> values = <ResponseCode> [
    OK,
    FAILED,
    AUTH_NEED,
  ];

  static final $core.Map<$core.int, ResponseCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ResponseCode? valueOf($core.int value) => _byValue[value];

  const ResponseCode._($core.int v, $core.String n) : super(v, n);
}

