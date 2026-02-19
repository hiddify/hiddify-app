///
//  Generated code. Do not modify.
//  source: v2/hcore/hcore.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use coreStatesDescriptor instead')
const CoreStates$json = const {
  '1': 'CoreStates',
  '2': const [
    const {'1': 'STOPPED', '2': 0},
    const {'1': 'STARTING', '2': 1},
    const {'1': 'STARTED', '2': 2},
    const {'1': 'STOPPING', '2': 3},
  ],
};

/// Descriptor for `CoreStates`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List coreStatesDescriptor = $convert.base64Decode('CgpDb3JlU3RhdGVzEgsKB1NUT1BQRUQQABIMCghTVEFSVElORxABEgsKB1NUQVJURUQQAhIMCghTVE9QUElORxAD');
@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = const {
  '1': 'MessageType',
  '2': const [
    const {'1': 'EMPTY', '2': 0},
    const {'1': 'EMPTY_CONFIGURATION', '2': 1},
    const {'1': 'START_COMMAND_SERVER', '2': 2},
    const {'1': 'CREATE_SERVICE', '2': 3},
    const {'1': 'START_SERVICE', '2': 4},
    const {'1': 'UNEXPECTED_ERROR', '2': 5},
    const {'1': 'ALREADY_STARTED', '2': 6},
    const {'1': 'ALREADY_STOPPED', '2': 7},
    const {'1': 'INSTANCE_NOT_FOUND', '2': 8},
    const {'1': 'INSTANCE_NOT_STOPPED', '2': 9},
    const {'1': 'INSTANCE_NOT_STARTED', '2': 10},
    const {'1': 'ERROR_BUILDING_CONFIG', '2': 11},
    const {'1': 'ERROR_PARSING_CONFIG', '2': 12},
    const {'1': 'ERROR_READING_CONFIG', '2': 13},
    const {'1': 'ERROR_EXTENSION', '2': 14},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode('CgtNZXNzYWdlVHlwZRIJCgVFTVBUWRAAEhcKE0VNUFRZX0NPTkZJR1VSQVRJT04QARIYChRTVEFSVF9DT01NQU5EX1NFUlZFUhACEhIKDkNSRUFURV9TRVJWSUNFEAMSEQoNU1RBUlRfU0VSVklDRRAEEhQKEFVORVhQRUNURURfRVJST1IQBRITCg9BTFJFQURZX1NUQVJURUQQBhITCg9BTFJFQURZX1NUT1BQRUQQBxIWChJJTlNUQU5DRV9OT1RfRk9VTkQQCBIYChRJTlNUQU5DRV9OT1RfU1RPUFBFRBAJEhgKFElOU1RBTkNFX05PVF9TVEFSVEVEEAoSGQoVRVJST1JfQlVJTERJTkdfQ09ORklHEAsSGAoURVJST1JfUEFSU0lOR19DT05GSUcQDBIYChRFUlJPUl9SRUFESU5HX0NPTkZJRxANEhMKD0VSUk9SX0VYVEVOU0lPThAO');
@$core.Deprecated('Use setupModeDescriptor instead')
const SetupMode$json = const {
  '1': 'SetupMode',
  '2': const [
    const {'1': 'OLD', '2': 0},
    const {'1': 'GRPC_NORMAL', '2': 1},
    const {'1': 'GRPC_BACKGROUND', '2': 2},
    const {'1': 'GRPC_NORMAL_INSECURE', '2': 3},
    const {'1': 'GRPC_BACKGROUND_INSECURE', '2': 4},
  ],
};

/// Descriptor for `SetupMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List setupModeDescriptor = $convert.base64Decode('CglTZXR1cE1vZGUSBwoDT0xEEAASDwoLR1JQQ19OT1JNQUwQARITCg9HUlBDX0JBQ0tHUk9VTkQQAhIYChRHUlBDX05PUk1BTF9JTlNFQ1VSRRADEhwKGEdSUENfQkFDS0dST1VORF9JTlNFQ1VSRRAE');
@$core.Deprecated('Use logLevelDescriptor instead')
const LogLevel$json = const {
  '1': 'LogLevel',
  '2': const [
    const {'1': 'TRACE', '2': 0},
    const {'1': 'DEBUG', '2': 1},
    const {'1': 'INFO', '2': 2},
    const {'1': 'WARNING', '2': 3},
    const {'1': 'ERROR', '2': 4},
    const {'1': 'FATAL', '2': 5},
  ],
};

/// Descriptor for `LogLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logLevelDescriptor = $convert.base64Decode('CghMb2dMZXZlbBIJCgVUUkFDRRAAEgkKBURFQlVHEAESCAoESU5GTxACEgsKB1dBUk5JTkcQAxIJCgVFUlJPUhAEEgkKBUZBVEFMEAU=');
@$core.Deprecated('Use logTypeDescriptor instead')
const LogType$json = const {
  '1': 'LogType',
  '2': const [
    const {'1': 'CORE', '2': 0},
    const {'1': 'SERVICE', '2': 1},
    const {'1': 'CONFIG', '2': 2},
  ],
};

/// Descriptor for `LogType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logTypeDescriptor = $convert.base64Decode('CgdMb2dUeXBlEggKBENPUkUQABILCgdTRVJWSUNFEAESCgoGQ09ORklHEAI=');
@$core.Deprecated('Use coreInfoResponseDescriptor instead')
const CoreInfoResponse$json = const {
  '1': 'CoreInfoResponse',
  '2': const [
    const {'1': 'core_state', '3': 1, '4': 1, '5': 14, '6': '.hcore.CoreStates', '10': 'coreState'},
    const {'1': 'message_type', '3': 2, '4': 1, '5': 14, '6': '.hcore.MessageType', '10': 'messageType'},
    const {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `CoreInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coreInfoResponseDescriptor = $convert.base64Decode('ChBDb3JlSW5mb1Jlc3BvbnNlEjAKCmNvcmVfc3RhdGUYASABKA4yES5oY29yZS5Db3JlU3RhdGVzUgljb3JlU3RhdGUSNQoMbWVzc2FnZV90eXBlGAIgASgOMhIuaGNvcmUuTWVzc2FnZVR5cGVSC21lc3NhZ2VUeXBlEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');
@$core.Deprecated('Use startRequestDescriptor instead')
const StartRequest$json = const {
  '1': 'StartRequest',
  '2': const [
    const {'1': 'config_path', '3': 1, '4': 1, '5': 9, '10': 'configPath'},
    const {'1': 'config_content', '3': 2, '4': 1, '5': 9, '10': 'configContent'},
    const {'1': 'disable_memory_limit', '3': 3, '4': 1, '5': 8, '10': 'disableMemoryLimit'},
    const {'1': 'delay_start', '3': 4, '4': 1, '5': 8, '10': 'delayStart'},
    const {'1': 'enable_old_command_server', '3': 5, '4': 1, '5': 8, '10': 'enableOldCommandServer'},
    const {'1': 'enable_raw_config', '3': 6, '4': 1, '5': 8, '10': 'enableRawConfig'},
    const {'1': 'config_name', '3': 7, '4': 1, '5': 9, '10': 'configName'},
  ],
};

/// Descriptor for `StartRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startRequestDescriptor = $convert.base64Decode('CgxTdGFydFJlcXVlc3QSHwoLY29uZmlnX3BhdGgYASABKAlSCmNvbmZpZ1BhdGgSJQoOY29uZmlnX2NvbnRlbnQYAiABKAlSDWNvbmZpZ0NvbnRlbnQSMAoUZGlzYWJsZV9tZW1vcnlfbGltaXQYAyABKAhSEmRpc2FibGVNZW1vcnlMaW1pdBIfCgtkZWxheV9zdGFydBgEIAEoCFIKZGVsYXlTdGFydBI5ChllbmFibGVfb2xkX2NvbW1hbmRfc2VydmVyGAUgASgIUhZlbmFibGVPbGRDb21tYW5kU2VydmVyEioKEWVuYWJsZV9yYXdfY29uZmlnGAYgASgIUg9lbmFibGVSYXdDb25maWcSHwoLY29uZmlnX25hbWUYByABKAlSCmNvbmZpZ05hbWU=');
@$core.Deprecated('Use closeRequestDescriptor instead')
const CloseRequest$json = const {
  '1': 'CloseRequest',
  '2': const [
    const {'1': 'mode', '3': 1, '4': 1, '5': 14, '6': '.hcore.SetupMode', '10': 'mode'},
  ],
};

/// Descriptor for `CloseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeRequestDescriptor = $convert.base64Decode('CgxDbG9zZVJlcXVlc3QSJAoEbW9kZRgBIAEoDjIQLmhjb3JlLlNldHVwTW9kZVIEbW9kZQ==');
@$core.Deprecated('Use setupRequestDescriptor instead')
const SetupRequest$json = const {
  '1': 'SetupRequest',
  '2': const [
    const {'1': 'base_path', '3': 1, '4': 1, '5': 9, '10': 'basePath'},
    const {'1': 'working_dir', '3': 2, '4': 1, '5': 9, '10': 'workingDir'},
    const {'1': 'temp_dir', '3': 3, '4': 1, '5': 9, '10': 'tempDir'},
    const {'1': 'flutter_status_port', '3': 4, '4': 1, '5': 3, '10': 'flutterStatusPort'},
    const {'1': 'listen', '3': 5, '4': 1, '5': 9, '10': 'listen'},
    const {'1': 'secret', '3': 6, '4': 1, '5': 9, '10': 'secret'},
    const {'1': 'debug', '3': 7, '4': 1, '5': 8, '10': 'debug'},
    const {'1': 'mode', '3': 8, '4': 1, '5': 14, '6': '.hcore.SetupMode', '10': 'mode'},
    const {'1': 'fix_android_stack', '3': 9, '4': 1, '5': 8, '10': 'fixAndroidStack'},
  ],
};

/// Descriptor for `SetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setupRequestDescriptor = $convert.base64Decode('CgxTZXR1cFJlcXVlc3QSGwoJYmFzZV9wYXRoGAEgASgJUghiYXNlUGF0aBIfCgt3b3JraW5nX2RpchgCIAEoCVIKd29ya2luZ0RpchIZCgh0ZW1wX2RpchgDIAEoCVIHdGVtcERpchIuChNmbHV0dGVyX3N0YXR1c19wb3J0GAQgASgDUhFmbHV0dGVyU3RhdHVzUG9ydBIWCgZsaXN0ZW4YBSABKAlSBmxpc3RlbhIWCgZzZWNyZXQYBiABKAlSBnNlY3JldBIUCgVkZWJ1ZxgHIAEoCFIFZGVidWcSJAoEbW9kZRgIIAEoDjIQLmhjb3JlLlNldHVwTW9kZVIEbW9kZRIqChFmaXhfYW5kcm9pZF9zdGFjaxgJIAEoCFIPZml4QW5kcm9pZFN0YWNr');
@$core.Deprecated('Use systemInfoDescriptor instead')
const SystemInfo$json = const {
  '1': 'SystemInfo',
  '2': const [
    const {'1': 'memory', '3': 1, '4': 1, '5': 3, '10': 'memory'},
    const {'1': 'goroutines', '3': 2, '4': 1, '5': 5, '10': 'goroutines'},
    const {'1': 'connections_in', '3': 3, '4': 1, '5': 5, '10': 'connectionsIn'},
    const {'1': 'connections_out', '3': 4, '4': 1, '5': 5, '10': 'connectionsOut'},
    const {'1': 'traffic_available', '3': 5, '4': 1, '5': 8, '10': 'trafficAvailable'},
    const {'1': 'uplink', '3': 6, '4': 1, '5': 3, '10': 'uplink'},
    const {'1': 'downlink', '3': 7, '4': 1, '5': 3, '10': 'downlink'},
    const {'1': 'uplink_total', '3': 8, '4': 1, '5': 3, '10': 'uplinkTotal'},
    const {'1': 'downlink_total', '3': 9, '4': 1, '5': 3, '10': 'downlinkTotal'},
    const {'1': 'current_outbound', '3': 10, '4': 1, '5': 9, '10': 'currentOutbound'},
    const {'1': 'current_profile', '3': 11, '4': 1, '5': 9, '10': 'currentProfile'},
  ],
};

/// Descriptor for `SystemInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemInfoDescriptor = $convert.base64Decode('CgpTeXN0ZW1JbmZvEhYKBm1lbW9yeRgBIAEoA1IGbWVtb3J5Eh4KCmdvcm91dGluZXMYAiABKAVSCmdvcm91dGluZXMSJQoOY29ubmVjdGlvbnNfaW4YAyABKAVSDWNvbm5lY3Rpb25zSW4SJwoPY29ubmVjdGlvbnNfb3V0GAQgASgFUg5jb25uZWN0aW9uc091dBIrChF0cmFmZmljX2F2YWlsYWJsZRgFIAEoCFIQdHJhZmZpY0F2YWlsYWJsZRIWCgZ1cGxpbmsYBiABKANSBnVwbGluaxIaCghkb3dubGluaxgHIAEoA1IIZG93bmxpbmsSIQoMdXBsaW5rX3RvdGFsGAggASgDUgt1cGxpbmtUb3RhbBIlCg5kb3dubGlua190b3RhbBgJIAEoA1INZG93bmxpbmtUb3RhbBIpChBjdXJyZW50X291dGJvdW5kGAogASgJUg9jdXJyZW50T3V0Ym91bmQSJwoPY3VycmVudF9wcm9maWxlGAsgASgJUg5jdXJyZW50UHJvZmlsZQ==');
@$core.Deprecated('Use outboundInfoDescriptor instead')
const OutboundInfo$json = const {
  '1': 'OutboundInfo',
  '2': const [
    const {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
    const {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'url_test_time', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'urlTestTime'},
    const {'1': 'url_test_delay', '3': 4, '4': 1, '5': 5, '10': 'urlTestDelay'},
    const {'1': 'ipinfo', '3': 5, '4': 1, '5': 11, '6': '.hcore.IpInfo', '9': 0, '10': 'ipinfo', '17': true},
    const {'1': 'is_selected', '3': 6, '4': 1, '5': 8, '10': 'isSelected'},
    const {'1': 'is_group', '3': 7, '4': 1, '5': 8, '10': 'isGroup'},
    const {'1': 'group_selected_tag', '3': 13, '4': 1, '5': 9, '9': 1, '10': 'groupSelectedTag', '17': true},
    const {'1': 'group_selected_tag_display', '3': 14, '4': 1, '5': 9, '9': 2, '10': 'groupSelectedTagDisplay', '17': true},
    const {'1': 'is_secure', '3': 8, '4': 1, '5': 8, '10': 'isSecure'},
    const {'1': 'is_visible', '3': 9, '4': 1, '5': 8, '10': 'isVisible'},
    const {'1': 'port', '3': 10, '4': 1, '5': 13, '10': 'port'},
    const {'1': 'host', '3': 11, '4': 1, '5': 9, '10': 'host'},
    const {'1': 'tag_display', '3': 12, '4': 1, '5': 9, '10': 'tagDisplay'},
    const {'1': 'upload', '3': 15, '4': 1, '5': 3, '10': 'upload'},
    const {'1': 'download', '3': 16, '4': 1, '5': 3, '10': 'download'},
  ],
  '8': const [
    const {'1': '_ipinfo'},
    const {'1': '_group_selected_tag'},
    const {'1': '_group_selected_tag_display'},
  ],
};

/// Descriptor for `OutboundInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundInfoDescriptor = $convert.base64Decode('CgxPdXRib3VuZEluZm8SEAoDdGFnGAEgASgJUgN0YWcSEgoEdHlwZRgCIAEoCVIEdHlwZRI+Cg11cmxfdGVzdF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFILdXJsVGVzdFRpbWUSJAoOdXJsX3Rlc3RfZGVsYXkYBCABKAVSDHVybFRlc3REZWxheRIqCgZpcGluZm8YBSABKAsyDS5oY29yZS5JcEluZm9IAFIGaXBpbmZviAEBEh8KC2lzX3NlbGVjdGVkGAYgASgIUgppc1NlbGVjdGVkEhkKCGlzX2dyb3VwGAcgASgIUgdpc0dyb3VwEjEKEmdyb3VwX3NlbGVjdGVkX3RhZxgNIAEoCUgBUhBncm91cFNlbGVjdGVkVGFniAEBEkAKGmdyb3VwX3NlbGVjdGVkX3RhZ19kaXNwbGF5GA4gASgJSAJSF2dyb3VwU2VsZWN0ZWRUYWdEaXNwbGF5iAEBEhsKCWlzX3NlY3VyZRgIIAEoCFIIaXNTZWN1cmUSHQoKaXNfdmlzaWJsZRgJIAEoCFIJaXNWaXNpYmxlEhIKBHBvcnQYCiABKA1SBHBvcnQSEgoEaG9zdBgLIAEoCVIEaG9zdBIfCgt0YWdfZGlzcGxheRgMIAEoCVIKdGFnRGlzcGxheRIWCgZ1cGxvYWQYDyABKANSBnVwbG9hZBIaCghkb3dubG9hZBgQIAEoA1IIZG93bmxvYWRCCQoHX2lwaW5mb0IVChNfZ3JvdXBfc2VsZWN0ZWRfdGFnQh0KG19ncm91cF9zZWxlY3RlZF90YWdfZGlzcGxheQ==');
@$core.Deprecated('Use ipInfoDescriptor instead')
const IpInfo$json = const {
  '1': 'IpInfo',
  '2': const [
    const {'1': 'ip', '3': 1, '4': 1, '5': 9, '10': 'ip'},
    const {'1': 'country_code', '3': 2, '4': 1, '5': 9, '10': 'country_code'},
    const {'1': 'region', '3': 3, '4': 1, '5': 9, '10': 'region'},
    const {'1': 'city', '3': 4, '4': 1, '5': 9, '10': 'city'},
    const {'1': 'asn', '3': 5, '4': 1, '5': 5, '10': 'asn'},
    const {'1': 'org', '3': 6, '4': 1, '5': 9, '10': 'org'},
    const {'1': 'latitude', '3': 7, '4': 1, '5': 1, '10': 'latitude'},
    const {'1': 'longitude', '3': 8, '4': 1, '5': 1, '10': 'longitude'},
    const {'1': 'postal_code', '3': 9, '4': 1, '5': 9, '10': 'postal_code'},
  ],
};

/// Descriptor for `IpInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ipInfoDescriptor = $convert.base64Decode('CgZJcEluZm8SDgoCaXAYASABKAlSAmlwEiIKDGNvdW50cnlfY29kZRgCIAEoCVIMY291bnRyeV9jb2RlEhYKBnJlZ2lvbhgDIAEoCVIGcmVnaW9uEhIKBGNpdHkYBCABKAlSBGNpdHkSEAoDYXNuGAUgASgFUgNhc24SEAoDb3JnGAYgASgJUgNvcmcSGgoIbGF0aXR1ZGUYByABKAFSCGxhdGl0dWRlEhwKCWxvbmdpdHVkZRgIIAEoAVIJbG9uZ2l0dWRlEiAKC3Bvc3RhbF9jb2RlGAkgASgJUgtwb3N0YWxfY29kZQ==');
@$core.Deprecated('Use outboundGroupDescriptor instead')
const OutboundGroup$json = const {
  '1': 'OutboundGroup',
  '2': const [
    const {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
    const {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'selected', '3': 3, '4': 1, '5': 9, '10': 'selected'},
    const {'1': 'selectable', '3': 4, '4': 1, '5': 8, '10': 'selectable'},
    const {'1': 'Is_expand', '3': 5, '4': 1, '5': 8, '10': 'IsExpand'},
    const {'1': 'items', '3': 6, '4': 3, '5': 11, '6': '.hcore.OutboundInfo', '10': 'items'},
  ],
};

/// Descriptor for `OutboundGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundGroupDescriptor = $convert.base64Decode('Cg1PdXRib3VuZEdyb3VwEhAKA3RhZxgBIAEoCVIDdGFnEhIKBHR5cGUYAiABKAlSBHR5cGUSGgoIc2VsZWN0ZWQYAyABKAlSCHNlbGVjdGVkEh4KCnNlbGVjdGFibGUYBCABKAhSCnNlbGVjdGFibGUSGwoJSXNfZXhwYW5kGAUgASgIUghJc0V4cGFuZBIpCgVpdGVtcxgGIAMoCzITLmhjb3JlLk91dGJvdW5kSW5mb1IFaXRlbXM=');
@$core.Deprecated('Use outboundGroupListDescriptor instead')
const OutboundGroupList$json = const {
  '1': 'OutboundGroupList',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.hcore.OutboundGroup', '10': 'items'},
  ],
};

/// Descriptor for `OutboundGroupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundGroupListDescriptor = $convert.base64Decode('ChFPdXRib3VuZEdyb3VwTGlzdBIqCgVpdGVtcxgBIAMoCzIULmhjb3JlLk91dGJvdW5kR3JvdXBSBWl0ZW1z');
@$core.Deprecated('Use warpAccountDescriptor instead')
const WarpAccount$json = const {
  '1': 'WarpAccount',
  '2': const [
    const {'1': 'account_id', '3': 1, '4': 1, '5': 9, '10': 'accountId'},
    const {'1': 'access_token', '3': 2, '4': 1, '5': 9, '10': 'accessToken'},
  ],
};

/// Descriptor for `WarpAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpAccountDescriptor = $convert.base64Decode('CgtXYXJwQWNjb3VudBIdCgphY2NvdW50X2lkGAEgASgJUglhY2NvdW50SWQSIQoMYWNjZXNzX3Rva2VuGAIgASgJUgthY2Nlc3NUb2tlbg==');
@$core.Deprecated('Use warpWireguardConfigDescriptor instead')
const WarpWireguardConfig$json = const {
  '1': 'WarpWireguardConfig',
  '2': const [
    const {'1': 'private_key', '3': 1, '4': 1, '5': 9, '10': 'private-key'},
    const {'1': 'local_address_ipv4', '3': 2, '4': 1, '5': 9, '10': 'local-address-ipv4'},
    const {'1': 'local_address_ipv6', '3': 3, '4': 1, '5': 9, '10': 'local-address-ipv6'},
    const {'1': 'peer_public_key', '3': 4, '4': 1, '5': 9, '10': 'peer-public-key'},
    const {'1': 'client_id', '3': 5, '4': 1, '5': 9, '10': 'client-id'},
  ],
};

/// Descriptor for `WarpWireguardConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpWireguardConfigDescriptor = $convert.base64Decode('ChNXYXJwV2lyZWd1YXJkQ29uZmlnEiAKC3ByaXZhdGVfa2V5GAEgASgJUgtwcml2YXRlLWtleRIuChJsb2NhbF9hZGRyZXNzX2lwdjQYAiABKAlSEmxvY2FsLWFkZHJlc3MtaXB2NBIuChJsb2NhbF9hZGRyZXNzX2lwdjYYAyABKAlSEmxvY2FsLWFkZHJlc3MtaXB2NhIoCg9wZWVyX3B1YmxpY19rZXkYBCABKAlSD3BlZXItcHVibGljLWtleRIcCgljbGllbnRfaWQYBSABKAlSCWNsaWVudC1pZA==');
@$core.Deprecated('Use warpGenerationResponseDescriptor instead')
const WarpGenerationResponse$json = const {
  '1': 'WarpGenerationResponse',
  '2': const [
    const {'1': 'account', '3': 1, '4': 1, '5': 11, '6': '.hcore.WarpAccount', '10': 'account'},
    const {'1': 'log', '3': 2, '4': 1, '5': 9, '10': 'log'},
    const {'1': 'config', '3': 3, '4': 1, '5': 11, '6': '.hcore.WarpWireguardConfig', '10': 'config'},
  ],
};

/// Descriptor for `WarpGenerationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpGenerationResponseDescriptor = $convert.base64Decode('ChZXYXJwR2VuZXJhdGlvblJlc3BvbnNlEiwKB2FjY291bnQYASABKAsyEi5oY29yZS5XYXJwQWNjb3VudFIHYWNjb3VudBIQCgNsb2cYAiABKAlSA2xvZxIyCgZjb25maWcYAyABKAsyGi5oY29yZS5XYXJwV2lyZWd1YXJkQ29uZmlnUgZjb25maWc=');
@$core.Deprecated('Use systemProxyStatusDescriptor instead')
const SystemProxyStatus$json = const {
  '1': 'SystemProxyStatus',
  '2': const [
    const {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    const {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SystemProxyStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemProxyStatusDescriptor = $convert.base64Decode('ChFTeXN0ZW1Qcm94eVN0YXR1cxIcCglhdmFpbGFibGUYASABKAhSCWF2YWlsYWJsZRIYCgdlbmFibGVkGAIgASgIUgdlbmFibGVk');
@$core.Deprecated('Use parseRequestDescriptor instead')
const ParseRequest$json = const {
  '1': 'ParseRequest',
  '2': const [
    const {'1': 'content', '3': 1, '4': 1, '5': 9, '10': 'content'},
    const {'1': 'config_path', '3': 2, '4': 1, '5': 9, '10': 'configPath'},
    const {'1': 'temp_path', '3': 3, '4': 1, '5': 9, '10': 'tempPath'},
    const {'1': 'debug', '3': 4, '4': 1, '5': 8, '10': 'debug'},
  ],
};

/// Descriptor for `ParseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseRequestDescriptor = $convert.base64Decode('CgxQYXJzZVJlcXVlc3QSGAoHY29udGVudBgBIAEoCVIHY29udGVudBIfCgtjb25maWdfcGF0aBgCIAEoCVIKY29uZmlnUGF0aBIbCgl0ZW1wX3BhdGgYAyABKAlSCHRlbXBQYXRoEhQKBWRlYnVnGAQgASgIUgVkZWJ1Zw==');
@$core.Deprecated('Use parseResponseDescriptor instead')
const ParseResponse$json = const {
  '1': 'ParseResponse',
  '2': const [
    const {'1': 'response_code', '3': 1, '4': 1, '5': 14, '6': '.hcommon.ResponseCode', '10': 'responseCode'},
    const {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    const {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ParseResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseResponseDescriptor = $convert.base64Decode('Cg1QYXJzZVJlc3BvbnNlEjoKDXJlc3BvbnNlX2NvZGUYASABKA4yFS5oY29tbW9uLlJlc3BvbnNlQ29kZVIMcmVzcG9uc2VDb2RlEhgKB2NvbnRlbnQYAiABKAlSB2NvbnRlbnQSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZQ==');
@$core.Deprecated('Use changeHiddifySettingsRequestDescriptor instead')
const ChangeHiddifySettingsRequest$json = const {
  '1': 'ChangeHiddifySettingsRequest',
  '2': const [
    const {'1': 'hiddify_settings_json', '3': 1, '4': 1, '5': 9, '10': 'hiddifySettingsJson'},
  ],
};

/// Descriptor for `ChangeHiddifySettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeHiddifySettingsRequestDescriptor = $convert.base64Decode('ChxDaGFuZ2VIaWRkaWZ5U2V0dGluZ3NSZXF1ZXN0EjIKFWhpZGRpZnlfc2V0dGluZ3NfanNvbhgBIAEoCVITaGlkZGlmeVNldHRpbmdzSnNvbg==');
@$core.Deprecated('Use generateConfigRequestDescriptor instead')
const GenerateConfigRequest$json = const {
  '1': 'GenerateConfigRequest',
  '2': const [
    const {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    const {'1': 'temp_path', '3': 2, '4': 1, '5': 9, '10': 'tempPath'},
    const {'1': 'debug', '3': 3, '4': 1, '5': 8, '10': 'debug'},
  ],
};

/// Descriptor for `GenerateConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateConfigRequestDescriptor = $convert.base64Decode('ChVHZW5lcmF0ZUNvbmZpZ1JlcXVlc3QSEgoEcGF0aBgBIAEoCVIEcGF0aBIbCgl0ZW1wX3BhdGgYAiABKAlSCHRlbXBQYXRoEhQKBWRlYnVnGAMgASgIUgVkZWJ1Zw==');
@$core.Deprecated('Use generateConfigResponseDescriptor instead')
const GenerateConfigResponse$json = const {
  '1': 'GenerateConfigResponse',
  '2': const [
    const {'1': 'config_content', '3': 1, '4': 1, '5': 9, '10': 'configContent'},
  ],
};

/// Descriptor for `GenerateConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateConfigResponseDescriptor = $convert.base64Decode('ChZHZW5lcmF0ZUNvbmZpZ1Jlc3BvbnNlEiUKDmNvbmZpZ19jb250ZW50GAEgASgJUg1jb25maWdDb250ZW50');
@$core.Deprecated('Use selectOutboundRequestDescriptor instead')
const SelectOutboundRequest$json = const {
  '1': 'SelectOutboundRequest',
  '2': const [
    const {'1': 'group_tag', '3': 1, '4': 1, '5': 9, '10': 'groupTag'},
    const {'1': 'outbound_tag', '3': 2, '4': 1, '5': 9, '10': 'outboundTag'},
  ],
};

/// Descriptor for `SelectOutboundRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOutboundRequestDescriptor = $convert.base64Decode('ChVTZWxlY3RPdXRib3VuZFJlcXVlc3QSGwoJZ3JvdXBfdGFnGAEgASgJUghncm91cFRhZxIhCgxvdXRib3VuZF90YWcYAiABKAlSC291dGJvdW5kVGFn');
@$core.Deprecated('Use urlTestRequestDescriptor instead')
const UrlTestRequest$json = const {
  '1': 'UrlTestRequest',
  '2': const [
    const {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
  ],
};

/// Descriptor for `UrlTestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List urlTestRequestDescriptor = $convert.base64Decode('Cg5VcmxUZXN0UmVxdWVzdBIQCgN0YWcYASABKAlSA3RhZw==');
@$core.Deprecated('Use generateWarpConfigRequestDescriptor instead')
const GenerateWarpConfigRequest$json = const {
  '1': 'GenerateWarpConfigRequest',
  '2': const [
    const {'1': 'license_key', '3': 1, '4': 1, '5': 9, '10': 'licenseKey'},
    const {'1': 'account_id', '3': 2, '4': 1, '5': 9, '10': 'accountId'},
    const {'1': 'access_token', '3': 3, '4': 1, '5': 9, '10': 'accessToken'},
  ],
};

/// Descriptor for `GenerateWarpConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateWarpConfigRequestDescriptor = $convert.base64Decode('ChlHZW5lcmF0ZVdhcnBDb25maWdSZXF1ZXN0Eh8KC2xpY2Vuc2Vfa2V5GAEgASgJUgpsaWNlbnNlS2V5Eh0KCmFjY291bnRfaWQYAiABKAlSCWFjY291bnRJZBIhCgxhY2Nlc3NfdG9rZW4YAyABKAlSC2FjY2Vzc1Rva2Vu');
@$core.Deprecated('Use setSystemProxyEnabledRequestDescriptor instead')
const SetSystemProxyEnabledRequest$json = const {
  '1': 'SetSystemProxyEnabledRequest',
  '2': const [
    const {'1': 'is_enabled', '3': 1, '4': 1, '5': 8, '10': 'isEnabled'},
  ],
};

/// Descriptor for `SetSystemProxyEnabledRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSystemProxyEnabledRequestDescriptor = $convert.base64Decode('ChxTZXRTeXN0ZW1Qcm94eUVuYWJsZWRSZXF1ZXN0Eh0KCmlzX2VuYWJsZWQYASABKAhSCWlzRW5hYmxlZA==');
@$core.Deprecated('Use logMessageDescriptor instead')
const LogMessage$json = const {
  '1': 'LogMessage',
  '2': const [
    const {'1': 'level', '3': 1, '4': 1, '5': 14, '6': '.hcore.LogLevel', '10': 'level'},
    const {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.hcore.LogType', '10': 'type'},
    const {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    const {'1': 'time', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'time'},
  ],
};

/// Descriptor for `LogMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logMessageDescriptor = $convert.base64Decode('CgpMb2dNZXNzYWdlEiUKBWxldmVsGAEgASgOMg8uaGNvcmUuTG9nTGV2ZWxSBWxldmVsEiIKBHR5cGUYAiABKA4yDi5oY29yZS5Mb2dUeXBlUgR0eXBlEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2USLgoEdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBHRpbWU=');
@$core.Deprecated('Use logRequestDescriptor instead')
const LogRequest$json = const {
  '1': 'LogRequest',
  '2': const [
    const {'1': 'level', '3': 1, '4': 1, '5': 14, '6': '.hcore.LogLevel', '10': 'level'},
  ],
};

/// Descriptor for `LogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logRequestDescriptor = $convert.base64Decode('CgpMb2dSZXF1ZXN0EiUKBWxldmVsGAEgASgOMg8uaGNvcmUuTG9nTGV2ZWxSBWxldmVs');
@$core.Deprecated('Use stopRequestDescriptor instead')
const StopRequest$json = const {
  '1': 'StopRequest',
};

/// Descriptor for `StopRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopRequestDescriptor = $convert.base64Decode('CgtTdG9wUmVxdWVzdA==');
