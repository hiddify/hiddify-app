//
//  Generated code. Do not modify.
//  source: v2/hcore/adminbgservice/admin_bg.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AdminBgStartRequest extends $pb.GeneratedMessage {
  factory AdminBgStartRequest({
    $core.bool? ipv6,
    $core.int? serverPort,
    $core.String? serverUsername,
    $core.String? serverPassword,
    $core.bool? strictRoute,
    $core.bool? endpointIndependentNat,
    $core.String? stack,
    $core.String? configContent,
    $core.String? configName,
    $core.String? settingsJson,
    $core.Map<$core.String, $core.List<$core.int>>? resources,
    $core.bool? disableMemoryLimit,
    $core.int? ownerPid,
  }) {
    final $result = create();
    if (ipv6 != null) {
      $result.ipv6 = ipv6;
    }
    if (serverPort != null) {
      $result.serverPort = serverPort;
    }
    if (serverUsername != null) {
      $result.serverUsername = serverUsername;
    }
    if (serverPassword != null) {
      $result.serverPassword = serverPassword;
    }
    if (strictRoute != null) {
      $result.strictRoute = strictRoute;
    }
    if (endpointIndependentNat != null) {
      $result.endpointIndependentNat = endpointIndependentNat;
    }
    if (stack != null) {
      $result.stack = stack;
    }
    if (configContent != null) {
      $result.configContent = configContent;
    }
    if (configName != null) {
      $result.configName = configName;
    }
    if (settingsJson != null) {
      $result.settingsJson = settingsJson;
    }
    if (resources != null) {
      $result.resources.addAll(resources);
    }
    if (disableMemoryLimit != null) {
      $result.disableMemoryLimit = disableMemoryLimit;
    }
    if (ownerPid != null) {
      $result.ownerPid = ownerPid;
    }
    return $result;
  }
  AdminBgStartRequest._() : super();
  factory AdminBgStartRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AdminBgStartRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AdminBgStartRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'adminbgservice'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ipv6')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'serverPort', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'serverUsername')
    ..aOS(4, _omitFieldNames ? '' : 'serverPassword')
    ..aOB(5, _omitFieldNames ? '' : 'strictRoute')
    ..aOB(6, _omitFieldNames ? '' : 'endpointIndependentNat')
    ..aOS(7, _omitFieldNames ? '' : 'stack')
    ..aOS(8, _omitFieldNames ? '' : 'configContent')
    ..aOS(9, _omitFieldNames ? '' : 'configName')
    ..aOS(10, _omitFieldNames ? '' : 'settingsJson')
    ..m<$core.String, $core.List<$core.int>>(11, _omitFieldNames ? '' : 'resources', entryClassName: 'AdminBgStartRequest.ResourcesEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OY, packageName: const $pb.PackageName('adminbgservice'))
    ..aOB(12, _omitFieldNames ? '' : 'disableMemoryLimit')
    ..a<$core.int>(13, _omitFieldNames ? '' : 'ownerPid', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AdminBgStartRequest clone() => AdminBgStartRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AdminBgStartRequest copyWith(void Function(AdminBgStartRequest) updates) => super.copyWith((message) => updates(message as AdminBgStartRequest)) as AdminBgStartRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdminBgStartRequest create() => AdminBgStartRequest._();
  AdminBgStartRequest createEmptyInstance() => create();
  static $pb.PbList<AdminBgStartRequest> createRepeated() => $pb.PbList<AdminBgStartRequest>();
  @$core.pragma('dart2js:noInline')
  static AdminBgStartRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AdminBgStartRequest>(create);
  static AdminBgStartRequest? _defaultInstance;

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

  /// Full-core start (macOS root daemon): config snapshot, settings, and local resources.
  @$pb.TagNumber(8)
  $core.String get configContent => $_getSZ(7);
  @$pb.TagNumber(8)
  set configContent($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasConfigContent() => $_has(7);
  @$pb.TagNumber(8)
  void clearConfigContent() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get configName => $_getSZ(8);
  @$pb.TagNumber(9)
  set configName($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasConfigName() => $_has(8);
  @$pb.TagNumber(9)
  void clearConfigName() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get settingsJson => $_getSZ(9);
  @$pb.TagNumber(10)
  set settingsJson($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasSettingsJson() => $_has(9);
  @$pb.TagNumber(10)
  void clearSettingsJson() => clearField(10);

  @$pb.TagNumber(11)
  $core.Map<$core.String, $core.List<$core.int>> get resources => $_getMap(10);

  @$pb.TagNumber(12)
  $core.bool get disableMemoryLimit => $_getBF(11);
  @$pb.TagNumber(12)
  set disableMemoryLimit($core.bool v) { $_setBool(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasDisableMemoryLimit() => $_has(11);
  @$pb.TagNumber(12)
  void clearDisableMemoryLimit() => clearField(12);

  /// When set, the daemon stops once this process is gone (app quit or crash).
  @$pb.TagNumber(13)
  $core.int get ownerPid => $_getIZ(12);
  @$pb.TagNumber(13)
  set ownerPid($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasOwnerPid() => $_has(12);
  @$pb.TagNumber(13)
  void clearOwnerPid() => clearField(13);
}

class AdminBgResponse extends $pb.GeneratedMessage {
  factory AdminBgResponse({
    $core.String? message,
  }) {
    final $result = create();
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  AdminBgResponse._() : super();
  factory AdminBgResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AdminBgResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AdminBgResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'adminbgservice'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AdminBgResponse clone() => AdminBgResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AdminBgResponse copyWith(void Function(AdminBgResponse) updates) => super.copyWith((message) => updates(message as AdminBgResponse)) as AdminBgResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdminBgResponse create() => AdminBgResponse._();
  AdminBgResponse createEmptyInstance() => create();
  static $pb.PbList<AdminBgResponse> createRepeated() => $pb.PbList<AdminBgResponse>();
  @$core.pragma('dart2js:noInline')
  static AdminBgResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AdminBgResponse>(create);
  static AdminBgResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
