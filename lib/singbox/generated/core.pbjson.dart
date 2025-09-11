//
//  Generated code. Do not modify.
//  source: core.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use parseConfigRequestDescriptor instead')
const ParseConfigRequest$json = {
  '1': 'ParseConfigRequest',
  '2': [
    {'1': 'tempPath', '3': 1, '4': 1, '5': 9, '10': 'tempPath'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'debug', '3': 3, '4': 1, '5': 8, '10': 'debug'},
  ],
};

/// Descriptor for `ParseConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseConfigRequestDescriptor = $convert.base64Decode(
    'ChJQYXJzZUNvbmZpZ1JlcXVlc3QSGgoIdGVtcFBhdGgYASABKAlSCHRlbXBQYXRoEhIKBHBhdG'
    'gYAiABKAlSBHBhdGgSFAoFZGVidWcYAyABKAhSBWRlYnVn');

@$core.Deprecated('Use parseConfigResponseDescriptor instead')
const ParseConfigResponse$json = {
  '1': 'ParseConfigResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'error', '17': true},
  ],
  '8': [
    {'1': '_error'},
  ],
};

/// Descriptor for `ParseConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseConfigResponseDescriptor = $convert.base64Decode(
    'ChNQYXJzZUNvbmZpZ1Jlc3BvbnNlEhkKBWVycm9yGAEgASgJSABSBWVycm9yiAEBQggKBl9lcn'
    'Jvcg==');

@$core.Deprecated('Use generateConfigRequestDescriptor instead')
const GenerateConfigRequest$json = {
  '1': 'GenerateConfigRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'debug', '3': 2, '4': 1, '5': 8, '10': 'debug'},
  ],
};

/// Descriptor for `GenerateConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateConfigRequestDescriptor = $convert.base64Decode(
    'ChVHZW5lcmF0ZUNvbmZpZ1JlcXVlc3QSEgoEcGF0aBgBIAEoCVIEcGF0aBIUCgVkZWJ1ZxgCIA'
    'EoCFIFZGVidWc=');

@$core.Deprecated('Use generateConfigResponseDescriptor instead')
const GenerateConfigResponse$json = {
  '1': 'GenerateConfigResponse',
  '2': [
    {'1': 'config', '3': 1, '4': 1, '5': 9, '10': 'config'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'error', '17': true},
  ],
  '8': [
    {'1': '_error'},
  ],
};

/// Descriptor for `GenerateConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateConfigResponseDescriptor = $convert.base64Decode(
    'ChZHZW5lcmF0ZUNvbmZpZ1Jlc3BvbnNlEhYKBmNvbmZpZxgBIAEoCVIGY29uZmlnEhkKBWVycm'
    '9yGAIgASgJSABSBWVycm9yiAEBQggKBl9lcnJvcg==');

