///
//  Generated code. Do not modify.
//  source: v2/profile/profile_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'profile.pb.dart' as $4;

import '../hcommon/common.pbenum.dart' as $1;

class ProfileRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ProfileRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'profile'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'url')
    ..hasRequiredFields = false
  ;

  ProfileRequest._() : super();
  factory ProfileRequest({
    $core.String? id,
    $core.String? name,
    $core.String? url,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (url != null) {
      _result.url = url;
    }
    return _result;
  }
  factory ProfileRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProfileRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProfileRequest clone() => ProfileRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProfileRequest copyWith(void Function(ProfileRequest) updates) => super.copyWith((message) => updates(message as ProfileRequest)) as ProfileRequest; // ignore: deprecated_member_use
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

class AddProfileRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AddProfileRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'profile'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'url')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'content')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'markAsActive')
    ..hasRequiredFields = false
  ;

  AddProfileRequest._() : super();
  factory AddProfileRequest({
    $core.String? url,
    $core.String? content,
    $core.String? name,
    $core.bool? markAsActive,
  }) {
    final _result = create();
    if (url != null) {
      _result.url = url;
    }
    if (content != null) {
      _result.content = content;
    }
    if (name != null) {
      _result.name = name;
    }
    if (markAsActive != null) {
      _result.markAsActive = markAsActive;
    }
    return _result;
  }
  factory AddProfileRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddProfileRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddProfileRequest clone() => AddProfileRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddProfileRequest copyWith(void Function(AddProfileRequest) updates) => super.copyWith((message) => updates(message as AddProfileRequest)) as AddProfileRequest; // ignore: deprecated_member_use
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

class ProfileResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ProfileResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'profile'), createEmptyInstance: create)
    ..aOM<$4.ProfileEntity>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'profile', subBuilder: $4.ProfileEntity.create)
    ..e<$1.ResponseCode>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'responseCode', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..hasRequiredFields = false
  ;

  ProfileResponse._() : super();
  factory ProfileResponse({
    $4.ProfileEntity? profile,
    $1.ResponseCode? responseCode,
    $core.String? message,
  }) {
    final _result = create();
    if (profile != null) {
      _result.profile = profile;
    }
    if (responseCode != null) {
      _result.responseCode = responseCode;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory ProfileResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProfileResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProfileResponse clone() => ProfileResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProfileResponse copyWith(void Function(ProfileResponse) updates) => super.copyWith((message) => updates(message as ProfileResponse)) as ProfileResponse; // ignore: deprecated_member_use
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

class MultiProfilesResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MultiProfilesResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'profile'), createEmptyInstance: create)
    ..pc<$4.ProfileEntity>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'profiles', $pb.PbFieldType.PM, subBuilder: $4.ProfileEntity.create)
    ..e<$1.ResponseCode>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'responseCode', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..hasRequiredFields = false
  ;

  MultiProfilesResponse._() : super();
  factory MultiProfilesResponse({
    $core.Iterable<$4.ProfileEntity>? profiles,
    $1.ResponseCode? responseCode,
    $core.String? message,
  }) {
    final _result = create();
    if (profiles != null) {
      _result.profiles.addAll(profiles);
    }
    if (responseCode != null) {
      _result.responseCode = responseCode;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory MultiProfilesResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MultiProfilesResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MultiProfilesResponse clone() => MultiProfilesResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MultiProfilesResponse copyWith(void Function(MultiProfilesResponse) updates) => super.copyWith((message) => updates(message as MultiProfilesResponse)) as MultiProfilesResponse; // ignore: deprecated_member_use
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

