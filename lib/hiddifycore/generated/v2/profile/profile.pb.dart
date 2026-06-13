// This is a generated file - do not edit.
//
// Generated from v2/profile/profile.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../hiddifyoptions/hiddify_options.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// ProfileEntity defines a profile entity.
class ProfileEntity extends $pb.GeneratedMessage {
  factory ProfileEntity({
    $core.String? id,
    $core.String? name,
    $core.String? url,
    $fixnum.Int64? lastUpdate,
    ProfileOptions? options,
    SubscriptionInfo? subInfo,
    $0.HiddifyOptions? overrideHiddifyOptions,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (url != null) result.url = url;
    if (lastUpdate != null) result.lastUpdate = lastUpdate;
    if (options != null) result.options = options;
    if (subInfo != null) result.subInfo = subInfo;
    if (overrideHiddifyOptions != null)
      result.overrideHiddifyOptions = overrideHiddifyOptions;
    return result;
  }

  ProfileEntity._();

  factory ProfileEntity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileEntity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileEntity',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'url')
    ..aInt64(5, _omitFieldNames ? '' : 'lastUpdate')
    ..aOM<ProfileOptions>(6, _omitFieldNames ? '' : 'options',
        subBuilder: ProfileOptions.create)
    ..aOM<SubscriptionInfo>(7, _omitFieldNames ? '' : 'subInfo',
        subBuilder: SubscriptionInfo.create)
    ..aOM<$0.HiddifyOptions>(8, _omitFieldNames ? '' : 'overrideHiddifyOptions',
        subBuilder: $0.HiddifyOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileEntity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileEntity copyWith(void Function(ProfileEntity) updates) =>
      super.copyWith((message) => updates(message as ProfileEntity))
          as ProfileEntity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileEntity create() => ProfileEntity._();
  @$core.override
  ProfileEntity createEmptyInstance() => create();
  static $pb.PbList<ProfileEntity> createRepeated() =>
      $pb.PbList<ProfileEntity>();
  @$core.pragma('dart2js:noInline')
  static ProfileEntity getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileEntity>(create);
  static ProfileEntity? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// bool active = 2; // Indicates if the profile is active.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(4)
  set url($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(4)
  void clearUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastUpdate => $_getI64(3);
  @$pb.TagNumber(5)
  set lastUpdate($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(5)
  $core.bool hasLastUpdate() => $_has(3);
  @$pb.TagNumber(5)
  void clearLastUpdate() => $_clearField(5);

  @$pb.TagNumber(6)
  ProfileOptions get options => $_getN(4);
  @$pb.TagNumber(6)
  set options(ProfileOptions value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOptions() => $_has(4);
  @$pb.TagNumber(6)
  void clearOptions() => $_clearField(6);
  @$pb.TagNumber(6)
  ProfileOptions ensureOptions() => $_ensure(4);

  @$pb.TagNumber(7)
  SubscriptionInfo get subInfo => $_getN(5);
  @$pb.TagNumber(7)
  set subInfo(SubscriptionInfo value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSubInfo() => $_has(5);
  @$pb.TagNumber(7)
  void clearSubInfo() => $_clearField(7);
  @$pb.TagNumber(7)
  SubscriptionInfo ensureSubInfo() => $_ensure(5);

  @$pb.TagNumber(8)
  $0.HiddifyOptions get overrideHiddifyOptions => $_getN(6);
  @$pb.TagNumber(8)
  set overrideHiddifyOptions($0.HiddifyOptions value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasOverrideHiddifyOptions() => $_has(6);
  @$pb.TagNumber(8)
  void clearOverrideHiddifyOptions() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.HiddifyOptions ensureOverrideHiddifyOptions() => $_ensure(6);
}

/// ProfileOptions defines options for a profile.
class ProfileOptions extends $pb.GeneratedMessage {
  factory ProfileOptions({
    $fixnum.Int64? updateInterval,
  }) {
    final result = create();
    if (updateInterval != null) result.updateInterval = updateInterval;
    return result;
  }

  ProfileOptions._();

  factory ProfileOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'updateInterval')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileOptions copyWith(void Function(ProfileOptions) updates) =>
      super.copyWith((message) => updates(message as ProfileOptions))
          as ProfileOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileOptions create() => ProfileOptions._();
  @$core.override
  ProfileOptions createEmptyInstance() => create();
  static $pb.PbList<ProfileOptions> createRepeated() =>
      $pb.PbList<ProfileOptions>();
  @$core.pragma('dart2js:noInline')
  static ProfileOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileOptions>(create);
  static ProfileOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get updateInterval => $_getI64(0);
  @$pb.TagNumber(1)
  set updateInterval($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUpdateInterval() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdateInterval() => $_clearField(1);
}

/// SubscriptionInfo defines subscription-related information.
class SubscriptionInfo extends $pb.GeneratedMessage {
  factory SubscriptionInfo({
    $fixnum.Int64? upload,
    $fixnum.Int64? download,
    $fixnum.Int64? total,
    $fixnum.Int64? expire,
    $core.String? webPageUrl,
    $core.String? supportUrl,
  }) {
    final result = create();
    if (upload != null) result.upload = upload;
    if (download != null) result.download = download;
    if (total != null) result.total = total;
    if (expire != null) result.expire = expire;
    if (webPageUrl != null) result.webPageUrl = webPageUrl;
    if (supportUrl != null) result.supportUrl = supportUrl;
    return result;
  }

  SubscriptionInfo._();

  factory SubscriptionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'upload')
    ..aInt64(2, _omitFieldNames ? '' : 'download')
    ..aInt64(3, _omitFieldNames ? '' : 'total')
    ..aInt64(4, _omitFieldNames ? '' : 'expire')
    ..aOS(5, _omitFieldNames ? '' : 'webPageUrl')
    ..aOS(6, _omitFieldNames ? '' : 'supportUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionInfo copyWith(void Function(SubscriptionInfo) updates) =>
      super.copyWith((message) => updates(message as SubscriptionInfo))
          as SubscriptionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionInfo create() => SubscriptionInfo._();
  @$core.override
  SubscriptionInfo createEmptyInstance() => create();
  static $pb.PbList<SubscriptionInfo> createRepeated() =>
      $pb.PbList<SubscriptionInfo>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionInfo>(create);
  static SubscriptionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get upload => $_getI64(0);
  @$pb.TagNumber(1)
  set upload($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUpload() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpload() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get download => $_getI64(1);
  @$pb.TagNumber(2)
  set download($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDownload() => $_has(1);
  @$pb.TagNumber(2)
  void clearDownload() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get total => $_getI64(2);
  @$pb.TagNumber(3)
  set total($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get expire => $_getI64(3);
  @$pb.TagNumber(4)
  set expire($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExpire() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpire() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get webPageUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set webPageUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWebPageUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearWebPageUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get supportUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set supportUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSupportUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearSupportUrl() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
