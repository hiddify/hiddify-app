// This is a generated file - do not edit.
//
// Generated from v2/profile/profile_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../hcommon/common.pbenum.dart' as $2;
import 'profile.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// *
///  ProfileRequest is the request message for fetching or identifying
///  a profile by ID, name, or URL.
class ProfileRequest extends $pb.GeneratedMessage {
  factory ProfileRequest({
    $core.String? id,
    $core.String? name,
    $core.String? url,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (url != null) result.url = url;
    return result;
  }

  ProfileRequest._();

  factory ProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileRequest copyWith(void Function(ProfileRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileRequest))
          as ProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileRequest create() => ProfileRequest._();
  @$core.override
  ProfileRequest createEmptyInstance() => create();
  static $pb.PbList<ProfileRequest> createRepeated() =>
      $pb.PbList<ProfileRequest>();
  @$core.pragma('dart2js:noInline')
  static ProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileRequest>(create);
  static ProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => $_clearField(3);
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
    final result = create();
    if (url != null) result.url = url;
    if (content != null) result.content = content;
    if (name != null) result.name = name;
    if (markAsActive != null) result.markAsActive = markAsActive;
    return result;
  }

  AddProfileRequest._();

  factory AddProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddProfileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOB(4, _omitFieldNames ? '' : 'markAsActive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddProfileRequest copyWith(void Function(AddProfileRequest) updates) =>
      super.copyWith((message) => updates(message as AddProfileRequest))
          as AddProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddProfileRequest create() => AddProfileRequest._();
  @$core.override
  AddProfileRequest createEmptyInstance() => create();
  static $pb.PbList<AddProfileRequest> createRepeated() =>
      $pb.PbList<AddProfileRequest>();
  @$core.pragma('dart2js:noInline')
  static AddProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddProfileRequest>(create);
  static AddProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get markAsActive => $_getBF(3);
  @$pb.TagNumber(4)
  set markAsActive($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMarkAsActive() => $_has(3);
  @$pb.TagNumber(4)
  void clearMarkAsActive() => $_clearField(4);
}

/// *
///  ProfileResponse is the response message for profile service operations.
class ProfileResponse extends $pb.GeneratedMessage {
  factory ProfileResponse({
    $1.ProfileEntity? profile,
    $2.ResponseCode? responseCode,
    $core.String? message,
  }) {
    final result = create();
    if (profile != null) result.profile = profile;
    if (responseCode != null) result.responseCode = responseCode;
    if (message != null) result.message = message;
    return result;
  }

  ProfileResponse._();

  factory ProfileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'),
      createEmptyInstance: create)
    ..aOM<$1.ProfileEntity>(1, _omitFieldNames ? '' : 'profile',
        subBuilder: $1.ProfileEntity.create)
    ..aE<$2.ResponseCode>(2, _omitFieldNames ? '' : 'responseCode',
        enumValues: $2.ResponseCode.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileResponse copyWith(void Function(ProfileResponse) updates) =>
      super.copyWith((message) => updates(message as ProfileResponse))
          as ProfileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileResponse create() => ProfileResponse._();
  @$core.override
  ProfileResponse createEmptyInstance() => create();
  static $pb.PbList<ProfileResponse> createRepeated() =>
      $pb.PbList<ProfileResponse>();
  @$core.pragma('dart2js:noInline')
  static ProfileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileResponse>(create);
  static ProfileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ProfileEntity get profile => $_getN(0);
  @$pb.TagNumber(1)
  set profile($1.ProfileEntity value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProfile() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfile() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ProfileEntity ensureProfile() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.ResponseCode get responseCode => $_getN(1);
  @$pb.TagNumber(2)
  set responseCode($2.ResponseCode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResponseCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

/// *
///  MultiProfilesResponse is the response message for fetching multi profiles.
class MultiProfilesResponse extends $pb.GeneratedMessage {
  factory MultiProfilesResponse({
    $core.Iterable<$1.ProfileEntity>? profiles,
    $2.ResponseCode? responseCode,
    $core.String? message,
  }) {
    final result = create();
    if (profiles != null) result.profiles.addAll(profiles);
    if (responseCode != null) result.responseCode = responseCode;
    if (message != null) result.message = message;
    return result;
  }

  MultiProfilesResponse._();

  factory MultiProfilesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MultiProfilesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MultiProfilesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'),
      createEmptyInstance: create)
    ..pPM<$1.ProfileEntity>(1, _omitFieldNames ? '' : 'profiles',
        subBuilder: $1.ProfileEntity.create)
    ..aE<$2.ResponseCode>(2, _omitFieldNames ? '' : 'responseCode',
        enumValues: $2.ResponseCode.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MultiProfilesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MultiProfilesResponse copyWith(
          void Function(MultiProfilesResponse) updates) =>
      super.copyWith((message) => updates(message as MultiProfilesResponse))
          as MultiProfilesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MultiProfilesResponse create() => MultiProfilesResponse._();
  @$core.override
  MultiProfilesResponse createEmptyInstance() => create();
  static $pb.PbList<MultiProfilesResponse> createRepeated() =>
      $pb.PbList<MultiProfilesResponse>();
  @$core.pragma('dart2js:noInline')
  static MultiProfilesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MultiProfilesResponse>(create);
  static MultiProfilesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.ProfileEntity> get profiles => $_getList(0);

  @$pb.TagNumber(2)
  $2.ResponseCode get responseCode => $_getN(1);
  @$pb.TagNumber(2)
  set responseCode($2.ResponseCode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResponseCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
