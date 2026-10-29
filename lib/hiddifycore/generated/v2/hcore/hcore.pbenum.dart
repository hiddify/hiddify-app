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

import 'package:protobuf/protobuf.dart' as $pb;

/// The lifecycle is owned by the core: STOPPED -> STARTING -> WAITING -> STARTED, and STOPPING
/// from any running state. A start is accepted only from STOPPED. While the core runs, its
/// monitoring moves it between WAITING, STARTED and NO_AVAILABLE_PROXIES.
class CoreStates extends $pb.ProtobufEnum {
  static const CoreStates STOPPED = CoreStates._(0, _omitEnumNames ? '' : 'STOPPED');
  static const CoreStates STARTING = CoreStates._(1, _omitEnumNames ? '' : 'STARTING');
  static const CoreStates STARTED = CoreStates._(2, _omitEnumNames ? '' : 'STARTED');
  static const CoreStates STOPPING = CoreStates._(3, _omitEnumNames ? '' : 'STOPPING');
  static const CoreStates HOT_RELOADING = CoreStates._(4, _omitEnumNames ? '' : 'HOT_RELOADING');
  static const CoreStates WAITING = CoreStates._(5, _omitEnumNames ? '' : 'WAITING');
  static const CoreStates NO_AVAILABLE_PROXIES = CoreStates._(6, _omitEnumNames ? '' : 'NO_AVAILABLE_PROXIES');

  static const $core.List<CoreStates> values = <CoreStates> [
    STOPPED,
    STARTING,
    STARTED,
    STOPPING,
    HOT_RELOADING,
    WAITING,
    NO_AVAILABLE_PROXIES,
  ];

  static final $core.Map<$core.int, CoreStates> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CoreStates? valueOf($core.int value) => _byValue[value];

  const CoreStates._($core.int v, $core.String n) : super(v, n);
}

class MessageType extends $pb.ProtobufEnum {
  static const MessageType EMPTY = MessageType._(0, _omitEnumNames ? '' : 'EMPTY');
  static const MessageType EMPTY_CONFIGURATION = MessageType._(1, _omitEnumNames ? '' : 'EMPTY_CONFIGURATION');
  static const MessageType START_COMMAND_SERVER = MessageType._(2, _omitEnumNames ? '' : 'START_COMMAND_SERVER');
  static const MessageType CREATE_SERVICE = MessageType._(3, _omitEnumNames ? '' : 'CREATE_SERVICE');
  static const MessageType START_SERVICE = MessageType._(4, _omitEnumNames ? '' : 'START_SERVICE');
  static const MessageType UNEXPECTED_ERROR = MessageType._(5, _omitEnumNames ? '' : 'UNEXPECTED_ERROR');
  static const MessageType ALREADY_STARTED = MessageType._(6, _omitEnumNames ? '' : 'ALREADY_STARTED');
  static const MessageType ALREADY_STOPPED = MessageType._(7, _omitEnumNames ? '' : 'ALREADY_STOPPED');
  static const MessageType INSTANCE_NOT_FOUND = MessageType._(8, _omitEnumNames ? '' : 'INSTANCE_NOT_FOUND');
  static const MessageType INSTANCE_NOT_STOPPED = MessageType._(9, _omitEnumNames ? '' : 'INSTANCE_NOT_STOPPED');
  static const MessageType INSTANCE_NOT_STARTED = MessageType._(10, _omitEnumNames ? '' : 'INSTANCE_NOT_STARTED');
  static const MessageType ERROR_BUILDING_CONFIG = MessageType._(11, _omitEnumNames ? '' : 'ERROR_BUILDING_CONFIG');
  static const MessageType ERROR_PARSING_CONFIG = MessageType._(12, _omitEnumNames ? '' : 'ERROR_PARSING_CONFIG');
  static const MessageType ERROR_READING_CONFIG = MessageType._(13, _omitEnumNames ? '' : 'ERROR_READING_CONFIG');
  static const MessageType ERROR_EXTENSION = MessageType._(14, _omitEnumNames ? '' : 'ERROR_EXTENSION');
  static const MessageType HOT_RELOAD_FAILED = MessageType._(15, _omitEnumNames ? '' : 'HOT_RELOAD_FAILED');

  static const $core.List<MessageType> values = <MessageType> [
    EMPTY,
    EMPTY_CONFIGURATION,
    START_COMMAND_SERVER,
    CREATE_SERVICE,
    START_SERVICE,
    UNEXPECTED_ERROR,
    ALREADY_STARTED,
    ALREADY_STOPPED,
    INSTANCE_NOT_FOUND,
    INSTANCE_NOT_STOPPED,
    INSTANCE_NOT_STARTED,
    ERROR_BUILDING_CONFIG,
    ERROR_PARSING_CONFIG,
    ERROR_READING_CONFIG,
    ERROR_EXTENSION,
    HOT_RELOAD_FAILED,
  ];

  static final $core.Map<$core.int, MessageType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MessageType? valueOf($core.int value) => _byValue[value];

  const MessageType._($core.int v, $core.String n) : super(v, n);
}

class SetupMode extends $pb.ProtobufEnum {
  static const SetupMode OLD = SetupMode._(0, _omitEnumNames ? '' : 'OLD');
  static const SetupMode GRPC_NORMAL = SetupMode._(1, _omitEnumNames ? '' : 'GRPC_NORMAL');
  static const SetupMode GRPC_BACKGROUND = SetupMode._(2, _omitEnumNames ? '' : 'GRPC_BACKGROUND');
  static const SetupMode GRPC_NORMAL_INSECURE = SetupMode._(3, _omitEnumNames ? '' : 'GRPC_NORMAL_INSECURE');
  static const SetupMode GRPC_BACKGROUND_INSECURE = SetupMode._(4, _omitEnumNames ? '' : 'GRPC_BACKGROUND_INSECURE');

  static const $core.List<SetupMode> values = <SetupMode> [
    OLD,
    GRPC_NORMAL,
    GRPC_BACKGROUND,
    GRPC_NORMAL_INSECURE,
    GRPC_BACKGROUND_INSECURE,
  ];

  static final $core.Map<$core.int, SetupMode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SetupMode? valueOf($core.int value) => _byValue[value];

  const SetupMode._($core.int v, $core.String n) : super(v, n);
}

class LogLevel extends $pb.ProtobufEnum {
  static const LogLevel TRACE = LogLevel._(0, _omitEnumNames ? '' : 'TRACE');
  static const LogLevel DEBUG = LogLevel._(1, _omitEnumNames ? '' : 'DEBUG');
  static const LogLevel INFO = LogLevel._(2, _omitEnumNames ? '' : 'INFO');
  static const LogLevel WARNING = LogLevel._(3, _omitEnumNames ? '' : 'WARNING');
  static const LogLevel ERROR = LogLevel._(4, _omitEnumNames ? '' : 'ERROR');
  static const LogLevel FATAL = LogLevel._(5, _omitEnumNames ? '' : 'FATAL');

  static const $core.List<LogLevel> values = <LogLevel> [
    TRACE,
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    FATAL,
  ];

  static final $core.Map<$core.int, LogLevel> _byValue = $pb.ProtobufEnum.initByValue(values);
  static LogLevel? valueOf($core.int value) => _byValue[value];

  const LogLevel._($core.int v, $core.String n) : super(v, n);
}

class LogType extends $pb.ProtobufEnum {
  static const LogType CORE = LogType._(0, _omitEnumNames ? '' : 'CORE');
  static const LogType SERVICE = LogType._(1, _omitEnumNames ? '' : 'SERVICE');
  static const LogType CONFIG = LogType._(2, _omitEnumNames ? '' : 'CONFIG');

  static const $core.List<LogType> values = <LogType> [
    CORE,
    SERVICE,
    CONFIG,
  ];

  static final $core.Map<$core.int, LogType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static LogType? valueOf($core.int value) => _byValue[value];

  const LogType._($core.int v, $core.String n) : super(v, n);
}

class AdminPreference extends $pb.ProtobufEnum {
  static const AdminPreference ADMIN_PREFERENCE_UNSET = AdminPreference._(0, _omitEnumNames ? '' : 'ADMIN_PREFERENCE_UNSET');
  static const AdminPreference ADMIN_PREFERENCE_PREFER_ADMIN = AdminPreference._(1, _omitEnumNames ? '' : 'ADMIN_PREFERENCE_PREFER_ADMIN');
  static const AdminPreference ADMIN_PREFERENCE_PREFER_NO_ADMIN = AdminPreference._(2, _omitEnumNames ? '' : 'ADMIN_PREFERENCE_PREFER_NO_ADMIN');

  static const $core.List<AdminPreference> values = <AdminPreference> [
    ADMIN_PREFERENCE_UNSET,
    ADMIN_PREFERENCE_PREFER_ADMIN,
    ADMIN_PREFERENCE_PREFER_NO_ADMIN,
  ];

  static final $core.Map<$core.int, AdminPreference> _byValue = $pb.ProtobufEnum.initByValue(values);
  static AdminPreference? valueOf($core.int value) => _byValue[value];

  const AdminPreference._($core.int v, $core.String n) : super(v, n);
}

class AdminBgServiceDecision extends $pb.ProtobufEnum {
  static const AdminBgServiceDecision ADMIN_BG_SERVICE_NO = AdminBgServiceDecision._(0, _omitEnumNames ? '' : 'ADMIN_BG_SERVICE_NO');
  static const AdminBgServiceDecision ADMIN_BG_SERVICE_ALREADY_CONNECTED = AdminBgServiceDecision._(1, _omitEnumNames ? '' : 'ADMIN_BG_SERVICE_ALREADY_CONNECTED');
  static const AdminBgServiceDecision ADMIN_BG_SERVICE_NEEDS_ADMIN = AdminBgServiceDecision._(2, _omitEnumNames ? '' : 'ADMIN_BG_SERVICE_NEEDS_ADMIN');
  static const AdminBgServiceDecision ADMIN_BG_SERVICE_OPTIONAL_PROXY_NEED_ADMIN = AdminBgServiceDecision._(3, _omitEnumNames ? '' : 'ADMIN_BG_SERVICE_OPTIONAL_PROXY_NEED_ADMIN');

  static const $core.List<AdminBgServiceDecision> values = <AdminBgServiceDecision> [
    ADMIN_BG_SERVICE_NO,
    ADMIN_BG_SERVICE_ALREADY_CONNECTED,
    ADMIN_BG_SERVICE_NEEDS_ADMIN,
    ADMIN_BG_SERVICE_OPTIONAL_PROXY_NEED_ADMIN,
  ];

  static final $core.Map<$core.int, AdminBgServiceDecision> _byValue = $pb.ProtobufEnum.initByValue(values);
  static AdminBgServiceDecision? valueOf($core.int value) => _byValue[value];

  const AdminBgServiceDecision._($core.int v, $core.String n) : super(v, n);
}

class EnsureAdminBgServiceProgress extends $pb.ProtobufEnum {
  static const EnsureAdminBgServiceProgress ENSURE_ADMIN_BG_WAITING_FOR_ELEVATION = EnsureAdminBgServiceProgress._(0, _omitEnumNames ? '' : 'ENSURE_ADMIN_BG_WAITING_FOR_ELEVATION');
  static const EnsureAdminBgServiceProgress ENSURE_ADMIN_BG_SERVICE_STARTING = EnsureAdminBgServiceProgress._(1, _omitEnumNames ? '' : 'ENSURE_ADMIN_BG_SERVICE_STARTING');
  static const EnsureAdminBgServiceProgress ENSURE_ADMIN_BG_SERVICE_CONNECTED = EnsureAdminBgServiceProgress._(2, _omitEnumNames ? '' : 'ENSURE_ADMIN_BG_SERVICE_CONNECTED');
  static const EnsureAdminBgServiceProgress ENSURE_ADMIN_BG_FAILED_PERMISSION_DENIED = EnsureAdminBgServiceProgress._(3, _omitEnumNames ? '' : 'ENSURE_ADMIN_BG_FAILED_PERMISSION_DENIED');
  static const EnsureAdminBgServiceProgress ENSURE_ADMIN_BG_FAILED_OTHER = EnsureAdminBgServiceProgress._(4, _omitEnumNames ? '' : 'ENSURE_ADMIN_BG_FAILED_OTHER');

  static const $core.List<EnsureAdminBgServiceProgress> values = <EnsureAdminBgServiceProgress> [
    ENSURE_ADMIN_BG_WAITING_FOR_ELEVATION,
    ENSURE_ADMIN_BG_SERVICE_STARTING,
    ENSURE_ADMIN_BG_SERVICE_CONNECTED,
    ENSURE_ADMIN_BG_FAILED_PERMISSION_DENIED,
    ENSURE_ADMIN_BG_FAILED_OTHER,
  ];

  static final $core.Map<$core.int, EnsureAdminBgServiceProgress> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EnsureAdminBgServiceProgress? valueOf($core.int value) => _byValue[value];

  const EnsureAdminBgServiceProgress._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
