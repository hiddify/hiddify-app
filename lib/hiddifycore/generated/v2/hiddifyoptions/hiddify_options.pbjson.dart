///
//  Generated code. Do not modify.
//  source: v2/hiddifyoptions/hiddify_options.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use domainStrategyDescriptor instead')
const DomainStrategy$json = const {
  '1': 'DomainStrategy',
  '2': const [
    const {'1': 'as_is', '2': 0},
    const {'1': 'prefer_ipv4', '2': 1},
    const {'1': 'prefer_ipv6', '2': 2},
    const {'1': 'ipv4_only', '2': 3},
    const {'1': 'ipv6_only', '2': 4},
  ],
};

/// Descriptor for `DomainStrategy`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List domainStrategyDescriptor = $convert.base64Decode('Cg5Eb21haW5TdHJhdGVneRIJCgVhc19pcxAAEg8KC3ByZWZlcl9pcHY0EAESDwoLcHJlZmVyX2lwdjYQAhINCglpcHY0X29ubHkQAxINCglpcHY2X29ubHkQBA==');
@$core.Deprecated('Use hiddifyOptionsDescriptor instead')
const HiddifyOptions$json = const {
  '1': 'HiddifyOptions',
  '2': const [
    const {'1': 'enable_full_config', '3': 1, '4': 1, '5': 8, '10': 'enableFullConfig'},
    const {'1': 'log_level', '3': 2, '4': 1, '5': 9, '10': 'logLevel'},
    const {'1': 'log_file', '3': 3, '4': 1, '5': 9, '10': 'logFile'},
    const {'1': 'enable_clash_api', '3': 4, '4': 1, '5': 8, '10': 'enableClashApi'},
    const {'1': 'clash_api_port', '3': 5, '4': 1, '5': 13, '10': 'clashApiPort'},
    const {'1': 'web_secret', '3': 6, '4': 1, '5': 9, '10': 'webSecret'},
    const {'1': 'region', '3': 7, '4': 1, '5': 9, '10': 'region'},
    const {'1': 'block_ads', '3': 8, '4': 1, '5': 8, '10': 'blockAds'},
    const {'1': 'use_xray_core_when_possible', '3': 9, '4': 1, '5': 8, '10': 'useXrayCoreWhenPossible'},
    const {'1': 'rules', '3': 10, '4': 3, '5': 11, '6': '.hiddifyoptions.Rule', '10': 'rules'},
    const {'1': 'warp', '3': 11, '4': 1, '5': 11, '6': '.hiddifyoptions.WarpOptions', '10': 'warp'},
    const {'1': 'warp2', '3': 12, '4': 1, '5': 11, '6': '.hiddifyoptions.WarpOptions', '10': 'warp2'},
    const {'1': 'mux', '3': 13, '4': 1, '5': 11, '6': '.hiddifyoptions.MuxOptions', '10': 'mux'},
    const {'1': 'tls_tricks', '3': 14, '4': 1, '5': 11, '6': '.hiddifyoptions.TLSTricks', '10': 'tlsTricks'},
    const {'1': 'dns_options', '3': 15, '4': 1, '5': 11, '6': '.hiddifyoptions.DNSOptions', '10': 'dnsOptions'},
    const {'1': 'inbound_options', '3': 16, '4': 1, '5': 11, '6': '.hiddifyoptions.InboundOptions', '10': 'inboundOptions'},
    const {'1': 'url_test_options', '3': 17, '4': 1, '5': 11, '6': '.hiddifyoptions.URLTestOptions', '10': 'urlTestOptions'},
    const {'1': 'route_options', '3': 18, '4': 1, '5': 11, '6': '.hiddifyoptions.RouteOptions', '10': 'routeOptions'},
  ],
};

/// Descriptor for `HiddifyOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hiddifyOptionsDescriptor = $convert.base64Decode('Cg5IaWRkaWZ5T3B0aW9ucxIsChJlbmFibGVfZnVsbF9jb25maWcYASABKAhSEGVuYWJsZUZ1bGxDb25maWcSGwoJbG9nX2xldmVsGAIgASgJUghsb2dMZXZlbBIZCghsb2dfZmlsZRgDIAEoCVIHbG9nRmlsZRIoChBlbmFibGVfY2xhc2hfYXBpGAQgASgIUg5lbmFibGVDbGFzaEFwaRIkCg5jbGFzaF9hcGlfcG9ydBgFIAEoDVIMY2xhc2hBcGlQb3J0Eh0KCndlYl9zZWNyZXQYBiABKAlSCXdlYlNlY3JldBIWCgZyZWdpb24YByABKAlSBnJlZ2lvbhIbCglibG9ja19hZHMYCCABKAhSCGJsb2NrQWRzEjwKG3VzZV94cmF5X2NvcmVfd2hlbl9wb3NzaWJsZRgJIAEoCFIXdXNlWHJheUNvcmVXaGVuUG9zc2libGUSKgoFcnVsZXMYCiADKAsyFC5oaWRkaWZ5b3B0aW9ucy5SdWxlUgVydWxlcxIvCgR3YXJwGAsgASgLMhsuaGlkZGlmeW9wdGlvbnMuV2FycE9wdGlvbnNSBHdhcnASMQoFd2FycDIYDCABKAsyGy5oaWRkaWZ5b3B0aW9ucy5XYXJwT3B0aW9uc1IFd2FycDISLAoDbXV4GA0gASgLMhouaGlkZGlmeW9wdGlvbnMuTXV4T3B0aW9uc1IDbXV4EjgKCnRsc190cmlja3MYDiABKAsyGS5oaWRkaWZ5b3B0aW9ucy5UTFNUcmlja3NSCXRsc1RyaWNrcxI7CgtkbnNfb3B0aW9ucxgPIAEoCzIaLmhpZGRpZnlvcHRpb25zLkROU09wdGlvbnNSCmRuc09wdGlvbnMSRwoPaW5ib3VuZF9vcHRpb25zGBAgASgLMh4uaGlkZGlmeW9wdGlvbnMuSW5ib3VuZE9wdGlvbnNSDmluYm91bmRPcHRpb25zEkgKEHVybF90ZXN0X29wdGlvbnMYESABKAsyHi5oaWRkaWZ5b3B0aW9ucy5VUkxUZXN0T3B0aW9uc1IOdXJsVGVzdE9wdGlvbnMSQQoNcm91dGVfb3B0aW9ucxgSIAEoCzIcLmhpZGRpZnlvcHRpb25zLlJvdXRlT3B0aW9uc1IMcm91dGVPcHRpb25z');
@$core.Deprecated('Use intRangeDescriptor instead')
const IntRange$json = const {
  '1': 'IntRange',
  '2': const [
    const {'1': 'from', '3': 1, '4': 1, '5': 5, '10': 'from'},
    const {'1': 'to', '3': 2, '4': 1, '5': 5, '10': 'to'},
  ],
};

/// Descriptor for `IntRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List intRangeDescriptor = $convert.base64Decode('CghJbnRSYW5nZRISCgRmcm9tGAEgASgFUgRmcm9tEg4KAnRvGAIgASgFUgJ0bw==');
@$core.Deprecated('Use dNSOptionsDescriptor instead')
const DNSOptions$json = const {
  '1': 'DNSOptions',
  '2': const [
    const {'1': 'remote_dns_address', '3': 1, '4': 1, '5': 9, '10': 'remoteDnsAddress'},
    const {'1': 'remote_dns_domain_strategy', '3': 2, '4': 1, '5': 14, '6': '.hiddifyoptions.DomainStrategy', '10': 'remoteDnsDomainStrategy'},
    const {'1': 'direct_dns_address', '3': 3, '4': 1, '5': 9, '10': 'directDnsAddress'},
    const {'1': 'direct_dns_domain_strategy', '3': 4, '4': 1, '5': 14, '6': '.hiddifyoptions.DomainStrategy', '10': 'directDnsDomainStrategy'},
    const {'1': 'independent_dns_cache', '3': 5, '4': 1, '5': 8, '10': 'independentDnsCache'},
    const {'1': 'enable_fake_dns', '3': 6, '4': 1, '5': 8, '10': 'enableFakeDns'},
    const {'1': 'enable_dns_routing', '3': 7, '4': 1, '5': 8, '10': 'enableDnsRouting'},
  ],
};

/// Descriptor for `DNSOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dNSOptionsDescriptor = $convert.base64Decode('CgpETlNPcHRpb25zEiwKEnJlbW90ZV9kbnNfYWRkcmVzcxgBIAEoCVIQcmVtb3RlRG5zQWRkcmVzcxJbChpyZW1vdGVfZG5zX2RvbWFpbl9zdHJhdGVneRgCIAEoDjIeLmhpZGRpZnlvcHRpb25zLkRvbWFpblN0cmF0ZWd5UhdyZW1vdGVEbnNEb21haW5TdHJhdGVneRIsChJkaXJlY3RfZG5zX2FkZHJlc3MYAyABKAlSEGRpcmVjdERuc0FkZHJlc3MSWwoaZGlyZWN0X2Ruc19kb21haW5fc3RyYXRlZ3kYBCABKA4yHi5oaWRkaWZ5b3B0aW9ucy5Eb21haW5TdHJhdGVneVIXZGlyZWN0RG5zRG9tYWluU3RyYXRlZ3kSMgoVaW5kZXBlbmRlbnRfZG5zX2NhY2hlGAUgASgIUhNpbmRlcGVuZGVudERuc0NhY2hlEiYKD2VuYWJsZV9mYWtlX2RucxgGIAEoCFINZW5hYmxlRmFrZURucxIsChJlbmFibGVfZG5zX3JvdXRpbmcYByABKAhSEGVuYWJsZURuc1JvdXRpbmc=');
@$core.Deprecated('Use inboundOptionsDescriptor instead')
const InboundOptions$json = const {
  '1': 'InboundOptions',
  '2': const [
    const {'1': 'enable_tun', '3': 1, '4': 1, '5': 8, '10': 'enableTun'},
    const {'1': 'enable_tun_service', '3': 2, '4': 1, '5': 8, '10': 'enableTunService'},
    const {'1': 'set_system_proxy', '3': 3, '4': 1, '5': 8, '10': 'setSystemProxy'},
    const {'1': 'mixed_port', '3': 4, '4': 1, '5': 13, '10': 'mixedPort'},
    const {'1': 'tproxy_port', '3': 5, '4': 1, '5': 13, '10': 'tproxyPort'},
    const {'1': 'redirect_port', '3': 10, '4': 1, '5': 13, '10': 'redirectPort'},
    const {'1': 'direct_port', '3': 6, '4': 1, '5': 13, '10': 'directPort'},
    const {'1': 'mtu', '3': 7, '4': 1, '5': 13, '10': 'mtu'},
    const {'1': 'strict_route', '3': 8, '4': 1, '5': 8, '10': 'strictRoute'},
    const {'1': 'tun_stack', '3': 9, '4': 1, '5': 9, '10': 'tunStack'},
  ],
};

/// Descriptor for `InboundOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inboundOptionsDescriptor = $convert.base64Decode('Cg5JbmJvdW5kT3B0aW9ucxIdCgplbmFibGVfdHVuGAEgASgIUgllbmFibGVUdW4SLAoSZW5hYmxlX3R1bl9zZXJ2aWNlGAIgASgIUhBlbmFibGVUdW5TZXJ2aWNlEigKEHNldF9zeXN0ZW1fcHJveHkYAyABKAhSDnNldFN5c3RlbVByb3h5Eh0KCm1peGVkX3BvcnQYBCABKA1SCW1peGVkUG9ydBIfCgt0cHJveHlfcG9ydBgFIAEoDVIKdHByb3h5UG9ydBIjCg1yZWRpcmVjdF9wb3J0GAogASgNUgxyZWRpcmVjdFBvcnQSHwoLZGlyZWN0X3BvcnQYBiABKA1SCmRpcmVjdFBvcnQSEAoDbXR1GAcgASgNUgNtdHUSIQoMc3RyaWN0X3JvdXRlGAggASgIUgtzdHJpY3RSb3V0ZRIbCgl0dW5fc3RhY2sYCSABKAlSCHR1blN0YWNr');
@$core.Deprecated('Use uRLTestOptionsDescriptor instead')
const URLTestOptions$json = const {
  '1': 'URLTestOptions',
  '2': const [
    const {'1': 'connection_test_url', '3': 1, '4': 1, '5': 9, '10': 'connectionTestUrl'},
    const {'1': 'url_test_interval', '3': 2, '4': 1, '5': 3, '10': 'urlTestInterval'},
  ],
};

/// Descriptor for `URLTestOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uRLTestOptionsDescriptor = $convert.base64Decode('Cg5VUkxUZXN0T3B0aW9ucxIuChNjb25uZWN0aW9uX3Rlc3RfdXJsGAEgASgJUhFjb25uZWN0aW9uVGVzdFVybBIqChF1cmxfdGVzdF9pbnRlcnZhbBgCIAEoA1IPdXJsVGVzdEludGVydmFs');
@$core.Deprecated('Use routeOptionsDescriptor instead')
const RouteOptions$json = const {
  '1': 'RouteOptions',
  '2': const [
    const {'1': 'resolve_destination', '3': 1, '4': 1, '5': 8, '10': 'resolveDestination'},
    const {'1': 'ipv6_mode', '3': 2, '4': 1, '5': 14, '6': '.hiddifyoptions.DomainStrategy', '10': 'ipv6Mode'},
    const {'1': 'bypass_lan', '3': 3, '4': 1, '5': 8, '10': 'bypassLan'},
    const {'1': 'allow_connection_from_lan', '3': 4, '4': 1, '5': 8, '10': 'allowConnectionFromLan'},
  ],
};

/// Descriptor for `RouteOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeOptionsDescriptor = $convert.base64Decode('CgxSb3V0ZU9wdGlvbnMSLwoTcmVzb2x2ZV9kZXN0aW5hdGlvbhgBIAEoCFIScmVzb2x2ZURlc3RpbmF0aW9uEjsKCWlwdjZfbW9kZRgCIAEoDjIeLmhpZGRpZnlvcHRpb25zLkRvbWFpblN0cmF0ZWd5UghpcHY2TW9kZRIdCgpieXBhc3NfbGFuGAMgASgIUglieXBhc3NMYW4SOQoZYWxsb3dfY29ubmVjdGlvbl9mcm9tX2xhbhgEIAEoCFIWYWxsb3dDb25uZWN0aW9uRnJvbUxhbg==');
@$core.Deprecated('Use tLSTricksDescriptor instead')
const TLSTricks$json = const {
  '1': 'TLSTricks',
  '2': const [
    const {'1': 'enable_fragment', '3': 1, '4': 1, '5': 8, '10': 'enableFragment'},
    const {'1': 'fragment_size', '3': 2, '4': 1, '5': 11, '6': '.hiddifyoptions.IntRange', '10': 'fragmentSize'},
    const {'1': 'fragment_sleep', '3': 3, '4': 1, '5': 11, '6': '.hiddifyoptions.IntRange', '10': 'fragmentSleep'},
    const {'1': 'mixed_sni_case', '3': 4, '4': 1, '5': 8, '10': 'mixedSniCase'},
    const {'1': 'enable_padding', '3': 5, '4': 1, '5': 8, '10': 'enablePadding'},
    const {'1': 'padding_size', '3': 6, '4': 1, '5': 11, '6': '.hiddifyoptions.IntRange', '10': 'paddingSize'},
  ],
};

/// Descriptor for `TLSTricks`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tLSTricksDescriptor = $convert.base64Decode('CglUTFNUcmlja3MSJwoPZW5hYmxlX2ZyYWdtZW50GAEgASgIUg5lbmFibGVGcmFnbWVudBI9Cg1mcmFnbWVudF9zaXplGAIgASgLMhguaGlkZGlmeW9wdGlvbnMuSW50UmFuZ2VSDGZyYWdtZW50U2l6ZRI/Cg5mcmFnbWVudF9zbGVlcBgDIAEoCzIYLmhpZGRpZnlvcHRpb25zLkludFJhbmdlUg1mcmFnbWVudFNsZWVwEiQKDm1peGVkX3NuaV9jYXNlGAQgASgIUgxtaXhlZFNuaUNhc2USJQoOZW5hYmxlX3BhZGRpbmcYBSABKAhSDWVuYWJsZVBhZGRpbmcSOwoMcGFkZGluZ19zaXplGAYgASgLMhguaGlkZGlmeW9wdGlvbnMuSW50UmFuZ2VSC3BhZGRpbmdTaXpl');
@$core.Deprecated('Use muxOptionsDescriptor instead')
const MuxOptions$json = const {
  '1': 'MuxOptions',
  '2': const [
    const {'1': 'enable', '3': 1, '4': 1, '5': 8, '10': 'enable'},
    const {'1': 'padding', '3': 2, '4': 1, '5': 8, '10': 'padding'},
    const {'1': 'max_streams', '3': 3, '4': 1, '5': 5, '10': 'maxStreams'},
    const {'1': 'protocol', '3': 4, '4': 1, '5': 9, '10': 'protocol'},
  ],
};

/// Descriptor for `MuxOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List muxOptionsDescriptor = $convert.base64Decode('CgpNdXhPcHRpb25zEhYKBmVuYWJsZRgBIAEoCFIGZW5hYmxlEhgKB3BhZGRpbmcYAiABKAhSB3BhZGRpbmcSHwoLbWF4X3N0cmVhbXMYAyABKAVSCm1heFN0cmVhbXMSGgoIcHJvdG9jb2wYBCABKAlSCHByb3RvY29s');
@$core.Deprecated('Use warpOptionsDescriptor instead')
const WarpOptions$json = const {
  '1': 'WarpOptions',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'enable_warp', '3': 2, '4': 1, '5': 8, '10': 'enableWarp'},
    const {'1': 'mode', '3': 3, '4': 1, '5': 9, '10': 'mode'},
    const {'1': 'wireguard_config', '3': 5, '4': 1, '5': 11, '6': '.hiddifyoptions.WarpWireguardConfig', '10': 'wireguardConfig'},
    const {'1': 'fake_packets', '3': 6, '4': 1, '5': 9, '10': 'fakePackets'},
    const {'1': 'fake_packet_size', '3': 7, '4': 1, '5': 11, '6': '.hiddifyoptions.IntRange', '10': 'fakePacketSize'},
    const {'1': 'fake_packet_delay', '3': 8, '4': 1, '5': 11, '6': '.hiddifyoptions.IntRange', '10': 'fakePacketDelay'},
    const {'1': 'fake_packet_mode', '3': 9, '4': 1, '5': 9, '10': 'fakePacketMode'},
    const {'1': 'clean_ip', '3': 10, '4': 1, '5': 9, '10': 'cleanIp'},
    const {'1': 'clean_port', '3': 11, '4': 1, '5': 13, '10': 'cleanPort'},
    const {'1': 'account', '3': 12, '4': 1, '5': 11, '6': '.hiddifyoptions.WarpAccount', '10': 'account'},
  ],
};

/// Descriptor for `WarpOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpOptionsDescriptor = $convert.base64Decode('CgtXYXJwT3B0aW9ucxIOCgJpZBgBIAEoCVICaWQSHwoLZW5hYmxlX3dhcnAYAiABKAhSCmVuYWJsZVdhcnASEgoEbW9kZRgDIAEoCVIEbW9kZRJOChB3aXJlZ3VhcmRfY29uZmlnGAUgASgLMiMuaGlkZGlmeW9wdGlvbnMuV2FycFdpcmVndWFyZENvbmZpZ1IPd2lyZWd1YXJkQ29uZmlnEiEKDGZha2VfcGFja2V0cxgGIAEoCVILZmFrZVBhY2tldHMSQgoQZmFrZV9wYWNrZXRfc2l6ZRgHIAEoCzIYLmhpZGRpZnlvcHRpb25zLkludFJhbmdlUg5mYWtlUGFja2V0U2l6ZRJEChFmYWtlX3BhY2tldF9kZWxheRgIIAEoCzIYLmhpZGRpZnlvcHRpb25zLkludFJhbmdlUg9mYWtlUGFja2V0RGVsYXkSKAoQZmFrZV9wYWNrZXRfbW9kZRgJIAEoCVIOZmFrZVBhY2tldE1vZGUSGQoIY2xlYW5faXAYCiABKAlSB2NsZWFuSXASHQoKY2xlYW5fcG9ydBgLIAEoDVIJY2xlYW5Qb3J0EjUKB2FjY291bnQYDCABKAsyGy5oaWRkaWZ5b3B0aW9ucy5XYXJwQWNjb3VudFIHYWNjb3VudA==');
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
    const {'1': 'private_key', '3': 1, '4': 1, '5': 9, '10': 'privateKey'},
    const {'1': 'local_address_ipv4', '3': 2, '4': 1, '5': 9, '10': 'localAddressIpv4'},
    const {'1': 'local_address_ipv6', '3': 3, '4': 1, '5': 9, '10': 'localAddressIpv6'},
    const {'1': 'peer_public_key', '3': 4, '4': 1, '5': 9, '10': 'peerPublicKey'},
    const {'1': 'client_id', '3': 5, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `WarpWireguardConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warpWireguardConfigDescriptor = $convert.base64Decode('ChNXYXJwV2lyZWd1YXJkQ29uZmlnEh8KC3ByaXZhdGVfa2V5GAEgASgJUgpwcml2YXRlS2V5EiwKEmxvY2FsX2FkZHJlc3NfaXB2NBgCIAEoCVIQbG9jYWxBZGRyZXNzSXB2NBIsChJsb2NhbF9hZGRyZXNzX2lwdjYYAyABKAlSEGxvY2FsQWRkcmVzc0lwdjYSJgoPcGVlcl9wdWJsaWNfa2V5GAQgASgJUg1wZWVyUHVibGljS2V5EhsKCWNsaWVudF9pZBgFIAEoCVIIY2xpZW50SWQ=');
@$core.Deprecated('Use ruleDescriptor instead')
const Rule$json = const {
  '1': 'Rule',
  '2': const [
    const {'1': 'rule_set_url', '3': 1, '4': 1, '5': 9, '10': 'ruleSetUrl'},
    const {'1': 'domains', '3': 2, '4': 1, '5': 9, '10': 'domains'},
    const {'1': 'ip', '3': 3, '4': 1, '5': 9, '10': 'ip'},
    const {'1': 'port', '3': 4, '4': 1, '5': 9, '10': 'port'},
    const {'1': 'network', '3': 5, '4': 1, '5': 9, '10': 'network'},
    const {'1': 'protocol', '3': 6, '4': 1, '5': 9, '10': 'protocol'},
    const {'1': 'outbound', '3': 7, '4': 1, '5': 9, '10': 'outbound'},
  ],
};

/// Descriptor for `Rule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ruleDescriptor = $convert.base64Decode('CgRSdWxlEiAKDHJ1bGVfc2V0X3VybBgBIAEoCVIKcnVsZVNldFVybBIYCgdkb21haW5zGAIgASgJUgdkb21haW5zEg4KAmlwGAMgASgJUgJpcBISCgRwb3J0GAQgASgJUgRwb3J0EhgKB25ldHdvcmsYBSABKAlSB25ldHdvcmsSGgoIcHJvdG9jb2wYBiABKAlSCHByb3RvY29sEhoKCG91dGJvdW5kGAcgASgJUghvdXRib3VuZA==');
