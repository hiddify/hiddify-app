///
//  Generated code. Do not modify.
//  source: v2/hcore/hcore.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../google/protobuf/timestamp.pb.dart' as $7;

import 'hcore.pbenum.dart';
import '../hcommon/common.pbenum.dart' as $1;

export 'hcore.pbenum.dart';

class CoreInfoResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CoreInfoResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..e<CoreStates>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'coreState', $pb.PbFieldType.OE, defaultOrMaker: CoreStates.STOPPED, valueOf: CoreStates.valueOf, enumValues: CoreStates.values)
    ..e<MessageType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'messageType', $pb.PbFieldType.OE, defaultOrMaker: MessageType.EMPTY, valueOf: MessageType.valueOf, enumValues: MessageType.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..hasRequiredFields = false
  ;

  CoreInfoResponse._() : super();
  factory CoreInfoResponse({
    CoreStates? coreState,
    MessageType? messageType,
    $core.String? message,
  }) {
    final _result = create();
    if (coreState != null) {
      _result.coreState = coreState;
    }
    if (messageType != null) {
      _result.messageType = messageType;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory CoreInfoResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CoreInfoResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CoreInfoResponse clone() => CoreInfoResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CoreInfoResponse copyWith(void Function(CoreInfoResponse) updates) => super.copyWith((message) => updates(message as CoreInfoResponse)) as CoreInfoResponse; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StartRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'configPath')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'configContent')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableMemoryLimit')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'delayStart')
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enableOldCommandServer')
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enableRawConfig')
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'configName')
    ..hasRequiredFields = false
  ;

  StartRequest._() : super();
  factory StartRequest({
    $core.String? configPath,
    $core.String? configContent,
    $core.bool? disableMemoryLimit,
    $core.bool? delayStart,
    $core.bool? enableOldCommandServer,
    $core.bool? enableRawConfig,
    $core.String? configName,
  }) {
    final _result = create();
    if (configPath != null) {
      _result.configPath = configPath;
    }
    if (configContent != null) {
      _result.configContent = configContent;
    }
    if (disableMemoryLimit != null) {
      _result.disableMemoryLimit = disableMemoryLimit;
    }
    if (delayStart != null) {
      _result.delayStart = delayStart;
    }
    if (enableOldCommandServer != null) {
      _result.enableOldCommandServer = enableOldCommandServer;
    }
    if (enableRawConfig != null) {
      _result.enableRawConfig = enableRawConfig;
    }
    if (configName != null) {
      _result.configName = configName;
    }
    return _result;
  }
  factory StartRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StartRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StartRequest clone() => StartRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StartRequest copyWith(void Function(StartRequest) updates) => super.copyWith((message) => updates(message as StartRequest)) as StartRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CloseRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..e<SetupMode>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mode', $pb.PbFieldType.OE, defaultOrMaker: SetupMode.OLD, valueOf: SetupMode.valueOf, enumValues: SetupMode.values)
    ..hasRequiredFields = false
  ;

  CloseRequest._() : super();
  factory CloseRequest({
    SetupMode? mode,
  }) {
    final _result = create();
    if (mode != null) {
      _result.mode = mode;
    }
    return _result;
  }
  factory CloseRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CloseRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CloseRequest clone() => CloseRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CloseRequest copyWith(void Function(CloseRequest) updates) => super.copyWith((message) => updates(message as CloseRequest)) as CloseRequest; // ignore: deprecated_member_use
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

class SetupRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SetupRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'basePath')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workingDir')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tempDir')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'flutterStatusPort')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'listen')
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'secret')
    ..aOB(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'debug')
    ..e<SetupMode>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mode', $pb.PbFieldType.OE, defaultOrMaker: SetupMode.OLD, valueOf: SetupMode.valueOf, enumValues: SetupMode.values)
    ..aOB(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fixAndroidStack')
    ..hasRequiredFields = false
  ;

  SetupRequest._() : super();
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
    final _result = create();
    if (basePath != null) {
      _result.basePath = basePath;
    }
    if (workingDir != null) {
      _result.workingDir = workingDir;
    }
    if (tempDir != null) {
      _result.tempDir = tempDir;
    }
    if (flutterStatusPort != null) {
      _result.flutterStatusPort = flutterStatusPort;
    }
    if (listen != null) {
      _result.listen = listen;
    }
    if (secret != null) {
      _result.secret = secret;
    }
    if (debug != null) {
      _result.debug = debug;
    }
    if (mode != null) {
      _result.mode = mode;
    }
    if (fixAndroidStack != null) {
      _result.fixAndroidStack = fixAndroidStack;
    }
    return _result;
  }
  factory SetupRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetupRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetupRequest clone() => SetupRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetupRequest copyWith(void Function(SetupRequest) updates) => super.copyWith((message) => updates(message as SetupRequest)) as SetupRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SystemInfo', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aInt64(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'memory')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'goroutines', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'connectionsIn', $pb.PbFieldType.O3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'connectionsOut', $pb.PbFieldType.O3)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trafficAvailable')
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'uplink')
    ..aInt64(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'downlink')
    ..aInt64(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'uplinkTotal')
    ..aInt64(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'downlinkTotal')
    ..aOS(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentOutbound')
    ..aOS(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentProfile')
    ..hasRequiredFields = false
  ;

  SystemInfo._() : super();
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
    final _result = create();
    if (memory != null) {
      _result.memory = memory;
    }
    if (goroutines != null) {
      _result.goroutines = goroutines;
    }
    if (connectionsIn != null) {
      _result.connectionsIn = connectionsIn;
    }
    if (connectionsOut != null) {
      _result.connectionsOut = connectionsOut;
    }
    if (trafficAvailable != null) {
      _result.trafficAvailable = trafficAvailable;
    }
    if (uplink != null) {
      _result.uplink = uplink;
    }
    if (downlink != null) {
      _result.downlink = downlink;
    }
    if (uplinkTotal != null) {
      _result.uplinkTotal = uplinkTotal;
    }
    if (downlinkTotal != null) {
      _result.downlinkTotal = downlinkTotal;
    }
    if (currentOutbound != null) {
      _result.currentOutbound = currentOutbound;
    }
    if (currentProfile != null) {
      _result.currentProfile = currentProfile;
    }
    return _result;
  }
  factory SystemInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SystemInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SystemInfo clone() => SystemInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SystemInfo copyWith(void Function(SystemInfo) updates) => super.copyWith((message) => updates(message as SystemInfo)) as SystemInfo; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'OutboundInfo', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tag')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..aOM<$7.Timestamp>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'urlTestTime', subBuilder: $7.Timestamp.create)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'urlTestDelay', $pb.PbFieldType.O3)
    ..aOM<IpInfo>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ipinfo', subBuilder: IpInfo.create)
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isSelected')
    ..aOB(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isGroup')
    ..aOB(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isSecure')
    ..aOB(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isVisible')
    ..a<$core.int>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'port', $pb.PbFieldType.OU3)
    ..aOS(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'host')
    ..aOS(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tagDisplay')
    ..aOS(13, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupSelectedTag')
    ..aOS(14, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupSelectedTagDisplay')
    ..aInt64(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'upload')
    ..aInt64(16, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'download')
    ..hasRequiredFields = false
  ;

  OutboundInfo._() : super();
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
    $core.String? groupSelectedTag,
    $core.String? groupSelectedTagDisplay,
    $fixnum.Int64? upload,
    $fixnum.Int64? download,
  }) {
    final _result = create();
    if (tag != null) {
      _result.tag = tag;
    }
    if (type != null) {
      _result.type = type;
    }
    if (urlTestTime != null) {
      _result.urlTestTime = urlTestTime;
    }
    if (urlTestDelay != null) {
      _result.urlTestDelay = urlTestDelay;
    }
    if (ipinfo != null) {
      _result.ipinfo = ipinfo;
    }
    if (isSelected != null) {
      _result.isSelected = isSelected;
    }
    if (isGroup != null) {
      _result.isGroup = isGroup;
    }
    if (isSecure != null) {
      _result.isSecure = isSecure;
    }
    if (isVisible != null) {
      _result.isVisible = isVisible;
    }
    if (port != null) {
      _result.port = port;
    }
    if (host != null) {
      _result.host = host;
    }
    if (tagDisplay != null) {
      _result.tagDisplay = tagDisplay;
    }
    if (groupSelectedTag != null) {
      _result.groupSelectedTag = groupSelectedTag;
    }
    if (groupSelectedTagDisplay != null) {
      _result.groupSelectedTagDisplay = groupSelectedTagDisplay;
    }
    if (upload != null) {
      _result.upload = upload;
    }
    if (download != null) {
      _result.download = download;
    }
    return _result;
  }
  factory OutboundInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutboundInfo clone() => OutboundInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutboundInfo copyWith(void Function(OutboundInfo) updates) => super.copyWith((message) => updates(message as OutboundInfo)) as OutboundInfo; // ignore: deprecated_member_use
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
}

class IpInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'IpInfo', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ip')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'country_code')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'region')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'city')
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'asn', $pb.PbFieldType.O3)
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'org')
    ..a<$core.double>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'latitude', $pb.PbFieldType.OD)
    ..a<$core.double>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'longitude', $pb.PbFieldType.OD)
    ..aOS(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postal_code')
    ..hasRequiredFields = false
  ;

  IpInfo._() : super();
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
    final _result = create();
    if (ip != null) {
      _result.ip = ip;
    }
    if (countryCode != null) {
      _result.countryCode = countryCode;
    }
    if (region != null) {
      _result.region = region;
    }
    if (city != null) {
      _result.city = city;
    }
    if (asn != null) {
      _result.asn = asn;
    }
    if (org != null) {
      _result.org = org;
    }
    if (latitude != null) {
      _result.latitude = latitude;
    }
    if (longitude != null) {
      _result.longitude = longitude;
    }
    if (postalCode != null) {
      _result.postalCode = postalCode;
    }
    return _result;
  }
  factory IpInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IpInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IpInfo clone() => IpInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IpInfo copyWith(void Function(IpInfo) updates) => super.copyWith((message) => updates(message as IpInfo)) as IpInfo; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'OutboundGroup', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tag')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'selected')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'selectable')
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'IsExpand', protoName: 'Is_expand')
    ..pc<OutboundInfo>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: OutboundInfo.create)
    ..hasRequiredFields = false
  ;

  OutboundGroup._() : super();
  factory OutboundGroup({
    $core.String? tag,
    $core.String? type,
    $core.String? selected,
    $core.bool? selectable,
    $core.bool? isExpand,
    $core.Iterable<OutboundInfo>? items,
  }) {
    final _result = create();
    if (tag != null) {
      _result.tag = tag;
    }
    if (type != null) {
      _result.type = type;
    }
    if (selected != null) {
      _result.selected = selected;
    }
    if (selectable != null) {
      _result.selectable = selectable;
    }
    if (isExpand != null) {
      _result.isExpand = isExpand;
    }
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory OutboundGroup.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundGroup.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutboundGroup clone() => OutboundGroup()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutboundGroup copyWith(void Function(OutboundGroup) updates) => super.copyWith((message) => updates(message as OutboundGroup)) as OutboundGroup; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'OutboundGroupList', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..pc<OutboundGroup>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: OutboundGroup.create)
    ..hasRequiredFields = false
  ;

  OutboundGroupList._() : super();
  factory OutboundGroupList({
    $core.Iterable<OutboundGroup>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory OutboundGroupList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundGroupList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutboundGroupList clone() => OutboundGroupList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutboundGroupList copyWith(void Function(OutboundGroupList) updates) => super.copyWith((message) => updates(message as OutboundGroupList)) as OutboundGroupList; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WarpAccount', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accessToken')
    ..hasRequiredFields = false
  ;

  WarpAccount._() : super();
  factory WarpAccount({
    $core.String? accountId,
    $core.String? accessToken,
  }) {
    final _result = create();
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (accessToken != null) {
      _result.accessToken = accessToken;
    }
    return _result;
  }
  factory WarpAccount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpAccount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpAccount clone() => WarpAccount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpAccount copyWith(void Function(WarpAccount) updates) => super.copyWith((message) => updates(message as WarpAccount)) as WarpAccount; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WarpWireguardConfig', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'private-key', protoName: 'private_key')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'local-address-ipv4', protoName: 'local_address_ipv4')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'local-address-ipv6', protoName: 'local_address_ipv6')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'peer-public-key', protoName: 'peer_public_key')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'client-id', protoName: 'client_id')
    ..hasRequiredFields = false
  ;

  WarpWireguardConfig._() : super();
  factory WarpWireguardConfig({
    $core.String? privateKey,
    $core.String? localAddressIpv4,
    $core.String? localAddressIpv6,
    $core.String? peerPublicKey,
    $core.String? clientId,
  }) {
    final _result = create();
    if (privateKey != null) {
      _result.privateKey = privateKey;
    }
    if (localAddressIpv4 != null) {
      _result.localAddressIpv4 = localAddressIpv4;
    }
    if (localAddressIpv6 != null) {
      _result.localAddressIpv6 = localAddressIpv6;
    }
    if (peerPublicKey != null) {
      _result.peerPublicKey = peerPublicKey;
    }
    if (clientId != null) {
      _result.clientId = clientId;
    }
    return _result;
  }
  factory WarpWireguardConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpWireguardConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpWireguardConfig clone() => WarpWireguardConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpWireguardConfig copyWith(void Function(WarpWireguardConfig) updates) => super.copyWith((message) => updates(message as WarpWireguardConfig)) as WarpWireguardConfig; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WarpGenerationResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOM<WarpAccount>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'account', subBuilder: WarpAccount.create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'log')
    ..aOM<WarpWireguardConfig>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'config', subBuilder: WarpWireguardConfig.create)
    ..hasRequiredFields = false
  ;

  WarpGenerationResponse._() : super();
  factory WarpGenerationResponse({
    WarpAccount? account,
    $core.String? log,
    WarpWireguardConfig? config,
  }) {
    final _result = create();
    if (account != null) {
      _result.account = account;
    }
    if (log != null) {
      _result.log = log;
    }
    if (config != null) {
      _result.config = config;
    }
    return _result;
  }
  factory WarpGenerationResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WarpGenerationResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WarpGenerationResponse clone() => WarpGenerationResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WarpGenerationResponse copyWith(void Function(WarpGenerationResponse) updates) => super.copyWith((message) => updates(message as WarpGenerationResponse)) as WarpGenerationResponse; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SystemProxyStatus', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'available')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enabled')
    ..hasRequiredFields = false
  ;

  SystemProxyStatus._() : super();
  factory SystemProxyStatus({
    $core.bool? available,
    $core.bool? enabled,
  }) {
    final _result = create();
    if (available != null) {
      _result.available = available;
    }
    if (enabled != null) {
      _result.enabled = enabled;
    }
    return _result;
  }
  factory SystemProxyStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SystemProxyStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SystemProxyStatus clone() => SystemProxyStatus()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SystemProxyStatus copyWith(void Function(SystemProxyStatus) updates) => super.copyWith((message) => updates(message as SystemProxyStatus)) as SystemProxyStatus; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ParseRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'content')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'configPath')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tempPath')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'debug')
    ..hasRequiredFields = false
  ;

  ParseRequest._() : super();
  factory ParseRequest({
    $core.String? content,
    $core.String? configPath,
    $core.String? tempPath,
    $core.bool? debug,
  }) {
    final _result = create();
    if (content != null) {
      _result.content = content;
    }
    if (configPath != null) {
      _result.configPath = configPath;
    }
    if (tempPath != null) {
      _result.tempPath = tempPath;
    }
    if (debug != null) {
      _result.debug = debug;
    }
    return _result;
  }
  factory ParseRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseRequest clone() => ParseRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseRequest copyWith(void Function(ParseRequest) updates) => super.copyWith((message) => updates(message as ParseRequest)) as ParseRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ParseResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..e<$1.ResponseCode>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'responseCode', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'content')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..hasRequiredFields = false
  ;

  ParseResponse._() : super();
  factory ParseResponse({
    $1.ResponseCode? responseCode,
    $core.String? content,
    $core.String? message,
  }) {
    final _result = create();
    if (responseCode != null) {
      _result.responseCode = responseCode;
    }
    if (content != null) {
      _result.content = content;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory ParseResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseResponse clone() => ParseResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseResponse copyWith(void Function(ParseResponse) updates) => super.copyWith((message) => updates(message as ParseResponse)) as ParseResponse; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ChangeHiddifySettingsRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hiddifySettingsJson')
    ..hasRequiredFields = false
  ;

  ChangeHiddifySettingsRequest._() : super();
  factory ChangeHiddifySettingsRequest({
    $core.String? hiddifySettingsJson,
  }) {
    final _result = create();
    if (hiddifySettingsJson != null) {
      _result.hiddifySettingsJson = hiddifySettingsJson;
    }
    return _result;
  }
  factory ChangeHiddifySettingsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChangeHiddifySettingsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChangeHiddifySettingsRequest clone() => ChangeHiddifySettingsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChangeHiddifySettingsRequest copyWith(void Function(ChangeHiddifySettingsRequest) updates) => super.copyWith((message) => updates(message as ChangeHiddifySettingsRequest)) as ChangeHiddifySettingsRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GenerateConfigRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'path')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tempPath')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'debug')
    ..hasRequiredFields = false
  ;

  GenerateConfigRequest._() : super();
  factory GenerateConfigRequest({
    $core.String? path,
    $core.String? tempPath,
    $core.bool? debug,
  }) {
    final _result = create();
    if (path != null) {
      _result.path = path;
    }
    if (tempPath != null) {
      _result.tempPath = tempPath;
    }
    if (debug != null) {
      _result.debug = debug;
    }
    return _result;
  }
  factory GenerateConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GenerateConfigRequest clone() => GenerateConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GenerateConfigRequest copyWith(void Function(GenerateConfigRequest) updates) => super.copyWith((message) => updates(message as GenerateConfigRequest)) as GenerateConfigRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GenerateConfigResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'configContent')
    ..hasRequiredFields = false
  ;

  GenerateConfigResponse._() : super();
  factory GenerateConfigResponse({
    $core.String? configContent,
  }) {
    final _result = create();
    if (configContent != null) {
      _result.configContent = configContent;
    }
    return _result;
  }
  factory GenerateConfigResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateConfigResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GenerateConfigResponse clone() => GenerateConfigResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GenerateConfigResponse copyWith(void Function(GenerateConfigResponse) updates) => super.copyWith((message) => updates(message as GenerateConfigResponse)) as GenerateConfigResponse; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOutboundRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupTag')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outboundTag')
    ..hasRequiredFields = false
  ;

  SelectOutboundRequest._() : super();
  factory SelectOutboundRequest({
    $core.String? groupTag,
    $core.String? outboundTag,
  }) {
    final _result = create();
    if (groupTag != null) {
      _result.groupTag = groupTag;
    }
    if (outboundTag != null) {
      _result.outboundTag = outboundTag;
    }
    return _result;
  }
  factory SelectOutboundRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOutboundRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOutboundRequest clone() => SelectOutboundRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOutboundRequest copyWith(void Function(SelectOutboundRequest) updates) => super.copyWith((message) => updates(message as SelectOutboundRequest)) as SelectOutboundRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UrlTestRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tag')
    ..hasRequiredFields = false
  ;

  UrlTestRequest._() : super();
  factory UrlTestRequest({
    $core.String? tag,
  }) {
    final _result = create();
    if (tag != null) {
      _result.tag = tag;
    }
    return _result;
  }
  factory UrlTestRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UrlTestRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UrlTestRequest clone() => UrlTestRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UrlTestRequest copyWith(void Function(UrlTestRequest) updates) => super.copyWith((message) => updates(message as UrlTestRequest)) as UrlTestRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GenerateWarpConfigRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'licenseKey')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accessToken')
    ..hasRequiredFields = false
  ;

  GenerateWarpConfigRequest._() : super();
  factory GenerateWarpConfigRequest({
    $core.String? licenseKey,
    $core.String? accountId,
    $core.String? accessToken,
  }) {
    final _result = create();
    if (licenseKey != null) {
      _result.licenseKey = licenseKey;
    }
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (accessToken != null) {
      _result.accessToken = accessToken;
    }
    return _result;
  }
  factory GenerateWarpConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateWarpConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GenerateWarpConfigRequest clone() => GenerateWarpConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GenerateWarpConfigRequest copyWith(void Function(GenerateWarpConfigRequest) updates) => super.copyWith((message) => updates(message as GenerateWarpConfigRequest)) as GenerateWarpConfigRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SetSystemProxyEnabledRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isEnabled')
    ..hasRequiredFields = false
  ;

  SetSystemProxyEnabledRequest._() : super();
  factory SetSystemProxyEnabledRequest({
    $core.bool? isEnabled,
  }) {
    final _result = create();
    if (isEnabled != null) {
      _result.isEnabled = isEnabled;
    }
    return _result;
  }
  factory SetSystemProxyEnabledRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetSystemProxyEnabledRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetSystemProxyEnabledRequest clone() => SetSystemProxyEnabledRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetSystemProxyEnabledRequest copyWith(void Function(SetSystemProxyEnabledRequest) updates) => super.copyWith((message) => updates(message as SetSystemProxyEnabledRequest)) as SetSystemProxyEnabledRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'LogMessage', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..e<LogLevel>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'level', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.TRACE, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..e<LogType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: LogType.CORE, valueOf: LogType.valueOf, enumValues: LogType.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..aOM<$7.Timestamp>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'time', subBuilder: $7.Timestamp.create)
    ..hasRequiredFields = false
  ;

  LogMessage._() : super();
  factory LogMessage({
    LogLevel? level,
    LogType? type,
    $core.String? message,
    $7.Timestamp? time,
  }) {
    final _result = create();
    if (level != null) {
      _result.level = level;
    }
    if (type != null) {
      _result.type = type;
    }
    if (message != null) {
      _result.message = message;
    }
    if (time != null) {
      _result.time = time;
    }
    return _result;
  }
  factory LogMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogMessage clone() => LogMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogMessage copyWith(void Function(LogMessage) updates) => super.copyWith((message) => updates(message as LogMessage)) as LogMessage; // ignore: deprecated_member_use
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

class LogRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'LogRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..e<LogLevel>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'level', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.TRACE, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..hasRequiredFields = false
  ;

  LogRequest._() : super();
  factory LogRequest({
    LogLevel? level,
  }) {
    final _result = create();
    if (level != null) {
      _result.level = level;
    }
    return _result;
  }
  factory LogRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogRequest clone() => LogRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogRequest copyWith(void Function(LogRequest) updates) => super.copyWith((message) => updates(message as LogRequest)) as LogRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StopRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'hcore'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  StopRequest._() : super();
  factory StopRequest() => create();
  factory StopRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StopRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StopRequest clone() => StopRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StopRequest copyWith(void Function(StopRequest) updates) => super.copyWith((message) => updates(message as StopRequest)) as StopRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StopRequest create() => StopRequest._();
  StopRequest createEmptyInstance() => create();
  static $pb.PbList<StopRequest> createRepeated() => $pb.PbList<StopRequest>();
  @$core.pragma('dart2js:noInline')
  static StopRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StopRequest>(create);
  static StopRequest? _defaultInstance;
}

