//
//  Generated code. Do not modify.
//  source: extension/extension.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use extensionResponseTypeDescriptor instead')
const ExtensionResponseType$json = {
  '1': 'ExtensionResponseType',
  '2': [
    {'1': 'NOTHING', '2': 0},
    {'1': 'UPDATE_UI', '2': 1},
    {'1': 'SHOW_DIALOG', '2': 2},
    {'1': 'END', '2': 3},
  ],
};

/// Descriptor for `ExtensionResponseType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List extensionResponseTypeDescriptor = $convert.base64Decode(
    'ChVFeHRlbnNpb25SZXNwb25zZVR5cGUSCwoHTk9USElORxAAEg0KCVVQREFURV9VSRABEg8KC1'
    'NIT1dfRElBTE9HEAISBwoDRU5EEAM=');

@$core.Deprecated('Use extensionActionResultDescriptor instead')
const ExtensionActionResult$json = {
  '1': 'ExtensionActionResult',
  '2': [
    {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    {'1': 'code', '3': 2, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'code'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ExtensionActionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionActionResultDescriptor = $convert.base64Decode(
    'ChVFeHRlbnNpb25BY3Rpb25SZXN1bHQSIQoMZXh0ZW5zaW9uX2lkGAEgASgJUgtleHRlbnNpb2'
    '5JZBIpCgRjb2RlGAIgASgOMhUuaGNvbW1vbi5SZXNwb25zZUNvZGVSBGNvZGUSGAoHbWVzc2Fn'
    'ZRgDIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use extensionListDescriptor instead')
const ExtensionList$json = {
  '1': 'ExtensionList',
  '2': [
    {'1': 'extensions', '3': 1, '4': 3, '5': 11, '6': '.extension.ExtensionMsg', '10': 'extensions'},
  ],
};

/// Descriptor for `ExtensionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionListDescriptor = $convert.base64Decode(
    'Cg1FeHRlbnNpb25MaXN0EjcKCmV4dGVuc2lvbnMYASADKAsyFy5leHRlbnNpb24uRXh0ZW5zaW'
    '9uTXNnUgpleHRlbnNpb25z');

@$core.Deprecated('Use editExtensionRequestDescriptor instead')
const EditExtensionRequest$json = {
  '1': 'EditExtensionRequest',
  '2': [
    {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    {'1': 'enable', '3': 2, '4': 1, '5': 8, '10': 'enable'},
  ],
};

/// Descriptor for `EditExtensionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editExtensionRequestDescriptor = $convert.base64Decode(
    'ChRFZGl0RXh0ZW5zaW9uUmVxdWVzdBIhCgxleHRlbnNpb25faWQYASABKAlSC2V4dGVuc2lvbk'
    'lkEhYKBmVuYWJsZRgCIAEoCFIGZW5hYmxl');

@$core.Deprecated('Use extensionMsgDescriptor instead')
const ExtensionMsg$json = {
  '1': 'ExtensionMsg',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'enable', '3': 4, '4': 1, '5': 8, '10': 'enable'},
  ],
};

/// Descriptor for `ExtensionMsg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionMsgDescriptor = $convert.base64Decode(
    'CgxFeHRlbnNpb25Nc2cSDgoCaWQYASABKAlSAmlkEhQKBXRpdGxlGAIgASgJUgV0aXRsZRIgCg'
    'tkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SFgoGZW5hYmxlGAQgASgIUgZlbmFibGU=');

@$core.Deprecated('Use extensionRequestDescriptor instead')
const ExtensionRequest$json = {
  '1': 'ExtensionRequest',
  '2': [
    {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    {'1': 'data', '3': 2, '4': 3, '5': 11, '6': '.extension.ExtensionRequest.DataEntry', '10': 'data'},
  ],
  '3': [ExtensionRequest_DataEntry$json],
};

@$core.Deprecated('Use extensionRequestDescriptor instead')
const ExtensionRequest_DataEntry$json = {
  '1': 'DataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ExtensionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionRequestDescriptor = $convert.base64Decode(
    'ChBFeHRlbnNpb25SZXF1ZXN0EiEKDGV4dGVuc2lvbl9pZBgBIAEoCVILZXh0ZW5zaW9uSWQSOQ'
    'oEZGF0YRgCIAMoCzIlLmV4dGVuc2lvbi5FeHRlbnNpb25SZXF1ZXN0LkRhdGFFbnRyeVIEZGF0'
    'YRo3CglEYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOg'
    'I4AQ==');

@$core.Deprecated('Use sendExtensionDataRequestDescriptor instead')
const SendExtensionDataRequest$json = {
  '1': 'SendExtensionDataRequest',
  '2': [
    {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    {'1': 'button', '3': 2, '4': 1, '5': 9, '10': 'button'},
    {'1': 'data', '3': 3, '4': 3, '5': 11, '6': '.extension.SendExtensionDataRequest.DataEntry', '10': 'data'},
  ],
  '3': [SendExtensionDataRequest_DataEntry$json],
};

@$core.Deprecated('Use sendExtensionDataRequestDescriptor instead')
const SendExtensionDataRequest_DataEntry$json = {
  '1': 'DataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `SendExtensionDataRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendExtensionDataRequestDescriptor = $convert.base64Decode(
    'ChhTZW5kRXh0ZW5zaW9uRGF0YVJlcXVlc3QSIQoMZXh0ZW5zaW9uX2lkGAEgASgJUgtleHRlbn'
    'Npb25JZBIWCgZidXR0b24YAiABKAlSBmJ1dHRvbhJBCgRkYXRhGAMgAygLMi0uZXh0ZW5zaW9u'
    'LlNlbmRFeHRlbnNpb25EYXRhUmVxdWVzdC5EYXRhRW50cnlSBGRhdGEaNwoJRGF0YUVudHJ5Eh'
    'AKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use extensionResponseDescriptor instead')
const ExtensionResponse$json = {
  '1': 'ExtensionResponse',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.extension.ExtensionResponseType', '10': 'type'},
    {'1': 'extension_id', '3': 2, '4': 1, '5': 9, '10': 'extensionId'},
    {'1': 'json_ui', '3': 3, '4': 1, '5': 9, '10': 'jsonUi'},
  ],
};

/// Descriptor for `ExtensionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionResponseDescriptor = $convert.base64Decode(
    'ChFFeHRlbnNpb25SZXNwb25zZRI0CgR0eXBlGAEgASgOMiAuZXh0ZW5zaW9uLkV4dGVuc2lvbl'
    'Jlc3BvbnNlVHlwZVIEdHlwZRIhCgxleHRlbnNpb25faWQYAiABKAlSC2V4dGVuc2lvbklkEhcK'
    'B2pzb25fdWkYAyABKAlSBmpzb25VaQ==');

