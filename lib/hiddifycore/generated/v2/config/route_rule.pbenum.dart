//
//  Generated code. Do not modify.
//  source: v2/config/route_rule.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Outbound extends $pb.ProtobufEnum {
  static const Outbound proxy = Outbound._(0, _omitEnumNames ? '' : 'proxy');
  static const Outbound direct = Outbound._(1, _omitEnumNames ? '' : 'direct');
  static const Outbound direct_with_fragment = Outbound._(2, _omitEnumNames ? '' : 'direct_with_fragment');
  static const Outbound block = Outbound._(3, _omitEnumNames ? '' : 'block');

  static const $core.List<Outbound> values = <Outbound> [
    proxy,
    direct,
    direct_with_fragment,
    block,
  ];

  static final $core.Map<$core.int, Outbound> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Outbound? valueOf($core.int value) => _byValue[value];

  const Outbound._($core.int v, $core.String n) : super(v, n);
}

class Network extends $pb.ProtobufEnum {
  static const Network all = Network._(0, _omitEnumNames ? '' : 'all');
  static const Network tcp = Network._(1, _omitEnumNames ? '' : 'tcp');
  static const Network udp = Network._(2, _omitEnumNames ? '' : 'udp');

  static const $core.List<Network> values = <Network> [
    all,
    tcp,
    udp,
  ];

  static final $core.Map<$core.int, Network> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Network? valueOf($core.int value) => _byValue[value];

  const Network._($core.int v, $core.String n) : super(v, n);
}

class Protocol extends $pb.ProtobufEnum {
  static const Protocol tls = Protocol._(0, _omitEnumNames ? '' : 'tls');
  static const Protocol http = Protocol._(1, _omitEnumNames ? '' : 'http');
  static const Protocol quic = Protocol._(2, _omitEnumNames ? '' : 'quic');
  static const Protocol stun = Protocol._(3, _omitEnumNames ? '' : 'stun');
  static const Protocol dns = Protocol._(4, _omitEnumNames ? '' : 'dns');
  static const Protocol bittorrent = Protocol._(5, _omitEnumNames ? '' : 'bittorrent');

  static const $core.List<Protocol> values = <Protocol> [
    tls,
    http,
    quic,
    stun,
    dns,
    bittorrent,
  ];

  static final $core.Map<$core.int, Protocol> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Protocol? valueOf($core.int value) => _byValue[value];

  const Protocol._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
