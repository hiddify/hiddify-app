//
//  Generated code. Do not modify.
//  source: v2/hcore/hcore.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use coreStatesDescriptor instead')
const CoreStates$json = {
  '1': 'CoreStates',
  '2': [
    {'1': 'STOPPED', '2': 0},
    {'1': 'STARTING', '2': 1},
    {'1': 'STARTED', '2': 2},
    {'1': 'STOPPING', '2': 3},
  ],
};

/// Descriptor for `CoreStates`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List coreStatesDescriptor = $convert.base64Decode(
    'CgpDb3JlU3RhdGVzEgsKB1NUT1BQRUQQABIMCghTVEFSVElORxABEgsKB1NUQVJURUQQAhIMCg'
    'hTVE9QUElORxAD');

@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = {
  '1': 'MessageType',
  '2': [
    {'1': 'EMPTY', '2': 0},
    {'1': 'EMPTY_CONFIGURATION', '2': 1},
    {'1': 'START_COMMAND_SERVER', '2': 2},
    {'1': 'CREATE_SERVICE', '2': 3},
    {'1': 'START_SERVICE', '2': 4},
    {'1': 'UNEXPECTED_ERROR', '2': 5},
    {'1': 'ALREADY_STARTED', '2': 6},
    {'1': 'ALREADY_STOPPED', '2': 7},
    {'1': 'INSTANCE_NOT_FOUND', '2': 8},
    {'1': 'INSTANCE_NOT_STOPPED', '2': 9},
    {'1': 'INSTANCE_NOT_STARTED', '2': 10},
    {'1': 'ERROR_BUILDING_CONFIG', '2': 11},
    {'1': 'ERROR_PARSING_CONFIG', '2': 12},
    {'1': 'ERROR_READING_CONFIG', '2': 13},
    {'1': 'ERROR_EXTENSION', '2': 14},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlVHlwZRIJCgVFTVBUWRAAEhcKE0VNUFRZX0NPTkZJR1VSQVRJT04QARIYChRTVE'
    'FSVF9DT01NQU5EX1NFUlZFUhACEhIKDkNSRUFURV9TRVJWSUNFEAMSEQoNU1RBUlRfU0VSVklD'
    'RRAEEhQKEFVORVhQRUNURURfRVJST1IQBRITCg9BTFJFQURZX1NUQVJURUQQBhITCg9BTFJFQU'
    'RZX1NUT1BQRUQQBxIWChJJTlNUQU5DRV9OT1RfRk9VTkQQCBIYChRJTlNUQU5DRV9OT1RfU1RP'
    'UFBFRBAJEhgKFElOU1RBTkNFX05PVF9TVEFSVEVEEAoSGQoVRVJST1JfQlVJTERJTkdfQ09ORk'
    'lHEAsSGAoURVJST1JfUEFSU0lOR19DT05GSUcQDBIYChRFUlJPUl9SRUFESU5HX0NPTkZJRxAN'
    'EhMKD0VSUk9SX0VYVEVOU0lPThAO');

@$core.Deprecated('Use setupModeDescriptor instead')
const SetupMode$json = {
  '1': 'SetupMode',
  '2': [
    {'1': 'OLD', '2': 0},
    {'1': 'GRPC_NORMAL', '2': 1},
    {'1': 'GRPC_BACKGROUND', '2': 2},
    {'1': 'GRPC_NORMAL_INSECURE', '2': 3},
    {'1': 'GRPC_BACKGROUND_INSECURE', '2': 4},
  ],
};

/// Descriptor for `SetupMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List setupModeDescriptor = $convert.base64Decode(
    'CglTZXR1cE1vZGUSBwoDT0xEEAASDwoLR1JQQ19OT1JNQUwQARITCg9HUlBDX0JBQ0tHUk9VTk'
    'QQAhIYChRHUlBDX05PUk1BTF9JTlNFQ1VSRRADEhwKGEdSUENfQkFDS0dST1VORF9JTlNFQ1VS'
    'RRAE');

@$core.Deprecated('Use logLevelDescriptor instead')
const LogLevel$json = {
  '1': 'LogLevel',
  '2': [
    {'1': 'DEBUG', '2': 0},
    {'1': 'INFO', '2': 1},
    {'1': 'WARNING', '2': 2},
    {'1': 'ERROR', '2': 3},
    {'1': 'FATAL', '2': 4},
  ],
};

/// Descriptor for `LogLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logLevelDescriptor = $convert.base64Decode(
    'CghMb2dMZXZlbBIJCgVERUJVRxAAEggKBElORk8QARILCgdXQVJOSU5HEAISCQoFRVJST1IQAx'
    'IJCgVGQVRBTBAE');

@$core.Deprecated('Use logTypeDescriptor instead')
const LogType$json = {
  '1': 'LogType',
  '2': [
    {'1': 'CORE', '2': 0},
    {'1': 'SERVICE', '2': 1},
    {'1': 'CONFIG', '2': 2},
  ],
};

/// Descriptor for `LogType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logTypeDescriptor = $convert.base64Decode(
    'CgdMb2dUeXBlEggKBENPUkUQABILCgdTRVJWSUNFEAESCgoGQ09ORklHEAI=');

@$core.Deprecated('Use coreInfoResponseDescriptor instead')
const CoreInfoResponse$json = {
  '1': 'CoreInfoResponse',
  '2': [
    {'1': 'core_state', '3': 1, '4': 1, '5': 14, '6': '.hcore.CoreStates', '10': 'coreState'},
    {'1': 'message_type', '3': 2, '4': 1, '5': 14, '6': '.hcore.MessageType', '10': 'messageType'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `CoreInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coreInfoResponseDescriptor = $convert.base64Decode(
    'ChBDb3JlSW5mb1Jlc3BvbnNlEjAKCmNvcmVfc3RhdGUYASABKA4yES5oY29yZS5Db3JlU3RhdG'
    'VzUgljb3JlU3RhdGUSNQoMbWVzc2FnZV90eXBlGAIgASgOMhIuaGNvcmUuTWVzc2FnZVR5cGVS'
    'C21lc3NhZ2VUeXBlEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use startRequestDescriptor instead')
const StartRequest$json = {
  '1': 'StartRequest',
  '2': [
    {'1': 'config_path', '3': 1, '4': 1, '5': 9, '10': 'configPath'},
    {'1': 'config_content', '3': 2, '4': 1, '5': 9, '10': 'configContent'},
    {'1': 'disable_memory_limit', '3': 3, '4': 1, '5': 8, '10': 'disableMemoryLimit'},
    {'1': 'delay_start', '3': 4, '4': 1, '5': 8, '10': 'delayStart'},
    {'1': 'enable_old_command_server', '3': 5, '4': 1, '5': 8, '10': 'enableOldCommandServer'},
    {'1': 'enable_raw_config', '3': 6, '4': 1, '5': 8, '10': 'enableRawConfig'},
  ],
};

/// Descriptor for `StartRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startRequestDescriptor = $convert.base64Decode(
    'CgxTdGFydFJlcXVlc3QSHwoLY29uZmlnX3BhdGgYASABKAlSCmNvbmZpZ1BhdGgSJQoOY29uZm'
    'lnX2NvbnRlbnQYAiABKAlSDWNvbmZpZ0NvbnRlbnQSMAoUZGlzYWJsZV9tZW1vcnlfbGltaXQY'
    'AyABKAhSEmRpc2FibGVNZW1vcnlMaW1pdBIfCgtkZWxheV9zdGFydBgEIAEoCFIKZGVsYXlTdG'
    'FydBI5ChllbmFibGVfb2xkX2NvbW1hbmRfc2VydmVyGAUgASgIUhZlbmFibGVPbGRDb21tYW5k'
    'U2VydmVyEioKEWVuYWJsZV9yYXdfY29uZmlnGAYgASgIUg9lbmFibGVSYXdDb25maWc=');

@$core.Deprecated('Use setupRequestDescriptor instead')
const SetupRequest$json = {
  '1': 'SetupRequest',
  '2': [
    {'1': 'base_path', '3': 1, '4': 1, '5': 9, '10': 'basePath'},
    {'1': 'working_dir', '3': 2, '4': 1, '5': 9, '10': 'workingDir'},
    {'1': 'temp_dir', '3': 3, '4': 1, '5': 9, '10': 'tempDir'},
    {'1': 'flutter_status_port', '3': 4, '4': 1, '5': 3, '10': 'flutterStatusPort'},
    {'1': 'listen', '3': 5, '4': 1, '5': 9, '10': 'listen'},
    {'1': 'secret', '3': 6, '4': 1, '5': 9, '10': 'secret'},
    {'1': 'debug', '3': 7, '4': 1, '5': 8, '10': 'debug'},
    {'1': 'mode', '3': 8, '4': 1, '5': 14, '6': '.hcore.SetupMode', '10': 'mode'},
  ],
};

/// Descriptor for `SetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setupRequestDescriptor = $convert.base64Decode(
    'CgxTZXR1cFJlcXVlc3QSGwoJYmFzZV9wYXRoGAEgASgJUghiYXNlUGF0aBIfCgt3b3JraW5nX2'
    'RpchgCIAEoCVIKd29ya2luZ0RpchIZCgh0ZW1wX2RpchgDIAEoCVIHdGVtcERpchIuChNmbHV0'
    'dGVyX3N0YXR1c19wb3J0GAQgASgDUhFmbHV0dGVyU3RhdHVzUG9ydBIWCgZsaXN0ZW4YBSABKA'
    'lSBmxpc3RlbhIWCgZzZWNyZXQYBiABKAlSBnNlY3JldBIUCgVkZWJ1ZxgHIAEoCFIFZGVidWcS'
    'JAoEbW9kZRgIIAEoDjIQLmhjb3JlLlNldHVwTW9kZVIEbW9kZQ==');

@$core.Deprecated('Use systemInfoDescriptor instead')
const SystemInfo$json = {
  '1': 'SystemInfo',
  '2': [
    {'1': 'memory', '3': 1, '4': 1, '5': 3, '10': 'memory'},
    {'1': 'goroutines', '3': 2, '4': 1, '5': 5, '10': 'goroutines'},
    {'1': 'connections_in', '3': 3, '4': 1, '5': 5, '10': 'connectionsIn'},
    {'1': 'connections_out', '3': 4, '4': 1, '5': 5, '10': 'connectionsOut'},
    {'1': 'traffic_available', '3': 5, '4': 1, '5': 8, '10': 'trafficAvailable'},
    {'1': 'uplink', '3': 6, '4': 1, '5': 3, '10': 'uplink'},
    {'1': 'downlink', '3': 7, '4': 1, '5': 3, '10': 'downlink'},
    {'1': 'uplink_total', '3': 8, '4': 1, '5': 3, '10': 'uplinkTotal'},
    {'1': 'downlink_total', '3': 9, '4': 1, '5': 3, '10': 'downlinkTotal'},
  ],
};

/// Descriptor for `SystemInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemInfoDescriptor = $convert.base64Decode(
    'CgpTeXN0ZW1JbmZvEhYKBm1lbW9yeRgBIAEoA1IGbWVtb3J5Eh4KCmdvcm91dGluZXMYAiABKA'
    'VSCmdvcm91dGluZXMSJQoOY29ubmVjdGlvbnNfaW4YAyABKAVSDWNvbm5lY3Rpb25zSW4SJwoP'
    'Y29ubmVjdGlvbnNfb3V0GAQgASgFUg5jb25uZWN0aW9uc091dBIrChF0cmFmZmljX2F2YWlsYW'
    'JsZRgFIAEoCFIQdHJhZmZpY0F2YWlsYWJsZRIWCgZ1cGxpbmsYBiABKANSBnVwbGluaxIaCghk'
    'b3dubGluaxgHIAEoA1IIZG93bmxpbmsSIQoMdXBsaW5rX3RvdGFsGAggASgDUgt1cGxpbmtUb3'
    'RhbBIlCg5kb3dubGlua190b3RhbBgJIAEoA1INZG93bmxpbmtUb3RhbA==');

@$core.Deprecated('Use outboundInfoDescriptor instead')
const OutboundInfo$json = {
  '1': 'OutboundInfo',
  '2': [
    {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'url_test_time', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'urlTestTime'},
    {'1': 'url_test_delay', '3': 4, '4': 1, '5': 5, '10': 'urlTestDelay'},
    {'1': 'ipinfo', '3': 5, '4': 1, '5': 11, '6': '.hcore.IpInfo', '9': 0, '10': 'ipinfo', '17': true},
    {'1': 'is_selected', '3': 6, '4': 1, '5': 8, '10': 'isSelected'},
    {'1': 'is_group', '3': 7, '4': 1, '5': 8, '10': 'isGroup'},
    {'1': 'group_selected_outbound', '3': 13, '4': 1, '5': 11, '6': '.hcore.OutboundInfo', '9': 1, '10': 'groupSelectedOutbound', '17': true},
    {'1': 'is_secure', '3': 8, '4': 1, '5': 8, '10': 'isSecure'},
    {'1': 'is_visible', '3': 9, '4': 1, '5': 8, '10': 'isVisible'},
    {'1': 'port', '3': 10, '4': 1, '5': 13, '10': 'port'},
    {'1': 'host', '3': 11, '4': 1, '5': 9, '10': 'host'},
    {'1': 'tag_display', '3': 12, '4': 1, '5': 9, '10': 'tagDisplay'},
  ],
  '8': [
    {'1': '_ipinfo'},
    {'1': '_group_selected_outbound'},
  ],
};

/// Descriptor for `OutboundInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundInfoDescriptor = $convert.base64Decode(
    'CgxPdXRib3VuZEluZm8SEAoDdGFnGAEgASgJUgN0YWcSEgoEdHlwZRgCIAEoCVIEdHlwZRI+Cg'
    '11cmxfdGVzdF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFILdXJsVGVz'
    'dFRpbWUSJAoOdXJsX3Rlc3RfZGVsYXkYBCABKAVSDHVybFRlc3REZWxheRIqCgZpcGluZm8YBS'
    'ABKAsyDS5oY29yZS5JcEluZm9IAFIGaXBpbmZviAEBEh8KC2lzX3NlbGVjdGVkGAYgASgIUgpp'
    'c1NlbGVjdGVkEhkKCGlzX2dyb3VwGAcgASgIUgdpc0dyb3VwElAKF2dyb3VwX3NlbGVjdGVkX2'
    '91dGJvdW5kGA0gASgLMhMuaGNvcmUuT3V0Ym91bmRJbmZvSAFSFWdyb3VwU2VsZWN0ZWRPdXRi'
    'b3VuZIgBARIbCglpc19zZWN1cmUYCCABKAhSCGlzU2VjdXJlEh0KCmlzX3Zpc2libGUYCSABKA'
    'hSCWlzVmlzaWJsZRISCgRwb3J0GAogASgNUgRwb3J0EhIKBGhvc3QYCyABKAlSBGhvc3QSHwoL'
    'dGFnX2Rpc3BsYXkYDCABKAlSCnRhZ0Rpc3BsYXlCCQoHX2lwaW5mb0IaChhfZ3JvdXBfc2VsZW'
    'N0ZWRfb3V0Ym91bmQ=');

@$core.Deprecated('Use ipInfoDescriptor instead')
const IpInfo$json = {
  '1': 'IpInfo',
  '2': [
    {'1': 'ip', '3': 1, '4': 1, '5': 9, '10': 'ip'},
    {'1': 'country_code', '3': 2, '4': 1, '5': 9, '10': 'country_code'},
    {'1': 'region', '3': 3, '4': 1, '5': 9, '10': 'region'},
    {'1': 'city', '3': 4, '4': 1, '5': 9, '10': 'city'},
    {'1': 'asn', '3': 5, '4': 1, '5': 5, '10': 'asn'},
    {'1': 'org', '3': 6, '4': 1, '5': 9, '10': 'org'},
    {'1': 'latitude', '3': 7, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 8, '4': 1, '5': 1, '10': 'longitude'},
    {'1': 'postal_code', '3': 9, '4': 1, '5': 9, '10': 'postal_code'},
  ],
};

/// Descriptor for `IpInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ipInfoDescriptor = $convert.base64Decode(
    'CgZJcEluZm8SDgoCaXAYASABKAlSAmlwEiIKDGNvdW50cnlfY29kZRgCIAEoCVIMY291bnRyeV'
    '9jb2RlEhYKBnJlZ2lvbhgDIAEoCVIGcmVnaW9uEhIKBGNpdHkYBCABKAlSBGNpdHkSEAoDYXNu'
    'GAUgASgFUgNhc24SEAoDb3JnGAYgASgJUgNvcmcSGgoIbGF0aXR1ZGUYByABKAFSCGxhdGl0dW'
    'RlEhwKCWxvbmdpdHVkZRgIIAEoAVIJbG9uZ2l0dWRlEiAKC3Bvc3RhbF9jb2RlGAkgASgJUgtw'
    'b3N0YWxfY29kZQ==');

@$core.Deprecated('Use outboundGroupDescriptor instead')
const OutboundGroup$json = {
  '1': 'OutboundGroup',
  '2': [
    {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'selected', '3': 3, '4': 1, '5': 11, '6': '.hcore.OutboundInfo', '10': 'selected'},
    {'1': 'selectable', '3': 4, '4': 1, '5': 8, '10': 'selectable'},
    {'1': 'Is_expand', '3': 5, '4': 1, '5': 8, '10': 'IsExpand'},
    {'1': 'items', '3': 6, '4': 3, '5': 11, '6': '.hcore.OutboundInfo', '10': 'items'},
  ],
};

/// Descriptor for `OutboundGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundGroupDescriptor = $convert.base64Decode(
    'Cg1PdXRib3VuZEdyb3VwEhAKA3RhZxgBIAEoCVIDdGFnEhIKBHR5cGUYAiABKAlSBHR5cGUSLw'
    'oIc2VsZWN0ZWQYAyABKAsyEy5oY29yZS5PdXRib3VuZEluZm9SCHNlbGVjdGVkEh4KCnNlbGVj'
    'dGFibGUYBCABKAhSCnNlbGVjdGFibGUSGwoJSXNfZXhwYW5kGAUgASgIUghJc0V4cGFuZBIpCg'
    'VpdGVtcxgGIAMoCzITLmhjb3JlLk91dGJvdW5kSW5mb1IFaXRlbXM=');

@$core.Deprecated('Use outboundGroupListDescriptor instead')
const OutboundGroupList$json = {
  '1': 'OutboundGroupList',
  '2': [
    {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.hcore.OutboundGroup', '10': 'items'},
  ],
};

/// Descriptor for `OutboundGroupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundGroupListDescriptor = $convert.base64Decode(
    'ChFPdXRib3VuZEdyb3VwTGlzdBIqCgVpdGVtcxgBIAMoCzIULmhjb3JlLk91dGJvdW5kR3JvdX'
    'BSBWl0ZW1z');

@$core.Deprecated('Use warpAccountDescriptor instead')
const WarpAccount$json = {
  '1': 'WarpAccount',
  '2': [
    {'1': 'account_id', '3': 1, '4': 1, '5': 9, '10': 'accountId'},
    {'1': 'access_token', '3': 2, '4': 1, '5': 9, '10': 'accessToken'},
  ],
};

/// Descriptor for `WarpAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpAccountDescriptor = $convert.base64Decode(
    'CgtXYXJwQWNjb3VudBIdCgphY2NvdW50X2lkGAEgASgJUglhY2NvdW50SWQSIQoMYWNjZXNzX3'
    'Rva2VuGAIgASgJUgthY2Nlc3NUb2tlbg==');

@$core.Deprecated('Use warpWireguardConfigDescriptor instead')
const WarpWireguardConfig$json = {
  '1': 'WarpWireguardConfig',
  '2': [
    {'1': 'private_key', '3': 1, '4': 1, '5': 9, '10': 'private-key'},
    {'1': 'local_address_ipv4', '3': 2, '4': 1, '5': 9, '10': 'local-address-ipv4'},
    {'1': 'local_address_ipv6', '3': 3, '4': 1, '5': 9, '10': 'local-address-ipv6'},
    {'1': 'peer_public_key', '3': 4, '4': 1, '5': 9, '10': 'peer-public-key'},
    {'1': 'client_id', '3': 5, '4': 1, '5': 9, '10': 'client-id'},
  ],
};

/// Descriptor for `WarpWireguardConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpWireguardConfigDescriptor = $convert.base64Decode(
    'ChNXYXJwV2lyZWd1YXJkQ29uZmlnEiAKC3ByaXZhdGVfa2V5GAEgASgJUgtwcml2YXRlLWtleR'
    'IuChJsb2NhbF9hZGRyZXNzX2lwdjQYAiABKAlSEmxvY2FsLWFkZHJlc3MtaXB2NBIuChJsb2Nh'
    'bF9hZGRyZXNzX2lwdjYYAyABKAlSEmxvY2FsLWFkZHJlc3MtaXB2NhIoCg9wZWVyX3B1YmxpY1'
    '9rZXkYBCABKAlSD3BlZXItcHVibGljLWtleRIcCgljbGllbnRfaWQYBSABKAlSCWNsaWVudC1p'
    'ZA==');

@$core.Deprecated('Use warpGenerationResponseDescriptor instead')
const WarpGenerationResponse$json = {
  '1': 'WarpGenerationResponse',
  '2': [
    {'1': 'account', '3': 1, '4': 1, '5': 11, '6': '.hcore.WarpAccount', '10': 'account'},
    {'1': 'log', '3': 2, '4': 1, '5': 9, '10': 'log'},
    {'1': 'config', '3': 3, '4': 1, '5': 11, '6': '.hcore.WarpWireguardConfig', '10': 'config'},
  ],
};

/// Descriptor for `WarpGenerationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpGenerationResponseDescriptor = $convert.base64Decode(
    'ChZXYXJwR2VuZXJhdGlvblJlc3BvbnNlEiwKB2FjY291bnQYASABKAsyEi5oY29yZS5XYXJwQW'
    'Njb3VudFIHYWNjb3VudBIQCgNsb2cYAiABKAlSA2xvZxIyCgZjb25maWcYAyABKAsyGi5oY29y'
    'ZS5XYXJwV2lyZWd1YXJkQ29uZmlnUgZjb25maWc=');

@$core.Deprecated('Use systemProxyStatusDescriptor instead')
const SystemProxyStatus$json = {
  '1': 'SystemProxyStatus',
  '2': [
    {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SystemProxyStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemProxyStatusDescriptor = $convert.base64Decode(
    'ChFTeXN0ZW1Qcm94eVN0YXR1cxIcCglhdmFpbGFibGUYASABKAhSCWF2YWlsYWJsZRIYCgdlbm'
    'FibGVkGAIgASgIUgdlbmFibGVk');

@$core.Deprecated('Use parseRequestDescriptor instead')
const ParseRequest$json = {
  '1': 'ParseRequest',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 9, '10': 'content'},
    {'1': 'config_path', '3': 2, '4': 1, '5': 9, '10': 'configPath'},
    {'1': 'temp_path', '3': 3, '4': 1, '5': 9, '10': 'tempPath'},
    {'1': 'debug', '3': 4, '4': 1, '5': 8, '10': 'debug'},
  ],
};

/// Descriptor for `ParseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseRequestDescriptor = $convert.base64Decode(
    'CgxQYXJzZVJlcXVlc3QSGAoHY29udGVudBgBIAEoCVIHY29udGVudBIfCgtjb25maWdfcGF0aB'
    'gCIAEoCVIKY29uZmlnUGF0aBIbCgl0ZW1wX3BhdGgYAyABKAlSCHRlbXBQYXRoEhQKBWRlYnVn'
    'GAQgASgIUgVkZWJ1Zw==');

@$core.Deprecated('Use parseResponseDescriptor instead')
const ParseResponse$json = {
  '1': 'ParseResponse',
  '2': [
    {'1': 'response_code', '3': 1, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'responseCode'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ParseResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseResponseDescriptor = $convert.base64Decode(
    'Cg1QYXJzZVJlc3BvbnNlEjoKDXJlc3BvbnNlX2NvZGUYASABKA4yFS5oY29tbW9uLlJlc3Bvbn'
    'NlQ29kZVIMcmVzcG9uc2VDb2RlEhgKB2NvbnRlbnQYAiABKAlSB2NvbnRlbnQSGAoHbWVzc2Fn'
    'ZRgDIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use changeHiddifySettingsRequestDescriptor instead')
const ChangeHiddifySettingsRequest$json = {
  '1': 'ChangeHiddifySettingsRequest',
  '2': [
    {'1': 'hiddify_settings_json', '3': 1, '4': 1, '5': 9, '10': 'hiddifySettingsJson'},
  ],
};

/// Descriptor for `ChangeHiddifySettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeHiddifySettingsRequestDescriptor = $convert.base64Decode(
    'ChxDaGFuZ2VIaWRkaWZ5U2V0dGluZ3NSZXF1ZXN0EjIKFWhpZGRpZnlfc2V0dGluZ3NfanNvbh'
    'gBIAEoCVITaGlkZGlmeVNldHRpbmdzSnNvbg==');

@$core.Deprecated('Use generateConfigRequestDescriptor instead')
const GenerateConfigRequest$json = {
  '1': 'GenerateConfigRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'temp_path', '3': 2, '4': 1, '5': 9, '10': 'tempPath'},
    {'1': 'debug', '3': 3, '4': 1, '5': 8, '10': 'debug'},
  ],
};

/// Descriptor for `GenerateConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateConfigRequestDescriptor = $convert.base64Decode(
    'ChVHZW5lcmF0ZUNvbmZpZ1JlcXVlc3QSEgoEcGF0aBgBIAEoCVIEcGF0aBIbCgl0ZW1wX3BhdG'
    'gYAiABKAlSCHRlbXBQYXRoEhQKBWRlYnVnGAMgASgIUgVkZWJ1Zw==');

@$core.Deprecated('Use generateConfigResponseDescriptor instead')
const GenerateConfigResponse$json = {
  '1': 'GenerateConfigResponse',
  '2': [
    {'1': 'config_content', '3': 1, '4': 1, '5': 9, '10': 'configContent'},
  ],
};

/// Descriptor for `GenerateConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateConfigResponseDescriptor = $convert.base64Decode(
    'ChZHZW5lcmF0ZUNvbmZpZ1Jlc3BvbnNlEiUKDmNvbmZpZ19jb250ZW50GAEgASgJUg1jb25maW'
    'dDb250ZW50');

@$core.Deprecated('Use selectOutboundRequestDescriptor instead')
const SelectOutboundRequest$json = {
  '1': 'SelectOutboundRequest',
  '2': [
    {'1': 'group_tag', '3': 1, '4': 1, '5': 9, '10': 'groupTag'},
    {'1': 'outbound_tag', '3': 2, '4': 1, '5': 9, '10': 'outboundTag'},
  ],
};

/// Descriptor for `SelectOutboundRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOutboundRequestDescriptor = $convert.base64Decode(
    'ChVTZWxlY3RPdXRib3VuZFJlcXVlc3QSGwoJZ3JvdXBfdGFnGAEgASgJUghncm91cFRhZxIhCg'
    'xvdXRib3VuZF90YWcYAiABKAlSC291dGJvdW5kVGFn');

@$core.Deprecated('Use urlTestRequestDescriptor instead')
const UrlTestRequest$json = {
  '1': 'UrlTestRequest',
  '2': [
    {'1': 'group_tag', '3': 1, '4': 1, '5': 9, '10': 'groupTag'},
  ],
};

/// Descriptor for `UrlTestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List urlTestRequestDescriptor = $convert.base64Decode(
    'Cg5VcmxUZXN0UmVxdWVzdBIbCglncm91cF90YWcYASABKAlSCGdyb3VwVGFn');

@$core.Deprecated('Use generateWarpConfigRequestDescriptor instead')
const GenerateWarpConfigRequest$json = {
  '1': 'GenerateWarpConfigRequest',
  '2': [
    {'1': 'license_key', '3': 1, '4': 1, '5': 9, '10': 'licenseKey'},
    {'1': 'account_id', '3': 2, '4': 1, '5': 9, '10': 'accountId'},
    {'1': 'access_token', '3': 3, '4': 1, '5': 9, '10': 'accessToken'},
  ],
};

/// Descriptor for `GenerateWarpConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateWarpConfigRequestDescriptor = $convert.base64Decode(
    'ChlHZW5lcmF0ZVdhcnBDb25maWdSZXF1ZXN0Eh8KC2xpY2Vuc2Vfa2V5GAEgASgJUgpsaWNlbn'
    'NlS2V5Eh0KCmFjY291bnRfaWQYAiABKAlSCWFjY291bnRJZBIhCgxhY2Nlc3NfdG9rZW4YAyAB'
    'KAlSC2FjY2Vzc1Rva2Vu');

@$core.Deprecated('Use setSystemProxyEnabledRequestDescriptor instead')
const SetSystemProxyEnabledRequest$json = {
  '1': 'SetSystemProxyEnabledRequest',
  '2': [
    {'1': 'is_enabled', '3': 1, '4': 1, '5': 8, '10': 'isEnabled'},
  ],
};

/// Descriptor for `SetSystemProxyEnabledRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSystemProxyEnabledRequestDescriptor = $convert.base64Decode(
    'ChxTZXRTeXN0ZW1Qcm94eUVuYWJsZWRSZXF1ZXN0Eh0KCmlzX2VuYWJsZWQYASABKAhSCWlzRW'
    '5hYmxlZA==');

@$core.Deprecated('Use logMessageDescriptor instead')
const LogMessage$json = {
  '1': 'LogMessage',
  '2': [
    {'1': 'level', '3': 1, '4': 1, '5': 14, '6': '.hcore.LogLevel', '10': 'level'},
    {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.hcore.LogType', '10': 'type'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'time', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'time'},
  ],
};

/// Descriptor for `LogMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logMessageDescriptor = $convert.base64Decode(
    'CgpMb2dNZXNzYWdlEiUKBWxldmVsGAEgASgOMg8uaGNvcmUuTG9nTGV2ZWxSBWxldmVsEiIKBH'
    'R5cGUYAiABKA4yDi5oY29yZS5Mb2dUeXBlUgR0eXBlEhgKB21lc3NhZ2UYAyABKAlSB21lc3Nh'
    'Z2USLgoEdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBHRpbWU=');

@$core.Deprecated('Use stopRequestDescriptor instead')
const StopRequest$json = {
  '1': 'StopRequest',
};

/// Descriptor for `StopRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopRequestDescriptor = $convert.base64Decode(
    'CgtTdG9wUmVxdWVzdA==');

