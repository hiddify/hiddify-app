///
//  Generated code. Do not modify.
//  source: v2/hcore/hcore.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class CoreStates extends $pb.ProtobufEnum {
  static const CoreStates STOPPED = CoreStates._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'STOPPED');
  static const CoreStates STARTING = CoreStates._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'STARTING');
  static const CoreStates STARTED = CoreStates._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'STARTED');
  static const CoreStates STOPPING = CoreStates._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'STOPPING');

  static const $core.List<CoreStates> values = <CoreStates> [
    STOPPED,
    STARTING,
    STARTED,
    STOPPING,
  ];

  static final $core.Map<$core.int, CoreStates> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CoreStates? valueOf($core.int value) => _byValue[value];

  const CoreStates._($core.int v, $core.String n) : super(v, n);
}

class MessageType extends $pb.ProtobufEnum {
  static const MessageType EMPTY = MessageType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EMPTY');
  static const MessageType EMPTY_CONFIGURATION = MessageType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EMPTY_CONFIGURATION');
  static const MessageType START_COMMAND_SERVER = MessageType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'START_COMMAND_SERVER');
  static const MessageType CREATE_SERVICE = MessageType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CREATE_SERVICE');
  static const MessageType START_SERVICE = MessageType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'START_SERVICE');
  static const MessageType UNEXPECTED_ERROR = MessageType._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UNEXPECTED_ERROR');
  static const MessageType ALREADY_STARTED = MessageType._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ALREADY_STARTED');
  static const MessageType ALREADY_STOPPED = MessageType._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ALREADY_STOPPED');
  static const MessageType INSTANCE_NOT_FOUND = MessageType._(8, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INSTANCE_NOT_FOUND');
  static const MessageType INSTANCE_NOT_STOPPED = MessageType._(9, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INSTANCE_NOT_STOPPED');
  static const MessageType INSTANCE_NOT_STARTED = MessageType._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INSTANCE_NOT_STARTED');
  static const MessageType ERROR_BUILDING_CONFIG = MessageType._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ERROR_BUILDING_CONFIG');
  static const MessageType ERROR_PARSING_CONFIG = MessageType._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ERROR_PARSING_CONFIG');
  static const MessageType ERROR_READING_CONFIG = MessageType._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ERROR_READING_CONFIG');
  static const MessageType ERROR_EXTENSION = MessageType._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ERROR_EXTENSION');

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
  ];

  static final $core.Map<$core.int, MessageType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MessageType? valueOf($core.int value) => _byValue[value];

  const MessageType._($core.int v, $core.String n) : super(v, n);
}

class SetupMode extends $pb.ProtobufEnum {
  static const SetupMode OLD = SetupMode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OLD');
  static const SetupMode GRPC_NORMAL = SetupMode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GRPC_NORMAL');
  static const SetupMode GRPC_BACKGROUND = SetupMode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GRPC_BACKGROUND');
  static const SetupMode GRPC_NORMAL_INSECURE = SetupMode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GRPC_NORMAL_INSECURE');
  static const SetupMode GRPC_BACKGROUND_INSECURE = SetupMode._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GRPC_BACKGROUND_INSECURE');

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
  static const LogLevel TRACE = LogLevel._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TRACE');
  static const LogLevel DEBUG = LogLevel._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DEBUG');
  static const LogLevel INFO = LogLevel._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INFO');
  static const LogLevel WARNING = LogLevel._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WARNING');
  static const LogLevel ERROR = LogLevel._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ERROR');
  static const LogLevel FATAL = LogLevel._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FATAL');

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
  static const LogType CORE = LogType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CORE');
  static const LogType SERVICE = LogType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SERVICE');
  static const LogType CONFIG = LogType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CONFIG');

  static const $core.List<LogType> values = <LogType> [
    CORE,
    SERVICE,
    CONFIG,
  ];

  static final $core.Map<$core.int, LogType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static LogType? valueOf($core.int value) => _byValue[value];

  const LogType._($core.int v, $core.String n) : super(v, n);
}

