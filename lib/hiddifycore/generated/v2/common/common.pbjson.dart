//
//  Generated code. Do not modify.
//  source: v2/common/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use responseCodeDescriptor instead')
const ResponseCode$json = {
  '1': 'ResponseCode',
  '2': [
    {'1': 'OK', '2': 0},
    {'1': 'FAILED', '2': 1},
    {'1': 'AUTH_NEED', '2': 2},
  ],
};

/// Descriptor for `ResponseCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List responseCodeDescriptor =
    $convert.base64Decode('CgxSZXNwb25zZUNvZGUSBgoCT0sQABIKCgZGQUlMRUQQARINCglBVVRIX05FRUQQAg==');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor = $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.common.ResponseCode', '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor =
    $convert.base64Decode('CghSZXNwb25zZRIoCgRjb2RlGAEgASgOMhQuY29tbW9uLlJlc3BvbnNlQ29kZVIEY29kZRIYCg'
        'dtZXNzYWdlGAIgASgJUgdtZXNzYWdl');
