//
//  Generated code. Do not modify.
//  source: v2/profile/profile_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../hcommon/common.pbenum.dart' as $1;
import 'profile.pb.dart' as $4;

/// *
///  ProfileRequest is the request message for fetching or identifying
///  a profile by ID, name, or URL.
class ProfileRequest extends $pb.GeneratedMessage {
  factory ProfileRequest({
    $core.String? id,
    $core.String? name,
    $core.String? url,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (url != null) {
      $result.url = url;
    }
    return $result;
  }
  ProfileRequest._() : super();
  factory ProfileRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProfileRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProfileRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProfileRequest clone() => ProfileRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProfileRequest copyWith(void Function(ProfileRequest) updates) => super.copyWith((message) => updates(message as ProfileRequest)) as ProfileRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileRequest create() => ProfileRequest._();
  ProfileRequest createEmptyInstance() => create();
  static $pb.PbList<ProfileRequest> createRepeated() => $pb.PbList<ProfileRequest>();
  @$core.pragma('dart2js:noInline')
  static ProfileRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProfileRequest>(create);
  static ProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => clearField(3);
}

/// *
///  AddProfileRequest is the request message for adding a profile
///  via URL or content.
class AddProfileRequest extends $pb.GeneratedMessage {
  factory AddProfileRequest({
    $core.String? url,
    $core.String? content,
    $core.String? name,
    $core.bool? markAsActive,
  }) {
    final $result = create();
    if (url != null) {
      $result.url = url;
    }
    if (content != null) {
      $result.content = content;
    }
    if (name != null) {
      $result.name = name;
    }
    if (markAsActive != null) {
      $result.markAsActive = markAsActive;
    }
    return $result;
  }
  AddProfileRequest._() : super();
  factory AddProfileRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddProfileRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddProfileRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOB(4, _omitFieldNames ? '' : 'markAsActive')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddProfileRequest clone() => AddProfileRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddProfileRequest copyWith(void Function(AddProfileRequest) updates) => super.copyWith((message) => updates(message as AddProfileRequest)) as AddProfileRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddProfileRequest create() => AddProfileRequest._();
  AddProfileRequest createEmptyInstance() => create();
  static $pb.PbList<AddProfileRequest> createRepeated() => $pb.PbList<AddProfileRequest>();
  @$core.pragma('dart2js:noInline')
  static AddProfileRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddProfileRequest>(create);
  static AddProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get markAsActive => $_getBF(3);
  @$pb.TagNumber(4)
  set markAsActive($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMarkAsActive() => $_has(3);
  @$pb.TagNumber(4)
  void clearMarkAsActive() => clearField(4);
}

/// *
///  ProfileResponse is the response message for profile service operations.
class ProfileResponse extends $pb.GeneratedMessage {
  factory ProfileResponse({
    $4.ProfileEntity? profile,
    $1.ResponseCode? responseCode,
    $core.String? message,
  }) {
    final $result = create();
    if (profile != null) {
      $result.profile = profile;
    }
    if (responseCode != null) {
      $result.responseCode = responseCode;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  ProfileResponse._() : super();
  factory ProfileResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProfileResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProfileResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'), createEmptyInstance: create)
    ..aOM<$4.ProfileEntity>(1, _omitFieldNames ? '' : 'profile', subBuilder: $4.ProfileEntity.create)
    ..e<$1.ResponseCode>(2, _omitFieldNames ? '' : 'responseCode', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProfileResponse clone() => ProfileResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProfileResponse copyWith(void Function(ProfileResponse) updates) => super.copyWith((message) => updates(message as ProfileResponse)) as ProfileResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileResponse create() => ProfileResponse._();
  ProfileResponse createEmptyInstance() => create();
  static $pb.PbList<ProfileResponse> createRepeated() => $pb.PbList<ProfileResponse>();
  @$core.pragma('dart2js:noInline')
  static ProfileResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProfileResponse>(create);
  static ProfileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $4.ProfileEntity get profile => $_getN(0);
  @$pb.TagNumber(1)
  set profile($4.ProfileEntity v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasProfile() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfile() => clearField(1);
  @$pb.TagNumber(1)
  $4.ProfileEntity ensureProfile() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ResponseCode get responseCode => $_getN(1);
  @$pb.TagNumber(2)
  set responseCode($1.ResponseCode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasResponseCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);
}

/// *
///  MultiProfilesResponse is the response message for fetching multi profiles.
class MultiProfilesResponse extends $pb.GeneratedMessage {
  factory MultiProfilesResponse({
    $core.Iterable<$4.ProfileEntity>? profiles,
    $1.ResponseCode? responseCode,
    $core.String? message,
  }) {
    final $result = create();
    if (profiles != null) {
      $result.profiles.addAll(profiles);
    }
    if (responseCode != null) {
      $result.responseCode = responseCode;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  MultiProfilesResponse._() : super();
  factory MultiProfilesResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MultiProfilesResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MultiProfilesResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'), createEmptyInstance: create)
    ..pc<$4.ProfileEntity>(1, _omitFieldNames ? '' : 'profiles', $pb.PbFieldType.PM, subBuilder: $4.ProfileEntity.create)
    ..e<$1.ResponseCode>(2, _omitFieldNames ? '' : 'responseCode', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MultiProfilesResponse clone() => MultiProfilesResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MultiProfilesResponse copyWith(void Function(MultiProfilesResponse) updates) => super.copyWith((message) => updates(message as MultiProfilesResponse)) as MultiProfilesResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MultiProfilesResponse create() => MultiProfilesResponse._();
  MultiProfilesResponse createEmptyInstance() => create();
  static $pb.PbList<MultiProfilesResponse> createRepeated() => $pb.PbList<MultiProfilesResponse>();
  @$core.pragma('dart2js:noInline')
  static MultiProfilesResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MultiProfilesResponse>(create);
  static MultiProfilesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$4.ProfileEntity> get profiles => $_getList(0);

  @$pb.TagNumber(2)
  $1.ResponseCode get responseCode => $_getN(1);
  @$pb.TagNumber(2)
  set responseCode($1.ResponseCode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasResponseCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
