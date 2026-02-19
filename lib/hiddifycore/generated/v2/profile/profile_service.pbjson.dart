///
//  Generated code. Do not modify.
//  source: v2/profile/profile_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use profileRequestDescriptor instead')
const ProfileRequest$json = const {
  '1': 'ProfileRequest',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'url', '3': 3, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `ProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileRequestDescriptor = $convert.base64Decode('Cg5Qcm9maWxlUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIQCgN1cmwYAyABKAlSA3VybA==');
@$core.Deprecated('Use addProfileRequestDescriptor instead')
const AddProfileRequest$json = const {
  '1': 'AddProfileRequest',
  '2': const [
    const {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    const {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'mark_as_active', '3': 4, '4': 1, '5': 8, '10': 'markAsActive'},
  ],
};

/// Descriptor for `AddProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addProfileRequestDescriptor = $convert.base64Decode('ChFBZGRQcm9maWxlUmVxdWVzdBIQCgN1cmwYASABKAlSA3VybBIYCgdjb250ZW50GAIgASgJUgdjb250ZW50EhIKBG5hbWUYAyABKAlSBG5hbWUSJAoObWFya19hc19hY3RpdmUYBCABKAhSDG1hcmtBc0FjdGl2ZQ==');
@$core.Deprecated('Use profileResponseDescriptor instead')
const ProfileResponse$json = const {
  '1': 'ProfileResponse',
  '2': const [
    const {'1': 'profile', '3': 1, '4': 1, '5': 11, '6': '.profile.ProfileEntity', '10': 'profile'},
    const {'1': 'response_code', '3': 2, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'responseCode'},
    const {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileResponseDescriptor = $convert.base64Decode('Cg9Qcm9maWxlUmVzcG9uc2USMAoHcHJvZmlsZRgBIAEoCzIWLnByb2ZpbGUuUHJvZmlsZUVudGl0eVIHcHJvZmlsZRI6Cg1yZXNwb25zZV9jb2RlGAIgASgOMhUuaGNvbW1vbi5SZXNwb25zZUNvZGVSDHJlc3BvbnNlQ29kZRIYCgdtZXNzYWdlGAMgASgJUgdtZXNzYWdl');
@$core.Deprecated('Use multiProfilesResponseDescriptor instead')
const MultiProfilesResponse$json = const {
  '1': 'MultiProfilesResponse',
  '2': const [
    const {'1': 'profiles', '3': 1, '4': 3, '5': 11, '6': '.profile.ProfileEntity', '10': 'profiles'},
    const {'1': 'response_code', '3': 2, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'responseCode'},
    const {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `MultiProfilesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List multiProfilesResponseDescriptor = $convert.base64Decode('ChVNdWx0aVByb2ZpbGVzUmVzcG9uc2USMgoIcHJvZmlsZXMYASADKAsyFi5wcm9maWxlLlByb2ZpbGVFbnRpdHlSCHByb2ZpbGVzEjoKDXJlc3BvbnNlX2NvZGUYAiABKA4yFS5oY29tbW9uLlJlc3BvbnNlQ29kZVIMcmVzcG9uc2VDb2RlEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');
