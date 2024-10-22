//
//  Generated code. Do not modify.
//  source: v2/hcore/hcore.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../google/protobuf/timestamp.pb.dart' as $7;
import '../hcommon/common.pbenum.dart' as $1;
import 'hcore.pbenum.dart';

export 'hcore.pbenum.dart';

class CoreInfoResponse extends $pb.GeneratedMessage {
  factory CoreInfoResponse({
    CoreStates? coreState,
    MessageType? messageType,
    $core.String? message,
  }) {
    final $result = create();
    if (coreState != null) {
      $result.coreState = coreState;
    }
    if (messageType != null) {
      $result.messageType = messageType;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  CoreInfoResponse._() : super();
  factory CoreInfoResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CoreInfoResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CoreInfoResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..e<CoreStates>(1, _omitFieldNames ? '' : 'coreState', $pb.PbFieldType.OE, defaultOrMaker: CoreStates.STOPPED, valueOf: CoreStates.valueOf, enumValues: CoreStates.values)
    ..e<MessageType>(2, _omitFieldNames ? '' : 'messageType', $pb.PbFieldType.OE, defaultOrMaker: MessageType.EMPTY, valueOf: MessageType.valueOf, enumValues: MessageType.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CoreInfoResponse clone() => CoreInfoResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CoreInfoResponse copyWith(void Function(CoreInfoResponse) updates) => super.copyWith((message) => updates(message as CoreInfoResponse)) as CoreInfoResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CoreInfoResponse create() => CoreInfoResponse._();
  CoreInfoResponse createEmptyInstance() => create();
  static $pb.PbList<CoreInfoResponse> createRepeated() => $pb.PbList<CoreInfoResponse>();
  @$core.pragma('dart2js:noInline')
  static CoreInfoResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CoreInfoResponse>(create);
  static CoreInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CoreStates get coreState => $_getN(0);
  @$pb.TagNumber(1)
  set coreState(CoreStates v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCoreState() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoreState() => clearField(1);

  @$pb.TagNumber(2)
  MessageType get messageType => $_getN(1);
  @$pb.TagNumber(2)
  set messageType(MessageType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessageType() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);
}

class StartRequest extends $pb.GeneratedMessage {
  factory StartRequest({
    $core.String? configPath,
    $core.String? configContent,
    $core.bool? disableMemoryLimit,
    $core.bool? delayStart,
    $core.bool? enableOldCommandServer,
    $core.bool? enableRawConfig,
  }) {
    final $result = create();
    if (configPath != null) {
      $result.configPath = configPath;
    }
    if (configContent != null) {
      $result.configContent = configContent;
    }
    if (disableMemoryLimit != null) {
      $result.disableMemoryLimit = disableMemoryLimit;
    }
    if (delayStart != null) {
      $result.delayStart = delayStart;
    }
    if (enableOldCommandServer != null) {
      $result.enableOldCommandServer = enableOldCommandServer;
    }
    if (enableRawConfig != null) {
      $result.enableRawConfig = enableRawConfig;
    }
    return $result;
  }
  StartRequest._() : super();
  factory StartRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StartRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'configPath')
    ..aOS(2, _omitFieldNames ? '' : 'configContent')
    ..aOB(3, _omitFieldNames ? '' : 'disableMemoryLimit')
    ..aOB(4, _omitFieldNames ? '' : 'delayStart')
    ..aOB(5, _omitFieldNames ? '' : 'enableOldCommandServer')
    ..aOB(6, _omitFieldNames ? '' : 'enableRawConfig')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StartRequest clone() => StartRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StartRequest copyWith(void Function(StartRequest) updates) => super.copyWith((message) => updates(message as StartRequest)) as StartRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartRequest create() => StartRequest._();
  StartRequest createEmptyInstance() => create();
  static $pb.PbList<StartRequest> createRepeated() => $pb.PbList<StartRequest>();
  @$core.pragma('dart2js:noInline')
  static StartRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartRequest>(create);
  static StartRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get configPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set configPath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConfigPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get configContent => $_getSZ(1);
  @$pb.TagNumber(2)
  set configContent($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasConfigContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfigContent() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get disableMemoryLimit => $_getBF(2);
  @$pb.TagNumber(3)
  set disableMemoryLimit($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDisableMemoryLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisableMemoryLimit() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get delayStart => $_getBF(3);
  @$pb.TagNumber(4)
  set delayStart($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDelayStart() => $_has(3);
  @$pb.TagNumber(4)
  void clearDelayStart() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enableOldCommandServer => $_getBF(4);
  @$pb.TagNumber(5)
  set enableOldCommandServer($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEnableOldCommandServer() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnableOldCommandServer() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enableRawConfig => $_getBF(5);
  @$pb.TagNumber(6)
  set enableRawConfig($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasEnableRawConfig() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnableRawConfig() => clearField(6);
}

class SetupRequest extends $pb.GeneratedMessage {
  factory SetupRequest({
    $core.String? basePath,
    $core.String? workingPath,
    $core.String? tempPath,
  }) {
    final $result = create();
    if (basePath != null) {
      $result.basePath = basePath;
    }
    if (workingPath != null) {
      $result.workingPath = workingPath;
    }
    if (tempPath != null) {
      $result.tempPath = tempPath;
    }
    return $result;
  }
  SetupRequest._() : super();
  factory SetupRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetupRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetupRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'basePath')
    ..aOS(2, _omitFieldNames ? '' : 'workingPath')
    ..aOS(3, _omitFieldNames ? '' : 'tempPath')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetupRequest clone() => SetupRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetupRequest copyWith(void Function(SetupRequest) updates) => super.copyWith((message) => updates(message as SetupRequest)) as SetupRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetupRequest create() => SetupRequest._();
  SetupRequest createEmptyInstance() => create();
  static $pb.PbList<SetupRequest> createRepeated() => $pb.PbList<SetupRequest>();
  @$core.pragma('dart2js:noInline')
  static SetupRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetupRequest>(create);
  static SetupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get basePath => $_getSZ(0);
  @$pb.TagNumber(1)
  set basePath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBasePath() => $_has(0);
  @$pb.TagNumber(1)
  void clearBasePath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get workingPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set workingPath($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWorkingPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkingPath() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get tempPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set tempPath($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTempPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearTempPath() => clearField(3);
}

class SystemInfo extends $pb.GeneratedMessage {
  factory SystemInfo({
    $fixnum.Int64? memory,
    $core.int? goroutines,
    $core.int? connectionsIn,
    $core.int? connectionsOut,
    $core.bool? trafficAvailable,
    $fixnum.Int64? uplink,
    $fixnum.Int64? downlink,
    $fixnum.Int64? uplinkTotal,
    $fixnum.Int64? downlinkTotal,
  }) {
    final $result = create();
    if (memory != null) {
      $result.memory = memory;
    }
    if (goroutines != null) {
      $result.goroutines = goroutines;
    }
    if (connectionsIn != null) {
      $result.connectionsIn = connectionsIn;
    }
    if (connectionsOut != null) {
      $result.connectionsOut = connectionsOut;
    }
    if (trafficAvailable != null) {
      $result.trafficAvailable = trafficAvailable;
    }
    if (uplink != null) {
      $result.uplink = uplink;
    }
    if (downlink != null) {
      $result.downlink = downlink;
    }
    if (uplinkTotal != null) {
      $result.uplinkTotal = uplinkTotal;
    }
    if (downlinkTotal != null) {
      $result.downlinkTotal = downlinkTotal;
    }
    return $result;
  }
  SystemInfo._() : super();
  factory SystemInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SystemInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SystemInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'memory')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'goroutines', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'connectionsIn', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'connectionsOut', $pb.PbFieldType.O3)
    ..aOB(5, _omitFieldNames ? '' : 'trafficAvailable')
    ..aInt64(6, _omitFieldNames ? '' : 'uplink')
    ..aInt64(7, _omitFieldNames ? '' : 'downlink')
    ..aInt64(8, _omitFieldNames ? '' : 'uplinkTotal')
    ..aInt64(9, _omitFieldNames ? '' : 'downlinkTotal')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SystemInfo clone() => SystemInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SystemInfo copyWith(void Function(SystemInfo) updates) => super.copyWith((message) => updates(message as SystemInfo)) as SystemInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SystemInfo create() => SystemInfo._();
  SystemInfo createEmptyInstance() => create();
  static $pb.PbList<SystemInfo> createRepeated() => $pb.PbList<SystemInfo>();
  @$core.pragma('dart2js:noInline')
  static SystemInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SystemInfo>(create);
  static SystemInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get memory => $_getI64(0);
  @$pb.TagNumber(1)
  set memory($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMemory() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemory() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get goroutines => $_getIZ(1);
  @$pb.TagNumber(2)
  set goroutines($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGoroutines() => $_has(1);
  @$pb.TagNumber(2)
  void clearGoroutines() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get connectionsIn => $_getIZ(2);
  @$pb.TagNumber(3)
  set connectionsIn($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasConnectionsIn() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnectionsIn() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get connectionsOut => $_getIZ(3);
  @$pb.TagNumber(4)
  set connectionsOut($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasConnectionsOut() => $_has(3);
  @$pb.TagNumber(4)
  void clearConnectionsOut() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get trafficAvailable => $_getBF(4);
  @$pb.TagNumber(5)
  set trafficAvailable($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTrafficAvailable() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrafficAvailable() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get uplink => $_getI64(5);
  @$pb.TagNumber(6)
  set uplink($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasUplink() => $_has(5);
  @$pb.TagNumber(6)
  void clearUplink() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get downlink => $_getI64(6);
  @$pb.TagNumber(7)
  set downlink($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasDownlink() => $_has(6);
  @$pb.TagNumber(7)
  void clearDownlink() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get uplinkTotal => $_getI64(7);
  @$pb.TagNumber(8)
  set uplinkTotal($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasUplinkTotal() => $_has(7);
  @$pb.TagNumber(8)
  void clearUplinkTotal() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get downlinkTotal => $_getI64(8);
  @$pb.TagNumber(9)
  set downlinkTotal($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasDownlinkTotal() => $_has(8);
  @$pb.TagNumber(9)
  void clearDownlinkTotal() => clearField(9);
}

class OutboundInfo extends $pb.GeneratedMessage {
  factory OutboundInfo({
    $core.String? tag,
    $core.String? type,
    $7.Timestamp? urlTestTime,
    $core.int? urlTestDelay,
    IpInfo? ipinfo,
    $core.bool? isSelected,
    $core.bool? isGroup,
    $core.bool? isSecure,
    $core.bool? isVisible,
    $core.int? port,
    $core.String? host,
    $core.String? tagDisplay,
  }) {
    final $result = create();
    if (tag != null) {
      $result.tag = tag;
    }
    if (type != null) {
      $result.type = type;
    }
    if (urlTestTime != null) {
      $result.urlTestTime = urlTestTime;
    }
    if (urlTestDelay != null) {
      $result.urlTestDelay = urlTestDelay;
    }
    if (ipinfo != null) {
      $result.ipinfo = ipinfo;
    }
    if (isSelected != null) {
      $result.isSelected = isSelected;
    }
    if (isGroup != null) {
      $result.isGroup = isGroup;
    }
    if (isSecure != null) {
      $result.isSecure = isSecure;
    }
    if (isVisible != null) {
      $result.isVisible = isVisible;
    }
    if (port != null) {
      $result.port = port;
    }
    if (host != null) {
      $result.host = host;
    }
    if (tagDisplay != null) {
      $result.tagDisplay = tagDisplay;
    }
    return $result;
  }
  OutboundInfo._() : super();
  factory OutboundInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OutboundInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOM<$7.Timestamp>(3, _omitFieldNames ? '' : 'urlTestTime', subBuilder: $7.Timestamp.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'urlTestDelay', $pb.PbFieldType.O3)
    ..aOM<IpInfo>(5, _omitFieldNames ? '' : 'ipinfo', subBuilder: IpInfo.create)
    ..aOB(6, _omitFieldNames ? '' : 'isSelected')
    ..aOB(7, _omitFieldNames ? '' : 'isGroup')
    ..aOB(8, _omitFieldNames ? '' : 'isSecure')
    ..aOB(9, _omitFieldNames ? '' : 'isVisible')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'port', $pb.PbFieldType.OU3)
    ..aOS(11, _omitFieldNames ? '' : 'host')
    ..aOS(12, _omitFieldNames ? '' : 'tagDisplay')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutboundInfo clone() => OutboundInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutboundInfo copyWith(void Function(OutboundInfo) updates) => super.copyWith((message) => updates(message as OutboundInfo)) as OutboundInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutboundInfo create() => OutboundInfo._();
  OutboundInfo createEmptyInstance() => create();
  static $pb.PbList<OutboundInfo> createRepeated() => $pb.PbList<OutboundInfo>();
  @$core.pragma('dart2js:noInline')
  static OutboundInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OutboundInfo>(create);
  static OutboundInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tag => $_getSZ(0);
  @$pb.TagNumber(1)
  set tag($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $7.Timestamp get urlTestTime => $_getN(2);
  @$pb.TagNumber(3)
  set urlTestTime($7.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasUrlTestTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrlTestTime() => clearField(3);
  @$pb.TagNumber(3)
  $7.Timestamp ensureUrlTestTime() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.int get urlTestDelay => $_getIZ(3);
  @$pb.TagNumber(4)
  set urlTestDelay($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUrlTestDelay() => $_has(3);
  @$pb.TagNumber(4)
  void clearUrlTestDelay() => clearField(4);

  @$pb.TagNumber(5)
  IpInfo get ipinfo => $_getN(4);
  @$pb.TagNumber(5)
  set ipinfo(IpInfo v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasIpinfo() => $_has(4);
  @$pb.TagNumber(5)
  void clearIpinfo() => clearField(5);
  @$pb.TagNumber(5)
  IpInfo ensureIpinfo() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.bool get isSelected => $_getBF(5);
  @$pb.TagNumber(6)
  set isSelected($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasIsSelected() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsSelected() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isGroup => $_getBF(6);
  @$pb.TagNumber(7)
  set isGroup($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasIsGroup() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsGroup() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isSecure => $_getBF(7);
  @$pb.TagNumber(8)
  set isSecure($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasIsSecure() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsSecure() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isVisible => $_getBF(8);
  @$pb.TagNumber(9)
  set isVisible($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasIsVisible() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsVisible() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get port => $_getIZ(9);
  @$pb.TagNumber(10)
  set port($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasPort() => $_has(9);
  @$pb.TagNumber(10)
  void clearPort() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get host => $_getSZ(10);
  @$pb.TagNumber(11)
  set host($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasHost() => $_has(10);
  @$pb.TagNumber(11)
  void clearHost() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get tagDisplay => $_getSZ(11);
  @$pb.TagNumber(12)
  set tagDisplay($core.String v) { $_setString(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasTagDisplay() => $_has(11);
  @$pb.TagNumber(12)
  void clearTagDisplay() => clearField(12);
}

class IpInfo extends $pb.GeneratedMessage {
  factory IpInfo({
    $core.String? ip,
    $core.String? countryCode,
    $core.String? region,
    $core.String? city,
    $core.int? asn,
    $core.String? org,
    $core.double? latitude,
    $core.double? longitude,
    $core.String? postalCode,
  }) {
    final $result = create();
    if (ip != null) {
      $result.ip = ip;
    }
    if (countryCode != null) {
      $result.countryCode = countryCode;
    }
    if (region != null) {
      $result.region = region;
    }
    if (city != null) {
      $result.city = city;
    }
    if (asn != null) {
      $result.asn = asn;
    }
    if (org != null) {
      $result.org = org;
    }
    if (latitude != null) {
      $result.latitude = latitude;
    }
    if (longitude != null) {
      $result.longitude = longitude;
    }
    if (postalCode != null) {
      $result.postalCode = postalCode;
    }
    return $result;
  }
  IpInfo._() : super();
  factory IpInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IpInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'IpInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ip')
    ..aOS(2, _omitFieldNames ? '' : 'country_code')
    ..aOS(3, _omitFieldNames ? '' : 'region')
    ..aOS(4, _omitFieldNames ? '' : 'city')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'asn', $pb.PbFieldType.O3)
    ..aOS(6, _omitFieldNames ? '' : 'org')
    ..a<$core.double>(7, _omitFieldNames ? '' : 'latitude', $pb.PbFieldType.OD)
    ..a<$core.double>(8, _omitFieldNames ? '' : 'longitude', $pb.PbFieldType.OD)
    ..aOS(9, _omitFieldNames ? '' : 'postal_code')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IpInfo clone() => IpInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IpInfo copyWith(void Function(IpInfo) updates) => super.copyWith((message) => updates(message as IpInfo)) as IpInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IpInfo create() => IpInfo._();
  IpInfo createEmptyInstance() => create();
  static $pb.PbList<IpInfo> createRepeated() => $pb.PbList<IpInfo>();
  @$core.pragma('dart2js:noInline')
  static IpInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IpInfo>(create);
  static IpInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ip => $_getSZ(0);
  @$pb.TagNumber(1)
  set ip($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIp() => $_has(0);
  @$pb.TagNumber(1)
  void clearIp() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get countryCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set countryCode($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCountryCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCountryCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get region => $_getSZ(2);
  @$pb.TagNumber(3)
  set region($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRegion() => $_has(2);
  @$pb.TagNumber(3)
  void clearRegion() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get city => $_getSZ(3);
  @$pb.TagNumber(4)
  set city($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCity() => $_has(3);
  @$pb.TagNumber(4)
  void clearCity() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get asn => $_getIZ(4);
  @$pb.TagNumber(5)
  set asn($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAsn() => $_has(4);
  @$pb.TagNumber(5)
  void clearAsn() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get org => $_getSZ(5);
  @$pb.TagNumber(6)
  set org($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasOrg() => $_has(5);
  @$pb.TagNumber(6)
  void clearOrg() => clearField(6);

  @$pb.TagNumber(7)
  $core.double get latitude => $_getN(6);
  @$pb.TagNumber(7)
  set latitude($core.double v) { $_setDouble(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasLatitude() => $_has(6);
  @$pb.TagNumber(7)
  void clearLatitude() => clearField(7);

  @$pb.TagNumber(8)
  $core.double get longitude => $_getN(7);
  @$pb.TagNumber(8)
  set longitude($core.double v) { $_setDouble(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasLongitude() => $_has(7);
  @$pb.TagNumber(8)
  void clearLongitude() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get postalCode => $_getSZ(8);
  @$pb.TagNumber(9)
  set postalCode($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasPostalCode() => $_has(8);
  @$pb.TagNumber(9)
  void clearPostalCode() => clearField(9);
}

class OutboundGroup extends $pb.GeneratedMessage {
  factory OutboundGroup({
    $core.String? tag,
    $core.String? type,
    OutboundInfo? selected,
    $core.bool? selectable,
    $core.bool? isExpand,
    $core.Iterable<OutboundInfo>? items,
  }) {
    final $result = create();
    if (tag != null) {
      $result.tag = tag;
    }
    if (type != null) {
      $result.type = type;
    }
    if (selected != null) {
      $result.selected = selected;
    }
    if (selectable != null) {
      $result.selectable = selectable;
    }
    if (isExpand != null) {
      $result.isExpand = isExpand;
    }
    if (items != null) {
      $result.items.addAll(items);
    }
    return $result;
  }
  OutboundGroup._() : super();
  factory OutboundGroup.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundGroup.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OutboundGroup', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOM<OutboundInfo>(3, _omitFieldNames ? '' : 'selected', subBuilder: OutboundInfo.create)
    ..aOB(4, _omitFieldNames ? '' : 'selectable')
    ..aOB(5, _omitFieldNames ? '' : 'IsExpand', protoName: 'Is_expand')
    ..pc<OutboundInfo>(6, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: OutboundInfo.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutboundGroup clone() => OutboundGroup()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutboundGroup copyWith(void Function(OutboundGroup) updates) => super.copyWith((message) => updates(message as OutboundGroup)) as OutboundGroup;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutboundGroup create() => OutboundGroup._();
  OutboundGroup createEmptyInstance() => create();
  static $pb.PbList<OutboundGroup> createRepeated() => $pb.PbList<OutboundGroup>();
  @$core.pragma('dart2js:noInline')
  static OutboundGroup getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OutboundGroup>(create);
  static OutboundGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tag => $_getSZ(0);
  @$pb.TagNumber(1)
  set tag($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  OutboundInfo get selected => $_getN(2);
  @$pb.TagNumber(3)
  set selected(OutboundInfo v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSelected() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelected() => clearField(3);
  @$pb.TagNumber(3)
  OutboundInfo ensureSelected() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get selectable => $_getBF(3);
  @$pb.TagNumber(4)
  set selectable($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSelectable() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelectable() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isExpand => $_getBF(4);
  @$pb.TagNumber(5)
  set isExpand($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsExpand() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsExpand() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<OutboundInfo> get items => $_getList(5);
}

class OutboundGroupList extends $pb.GeneratedMessage {
  factory OutboundGroupList({
    $core.Iterable<OutboundGroup>? items,
  }) {
    final $result = create();
    if (items != null) {
      $result.items.addAll(items);
    }
    return $result;
  }
  OutboundGroupList._() : super();
  factory OutboundGroupList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundGroupList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OutboundGroupList', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..pc<OutboundGroup>(1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: OutboundGroup.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutboundGroupList clone() => OutboundGroupList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutboundGroupList copyWith(void Function(OutboundGroupList) updates) => super.copyWith((message) => updates(message as OutboundGroupList)) as OutboundGroupList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutboundGroupList create() => OutboundGroupList._();
  OutboundGroupList createEmptyInstance() => create();
  static $pb.PbList<OutboundGroupList> createRepeated() => $pb.PbList<OutboundGroupList>();
  @$core.pragma('dart2js:noInline')
  static OutboundGroupList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OutboundGroupList>(create);
  static OutboundGroupList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<OutboundGroup> get items => $_getList(0);
}

class WarpAccount extends $pb.GeneratedMessage {
  factory WarpAccount({
    $core.String? accountId,
    $core.String? accessToken,
  }) {
    final $result = create();
    if (accountId != null) {
      $result.accountId = accountId;
    }
    if (accessToken != null) {
      $result.accessToken = accessToken;
    }
    return $result;
  }
  WarpAccount._() : super();
  factory WarpAccount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpAccount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WarpAccount', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'accountId')
    ..aOS(2, _omitFieldNames ? '' : 'accessToken')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpAccount clone() => WarpAccount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpAccount copyWith(void Function(WarpAccount) updates) => super.copyWith((message) => updates(message as WarpAccount)) as WarpAccount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpAccount create() => WarpAccount._();
  WarpAccount createEmptyInstance() => create();
  static $pb.PbList<WarpAccount> createRepeated() => $pb.PbList<WarpAccount>();
  @$core.pragma('dart2js:noInline')
  static WarpAccount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WarpAccount>(create);
  static WarpAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get accountId => $_getSZ(0);
  @$pb.TagNumber(1)
  set accountId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccountId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get accessToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set accessToken($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccessToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessToken() => clearField(2);
}

class WarpWireguardConfig extends $pb.GeneratedMessage {
  factory WarpWireguardConfig({
    $core.String? privateKey,
    $core.String? localAddressIpv4,
    $core.String? localAddressIpv6,
    $core.String? peerPublicKey,
    $core.String? clientId,
  }) {
    final $result = create();
    if (privateKey != null) {
      $result.privateKey = privateKey;
    }
    if (localAddressIpv4 != null) {
      $result.localAddressIpv4 = localAddressIpv4;
    }
    if (localAddressIpv6 != null) {
      $result.localAddressIpv6 = localAddressIpv6;
    }
    if (peerPublicKey != null) {
      $result.peerPublicKey = peerPublicKey;
    }
    if (clientId != null) {
      $result.clientId = clientId;
    }
    return $result;
  }
  WarpWireguardConfig._() : super();
  factory WarpWireguardConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpWireguardConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WarpWireguardConfig', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'private-key', protoName: 'private_key')
    ..aOS(2, _omitFieldNames ? '' : 'local-address-ipv4', protoName: 'local_address_ipv4')
    ..aOS(3, _omitFieldNames ? '' : 'local-address-ipv6', protoName: 'local_address_ipv6')
    ..aOS(4, _omitFieldNames ? '' : 'peer-public-key', protoName: 'peer_public_key')
    ..aOS(5, _omitFieldNames ? '' : 'client-id', protoName: 'client_id')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpWireguardConfig clone() => WarpWireguardConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpWireguardConfig copyWith(void Function(WarpWireguardConfig) updates) => super.copyWith((message) => updates(message as WarpWireguardConfig)) as WarpWireguardConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpWireguardConfig create() => WarpWireguardConfig._();
  WarpWireguardConfig createEmptyInstance() => create();
  static $pb.PbList<WarpWireguardConfig> createRepeated() => $pb.PbList<WarpWireguardConfig>();
  @$core.pragma('dart2js:noInline')
  static WarpWireguardConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WarpWireguardConfig>(create);
  static WarpWireguardConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get privateKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set privateKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPrivateKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrivateKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get localAddressIpv4 => $_getSZ(1);
  @$pb.TagNumber(2)
  set localAddressIpv4($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLocalAddressIpv4() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalAddressIpv4() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get localAddressIpv6 => $_getSZ(2);
  @$pb.TagNumber(3)
  set localAddressIpv6($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLocalAddressIpv6() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalAddressIpv6() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get peerPublicKey => $_getSZ(3);
  @$pb.TagNumber(4)
  set peerPublicKey($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPeerPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearPeerPublicKey() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get clientId => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasClientId() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientId() => clearField(5);
}

class WarpGenerationResponse extends $pb.GeneratedMessage {
  factory WarpGenerationResponse({
    WarpAccount? account,
    $core.String? log,
    WarpWireguardConfig? config,
  }) {
    final $result = create();
    if (account != null) {
      $result.account = account;
    }
    if (log != null) {
      $result.log = log;
    }
    if (config != null) {
      $result.config = config;
    }
    return $result;
  }
  WarpGenerationResponse._() : super();
  factory WarpGenerationResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpGenerationResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WarpGenerationResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOM<WarpAccount>(1, _omitFieldNames ? '' : 'account', subBuilder: WarpAccount.create)
    ..aOS(2, _omitFieldNames ? '' : 'log')
    ..aOM<WarpWireguardConfig>(3, _omitFieldNames ? '' : 'config', subBuilder: WarpWireguardConfig.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpGenerationResponse clone() => WarpGenerationResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpGenerationResponse copyWith(void Function(WarpGenerationResponse) updates) => super.copyWith((message) => updates(message as WarpGenerationResponse)) as WarpGenerationResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarpGenerationResponse create() => WarpGenerationResponse._();
  WarpGenerationResponse createEmptyInstance() => create();
  static $pb.PbList<WarpGenerationResponse> createRepeated() => $pb.PbList<WarpGenerationResponse>();
  @$core.pragma('dart2js:noInline')
  static WarpGenerationResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WarpGenerationResponse>(create);
  static WarpGenerationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  WarpAccount get account => $_getN(0);
  @$pb.TagNumber(1)
  set account(WarpAccount v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccount() => clearField(1);
  @$pb.TagNumber(1)
  WarpAccount ensureAccount() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get log => $_getSZ(1);
  @$pb.TagNumber(2)
  set log($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLog() => $_has(1);
  @$pb.TagNumber(2)
  void clearLog() => clearField(2);

  @$pb.TagNumber(3)
  WarpWireguardConfig get config => $_getN(2);
  @$pb.TagNumber(3)
  set config(WarpWireguardConfig v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasConfig() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfig() => clearField(3);
  @$pb.TagNumber(3)
  WarpWireguardConfig ensureConfig() => $_ensure(2);
}

class SystemProxyStatus extends $pb.GeneratedMessage {
  factory SystemProxyStatus({
    $core.bool? available,
    $core.bool? enabled,
  }) {
    final $result = create();
    if (available != null) {
      $result.available = available;
    }
    if (enabled != null) {
      $result.enabled = enabled;
    }
    return $result;
  }
  SystemProxyStatus._() : super();
  factory SystemProxyStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SystemProxyStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SystemProxyStatus', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'available')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SystemProxyStatus clone() => SystemProxyStatus()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SystemProxyStatus copyWith(void Function(SystemProxyStatus) updates) => super.copyWith((message) => updates(message as SystemProxyStatus)) as SystemProxyStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SystemProxyStatus create() => SystemProxyStatus._();
  SystemProxyStatus createEmptyInstance() => create();
  static $pb.PbList<SystemProxyStatus> createRepeated() => $pb.PbList<SystemProxyStatus>();
  @$core.pragma('dart2js:noInline')
  static SystemProxyStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SystemProxyStatus>(create);
  static SystemProxyStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get available => $_getBF(0);
  @$pb.TagNumber(1)
  set available($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAvailable() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvailable() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => clearField(2);
}

class ParseRequest extends $pb.GeneratedMessage {
  factory ParseRequest({
    $core.String? content,
    $core.String? configPath,
    $core.String? tempPath,
    $core.bool? debug,
  }) {
    final $result = create();
    if (content != null) {
      $result.content = content;
    }
    if (configPath != null) {
      $result.configPath = configPath;
    }
    if (tempPath != null) {
      $result.tempPath = tempPath;
    }
    if (debug != null) {
      $result.debug = debug;
    }
    return $result;
  }
  ParseRequest._() : super();
  factory ParseRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'content')
    ..aOS(2, _omitFieldNames ? '' : 'configPath')
    ..aOS(3, _omitFieldNames ? '' : 'tempPath')
    ..aOB(4, _omitFieldNames ? '' : 'debug')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseRequest clone() => ParseRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseRequest copyWith(void Function(ParseRequest) updates) => super.copyWith((message) => updates(message as ParseRequest)) as ParseRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseRequest create() => ParseRequest._();
  ParseRequest createEmptyInstance() => create();
  static $pb.PbList<ParseRequest> createRepeated() => $pb.PbList<ParseRequest>();
  @$core.pragma('dart2js:noInline')
  static ParseRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseRequest>(create);
  static ParseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get content => $_getSZ(0);
  @$pb.TagNumber(1)
  set content($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get configPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set configPath($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasConfigPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfigPath() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get tempPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set tempPath($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTempPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearTempPath() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get debug => $_getBF(3);
  @$pb.TagNumber(4)
  set debug($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDebug() => $_has(3);
  @$pb.TagNumber(4)
  void clearDebug() => clearField(4);
}

class ParseResponse extends $pb.GeneratedMessage {
  factory ParseResponse({
    $1.ResponseCode? responseCode,
    $core.String? content,
    $core.String? message,
  }) {
    final $result = create();
    if (responseCode != null) {
      $result.responseCode = responseCode;
    }
    if (content != null) {
      $result.content = content;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  ParseResponse._() : super();
  factory ParseResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..e<$1.ResponseCode>(1, _omitFieldNames ? '' : 'responseCode', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseResponse clone() => ParseResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseResponse copyWith(void Function(ParseResponse) updates) => super.copyWith((message) => updates(message as ParseResponse)) as ParseResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseResponse create() => ParseResponse._();
  ParseResponse createEmptyInstance() => create();
  static $pb.PbList<ParseResponse> createRepeated() => $pb.PbList<ParseResponse>();
  @$core.pragma('dart2js:noInline')
  static ParseResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseResponse>(create);
  static ParseResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ResponseCode get responseCode => $_getN(0);
  @$pb.TagNumber(1)
  set responseCode($1.ResponseCode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasResponseCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearResponseCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);
}

class ChangeHiddifySettingsRequest extends $pb.GeneratedMessage {
  factory ChangeHiddifySettingsRequest({
    $core.String? hiddifySettingsJson,
  }) {
    final $result = create();
    if (hiddifySettingsJson != null) {
      $result.hiddifySettingsJson = hiddifySettingsJson;
    }
    return $result;
  }
  ChangeHiddifySettingsRequest._() : super();
  factory ChangeHiddifySettingsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChangeHiddifySettingsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChangeHiddifySettingsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hiddifySettingsJson')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChangeHiddifySettingsRequest clone() => ChangeHiddifySettingsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChangeHiddifySettingsRequest copyWith(void Function(ChangeHiddifySettingsRequest) updates) => super.copyWith((message) => updates(message as ChangeHiddifySettingsRequest)) as ChangeHiddifySettingsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeHiddifySettingsRequest create() => ChangeHiddifySettingsRequest._();
  ChangeHiddifySettingsRequest createEmptyInstance() => create();
  static $pb.PbList<ChangeHiddifySettingsRequest> createRepeated() => $pb.PbList<ChangeHiddifySettingsRequest>();
  @$core.pragma('dart2js:noInline')
  static ChangeHiddifySettingsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChangeHiddifySettingsRequest>(create);
  static ChangeHiddifySettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hiddifySettingsJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set hiddifySettingsJson($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHiddifySettingsJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearHiddifySettingsJson() => clearField(1);
}

class GenerateConfigRequest extends $pb.GeneratedMessage {
  factory GenerateConfigRequest({
    $core.String? path,
    $core.String? tempPath,
    $core.bool? debug,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (tempPath != null) {
      $result.tempPath = tempPath;
    }
    if (debug != null) {
      $result.debug = debug;
    }
    return $result;
  }
  GenerateConfigRequest._() : super();
  factory GenerateConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateConfigRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'tempPath')
    ..aOB(3, _omitFieldNames ? '' : 'debug')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GenerateConfigRequest clone() => GenerateConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GenerateConfigRequest copyWith(void Function(GenerateConfigRequest) updates) => super.copyWith((message) => updates(message as GenerateConfigRequest)) as GenerateConfigRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateConfigRequest create() => GenerateConfigRequest._();
  GenerateConfigRequest createEmptyInstance() => create();
  static $pb.PbList<GenerateConfigRequest> createRepeated() => $pb.PbList<GenerateConfigRequest>();
  @$core.pragma('dart2js:noInline')
  static GenerateConfigRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GenerateConfigRequest>(create);
  static GenerateConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get tempPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set tempPath($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTempPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearTempPath() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get debug => $_getBF(2);
  @$pb.TagNumber(3)
  set debug($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDebug() => $_has(2);
  @$pb.TagNumber(3)
  void clearDebug() => clearField(3);
}

class GenerateConfigResponse extends $pb.GeneratedMessage {
  factory GenerateConfigResponse({
    $core.String? configContent,
  }) {
    final $result = create();
    if (configContent != null) {
      $result.configContent = configContent;
    }
    return $result;
  }
  GenerateConfigResponse._() : super();
  factory GenerateConfigResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateConfigResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateConfigResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'configContent')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GenerateConfigResponse clone() => GenerateConfigResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GenerateConfigResponse copyWith(void Function(GenerateConfigResponse) updates) => super.copyWith((message) => updates(message as GenerateConfigResponse)) as GenerateConfigResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateConfigResponse create() => GenerateConfigResponse._();
  GenerateConfigResponse createEmptyInstance() => create();
  static $pb.PbList<GenerateConfigResponse> createRepeated() => $pb.PbList<GenerateConfigResponse>();
  @$core.pragma('dart2js:noInline')
  static GenerateConfigResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GenerateConfigResponse>(create);
  static GenerateConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get configContent => $_getSZ(0);
  @$pb.TagNumber(1)
  set configContent($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConfigContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigContent() => clearField(1);
}

class SelectOutboundRequest extends $pb.GeneratedMessage {
  factory SelectOutboundRequest({
    $core.String? groupTag,
    $core.String? outboundTag,
  }) {
    final $result = create();
    if (groupTag != null) {
      $result.groupTag = groupTag;
    }
    if (outboundTag != null) {
      $result.outboundTag = outboundTag;
    }
    return $result;
  }
  SelectOutboundRequest._() : super();
  factory SelectOutboundRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOutboundRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SelectOutboundRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupTag')
    ..aOS(2, _omitFieldNames ? '' : 'outboundTag')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOutboundRequest clone() => SelectOutboundRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOutboundRequest copyWith(void Function(SelectOutboundRequest) updates) => super.copyWith((message) => updates(message as SelectOutboundRequest)) as SelectOutboundRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SelectOutboundRequest create() => SelectOutboundRequest._();
  SelectOutboundRequest createEmptyInstance() => create();
  static $pb.PbList<SelectOutboundRequest> createRepeated() => $pb.PbList<SelectOutboundRequest>();
  @$core.pragma('dart2js:noInline')
  static SelectOutboundRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOutboundRequest>(create);
  static SelectOutboundRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupTag => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupTag($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupTag() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get outboundTag => $_getSZ(1);
  @$pb.TagNumber(2)
  set outboundTag($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOutboundTag() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutboundTag() => clearField(2);
}

class UrlTestRequest extends $pb.GeneratedMessage {
  factory UrlTestRequest({
    $core.String? groupTag,
  }) {
    final $result = create();
    if (groupTag != null) {
      $result.groupTag = groupTag;
    }
    return $result;
  }
  UrlTestRequest._() : super();
  factory UrlTestRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UrlTestRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UrlTestRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupTag')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UrlTestRequest clone() => UrlTestRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UrlTestRequest copyWith(void Function(UrlTestRequest) updates) => super.copyWith((message) => updates(message as UrlTestRequest)) as UrlTestRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UrlTestRequest create() => UrlTestRequest._();
  UrlTestRequest createEmptyInstance() => create();
  static $pb.PbList<UrlTestRequest> createRepeated() => $pb.PbList<UrlTestRequest>();
  @$core.pragma('dart2js:noInline')
  static UrlTestRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UrlTestRequest>(create);
  static UrlTestRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupTag => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupTag($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupTag() => clearField(1);
}

class GenerateWarpConfigRequest extends $pb.GeneratedMessage {
  factory GenerateWarpConfigRequest({
    $core.String? licenseKey,
    $core.String? accountId,
    $core.String? accessToken,
  }) {
    final $result = create();
    if (licenseKey != null) {
      $result.licenseKey = licenseKey;
    }
    if (accountId != null) {
      $result.accountId = accountId;
    }
    if (accessToken != null) {
      $result.accessToken = accessToken;
    }
    return $result;
  }
  GenerateWarpConfigRequest._() : super();
  factory GenerateWarpConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateWarpConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateWarpConfigRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'licenseKey')
    ..aOS(2, _omitFieldNames ? '' : 'accountId')
    ..aOS(3, _omitFieldNames ? '' : 'accessToken')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GenerateWarpConfigRequest clone() => GenerateWarpConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GenerateWarpConfigRequest copyWith(void Function(GenerateWarpConfigRequest) updates) => super.copyWith((message) => updates(message as GenerateWarpConfigRequest)) as GenerateWarpConfigRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateWarpConfigRequest create() => GenerateWarpConfigRequest._();
  GenerateWarpConfigRequest createEmptyInstance() => create();
  static $pb.PbList<GenerateWarpConfigRequest> createRepeated() => $pb.PbList<GenerateWarpConfigRequest>();
  @$core.pragma('dart2js:noInline')
  static GenerateWarpConfigRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GenerateWarpConfigRequest>(create);
  static GenerateWarpConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get licenseKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set licenseKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLicenseKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearLicenseKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get accountId => $_getSZ(1);
  @$pb.TagNumber(2)
  set accountId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccountId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccountId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get accessToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set accessToken($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAccessToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccessToken() => clearField(3);
}

class SetSystemProxyEnabledRequest extends $pb.GeneratedMessage {
  factory SetSystemProxyEnabledRequest({
    $core.bool? isEnabled,
  }) {
    final $result = create();
    if (isEnabled != null) {
      $result.isEnabled = isEnabled;
    }
    return $result;
  }
  SetSystemProxyEnabledRequest._() : super();
  factory SetSystemProxyEnabledRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetSystemProxyEnabledRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetSystemProxyEnabledRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isEnabled')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetSystemProxyEnabledRequest clone() => SetSystemProxyEnabledRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetSystemProxyEnabledRequest copyWith(void Function(SetSystemProxyEnabledRequest) updates) => super.copyWith((message) => updates(message as SetSystemProxyEnabledRequest)) as SetSystemProxyEnabledRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetSystemProxyEnabledRequest create() => SetSystemProxyEnabledRequest._();
  SetSystemProxyEnabledRequest createEmptyInstance() => create();
  static $pb.PbList<SetSystemProxyEnabledRequest> createRepeated() => $pb.PbList<SetSystemProxyEnabledRequest>();
  @$core.pragma('dart2js:noInline')
  static SetSystemProxyEnabledRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetSystemProxyEnabledRequest>(create);
  static SetSystemProxyEnabledRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isEnabled => $_getBF(0);
  @$pb.TagNumber(1)
  set isEnabled($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIsEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsEnabled() => clearField(1);
}

class LogMessage extends $pb.GeneratedMessage {
  factory LogMessage({
    LogLevel? level,
    LogType? type,
    $core.String? message,
    $7.Timestamp? time,
  }) {
    final $result = create();
    if (level != null) {
      $result.level = level;
    }
    if (type != null) {
      $result.type = type;
    }
    if (message != null) {
      $result.message = message;
    }
    if (time != null) {
      $result.time = time;
    }
    return $result;
  }
  LogMessage._() : super();
  factory LogMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..e<LogLevel>(1, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.DEBUG, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..e<LogType>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: LogType.CORE, valueOf: LogType.valueOf, enumValues: LogType.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOM<$7.Timestamp>(4, _omitFieldNames ? '' : 'time', subBuilder: $7.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogMessage clone() => LogMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogMessage copyWith(void Function(LogMessage) updates) => super.copyWith((message) => updates(message as LogMessage)) as LogMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogMessage create() => LogMessage._();
  LogMessage createEmptyInstance() => create();
  static $pb.PbList<LogMessage> createRepeated() => $pb.PbList<LogMessage>();
  @$core.pragma('dart2js:noInline')
  static LogMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogMessage>(create);
  static LogMessage? _defaultInstance;

  @$pb.TagNumber(1)
  LogLevel get level => $_getN(0);
  @$pb.TagNumber(1)
  set level(LogLevel v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => clearField(1);

  @$pb.TagNumber(2)
  LogType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(LogType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);

  @$pb.TagNumber(4)
  $7.Timestamp get time => $_getN(3);
  @$pb.TagNumber(4)
  set time($7.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearTime() => clearField(4);
  @$pb.TagNumber(4)
  $7.Timestamp ensureTime() => $_ensure(3);
}

class StopRequest extends $pb.GeneratedMessage {
  factory StopRequest() => create();
  StopRequest._() : super();
  factory StopRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StopRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StopRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StopRequest clone() => StopRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StopRequest copyWith(void Function(StopRequest) updates) => super.copyWith((message) => updates(message as StopRequest)) as StopRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopRequest create() => StopRequest._();
  StopRequest createEmptyInstance() => create();
  static $pb.PbList<StopRequest> createRepeated() => $pb.PbList<StopRequest>();
  @$core.pragma('dart2js:noInline')
  static StopRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StopRequest>(create);
  static StopRequest? _defaultInstance;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
