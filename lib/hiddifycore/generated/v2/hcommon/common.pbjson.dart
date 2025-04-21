///
//  Generated code. Do not modify.
//  source: v2/hcommon/common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use responseCodeDescriptor instead')
const ResponseCode$json = const {
  '1': 'ResponseCode',
  '2': const [
    const {'1': 'OK', '2': 0},
    const {'1': 'FAILED', '2': 1},
    const {'1': 'AUTH_NEED', '2': 2},
  ],
};

/// Descriptor for `ResponseCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List responseCodeDescriptor = $convert.base64Decode('CgxSZXNwb25zZUNvZGUSBgoCT0sQABIKCgZGQUlMRUQQARINCglBVVRIX05FRUQQAg==');
@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = const {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor = $convert.base64Decode('CgVFbXB0eQ==');
@$core.Deprecated('Use responseDescriptor instead')
const Response$json = const {
  '1': 'Response',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'code'},
    const {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode('CghSZXNwb25zZRIpCgRjb2RlGAEgASgOMhUuaGNvbW1vbi5SZXNwb25zZUNvZGVSBGNvZGUSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');
