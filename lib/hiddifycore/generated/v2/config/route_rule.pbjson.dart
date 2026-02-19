///
//  Generated code. Do not modify.
//  source: v2/config/route_rule.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use outboundDescriptor instead')
const Outbound$json = const {
  '1': 'Outbound',
  '2': const [
    const {'1': 'proxy', '2': 0},
    const {'1': 'direct', '2': 1},
    const {'1': 'direct_with_fragment', '2': 2},
    const {'1': 'block', '2': 3},
  ],
};

/// Descriptor for `Outbound`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outboundDescriptor = $convert.base64Decode('CghPdXRib3VuZBIJCgVwcm94eRAAEgoKBmRpcmVjdBABEhgKFGRpcmVjdF93aXRoX2ZyYWdtZW50EAISCQoFYmxvY2sQAw==');
@$core.Deprecated('Use networkDescriptor instead')
const Network$json = const {
  '1': 'Network',
  '2': const [
    const {'1': 'all', '2': 0},
    const {'1': 'tcp', '2': 1},
    const {'1': 'udp', '2': 2},
  ],
};

/// Descriptor for `Network`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List networkDescriptor = $convert.base64Decode('CgdOZXR3b3JrEgcKA2FsbBAAEgcKA3RjcBABEgcKA3VkcBAC');
@$core.Deprecated('Use protocolDescriptor instead')
const Protocol$json = const {
  '1': 'Protocol',
  '2': const [
    const {'1': 'tls', '2': 0},
    const {'1': 'http', '2': 1},
    const {'1': 'quic', '2': 2},
    const {'1': 'stun', '2': 3},
    const {'1': 'dns', '2': 4},
    const {'1': 'bittorrent', '2': 5},
  ],
};

/// Descriptor for `Protocol`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List protocolDescriptor = $convert.base64Decode('CghQcm90b2NvbBIHCgN0bHMQABIICgRodHRwEAESCAoEcXVpYxACEggKBHN0dW4QAxIHCgNkbnMQBBIOCgpiaXR0b3JyZW50EAU=');
@$core.Deprecated('Use routeRuleDescriptor instead')
const RouteRule$json = const {
  '1': 'RouteRule',
  '2': const [
    const {'1': 'rules', '3': 1, '4': 3, '5': 11, '6': '.config.Rule', '10': 'rules'},
  ],
};

/// Descriptor for `RouteRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeRuleDescriptor = $convert.base64Decode('CglSb3V0ZVJ1bGUSIgoFcnVsZXMYASADKAsyDC5jb25maWcuUnVsZVIFcnVsZXM=');
@$core.Deprecated('Use ruleDescriptor instead')
const Rule$json = const {
  '1': 'Rule',
  '2': const [
    const {'1': 'list_order', '3': 1, '4': 1, '5': 13, '10': 'list_order'},
    const {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'outbound', '3': 4, '4': 1, '5': 14, '6': '.config.Outbound', '10': 'outbound'},
    const {'1': 'rule_sets', '3': 5, '4': 3, '5': 9, '10': 'rule_set'},
    const {'1': 'package_names', '3': 6, '4': 3, '5': 9, '10': 'package_name'},
    const {'1': 'process_names', '3': 7, '4': 3, '5': 9, '10': 'process_name'},
    const {'1': 'process_paths', '3': 8, '4': 3, '5': 9, '10': 'process_path'},
    const {'1': 'network', '3': 9, '4': 1, '5': 14, '6': '.config.Network', '10': 'network'},
    const {'1': 'port_ranges', '3': 10, '4': 3, '5': 9, '10': 'port_range'},
    const {'1': 'source_port_ranges', '3': 11, '4': 3, '5': 9, '10': 'source_port_range'},
    const {'1': 'protocols', '3': 12, '4': 3, '5': 14, '6': '.config.Protocol', '10': 'protocol'},
    const {'1': 'ip_cidrs', '3': 13, '4': 3, '5': 9, '10': 'ip_cidr'},
    const {'1': 'source_ip_cidrs', '3': 14, '4': 3, '5': 9, '10': 'source_ip_cidr'},
    const {'1': 'domains', '3': 15, '4': 3, '5': 9, '10': 'domain'},
    const {'1': 'domain_suffixes', '3': 16, '4': 3, '5': 9, '10': 'domain_suffix'},
    const {'1': 'domain_keywords', '3': 17, '4': 3, '5': 9, '10': 'domain_keyword'},
    const {'1': 'domain_regexes', '3': 18, '4': 3, '5': 9, '10': 'domain_regex'},
  ],
};

/// Descriptor for `Rule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ruleDescriptor = $convert.base64Decode('CgRSdWxlEh4KCmxpc3Rfb3JkZXIYASABKA1SCmxpc3Rfb3JkZXISGAoHZW5hYmxlZBgCIAEoCFIHZW5hYmxlZBISCgRuYW1lGAMgASgJUgRuYW1lEiwKCG91dGJvdW5kGAQgASgOMhAuY29uZmlnLk91dGJvdW5kUghvdXRib3VuZBIbCglydWxlX3NldHMYBSADKAlSCHJ1bGVfc2V0EiMKDXBhY2thZ2VfbmFtZXMYBiADKAlSDHBhY2thZ2VfbmFtZRIjCg1wcm9jZXNzX25hbWVzGAcgAygJUgxwcm9jZXNzX25hbWUSIwoNcHJvY2Vzc19wYXRocxgIIAMoCVIMcHJvY2Vzc19wYXRoEikKB25ldHdvcmsYCSABKA4yDy5jb25maWcuTmV0d29ya1IHbmV0d29yaxIfCgtwb3J0X3JhbmdlcxgKIAMoCVIKcG9ydF9yYW5nZRItChJzb3VyY2VfcG9ydF9yYW5nZXMYCyADKAlSEXNvdXJjZV9wb3J0X3JhbmdlEi0KCXByb3RvY29scxgMIAMoDjIQLmNvbmZpZy5Qcm90b2NvbFIIcHJvdG9jb2wSGQoIaXBfY2lkcnMYDSADKAlSB2lwX2NpZHISJwoPc291cmNlX2lwX2NpZHJzGA4gAygJUg5zb3VyY2VfaXBfY2lkchIXCgdkb21haW5zGA8gAygJUgZkb21haW4SJgoPZG9tYWluX3N1ZmZpeGVzGBAgAygJUg1kb21haW5fc3VmZml4EicKD2RvbWFpbl9rZXl3b3JkcxgRIAMoCVIOZG9tYWluX2tleXdvcmQSJAoOZG9tYWluX3JlZ2V4ZXMYEiADKAlSDGRvbWFpbl9yZWdleA==');
