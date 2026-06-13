// This is a generated file - do not edit.
//
// Generated from v2/ezytel/ezytel.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use channelInfoRequestDescriptor instead')
const ChannelInfoRequest$json = {
  '1': 'ChannelInfoRequest',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'last_read', '3': 2, '4': 1, '5': 3, '10': 'lastRead'},
    {
      '1': 'disable_inline_images',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'disableInlineImages'
    },
  ],
};

/// Descriptor for `ChannelInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelInfoRequestDescriptor = $convert.base64Decode(
    'ChJDaGFubmVsSW5mb1JlcXVlc3QSHQoKY2hhbm5lbF9pZBgBIAEoCVIJY2hhbm5lbElkEhsKCW'
    'xhc3RfcmVhZBgCIAEoA1IIbGFzdFJlYWQSMgoVZGlzYWJsZV9pbmxpbmVfaW1hZ2VzGAMgASgI'
    'UhNkaXNhYmxlSW5saW5lSW1hZ2Vz');

@$core.Deprecated('Use channelInfoDescriptor instead')
const ChannelInfo$json = {
  '1': 'ChannelInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'avatar_path', '3': 3, '4': 1, '5': 9, '10': 'avatarPath'},
    {'1': 'date', '3': 4, '4': 1, '5': 3, '10': 'date'},
    {'1': 'date_str', '3': 5, '4': 1, '5': 9, '10': 'dateStr'},
    {'1': 'newmsg', '3': 6, '4': 1, '5': 9, '10': 'newmsg'},
    {'1': 'last_post_id', '3': 7, '4': 1, '5': 3, '10': 'lastPostId'},
    {'1': 'ok', '3': 8, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ChannelInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelInfoDescriptor = $convert.base64Decode(
    'CgtDaGFubmVsSW5mbxISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUg'
    'tkZXNjcmlwdGlvbhIfCgthdmF0YXJfcGF0aBgDIAEoCVIKYXZhdGFyUGF0aBISCgRkYXRlGAQg'
    'ASgDUgRkYXRlEhkKCGRhdGVfc3RyGAUgASgJUgdkYXRlU3RyEhYKBm5ld21zZxgGIAEoCVIGbm'
    'V3bXNnEiAKDGxhc3RfcG9zdF9pZBgHIAEoA1IKbGFzdFBvc3RJZBIOCgJvaxgIIAEoCFICb2s=');

@$core.Deprecated('Use channelMessagesRequestDescriptor instead')
const ChannelMessagesRequest$json = {
  '1': 'ChannelMessagesRequest',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'before', '3': 2, '4': 1, '5': 3, '10': 'before'},
    {
      '1': 'disable_inline_images',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'disableInlineImages'
    },
  ],
};

/// Descriptor for `ChannelMessagesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelMessagesRequestDescriptor = $convert.base64Decode(
    'ChZDaGFubmVsTWVzc2FnZXNSZXF1ZXN0Eh0KCmNoYW5uZWxfaWQYASABKAlSCWNoYW5uZWxJZB'
    'IWCgZiZWZvcmUYAiABKANSBmJlZm9yZRIyChVkaXNhYmxlX2lubGluZV9pbWFnZXMYAyABKAhS'
    'E2Rpc2FibGVJbmxpbmVJbWFnZXM=');

@$core.Deprecated('Use channelMessagesResponseDescriptor instead')
const ChannelMessagesResponse$json = {
  '1': 'ChannelMessagesResponse',
  '2': [
    {'1': 'html', '3': 1, '4': 1, '5': 9, '10': 'html'},
    {'1': 'channel_avatar', '3': 2, '4': 1, '5': 9, '10': 'channelAvatar'},
    {'1': 'last_post_id', '3': 3, '4': 1, '5': 3, '10': 'lastPostId'},
  ],
};

/// Descriptor for `ChannelMessagesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelMessagesResponseDescriptor = $convert.base64Decode(
    'ChdDaGFubmVsTWVzc2FnZXNSZXNwb25zZRISCgRodG1sGAEgASgJUgRodG1sEiUKDmNoYW5uZW'
    'xfYXZhdGFyGAIgASgJUg1jaGFubmVsQXZhdGFyEiAKDGxhc3RfcG9zdF9pZBgDIAEoA1IKbGFz'
    'dFBvc3RJZA==');

@$core.Deprecated('Use proxyImageRequestDescriptor instead')
const ProxyImageRequest$json = {
  '1': 'ProxyImageRequest',
  '2': [
    {'1': 'hex_url', '3': 1, '4': 1, '5': 9, '10': 'hexUrl'},
  ],
};

/// Descriptor for `ProxyImageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List proxyImageRequestDescriptor = $convert.base64Decode(
    'ChFQcm94eUltYWdlUmVxdWVzdBIXCgdoZXhfdXJsGAEgASgJUgZoZXhVcmw=');

@$core.Deprecated('Use proxyImageResponseDescriptor instead')
const ProxyImageResponse$json = {
  '1': 'ProxyImageResponse',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'content_type', '3': 2, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'cache_name', '3': 3, '4': 1, '5': 9, '10': 'cacheName'},
  ],
};

/// Descriptor for `ProxyImageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List proxyImageResponseDescriptor = $convert.base64Decode(
    'ChJQcm94eUltYWdlUmVzcG9uc2USEgoEZGF0YRgBIAEoDFIEZGF0YRIhCgxjb250ZW50X3R5cG'
    'UYAiABKAlSC2NvbnRlbnRUeXBlEh0KCmNhY2hlX25hbWUYAyABKAlSCWNhY2hlTmFtZQ==');

@$core.Deprecated('Use parseChannelsRequestDescriptor instead')
const ParseChannelsRequest$json = {
  '1': 'ParseChannelsRequest',
  '2': [
    {'1': 'raw', '3': 1, '4': 1, '5': 9, '10': 'raw'},
  ],
};

/// Descriptor for `ParseChannelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseChannelsRequestDescriptor = $convert
    .base64Decode('ChRQYXJzZUNoYW5uZWxzUmVxdWVzdBIQCgNyYXcYASABKAlSA3Jhdw==');

@$core.Deprecated('Use parseChannelsResponseDescriptor instead')
const ParseChannelsResponse$json = {
  '1': 'ParseChannelsResponse',
  '2': [
    {'1': 'channel_ids', '3': 1, '4': 3, '5': 9, '10': 'channelIds'},
  ],
};

/// Descriptor for `ParseChannelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseChannelsResponseDescriptor = $convert.base64Decode(
    'ChVQYXJzZUNoYW5uZWxzUmVzcG9uc2USHwoLY2hhbm5lbF9pZHMYASADKAlSCmNoYW5uZWxJZH'
    'M=');
