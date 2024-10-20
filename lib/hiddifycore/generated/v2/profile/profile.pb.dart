//
//  Generated code. Do not modify.
//  source: v2/profile/profile.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../hiddifyoptions/hiddify_options.pb.dart' as $8;

/// ProfileEntity defines a profile entity.
class ProfileEntity extends $pb.GeneratedMessage {
  factory ProfileEntity({
    $core.String? id,
    $core.String? name,
    $core.String? url,
    $fixnum.Int64? lastUpdate,
    ProfileOptions? options,
    SubscriptionInfo? subInfo,
    $8.HiddifyOptions? overrideHiddifyOptions,
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
    if (lastUpdate != null) {
      $result.lastUpdate = lastUpdate;
    }
    if (options != null) {
      $result.options = options;
    }
    if (subInfo != null) {
      $result.subInfo = subInfo;
    }
    if (overrideHiddifyOptions != null) {
      $result.overrideHiddifyOptions = overrideHiddifyOptions;
    }
    return $result;
  }
  ProfileEntity._() : super();
  factory ProfileEntity.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProfileEntity.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProfileEntity', package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'url')
    ..aInt64(5, _omitFieldNames ? '' : 'lastUpdate')
    ..aOM<ProfileOptions>(6, _omitFieldNames ? '' : 'options', subBuilder: ProfileOptions.create)
    ..aOM<SubscriptionInfo>(7, _omitFieldNames ? '' : 'subInfo', subBuilder: SubscriptionInfo.create)
    ..aOM<$8.HiddifyOptions>(8, _omitFieldNames ? '' : 'overrideHiddifyOptions', subBuilder: $8.HiddifyOptions.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProfileEntity clone() => ProfileEntity()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProfileEntity copyWith(void Function(ProfileEntity) updates) => super.copyWith((message) => updates(message as ProfileEntity)) as ProfileEntity;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileEntity create() => ProfileEntity._();
  ProfileEntity createEmptyInstance() => create();
  static $pb.PbList<ProfileEntity> createRepeated() => $pb.PbList<ProfileEntity>();
  @$core.pragma('dart2js:noInline')
  static ProfileEntity getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProfileEntity>(create);
  static ProfileEntity? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// bool active = 2; // Indicates if the profile is active.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(4)
  set url($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(4)
  void clearUrl() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastUpdate => $_getI64(3);
  @$pb.TagNumber(5)
  set lastUpdate($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasLastUpdate() => $_has(3);
  @$pb.TagNumber(5)
  void clearLastUpdate() => clearField(5);

  @$pb.TagNumber(6)
  ProfileOptions get options => $_getN(4);
  @$pb.TagNumber(6)
  set options(ProfileOptions v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasOptions() => $_has(4);
  @$pb.TagNumber(6)
  void clearOptions() => clearField(6);
  @$pb.TagNumber(6)
  ProfileOptions ensureOptions() => $_ensure(4);

  @$pb.TagNumber(7)
  SubscriptionInfo get subInfo => $_getN(5);
  @$pb.TagNumber(7)
  set subInfo(SubscriptionInfo v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasSubInfo() => $_has(5);
  @$pb.TagNumber(7)
  void clearSubInfo() => clearField(7);
  @$pb.TagNumber(7)
  SubscriptionInfo ensureSubInfo() => $_ensure(5);

  @$pb.TagNumber(8)
  $8.HiddifyOptions get overrideHiddifyOptions => $_getN(6);
  @$pb.TagNumber(8)
  set overrideHiddifyOptions($8.HiddifyOptions v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasOverrideHiddifyOptions() => $_has(6);
  @$pb.TagNumber(8)
  void clearOverrideHiddifyOptions() => clearField(8);
  @$pb.TagNumber(8)
  $8.HiddifyOptions ensureOverrideHiddifyOptions() => $_ensure(6);
}

/// ProfileOptions defines options for a profile.
class ProfileOptions extends $pb.GeneratedMessage {
  factory ProfileOptions({
    $fixnum.Int64? updateInterval,
  }) {
    final $result = create();
    if (updateInterval != null) {
      $result.updateInterval = updateInterval;
    }
    return $result;
  }
  ProfileOptions._() : super();
  factory ProfileOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProfileOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProfileOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'updateInterval')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProfileOptions clone() => ProfileOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProfileOptions copyWith(void Function(ProfileOptions) updates) => super.copyWith((message) => updates(message as ProfileOptions)) as ProfileOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileOptions create() => ProfileOptions._();
  ProfileOptions createEmptyInstance() => create();
  static $pb.PbList<ProfileOptions> createRepeated() => $pb.PbList<ProfileOptions>();
  @$core.pragma('dart2js:noInline')
  static ProfileOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProfileOptions>(create);
  static ProfileOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get updateInterval => $_getI64(0);
  @$pb.TagNumber(1)
  set updateInterval($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUpdateInterval() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdateInterval() => clearField(1);
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
    final $result = create();
    if (upload != null) {
      $result.upload = upload;
    }
    if (download != null) {
      $result.download = download;
    }
    if (total != null) {
      $result.total = total;
    }
    if (expire != null) {
      $result.expire = expire;
    }
    if (webPageUrl != null) {
      $result.webPageUrl = webPageUrl;
    }
    if (supportUrl != null) {
      $result.supportUrl = supportUrl;
    }
    return $result;
  }
  SubscriptionInfo._() : super();
  factory SubscriptionInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SubscriptionInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SubscriptionInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'profile'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'upload')
    ..aInt64(2, _omitFieldNames ? '' : 'download')
    ..aInt64(3, _omitFieldNames ? '' : 'total')
    ..aInt64(4, _omitFieldNames ? '' : 'expire')
    ..aOS(5, _omitFieldNames ? '' : 'webPageUrl')
    ..aOS(6, _omitFieldNames ? '' : 'supportUrl')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SubscriptionInfo clone() => SubscriptionInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SubscriptionInfo copyWith(void Function(SubscriptionInfo) updates) => super.copyWith((message) => updates(message as SubscriptionInfo)) as SubscriptionInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionInfo create() => SubscriptionInfo._();
  SubscriptionInfo createEmptyInstance() => create();
  static $pb.PbList<SubscriptionInfo> createRepeated() => $pb.PbList<SubscriptionInfo>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscriptionInfo>(create);
  static SubscriptionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get upload => $_getI64(0);
  @$pb.TagNumber(1)
  set upload($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUpload() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpload() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get download => $_getI64(1);
  @$pb.TagNumber(2)
  set download($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDownload() => $_has(1);
  @$pb.TagNumber(2)
  void clearDownload() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get total => $_getI64(2);
  @$pb.TagNumber(3)
  set total($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get expire => $_getI64(3);
  @$pb.TagNumber(4)
  set expire($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasExpire() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpire() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get webPageUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set webPageUrl($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasWebPageUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearWebPageUrl() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get supportUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set supportUrl($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSupportUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearSupportUrl() => clearField(6);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
