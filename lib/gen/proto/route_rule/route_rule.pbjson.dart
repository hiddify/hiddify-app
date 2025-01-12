//
//  Generated code. Do not modify.
//  source: route_rule/route_rule.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use outboundDescriptor instead')
const Outbound$json = {
  '1': 'Outbound',
  '2': [
    {'1': 'proxy', '2': 0},
    {'1': 'direct', '2': 1},
    {'1': 'direct_with_fragment', '2': 2},
    {'1': 'block', '2': 3},
  ],
};

/// Descriptor for `Outbound`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outboundDescriptor = $convert.base64Decode(
    'CghPdXRib3VuZBIJCgVwcm94eRAAEgoKBmRpcmVjdBABEhgKFGRpcmVjdF93aXRoX2ZyYWdtZW'
    '50EAISCQoFYmxvY2sQAw==');

@$core.Deprecated('Use networkDescriptor instead')
const Network$json = {
  '1': 'Network',
  '2': [
    {'1': 'all', '2': 0},
    {'1': 'tcp', '2': 1},
    {'1': 'udp', '2': 2},
  ],
};

/// Descriptor for `Network`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List networkDescriptor = $convert.base64Decode(
    'CgdOZXR3b3JrEgcKA2FsbBAAEgcKA3RjcBABEgcKA3VkcBAC');

@$core.Deprecated('Use protocolDescriptor instead')
const Protocol$json = {
  '1': 'Protocol',
  '2': [
    {'1': 'tls', '2': 0},
    {'1': 'http', '2': 1},
    {'1': 'quic', '2': 2},
    {'1': 'stun', '2': 3},
    {'1': 'dns', '2': 4},
    {'1': 'bittorrent', '2': 5},
  ],
};

/// Descriptor for `Protocol`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List protocolDescriptor = $convert.base64Decode(
    'CghQcm90b2NvbBIHCgN0bHMQABIICgRodHRwEAESCAoEcXVpYxACEggKBHN0dW4QAxIHCgNkbn'
    'MQBBIOCgpiaXR0b3JyZW50EAU=');

@$core.Deprecated('Use routeRuleDescriptor instead')
const RouteRule$json = {
  '1': 'RouteRule',
  '2': [
    {'1': 'rules', '3': 1, '4': 3, '5': 11, '6': '.Rule', '10': 'rules'},
  ],
};

/// Descriptor for `RouteRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeRuleDescriptor = $convert.base64Decode(
    'CglSb3V0ZVJ1bGUSGwoFcnVsZXMYASADKAsyBS5SdWxlUgVydWxlcw==');

@$core.Deprecated('Use ruleDescriptor instead')
const Rule$json = {
  '1': 'Rule',
  '2': [
    {'1': 'list_order', '3': 1, '4': 1, '5': 13, '10': 'list_order'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'outbound', '3': 4, '4': 1, '5': 14, '6': '.Outbound', '10': 'outbound'},
    {'1': 'rule_sets', '3': 5, '4': 3, '5': 9, '10': 'rule_set'},
    {'1': 'package_names', '3': 6, '4': 3, '5': 9, '10': 'package_name'},
    {'1': 'process_names', '3': 7, '4': 3, '5': 9, '10': 'process_name'},
    {'1': 'process_paths', '3': 8, '4': 3, '5': 9, '10': 'process_path'},
    {'1': 'network', '3': 9, '4': 1, '5': 14, '6': '.Network', '10': 'network'},
    {'1': 'port_ranges', '3': 10, '4': 3, '5': 9, '10': 'port_range'},
    {'1': 'source_port_ranges', '3': 11, '4': 3, '5': 9, '10': 'source_port_range'},
    {'1': 'protocols', '3': 12, '4': 3, '5': 14, '6': '.Protocol', '10': 'protocol'},
    {'1': 'ip_cidrs', '3': 13, '4': 3, '5': 9, '10': 'ip_cidr'},
    {'1': 'source_ip_cidrs', '3': 14, '4': 3, '5': 9, '10': 'source_ip_cidr'},
    {'1': 'domains', '3': 15, '4': 3, '5': 9, '10': 'domain'},
    {'1': 'domain_suffixes', '3': 16, '4': 3, '5': 9, '10': 'domain_suffix'},
    {'1': 'domain_keywords', '3': 17, '4': 3, '5': 9, '10': 'domain_keyword'},
    {'1': 'domain_regexes', '3': 18, '4': 3, '5': 9, '10': 'domain_regex'},
  ],
};

/// Descriptor for `Rule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ruleDescriptor = $convert.base64Decode(
    'CgRSdWxlEh4KCmxpc3Rfb3JkZXIYASABKA1SCmxpc3Rfb3JkZXISGAoHZW5hYmxlZBgCIAEoCF'
    'IHZW5hYmxlZBISCgRuYW1lGAMgASgJUgRuYW1lEiUKCG91dGJvdW5kGAQgASgOMgkuT3V0Ym91'
    'bmRSCG91dGJvdW5kEhsKCXJ1bGVfc2V0cxgFIAMoCVIIcnVsZV9zZXQSIwoNcGFja2FnZV9uYW'
    '1lcxgGIAMoCVIMcGFja2FnZV9uYW1lEiMKDXByb2Nlc3NfbmFtZXMYByADKAlSDHByb2Nlc3Nf'
    'bmFtZRIjCg1wcm9jZXNzX3BhdGhzGAggAygJUgxwcm9jZXNzX3BhdGgSIgoHbmV0d29yaxgJIA'
    'EoDjIILk5ldHdvcmtSB25ldHdvcmsSHwoLcG9ydF9yYW5nZXMYCiADKAlSCnBvcnRfcmFuZ2US'
    'LQoSc291cmNlX3BvcnRfcmFuZ2VzGAsgAygJUhFzb3VyY2VfcG9ydF9yYW5nZRImCglwcm90b2'
    'NvbHMYDCADKA4yCS5Qcm90b2NvbFIIcHJvdG9jb2wSGQoIaXBfY2lkcnMYDSADKAlSB2lwX2Np'
    'ZHISJwoPc291cmNlX2lwX2NpZHJzGA4gAygJUg5zb3VyY2VfaXBfY2lkchIXCgdkb21haW5zGA'
    '8gAygJUgZkb21haW4SJgoPZG9tYWluX3N1ZmZpeGVzGBAgAygJUg1kb21haW5fc3VmZml4EicK'
    'D2RvbWFpbl9rZXl3b3JkcxgRIAMoCVIOZG9tYWluX2tleXdvcmQSJAoOZG9tYWluX3JlZ2V4ZX'
    'MYEiADKAlSDGRvbWFpbl9yZWdleA==');

