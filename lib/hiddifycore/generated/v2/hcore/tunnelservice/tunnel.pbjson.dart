///
//  Generated code. Do not modify.
//  source: v2/hcore/tunnelservice/tunnel.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use tunnelStartRequestDescriptor instead')
const TunnelStartRequest$json = const {
  '1': 'TunnelStartRequest',
  '2': const [
    const {'1': 'ipv6', '3': 1, '4': 1, '5': 8, '10': 'ipv6'},
    const {'1': 'server_port', '3': 2, '4': 1, '5': 5, '10': 'serverPort'},
    const {'1': 'server_username', '3': 3, '4': 1, '5': 9, '10': 'serverUsername'},
    const {'1': 'server_password', '3': 4, '4': 1, '5': 9, '10': 'serverPassword'},
    const {'1': 'strict_route', '3': 5, '4': 1, '5': 8, '10': 'strictRoute'},
    const {'1': 'endpoint_independent_nat', '3': 6, '4': 1, '5': 8, '10': 'endpointIndependentNat'},
    const {'1': 'stack', '3': 7, '4': 1, '5': 9, '10': 'stack'},
  ],
};

/// Descriptor for `TunnelStartRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tunnelStartRequestDescriptor = $convert.base64Decode('ChJUdW5uZWxTdGFydFJlcXVlc3QSEgoEaXB2NhgBIAEoCFIEaXB2NhIfCgtzZXJ2ZXJfcG9ydBgCIAEoBVIKc2VydmVyUG9ydBInCg9zZXJ2ZXJfdXNlcm5hbWUYAyABKAlSDnNlcnZlclVzZXJuYW1lEicKD3NlcnZlcl9wYXNzd29yZBgEIAEoCVIOc2VydmVyUGFzc3dvcmQSIQoMc3RyaWN0X3JvdXRlGAUgASgIUgtzdHJpY3RSb3V0ZRI4ChhlbmRwb2ludF9pbmRlcGVuZGVudF9uYXQYBiABKAhSFmVuZHBvaW50SW5kZXBlbmRlbnROYXQSFAoFc3RhY2sYByABKAlSBXN0YWNr');
@$core.Deprecated('Use tunnelResponseDescriptor instead')
const TunnelResponse$json = const {
  '1': 'TunnelResponse',
  '2': const [
    const {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `TunnelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tunnelResponseDescriptor = $convert.base64Decode('Cg5UdW5uZWxSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl');
