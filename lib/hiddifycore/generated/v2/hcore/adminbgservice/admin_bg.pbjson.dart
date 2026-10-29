//
//  Generated code. Do not modify.
//  source: v2/hcore/adminbgservice/admin_bg.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use adminBgStartRequestDescriptor instead')
const AdminBgStartRequest$json = {
  '1': 'AdminBgStartRequest',
  '2': [
    {'1': 'ipv6', '3': 1, '4': 1, '5': 8, '10': 'ipv6'},
    {'1': 'server_port', '3': 2, '4': 1, '5': 5, '10': 'serverPort'},
    {'1': 'server_username', '3': 3, '4': 1, '5': 9, '10': 'serverUsername'},
    {'1': 'server_password', '3': 4, '4': 1, '5': 9, '10': 'serverPassword'},
    {'1': 'strict_route', '3': 5, '4': 1, '5': 8, '10': 'strictRoute'},
    {'1': 'endpoint_independent_nat', '3': 6, '4': 1, '5': 8, '10': 'endpointIndependentNat'},
    {'1': 'stack', '3': 7, '4': 1, '5': 9, '10': 'stack'},
    {'1': 'config_content', '3': 8, '4': 1, '5': 9, '10': 'configContent'},
    {'1': 'config_name', '3': 9, '4': 1, '5': 9, '10': 'configName'},
    {'1': 'settings_json', '3': 10, '4': 1, '5': 9, '10': 'settingsJson'},
    {'1': 'resources', '3': 11, '4': 3, '5': 11, '6': '.adminbgservice.AdminBgStartRequest.ResourcesEntry', '10': 'resources'},
    {'1': 'disable_memory_limit', '3': 12, '4': 1, '5': 8, '10': 'disableMemoryLimit'},
    {'1': 'owner_pid', '3': 13, '4': 1, '5': 5, '10': 'ownerPid'},
  ],
  '3': [AdminBgStartRequest_ResourcesEntry$json],
};

@$core.Deprecated('Use adminBgStartRequestDescriptor instead')
const AdminBgStartRequest_ResourcesEntry$json = {
  '1': 'ResourcesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `AdminBgStartRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminBgStartRequestDescriptor = $convert.base64Decode(
    'ChNBZG1pbkJnU3RhcnRSZXF1ZXN0EhIKBGlwdjYYASABKAhSBGlwdjYSHwoLc2VydmVyX3Bvcn'
    'QYAiABKAVSCnNlcnZlclBvcnQSJwoPc2VydmVyX3VzZXJuYW1lGAMgASgJUg5zZXJ2ZXJVc2Vy'
    'bmFtZRInCg9zZXJ2ZXJfcGFzc3dvcmQYBCABKAlSDnNlcnZlclBhc3N3b3JkEiEKDHN0cmljdF'
    '9yb3V0ZRgFIAEoCFILc3RyaWN0Um91dGUSOAoYZW5kcG9pbnRfaW5kZXBlbmRlbnRfbmF0GAYg'
    'ASgIUhZlbmRwb2ludEluZGVwZW5kZW50TmF0EhQKBXN0YWNrGAcgASgJUgVzdGFjaxIlCg5jb2'
    '5maWdfY29udGVudBgIIAEoCVINY29uZmlnQ29udGVudBIfCgtjb25maWdfbmFtZRgJIAEoCVIK'
    'Y29uZmlnTmFtZRIjCg1zZXR0aW5nc19qc29uGAogASgJUgxzZXR0aW5nc0pzb24SUAoJcmVzb3'
    'VyY2VzGAsgAygLMjIuYWRtaW5iZ3NlcnZpY2UuQWRtaW5CZ1N0YXJ0UmVxdWVzdC5SZXNvdXJj'
    'ZXNFbnRyeVIJcmVzb3VyY2VzEjAKFGRpc2FibGVfbWVtb3J5X2xpbWl0GAwgASgIUhJkaXNhYm'
    'xlTWVtb3J5TGltaXQSGwoJb3duZXJfcGlkGA0gASgFUghvd25lclBpZBo8Cg5SZXNvdXJjZXNF'
    'bnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoDFIFdmFsdWU6AjgB');

@$core.Deprecated('Use adminBgResponseDescriptor instead')
const AdminBgResponse$json = {
  '1': 'AdminBgResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `AdminBgResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminBgResponseDescriptor = $convert.base64Decode(
    'Cg9BZG1pbkJnUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZQ==');

