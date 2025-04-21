///
//  Generated code. Do not modify.
//  source: v2/hcore/tunnelservice/tunnel.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class TunnelStartRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TunnelStartRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'tunnelservice'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ipv6')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverPort', $pb.PbFieldType.O3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverUsername')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverPassword')
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'strictRoute')
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'endpointIndependentNat')
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'stack')
    ..hasRequiredFields = false
  ;

  TunnelStartRequest._() : super();
  factory TunnelStartRequest({
    $core.bool? ipv6,
    $core.int? serverPort,
    $core.String? serverUsername,
    $core.String? serverPassword,
    $core.bool? strictRoute,
    $core.bool? endpointIndependentNat,
    $core.String? stack,
  }) {
    final _result = create();
    if (ipv6 != null) {
      _result.ipv6 = ipv6;
    }
    if (serverPort != null) {
      _result.serverPort = serverPort;
    }
    if (serverUsername != null) {
      _result.serverUsername = serverUsername;
    }
    if (serverPassword != null) {
      _result.serverPassword = serverPassword;
    }
    if (strictRoute != null) {
      _result.strictRoute = strictRoute;
    }
    if (endpointIndependentNat != null) {
      _result.endpointIndependentNat = endpointIndependentNat;
    }
    if (stack != null) {
      _result.stack = stack;
    }
    return _result;
  }
  factory TunnelStartRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TunnelStartRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TunnelStartRequest clone() => TunnelStartRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TunnelStartRequest copyWith(void Function(TunnelStartRequest) updates) => super.copyWith((message) => updates(message as TunnelStartRequest)) as TunnelStartRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TunnelStartRequest create() => TunnelStartRequest._();
  TunnelStartRequest createEmptyInstance() => create();
  static $pb.PbList<TunnelStartRequest> createRepeated() => $pb.PbList<TunnelStartRequest>();
  @$core.pragma('dart2js:noInline')
  static TunnelStartRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TunnelStartRequest>(create);
  static TunnelStartRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ipv6 => $_getBF(0);
  @$pb.TagNumber(1)
  set ipv6($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIpv6() => $_has(0);
  @$pb.TagNumber(1)
  void clearIpv6() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get serverPort => $_getIZ(1);
  @$pb.TagNumber(2)
  set serverPort($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasServerPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerPort() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverUsername => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverUsername($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasServerUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerUsername() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get serverPassword => $_getSZ(3);
  @$pb.TagNumber(4)
  set serverPassword($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasServerPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearServerPassword() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get strictRoute => $_getBF(4);
  @$pb.TagNumber(5)
  set strictRoute($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasStrictRoute() => $_has(4);
  @$pb.TagNumber(5)
  void clearStrictRoute() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get endpointIndependentNat => $_getBF(5);
  @$pb.TagNumber(6)
  set endpointIndependentNat($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasEndpointIndependentNat() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndpointIndependentNat() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get stack => $_getSZ(6);
  @$pb.TagNumber(7)
  set stack($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasStack() => $_has(6);
  @$pb.TagNumber(7)
  void clearStack() => clearField(7);
}

class TunnelResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TunnelResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'tunnelservice'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..hasRequiredFields = false
  ;

  TunnelResponse._() : super();
  factory TunnelResponse({
    $core.String? message,
  }) {
    final _result = create();
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory TunnelResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TunnelResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TunnelResponse clone() => TunnelResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TunnelResponse copyWith(void Function(TunnelResponse) updates) => super.copyWith((message) => updates(message as TunnelResponse)) as TunnelResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TunnelResponse create() => TunnelResponse._();
  TunnelResponse createEmptyInstance() => create();
  static $pb.PbList<TunnelResponse> createRepeated() => $pb.PbList<TunnelResponse>();
  @$core.pragma('dart2js:noInline')
  static TunnelResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TunnelResponse>(create);
  static TunnelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);
}

