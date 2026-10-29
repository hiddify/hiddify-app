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

import '../../google/protobuf/timestamp.pb.dart' as $2;
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
    $core.String? configName,
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
    if (configName != null) {
      $result.configName = configName;
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
    ..aOS(7, _omitFieldNames ? '' : 'configName')
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

  @$pb.TagNumber(7)
  $core.String get configName => $_getSZ(6);
  @$pb.TagNumber(7)
  set configName($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasConfigName() => $_has(6);
  @$pb.TagNumber(7)
  void clearConfigName() => clearField(7);
}

class CloseRequest extends $pb.GeneratedMessage {
  factory CloseRequest({
    SetupMode? mode,
  }) {
    final $result = create();
    if (mode != null) {
      $result.mode = mode;
    }
    return $result;
  }
  CloseRequest._() : super();
  factory CloseRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CloseRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CloseRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..e<SetupMode>(1, _omitFieldNames ? '' : 'mode', $pb.PbFieldType.OE, defaultOrMaker: SetupMode.OLD, valueOf: SetupMode.valueOf, enumValues: SetupMode.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CloseRequest clone() => CloseRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CloseRequest copyWith(void Function(CloseRequest) updates) => super.copyWith((message) => updates(message as CloseRequest)) as CloseRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseRequest create() => CloseRequest._();
  CloseRequest createEmptyInstance() => create();
  static $pb.PbList<CloseRequest> createRepeated() => $pb.PbList<CloseRequest>();
  @$core.pragma('dart2js:noInline')
  static CloseRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CloseRequest>(create);
  static CloseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SetupMode get mode => $_getN(0);
  @$pb.TagNumber(1)
  set mode(SetupMode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => clearField(1);
}

/// Define the message equivalent of SetupParameters
class SetupRequest extends $pb.GeneratedMessage {
  factory SetupRequest({
    $core.String? basePath,
    $core.String? workingDir,
    $core.String? tempDir,
    $fixnum.Int64? flutterStatusPort,
    $core.String? listen,
    $core.String? secret,
    $core.bool? debug,
    SetupMode? mode,
    $core.bool? fixAndroidStack,
  }) {
    final $result = create();
    if (basePath != null) {
      $result.basePath = basePath;
    }
    if (workingDir != null) {
      $result.workingDir = workingDir;
    }
    if (tempDir != null) {
      $result.tempDir = tempDir;
    }
    if (flutterStatusPort != null) {
      $result.flutterStatusPort = flutterStatusPort;
    }
    if (listen != null) {
      $result.listen = listen;
    }
    if (secret != null) {
      $result.secret = secret;
    }
    if (debug != null) {
      $result.debug = debug;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    if (fixAndroidStack != null) {
      $result.fixAndroidStack = fixAndroidStack;
    }
    return $result;
  }
  SetupRequest._() : super();
  factory SetupRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetupRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetupRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'basePath')
    ..aOS(2, _omitFieldNames ? '' : 'workingDir')
    ..aOS(3, _omitFieldNames ? '' : 'tempDir')
    ..aInt64(4, _omitFieldNames ? '' : 'flutterStatusPort')
    ..aOS(5, _omitFieldNames ? '' : 'listen')
    ..aOS(6, _omitFieldNames ? '' : 'secret')
    ..aOB(7, _omitFieldNames ? '' : 'debug')
    ..e<SetupMode>(8, _omitFieldNames ? '' : 'mode', $pb.PbFieldType.OE, defaultOrMaker: SetupMode.OLD, valueOf: SetupMode.valueOf, enumValues: SetupMode.values)
    ..aOB(9, _omitFieldNames ? '' : 'fixAndroidStack')
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
  $core.String get workingDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set workingDir($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWorkingDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkingDir() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get tempDir => $_getSZ(2);
  @$pb.TagNumber(3)
  set tempDir($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTempDir() => $_has(2);
  @$pb.TagNumber(3)
  void clearTempDir() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get flutterStatusPort => $_getI64(3);
  @$pb.TagNumber(4)
  set flutterStatusPort($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFlutterStatusPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearFlutterStatusPort() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get listen => $_getSZ(4);
  @$pb.TagNumber(5)
  set listen($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasListen() => $_has(4);
  @$pb.TagNumber(5)
  void clearListen() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get secret => $_getSZ(5);
  @$pb.TagNumber(6)
  set secret($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSecret() => $_has(5);
  @$pb.TagNumber(6)
  void clearSecret() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get debug => $_getBF(6);
  @$pb.TagNumber(7)
  set debug($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasDebug() => $_has(6);
  @$pb.TagNumber(7)
  void clearDebug() => clearField(7);

  @$pb.TagNumber(8)
  SetupMode get mode => $_getN(7);
  @$pb.TagNumber(8)
  set mode(SetupMode v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasMode() => $_has(7);
  @$pb.TagNumber(8)
  void clearMode() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get fixAndroidStack => $_getBF(8);
  @$pb.TagNumber(9)
  set fixAndroidStack($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasFixAndroidStack() => $_has(8);
  @$pb.TagNumber(9)
  void clearFixAndroidStack() => clearField(9);
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
    $core.String? currentOutbound,
    $core.String? currentProfile,
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
    if (currentOutbound != null) {
      $result.currentOutbound = currentOutbound;
    }
    if (currentProfile != null) {
      $result.currentProfile = currentProfile;
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
    ..aOS(10, _omitFieldNames ? '' : 'currentOutbound')
    ..aOS(11, _omitFieldNames ? '' : 'currentProfile')
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

  @$pb.TagNumber(10)
  $core.String get currentOutbound => $_getSZ(9);
  @$pb.TagNumber(10)
  set currentOutbound($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasCurrentOutbound() => $_has(9);
  @$pb.TagNumber(10)
  void clearCurrentOutbound() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get currentProfile => $_getSZ(10);
  @$pb.TagNumber(11)
  set currentProfile($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasCurrentProfile() => $_has(10);
  @$pb.TagNumber(11)
  void clearCurrentProfile() => clearField(11);
}

class OutboundInfo extends $pb.GeneratedMessage {
  factory OutboundInfo({
    $core.String? tag,
    $core.String? type,
    $2.Timestamp? urlTestTime,
    $core.int? urlTestDelay,
    IpInfo? ipinfo,
    $core.bool? isSelected,
    $core.bool? isGroup,
    $core.bool? isSecure,
    $core.bool? isVisible,
    $core.int? port,
    $core.String? host,
    $core.String? tagDisplay,
    $core.String? groupSelectedTag,
    $core.String? groupSelectedTagDisplay,
    $fixnum.Int64? upload,
    $fixnum.Int64? download,
    $core.String? detour,
    Status? status,
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
    if (groupSelectedTag != null) {
      $result.groupSelectedTag = groupSelectedTag;
    }
    if (groupSelectedTagDisplay != null) {
      $result.groupSelectedTagDisplay = groupSelectedTagDisplay;
    }
    if (upload != null) {
      $result.upload = upload;
    }
    if (download != null) {
      $result.download = download;
    }
    if (detour != null) {
      $result.detour = detour;
    }
    if (status != null) {
      $result.status = status;
    }
    return $result;
  }
  OutboundInfo._() : super();
  factory OutboundInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OutboundInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOM<$2.Timestamp>(3, _omitFieldNames ? '' : 'urlTestTime', subBuilder: $2.Timestamp.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'urlTestDelay', $pb.PbFieldType.O3)
    ..aOM<IpInfo>(5, _omitFieldNames ? '' : 'ipinfo', subBuilder: IpInfo.create)
    ..aOB(6, _omitFieldNames ? '' : 'isSelected')
    ..aOB(7, _omitFieldNames ? '' : 'isGroup')
    ..aOB(8, _omitFieldNames ? '' : 'isSecure')
    ..aOB(9, _omitFieldNames ? '' : 'isVisible')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'port', $pb.PbFieldType.OU3)
    ..aOS(11, _omitFieldNames ? '' : 'host')
    ..aOS(12, _omitFieldNames ? '' : 'tagDisplay')
    ..aOS(13, _omitFieldNames ? '' : 'groupSelectedTag')
    ..aOS(14, _omitFieldNames ? '' : 'groupSelectedTagDisplay')
    ..aInt64(15, _omitFieldNames ? '' : 'upload')
    ..aInt64(16, _omitFieldNames ? '' : 'download')
    ..aOS(17, _omitFieldNames ? '' : 'detour')
    ..e<Status>(18, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: Status.READY, valueOf: Status.valueOf, enumValues: Status.values)
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
  $2.Timestamp get urlTestTime => $_getN(2);
  @$pb.TagNumber(3)
  set urlTestTime($2.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasUrlTestTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrlTestTime() => clearField(3);
  @$pb.TagNumber(3)
  $2.Timestamp ensureUrlTestTime() => $_ensure(2);

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

  @$pb.TagNumber(13)
  $core.String get groupSelectedTag => $_getSZ(12);
  @$pb.TagNumber(13)
  set groupSelectedTag($core.String v) { $_setString(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasGroupSelectedTag() => $_has(12);
  @$pb.TagNumber(13)
  void clearGroupSelectedTag() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get groupSelectedTagDisplay => $_getSZ(13);
  @$pb.TagNumber(14)
  set groupSelectedTagDisplay($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasGroupSelectedTagDisplay() => $_has(13);
  @$pb.TagNumber(14)
  void clearGroupSelectedTagDisplay() => clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get upload => $_getI64(14);
  @$pb.TagNumber(15)
  set upload($fixnum.Int64 v) { $_setInt64(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasUpload() => $_has(14);
  @$pb.TagNumber(15)
  void clearUpload() => clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get download => $_getI64(15);
  @$pb.TagNumber(16)
  set download($fixnum.Int64 v) { $_setInt64(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasDownload() => $_has(15);
  @$pb.TagNumber(16)
  void clearDownload() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get detour => $_getSZ(16);
  @$pb.TagNumber(17)
  set detour($core.String v) { $_setString(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasDetour() => $_has(16);
  @$pb.TagNumber(17)
  void clearDetour() => clearField(17);

  @$pb.TagNumber(18)
  Status get status => $_getN(17);
  @$pb.TagNumber(18)
  set status(Status v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasStatus() => $_has(17);
  @$pb.TagNumber(18)
  void clearStatus() => clearField(18);
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
    $core.String? selected,
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
    ..aOS(3, _omitFieldNames ? '' : 'selected')
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
  $core.String get selected => $_getSZ(2);
  @$pb.TagNumber(3)
  set selected($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSelected() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelected() => clearField(3);

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
    OutboundInfo? chainHop,
  }) {
    final $result = create();
    if (items != null) {
      $result.items.addAll(items);
    }
    if (chainHop != null) {
      $result.chainHop = chainHop;
    }
    return $result;
  }
  OutboundGroupList._() : super();
  factory OutboundGroupList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundGroupList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OutboundGroupList', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..pc<OutboundGroup>(1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: OutboundGroup.create)
    ..aOM<OutboundInfo>(2, _omitFieldNames ? '' : 'chainHop', subBuilder: OutboundInfo.create)
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

  @$pb.TagNumber(2)
  OutboundInfo get chainHop => $_getN(1);
  @$pb.TagNumber(2)
  set chainHop(OutboundInfo v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasChainHop() => $_has(1);
  @$pb.TagNumber(2)
  void clearChainHop() => clearField(2);
  @$pb.TagNumber(2)
  OutboundInfo ensureChainHop() => $_ensure(1);
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
    $core.String? tag,
  }) {
    final $result = create();
    if (tag != null) {
      $result.tag = tag;
    }
    return $result;
  }
  UrlTestRequest._() : super();
  factory UrlTestRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UrlTestRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UrlTestRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
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
  $core.String get tag => $_getSZ(0);
  @$pb.TagNumber(1)
  set tag($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => clearField(1);
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
    $2.Timestamp? time,
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
    ..e<LogLevel>(1, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.TRACE, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..e<LogType>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: LogType.CORE, valueOf: LogType.valueOf, enumValues: LogType.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'time', subBuilder: $2.Timestamp.create)
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
  $2.Timestamp get time => $_getN(3);
  @$pb.TagNumber(4)
  set time($2.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearTime() => clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureTime() => $_ensure(3);
}

class LogRequest extends $pb.GeneratedMessage {
  factory LogRequest({
    LogLevel? level,
  }) {
    final $result = create();
    if (level != null) {
      $result.level = level;
    }
    return $result;
  }
  LogRequest._() : super();
  factory LogRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..e<LogLevel>(1, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.TRACE, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogRequest clone() => LogRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogRequest copyWith(void Function(LogRequest) updates) => super.copyWith((message) => updates(message as LogRequest)) as LogRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogRequest create() => LogRequest._();
  LogRequest createEmptyInstance() => create();
  static $pb.PbList<LogRequest> createRepeated() => $pb.PbList<LogRequest>();
  @$core.pragma('dart2js:noInline')
  static LogRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogRequest>(create);
  static LogRequest? _defaultInstance;

  @$pb.TagNumber(1)
  LogLevel get level => $_getN(0);
  @$pb.TagNumber(1)
  set level(LogLevel v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => clearField(1);
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

class LANIPResponse extends $pb.GeneratedMessage {
  factory LANIPResponse({
    $core.String? ip,
  }) {
    final $result = create();
    if (ip != null) {
      $result.ip = ip;
    }
    return $result;
  }
  LANIPResponse._() : super();
  factory LANIPResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LANIPResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LANIPResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ip')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LANIPResponse clone() => LANIPResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LANIPResponse copyWith(void Function(LANIPResponse) updates) => super.copyWith((message) => updates(message as LANIPResponse)) as LANIPResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LANIPResponse create() => LANIPResponse._();
  LANIPResponse createEmptyInstance() => create();
  static $pb.PbList<LANIPResponse> createRepeated() => $pb.PbList<LANIPResponse>();
  @$core.pragma('dart2js:noInline')
  static LANIPResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LANIPResponse>(create);
  static LANIPResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ip => $_getSZ(0);
  @$pb.TagNumber(1)
  set ip($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIp() => $_has(0);
  @$pb.TagNumber(1)
  void clearIp() => clearField(1);
}

class IsAdminResponse extends $pb.GeneratedMessage {
  factory IsAdminResponse({
    $core.bool? isAdmin,
  }) {
    final $result = create();
    if (isAdmin != null) {
      $result.isAdmin = isAdmin;
    }
    return $result;
  }
  IsAdminResponse._() : super();
  factory IsAdminResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IsAdminResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'IsAdminResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isAdmin')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IsAdminResponse clone() => IsAdminResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IsAdminResponse copyWith(void Function(IsAdminResponse) updates) => super.copyWith((message) => updates(message as IsAdminResponse)) as IsAdminResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IsAdminResponse create() => IsAdminResponse._();
  IsAdminResponse createEmptyInstance() => create();
  static $pb.PbList<IsAdminResponse> createRepeated() => $pb.PbList<IsAdminResponse>();
  @$core.pragma('dart2js:noInline')
  static IsAdminResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IsAdminResponse>(create);
  static IsAdminResponse? _defaultInstance;

  /// True when the core process runs as Administrator (Windows) or root (Unix).
  @$pb.TagNumber(1)
  $core.bool get isAdmin => $_getBF(0);
  @$pb.TagNumber(1)
  set isAdmin($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIsAdmin() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsAdmin() => clearField(1);
}

class AdminNeededProxy extends $pb.GeneratedMessage {
  factory AdminNeededProxy({
    $core.String? tag,
    $core.String? summary,
    $core.String? detail,
  }) {
    final $result = create();
    if (tag != null) {
      $result.tag = tag;
    }
    if (summary != null) {
      $result.summary = summary;
    }
    if (detail != null) {
      $result.detail = detail;
    }
    return $result;
  }
  AdminNeededProxy._() : super();
  factory AdminNeededProxy.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AdminNeededProxy.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AdminNeededProxy', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
    ..aOS(2, _omitFieldNames ? '' : 'summary')
    ..aOS(3, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AdminNeededProxy clone() => AdminNeededProxy()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AdminNeededProxy copyWith(void Function(AdminNeededProxy) updates) => super.copyWith((message) => updates(message as AdminNeededProxy)) as AdminNeededProxy;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdminNeededProxy create() => AdminNeededProxy._();
  AdminNeededProxy createEmptyInstance() => create();
  static $pb.PbList<AdminNeededProxy> createRepeated() => $pb.PbList<AdminNeededProxy>();
  @$core.pragma('dart2js:noInline')
  static AdminNeededProxy getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AdminNeededProxy>(create);
  static AdminNeededProxy? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tag => $_getSZ(0);
  @$pb.TagNumber(1)
  set tag($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get summary => $_getSZ(1);
  @$pb.TagNumber(2)
  set summary($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSummary() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummary() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get detail => $_getSZ(2);
  @$pb.TagNumber(3)
  set detail($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDetail() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetail() => clearField(3);
}

class NeedAdminBgServiceRequest extends $pb.GeneratedMessage {
  factory NeedAdminBgServiceRequest({
    $core.String? serviceMode,
    $core.String? hiddifySettingsJson,
    AdminPreference? adminPreference,
    $core.bool? privilegeErrorRemembered,
  }) {
    final $result = create();
    if (serviceMode != null) {
      $result.serviceMode = serviceMode;
    }
    if (hiddifySettingsJson != null) {
      $result.hiddifySettingsJson = hiddifySettingsJson;
    }
    if (adminPreference != null) {
      $result.adminPreference = adminPreference;
    }
    if (privilegeErrorRemembered != null) {
      $result.privilegeErrorRemembered = privilegeErrorRemembered;
    }
    return $result;
  }
  NeedAdminBgServiceRequest._() : super();
  factory NeedAdminBgServiceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NeedAdminBgServiceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NeedAdminBgServiceRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceMode')
    ..aOS(2, _omitFieldNames ? '' : 'hiddifySettingsJson')
    ..e<AdminPreference>(3, _omitFieldNames ? '' : 'adminPreference', $pb.PbFieldType.OE, defaultOrMaker: AdminPreference.ADMIN_PREFERENCE_UNSET, valueOf: AdminPreference.valueOf, enumValues: AdminPreference.values)
    ..aOB(4, _omitFieldNames ? '' : 'privilegeErrorRemembered')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NeedAdminBgServiceRequest clone() => NeedAdminBgServiceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NeedAdminBgServiceRequest copyWith(void Function(NeedAdminBgServiceRequest) updates) => super.copyWith((message) => updates(message as NeedAdminBgServiceRequest)) as NeedAdminBgServiceRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NeedAdminBgServiceRequest create() => NeedAdminBgServiceRequest._();
  NeedAdminBgServiceRequest createEmptyInstance() => create();
  static $pb.PbList<NeedAdminBgServiceRequest> createRepeated() => $pb.PbList<NeedAdminBgServiceRequest>();
  @$core.pragma('dart2js:noInline')
  static NeedAdminBgServiceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NeedAdminBgServiceRequest>(create);
  static NeedAdminBgServiceRequest? _defaultInstance;

  /// proxy | system-proxy | vpn
  @$pb.TagNumber(1)
  $core.String get serviceMode => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceMode($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasServiceMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceMode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get hiddifySettingsJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set hiddifySettingsJson($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHiddifySettingsJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearHiddifySettingsJson() => clearField(2);

  @$pb.TagNumber(3)
  AdminPreference get adminPreference => $_getN(2);
  @$pb.TagNumber(3)
  set adminPreference(AdminPreference v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAdminPreference() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdminPreference() => clearField(3);

  /// True after an in-process start failed with a privilege error.
  @$pb.TagNumber(4)
  $core.bool get privilegeErrorRemembered => $_getBF(3);
  @$pb.TagNumber(4)
  set privilegeErrorRemembered($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPrivilegeErrorRemembered() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrivilegeErrorRemembered() => clearField(4);
}

class NeedAdminBgServiceResponse extends $pb.GeneratedMessage {
  factory NeedAdminBgServiceResponse({
    AdminBgServiceDecision? decision,
    $core.Iterable<AdminNeededProxy>? adminNeededProxies,
  }) {
    final $result = create();
    if (decision != null) {
      $result.decision = decision;
    }
    if (adminNeededProxies != null) {
      $result.adminNeededProxies.addAll(adminNeededProxies);
    }
    return $result;
  }
  NeedAdminBgServiceResponse._() : super();
  factory NeedAdminBgServiceResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NeedAdminBgServiceResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NeedAdminBgServiceResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..e<AdminBgServiceDecision>(1, _omitFieldNames ? '' : 'decision', $pb.PbFieldType.OE, defaultOrMaker: AdminBgServiceDecision.ADMIN_BG_SERVICE_NO, valueOf: AdminBgServiceDecision.valueOf, enumValues: AdminBgServiceDecision.values)
    ..pc<AdminNeededProxy>(2, _omitFieldNames ? '' : 'adminNeededProxies', $pb.PbFieldType.PM, subBuilder: AdminNeededProxy.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NeedAdminBgServiceResponse clone() => NeedAdminBgServiceResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NeedAdminBgServiceResponse copyWith(void Function(NeedAdminBgServiceResponse) updates) => super.copyWith((message) => updates(message as NeedAdminBgServiceResponse)) as NeedAdminBgServiceResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NeedAdminBgServiceResponse create() => NeedAdminBgServiceResponse._();
  NeedAdminBgServiceResponse createEmptyInstance() => create();
  static $pb.PbList<NeedAdminBgServiceResponse> createRepeated() => $pb.PbList<NeedAdminBgServiceResponse>();
  @$core.pragma('dart2js:noInline')
  static NeedAdminBgServiceResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NeedAdminBgServiceResponse>(create);
  static NeedAdminBgServiceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  AdminBgServiceDecision get decision => $_getN(0);
  @$pb.TagNumber(1)
  set decision(AdminBgServiceDecision v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDecision() => $_has(0);
  @$pb.TagNumber(1)
  void clearDecision() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<AdminNeededProxy> get adminNeededProxies => $_getList(1);
}

class EnsureAdminBgServiceRequest extends $pb.GeneratedMessage {
  factory EnsureAdminBgServiceRequest({
    $core.String? configContent,
    $core.String? configName,
    $core.String? settingsJson,
    $core.Map<$core.String, $core.List<$core.int>>? resources,
    $core.bool? disableMemoryLimit,
    $core.int? ownerPid,
    $core.String? cliPath,
    $core.String? ownerUser,
  }) {
    final $result = create();
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
    if (cliPath != null) {
      $result.cliPath = cliPath;
    }
    if (ownerUser != null) {
      $result.ownerUser = ownerUser;
    }
    return $result;
  }
  EnsureAdminBgServiceRequest._() : super();
  factory EnsureAdminBgServiceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EnsureAdminBgServiceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EnsureAdminBgServiceRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'configContent')
    ..aOS(2, _omitFieldNames ? '' : 'configName')
    ..aOS(3, _omitFieldNames ? '' : 'settingsJson')
    ..m<$core.String, $core.List<$core.int>>(4, _omitFieldNames ? '' : 'resources', entryClassName: 'EnsureAdminBgServiceRequest.ResourcesEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OY, packageName: const $pb.PackageName('hcore'))
    ..aOB(5, _omitFieldNames ? '' : 'disableMemoryLimit')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'ownerPid', $pb.PbFieldType.O3)
    ..aOS(7, _omitFieldNames ? '' : 'cliPath')
    ..aOS(8, _omitFieldNames ? '' : 'ownerUser')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EnsureAdminBgServiceRequest clone() => EnsureAdminBgServiceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EnsureAdminBgServiceRequest copyWith(void Function(EnsureAdminBgServiceRequest) updates) => super.copyWith((message) => updates(message as EnsureAdminBgServiceRequest)) as EnsureAdminBgServiceRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnsureAdminBgServiceRequest create() => EnsureAdminBgServiceRequest._();
  EnsureAdminBgServiceRequest createEmptyInstance() => create();
  static $pb.PbList<EnsureAdminBgServiceRequest> createRepeated() => $pb.PbList<EnsureAdminBgServiceRequest>();
  @$core.pragma('dart2js:noInline')
  static EnsureAdminBgServiceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EnsureAdminBgServiceRequest>(create);
  static EnsureAdminBgServiceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get configContent => $_getSZ(0);
  @$pb.TagNumber(1)
  set configContent($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConfigContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigContent() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get configName => $_getSZ(1);
  @$pb.TagNumber(2)
  set configName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasConfigName() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfigName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get settingsJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set settingsJson($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSettingsJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearSettingsJson() => clearField(3);

  @$pb.TagNumber(4)
  $core.Map<$core.String, $core.List<$core.int>> get resources => $_getMap(3);

  @$pb.TagNumber(5)
  $core.bool get disableMemoryLimit => $_getBF(4);
  @$pb.TagNumber(5)
  set disableMemoryLimit($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDisableMemoryLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisableMemoryLimit() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get ownerPid => $_getIZ(5);
  @$pb.TagNumber(6)
  set ownerPid($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasOwnerPid() => $_has(5);
  @$pb.TagNumber(6)
  void clearOwnerPid() => clearField(6);

  /// Absolute path to this app's HiddifyCli / HiddifyCli.exe (used for elevate install).
  @$pb.TagNumber(7)
  $core.String get cliPath => $_getSZ(6);
  @$pb.TagNumber(7)
  set cliPath($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasCliPath() => $_has(6);
  @$pb.TagNumber(7)
  void clearCliPath() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get ownerUser => $_getSZ(7);
  @$pb.TagNumber(8)
  set ownerUser($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasOwnerUser() => $_has(7);
  @$pb.TagNumber(8)
  void clearOwnerUser() => clearField(8);
}

class EnsureAdminBgServiceEvent extends $pb.GeneratedMessage {
  factory EnsureAdminBgServiceEvent({
    EnsureAdminBgServiceProgress? progress,
    $core.String? message,
    $core.int? servicePort,
  }) {
    final $result = create();
    if (progress != null) {
      $result.progress = progress;
    }
    if (message != null) {
      $result.message = message;
    }
    if (servicePort != null) {
      $result.servicePort = servicePort;
    }
    return $result;
  }
  EnsureAdminBgServiceEvent._() : super();
  factory EnsureAdminBgServiceEvent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EnsureAdminBgServiceEvent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EnsureAdminBgServiceEvent', package: const $pb.PackageName(_omitMessageNames ? '' : 'hcore'), createEmptyInstance: create)
    ..e<EnsureAdminBgServiceProgress>(1, _omitFieldNames ? '' : 'progress', $pb.PbFieldType.OE, defaultOrMaker: EnsureAdminBgServiceProgress.ENSURE_ADMIN_BG_WAITING_FOR_ELEVATION, valueOf: EnsureAdminBgServiceProgress.valueOf, enumValues: EnsureAdminBgServiceProgress.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'servicePort', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EnsureAdminBgServiceEvent clone() => EnsureAdminBgServiceEvent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EnsureAdminBgServiceEvent copyWith(void Function(EnsureAdminBgServiceEvent) updates) => super.copyWith((message) => updates(message as EnsureAdminBgServiceEvent)) as EnsureAdminBgServiceEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnsureAdminBgServiceEvent create() => EnsureAdminBgServiceEvent._();
  EnsureAdminBgServiceEvent createEmptyInstance() => create();
  static $pb.PbList<EnsureAdminBgServiceEvent> createRepeated() => $pb.PbList<EnsureAdminBgServiceEvent>();
  @$core.pragma('dart2js:noInline')
  static EnsureAdminBgServiceEvent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EnsureAdminBgServiceEvent>(create);
  static EnsureAdminBgServiceEvent? _defaultInstance;

  @$pb.TagNumber(1)
  EnsureAdminBgServiceProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(EnsureAdminBgServiceProgress v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get servicePort => $_getIZ(2);
  @$pb.TagNumber(3)
  set servicePort($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasServicePort() => $_has(2);
  @$pb.TagNumber(3)
  void clearServicePort() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
