//
//  Generated code. Do not modify.
//  source: v2/profile/profile_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use profileRequestDescriptor instead')
const ProfileRequest$json = {
  '1': 'ProfileRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'url', '3': 3, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `ProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileRequestDescriptor = $convert.base64Decode(
    'Cg5Qcm9maWxlUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIQCg'
    'N1cmwYAyABKAlSA3VybA==');

@$core.Deprecated('Use addProfileRequestDescriptor instead')
const AddProfileRequest$json = {
  '1': 'AddProfileRequest',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'mark_as_active', '3': 4, '4': 1, '5': 8, '10': 'markAsActive'},
  ],
};

/// Descriptor for `AddProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addProfileRequestDescriptor = $convert.base64Decode(
    'ChFBZGRQcm9maWxlUmVxdWVzdBIQCgN1cmwYASABKAlSA3VybBIYCgdjb250ZW50GAIgASgJUg'
    'djb250ZW50EhIKBG5hbWUYAyABKAlSBG5hbWUSJAoObWFya19hc19hY3RpdmUYBCABKAhSDG1h'
    'cmtBc0FjdGl2ZQ==');

@$core.Deprecated('Use profileResponseDescriptor instead')
const ProfileResponse$json = {
  '1': 'ProfileResponse',
  '2': [
    {'1': 'profile', '3': 1, '4': 1, '5': 11, '6': '.profile.ProfileEntity', '10': 'profile'},
    {'1': 'response_code', '3': 2, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'responseCode'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileResponseDescriptor = $convert.base64Decode(
    'Cg9Qcm9maWxlUmVzcG9uc2USMAoHcHJvZmlsZRgBIAEoCzIWLnByb2ZpbGUuUHJvZmlsZUVudG'
    'l0eVIHcHJvZmlsZRI6Cg1yZXNwb25zZV9jb2RlGAIgASgOMhUuaGNvbW1vbi5SZXNwb25zZUNv'
    'ZGVSDHJlc3BvbnNlQ29kZRIYCgdtZXNzYWdlGAMgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use multiProfilesResponseDescriptor instead')
const MultiProfilesResponse$json = {
  '1': 'MultiProfilesResponse',
  '2': [
    {'1': 'profiles', '3': 1, '4': 3, '5': 11, '6': '.profile.ProfileEntity', '10': 'profiles'},
    {'1': 'response_code', '3': 2, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'responseCode'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `MultiProfilesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List multiProfilesResponseDescriptor = $convert.base64Decode(
    'ChVNdWx0aVByb2ZpbGVzUmVzcG9uc2USMgoIcHJvZmlsZXMYASADKAsyFi5wcm9maWxlLlByb2'
    'ZpbGVFbnRpdHlSCHByb2ZpbGVzEjoKDXJlc3BvbnNlX2NvZGUYAiABKA4yFS5oY29tbW9uLlJl'
    'c3BvbnNlQ29kZVIMcmVzcG9uc2VDb2RlEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');

