///
//  Generated code. Do not modify.
//  source: v2/profile/profile.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use profileEntityDescriptor instead')
const ProfileEntity$json = const {
  '1': 'ProfileEntity',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'url', '3': 4, '4': 1, '5': 9, '10': 'url'},
    const {'1': 'last_update', '3': 5, '4': 1, '5': 3, '10': 'lastUpdate'},
    const {'1': 'options', '3': 6, '4': 1, '5': 11, '6': '.profile.ProfileOptions', '10': 'options'},
    const {'1': 'sub_info', '3': 7, '4': 1, '5': 11, '6': '.profile.SubscriptionInfo', '10': 'subInfo'},
    const {'1': 'override_hiddify_options', '3': 8, '4': 1, '5': 11, '6': '.hiddifyoptions.HiddifyOptions', '10': 'overrideHiddifyOptions'},
  ],
};

/// Descriptor for `ProfileEntity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileEntityDescriptor = $convert.base64Decode('Cg1Qcm9maWxlRW50aXR5Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAMgASgJUgRuYW1lEhAKA3VybBgEIAEoCVIDdXJsEh8KC2xhc3RfdXBkYXRlGAUgASgDUgpsYXN0VXBkYXRlEjEKB29wdGlvbnMYBiABKAsyFy5wcm9maWxlLlByb2ZpbGVPcHRpb25zUgdvcHRpb25zEjQKCHN1Yl9pbmZvGAcgASgLMhkucHJvZmlsZS5TdWJzY3JpcHRpb25JbmZvUgdzdWJJbmZvElgKGG92ZXJyaWRlX2hpZGRpZnlfb3B0aW9ucxgIIAEoCzIeLmhpZGRpZnlvcHRpb25zLkhpZGRpZnlPcHRpb25zUhZvdmVycmlkZUhpZGRpZnlPcHRpb25z');
@$core.Deprecated('Use profileOptionsDescriptor instead')
const ProfileOptions$json = const {
  '1': 'ProfileOptions',
  '2': const [
    const {'1': 'update_interval', '3': 1, '4': 1, '5': 3, '10': 'updateInterval'},
  ],
};

/// Descriptor for `ProfileOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileOptionsDescriptor = $convert.base64Decode('Cg5Qcm9maWxlT3B0aW9ucxInCg91cGRhdGVfaW50ZXJ2YWwYASABKANSDnVwZGF0ZUludGVydmFs');
@$core.Deprecated('Use subscriptionInfoDescriptor instead')
const SubscriptionInfo$json = const {
  '1': 'SubscriptionInfo',
  '2': const [
    const {'1': 'upload', '3': 1, '4': 1, '5': 3, '10': 'upload'},
    const {'1': 'download', '3': 2, '4': 1, '5': 3, '10': 'download'},
    const {'1': 'total', '3': 3, '4': 1, '5': 3, '10': 'total'},
    const {'1': 'expire', '3': 4, '4': 1, '5': 3, '10': 'expire'},
    const {'1': 'web_page_url', '3': 5, '4': 1, '5': 9, '10': 'webPageUrl'},
    const {'1': 'support_url', '3': 6, '4': 1, '5': 9, '10': 'supportUrl'},
  ],
};

/// Descriptor for `SubscriptionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionInfoDescriptor = $convert.base64Decode('ChBTdWJzY3JpcHRpb25JbmZvEhYKBnVwbG9hZBgBIAEoA1IGdXBsb2FkEhoKCGRvd25sb2FkGAIgASgDUghkb3dubG9hZBIUCgV0b3RhbBgDIAEoA1IFdG90YWwSFgoGZXhwaXJlGAQgASgDUgZleHBpcmUSIAoMd2ViX3BhZ2VfdXJsGAUgASgJUgp3ZWJQYWdlVXJsEh8KC3N1cHBvcnRfdXJsGAYgASgJUgpzdXBwb3J0VXJs');
