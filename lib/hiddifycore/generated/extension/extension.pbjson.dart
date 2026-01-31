///
//  Generated code. Do not modify.
//  source: extension/extension.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use extensionResponseTypeDescriptor instead')
const ExtensionResponseType$json = const {
  '1': 'ExtensionResponseType',
  '2': const [
    const {'1': 'NOTHING', '2': 0},
    const {'1': 'UPDATE_UI', '2': 1},
    const {'1': 'SHOW_DIALOG', '2': 2},
    const {'1': 'END', '2': 3},
  ],
};

/// Descriptor for `ExtensionResponseType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List extensionResponseTypeDescriptor = $convert.base64Decode('ChVFeHRlbnNpb25SZXNwb25zZVR5cGUSCwoHTk9USElORxAAEg0KCVVQREFURV9VSRABEg8KC1NIT1dfRElBTE9HEAISBwoDRU5EEAM=');
@$core.Deprecated('Use extensionActionResultDescriptor instead')
const ExtensionActionResult$json = const {
  '1': 'ExtensionActionResult',
  '2': const [
    const {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    const {'1': 'code', '3': 2, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'code'},
    const {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ExtensionActionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionActionResultDescriptor = $convert.base64Decode('ChVFeHRlbnNpb25BY3Rpb25SZXN1bHQSIQoMZXh0ZW5zaW9uX2lkGAEgASgJUgtleHRlbnNpb25JZBIpCgRjb2RlGAIgASgOMhUuaGNvbW1vbi5SZXNwb25zZUNvZGVSBGNvZGUSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZQ==');
@$core.Deprecated('Use extensionListDescriptor instead')
const ExtensionList$json = const {
  '1': 'ExtensionList',
  '2': const [
    const {'1': 'extensions', '3': 1, '4': 3, '5': 11, '6': '.extension.ExtensionMsg', '10': 'extensions'},
  ],
};

/// Descriptor for `ExtensionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionListDescriptor = $convert.base64Decode('Cg1FeHRlbnNpb25MaXN0EjcKCmV4dGVuc2lvbnMYASADKAsyFy5leHRlbnNpb24uRXh0ZW5zaW9uTXNnUgpleHRlbnNpb25z');
@$core.Deprecated('Use editExtensionRequestDescriptor instead')
const EditExtensionRequest$json = const {
  '1': 'EditExtensionRequest',
  '2': const [
    const {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    const {'1': 'enable', '3': 2, '4': 1, '5': 8, '10': 'enable'},
  ],
};

/// Descriptor for `EditExtensionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editExtensionRequestDescriptor = $convert.base64Decode('ChRFZGl0RXh0ZW5zaW9uUmVxdWVzdBIhCgxleHRlbnNpb25faWQYASABKAlSC2V4dGVuc2lvbklkEhYKBmVuYWJsZRgCIAEoCFIGZW5hYmxl');
@$core.Deprecated('Use extensionMsgDescriptor instead')
const ExtensionMsg$json = const {
  '1': 'ExtensionMsg',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    const {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    const {'1': 'enable', '3': 4, '4': 1, '5': 8, '10': 'enable'},
  ],
};

/// Descriptor for `ExtensionMsg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionMsgDescriptor = $convert.base64Decode('CgxFeHRlbnNpb25Nc2cSDgoCaWQYASABKAlSAmlkEhQKBXRpdGxlGAIgASgJUgV0aXRsZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SFgoGZW5hYmxlGAQgASgIUgZlbmFibGU=');
@$core.Deprecated('Use extensionRequestDescriptor instead')
const ExtensionRequest$json = const {
  '1': 'ExtensionRequest',
  '2': const [
    const {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    const {'1': 'data', '3': 2, '4': 3, '5': 11, '6': '.extension.ExtensionRequest.DataEntry', '10': 'data'},
  ],
  '3': const [ExtensionRequest_DataEntry$json],
};

@$core.Deprecated('Use extensionRequestDescriptor instead')
const ExtensionRequest_DataEntry$json = const {
  '1': 'DataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `ExtensionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionRequestDescriptor = $convert.base64Decode('ChBFeHRlbnNpb25SZXF1ZXN0EiEKDGV4dGVuc2lvbl9pZBgBIAEoCVILZXh0ZW5zaW9uSWQSOQoEZGF0YRgCIAMoCzIlLmV4dGVuc2lvbi5FeHRlbnNpb25SZXF1ZXN0LkRhdGFFbnRyeVIEZGF0YRo3CglEYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
@$core.Deprecated('Use sendExtensionDataRequestDescriptor instead')
const SendExtensionDataRequest$json = const {
  '1': 'SendExtensionDataRequest',
  '2': const [
    const {'1': 'extension_id', '3': 1, '4': 1, '5': 9, '10': 'extensionId'},
    const {'1': 'button', '3': 2, '4': 1, '5': 9, '10': 'button'},
    const {'1': 'data', '3': 3, '4': 3, '5': 11, '6': '.extension.SendExtensionDataRequest.DataEntry', '10': 'data'},
  ],
  '3': const [SendExtensionDataRequest_DataEntry$json],
};

@$core.Deprecated('Use sendExtensionDataRequestDescriptor instead')
const SendExtensionDataRequest_DataEntry$json = const {
  '1': 'DataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `SendExtensionDataRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendExtensionDataRequestDescriptor = $convert.base64Decode('ChhTZW5kRXh0ZW5zaW9uRGF0YVJlcXVlc3QSIQoMZXh0ZW5zaW9uX2lkGAEgASgJUgtleHRlbnNpb25JZBIWCgZidXR0b24YAiABKAlSBmJ1dHRvbhJBCgRkYXRhGAMgAygLMi0uZXh0ZW5zaW9uLlNlbmRFeHRlbnNpb25EYXRhUmVxdWVzdC5EYXRhRW50cnlSBGRhdGEaNwoJRGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');
@$core.Deprecated('Use extensionResponseDescriptor instead')
const ExtensionResponse$json = const {
  '1': 'ExtensionResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.extension.ExtensionResponseType', '10': 'type'},
    const {'1': 'extension_id', '3': 2, '4': 1, '5': 9, '10': 'extensionId'},
    const {'1': 'json_ui', '3': 3, '4': 1, '5': 9, '10': 'jsonUi'},
  ],
};

/// Descriptor for `ExtensionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionResponseDescriptor = $convert.base64Decode('ChFFeHRlbnNpb25SZXNwb25zZRI0CgR0eXBlGAEgASgOMiAuZXh0ZW5zaW9uLkV4dGVuc2lvblJlc3BvbnNlVHlwZVIEdHlwZRIhCgxleHRlbnNpb25faWQYAiABKAlSC2V4dGVuc2lvbklkEhcKB2pzb25fdWkYAyABKAlSBmpzb25VaQ==');
