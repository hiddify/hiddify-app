//
//  Generated code. Do not modify.
//  source: v2/profile/profile.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use profileEntityDescriptor instead')
const ProfileEntity$json = {
  '1': 'ProfileEntity',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'url', '3': 4, '4': 1, '5': 9, '10': 'url'},
    {'1': 'last_update', '3': 5, '4': 1, '5': 3, '10': 'lastUpdate'},
    {'1': 'options', '3': 6, '4': 1, '5': 11, '6': '.profile.ProfileOptions', '10': 'options'},
    {'1': 'sub_info', '3': 7, '4': 1, '5': 11, '6': '.profile.SubscriptionInfo', '10': 'subInfo'},
    {'1': 'override_hiddify_options', '3': 8, '4': 1, '5': 11, '6': '.hiddifyoptions.HiddifyOptions', '10': 'overrideHiddifyOptions'},
  ],
};

/// Descriptor for `ProfileEntity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileEntityDescriptor = $convert.base64Decode(
    'Cg1Qcm9maWxlRW50aXR5Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAMgASgJUgRuYW1lEhAKA3'
    'VybBgEIAEoCVIDdXJsEh8KC2xhc3RfdXBkYXRlGAUgASgDUgpsYXN0VXBkYXRlEjEKB29wdGlv'
    'bnMYBiABKAsyFy5wcm9maWxlLlByb2ZpbGVPcHRpb25zUgdvcHRpb25zEjQKCHN1Yl9pbmZvGA'
    'cgASgLMhkucHJvZmlsZS5TdWJzY3JpcHRpb25JbmZvUgdzdWJJbmZvElgKGG92ZXJyaWRlX2hp'
    'ZGRpZnlfb3B0aW9ucxgIIAEoCzIeLmhpZGRpZnlvcHRpb25zLkhpZGRpZnlPcHRpb25zUhZvdm'
    'VycmlkZUhpZGRpZnlPcHRpb25z');

@$core.Deprecated('Use profileOptionsDescriptor instead')
const ProfileOptions$json = {
  '1': 'ProfileOptions',
  '2': [
    {'1': 'update_interval', '3': 1, '4': 1, '5': 3, '10': 'updateInterval'},
  ],
};

/// Descriptor for `ProfileOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileOptionsDescriptor = $convert.base64Decode(
    'Cg5Qcm9maWxlT3B0aW9ucxInCg91cGRhdGVfaW50ZXJ2YWwYASABKANSDnVwZGF0ZUludGVydm'
    'Fs');

@$core.Deprecated('Use subscriptionInfoDescriptor instead')
const SubscriptionInfo$json = {
  '1': 'SubscriptionInfo',
  '2': [
    {'1': 'upload', '3': 1, '4': 1, '5': 3, '10': 'upload'},
    {'1': 'download', '3': 2, '4': 1, '5': 3, '10': 'download'},
    {'1': 'total', '3': 3, '4': 1, '5': 3, '10': 'total'},
    {'1': 'expire', '3': 4, '4': 1, '5': 3, '10': 'expire'},
    {'1': 'web_page_url', '3': 5, '4': 1, '5': 9, '10': 'webPageUrl'},
    {'1': 'support_url', '3': 6, '4': 1, '5': 9, '10': 'supportUrl'},
  ],
};

/// Descriptor for `SubscriptionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionInfoDescriptor = $convert.base64Decode(
    'ChBTdWJzY3JpcHRpb25JbmZvEhYKBnVwbG9hZBgBIAEoA1IGdXBsb2FkEhoKCGRvd25sb2FkGA'
    'IgASgDUghkb3dubG9hZBIUCgV0b3RhbBgDIAEoA1IFdG90YWwSFgoGZXhwaXJlGAQgASgDUgZl'
    'eHBpcmUSIAoMd2ViX3BhZ2VfdXJsGAUgASgJUgp3ZWJQYWdlVXJsEh8KC3N1cHBvcnRfdXJsGA'
    'YgASgJUgpzdXBwb3J0VXJs');

