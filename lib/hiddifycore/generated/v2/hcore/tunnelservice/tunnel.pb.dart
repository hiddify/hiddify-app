// This is a generated file - do not edit.
//
// Generated from v2/hcore/tunnelservice/tunnel.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class TunnelStartRequest extends $pb.GeneratedMessage {
  factory TunnelStartRequest({
    $core.bool? ipv6,
    $core.int? serverPort,
    $core.String? serverUsername,
    $core.String? serverPassword,
    $core.bool? strictRoute,
    $core.bool? endpointIndependentNat,
    $core.String? stack,
  }) {
    final result = create();
    if (ipv6 != null) result.ipv6 = ipv6;
    if (serverPort != null) result.serverPort = serverPort;
    if (serverUsername != null) result.serverUsername = serverUsername;
    if (serverPassword != null) result.serverPassword = serverPassword;
    if (strictRoute != null) result.strictRoute = strictRoute;
    if (endpointIndependentNat != null)
      result.endpointIndependentNat = endpointIndependentNat;
    if (stack != null) result.stack = stack;
    return result;
  }

  TunnelStartRequest._();

  factory TunnelStartRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TunnelStartRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TunnelStartRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'tunnelservice'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ipv6')
    ..aI(2, _omitFieldNames ? '' : 'serverPort')
    ..aOS(3, _omitFieldNames ? '' : 'serverUsername')
    ..aOS(4, _omitFieldNames ? '' : 'serverPassword')
    ..aOB(5, _omitFieldNames ? '' : 'strictRoute')
    ..aOB(6, _omitFieldNames ? '' : 'endpointIndependentNat')
    ..aOS(7, _omitFieldNames ? '' : 'stack')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TunnelStartRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TunnelStartRequest copyWith(void Function(TunnelStartRequest) updates) =>
      super.copyWith((message) => updates(message as TunnelStartRequest))
          as TunnelStartRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TunnelStartRequest create() => TunnelStartRequest._();
  @$core.override
  TunnelStartRequest createEmptyInstance() => create();
  static $pb.PbList<TunnelStartRequest> createRepeated() =>
      $pb.PbList<TunnelStartRequest>();
  @$core.pragma('dart2js:noInline')
  static TunnelStartRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TunnelStartRequest>(create);
  static TunnelStartRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ipv6 => $_getBF(0);
  @$pb.TagNumber(1)
  set ipv6($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIpv6() => $_has(0);
  @$pb.TagNumber(1)
  void clearIpv6() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get serverPort => $_getIZ(1);
  @$pb.TagNumber(2)
  set serverPort($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerPort() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverUsername => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverUsername($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerUsername() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get serverPassword => $_getSZ(3);
  @$pb.TagNumber(4)
  set serverPassword($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasServerPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearServerPassword() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get strictRoute => $_getBF(4);
  @$pb.TagNumber(5)
  set strictRoute($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStrictRoute() => $_has(4);
  @$pb.TagNumber(5)
  void clearStrictRoute() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get endpointIndependentNat => $_getBF(5);
  @$pb.TagNumber(6)
  set endpointIndependentNat($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEndpointIndependentNat() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndpointIndependentNat() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get stack => $_getSZ(6);
  @$pb.TagNumber(7)
  set stack($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStack() => $_has(6);
  @$pb.TagNumber(7)
  void clearStack() => $_clearField(7);
}

class TunnelResponse extends $pb.GeneratedMessage {
  factory TunnelResponse({
    $core.String? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  TunnelResponse._();

  factory TunnelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TunnelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TunnelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'tunnelservice'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TunnelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TunnelResponse copyWith(void Function(TunnelResponse) updates) =>
      super.copyWith((message) => updates(message as TunnelResponse))
          as TunnelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TunnelResponse create() => TunnelResponse._();
  @$core.override
  TunnelResponse createEmptyInstance() => create();
  static $pb.PbList<TunnelResponse> createRepeated() =>
      $pb.PbList<TunnelResponse>();
  @$core.pragma('dart2js:noInline')
  static TunnelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TunnelResponse>(create);
  static TunnelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
