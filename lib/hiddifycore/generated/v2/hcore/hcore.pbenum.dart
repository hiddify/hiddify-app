// This is a generated file - do not edit.
//
// Generated from v2/hcore/hcore.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CoreStates extends $pb.ProtobufEnum {
  static const CoreStates STOPPED =
      CoreStates._(0, _omitEnumNames ? '' : 'STOPPED');
  static const CoreStates STARTING =
      CoreStates._(1, _omitEnumNames ? '' : 'STARTING');
  static const CoreStates STARTED =
      CoreStates._(2, _omitEnumNames ? '' : 'STARTED');
  static const CoreStates STOPPING =
      CoreStates._(3, _omitEnumNames ? '' : 'STOPPING');

  static const $core.List<CoreStates> values = <CoreStates>[
    STOPPED,
    STARTING,
    STARTED,
    STOPPING,
  ];

  static final $core.List<CoreStates?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CoreStates? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CoreStates._(super.value, super.name);
}

class MessageType extends $pb.ProtobufEnum {
  static const MessageType EMPTY =
      MessageType._(0, _omitEnumNames ? '' : 'EMPTY');
  static const MessageType EMPTY_CONFIGURATION =
      MessageType._(1, _omitEnumNames ? '' : 'EMPTY_CONFIGURATION');
  static const MessageType START_COMMAND_SERVER =
      MessageType._(2, _omitEnumNames ? '' : 'START_COMMAND_SERVER');
  static const MessageType CREATE_SERVICE =
      MessageType._(3, _omitEnumNames ? '' : 'CREATE_SERVICE');
  static const MessageType START_SERVICE =
      MessageType._(4, _omitEnumNames ? '' : 'START_SERVICE');
  static const MessageType UNEXPECTED_ERROR =
      MessageType._(5, _omitEnumNames ? '' : 'UNEXPECTED_ERROR');
  static const MessageType ALREADY_STARTED =
      MessageType._(6, _omitEnumNames ? '' : 'ALREADY_STARTED');
  static const MessageType ALREADY_STOPPED =
      MessageType._(7, _omitEnumNames ? '' : 'ALREADY_STOPPED');
  static const MessageType INSTANCE_NOT_FOUND =
      MessageType._(8, _omitEnumNames ? '' : 'INSTANCE_NOT_FOUND');
  static const MessageType INSTANCE_NOT_STOPPED =
      MessageType._(9, _omitEnumNames ? '' : 'INSTANCE_NOT_STOPPED');
  static const MessageType INSTANCE_NOT_STARTED =
      MessageType._(10, _omitEnumNames ? '' : 'INSTANCE_NOT_STARTED');
  static const MessageType ERROR_BUILDING_CONFIG =
      MessageType._(11, _omitEnumNames ? '' : 'ERROR_BUILDING_CONFIG');
  static const MessageType ERROR_PARSING_CONFIG =
      MessageType._(12, _omitEnumNames ? '' : 'ERROR_PARSING_CONFIG');
  static const MessageType ERROR_READING_CONFIG =
      MessageType._(13, _omitEnumNames ? '' : 'ERROR_READING_CONFIG');
  static const MessageType ERROR_EXTENSION =
      MessageType._(14, _omitEnumNames ? '' : 'ERROR_EXTENSION');

  static const $core.List<MessageType> values = <MessageType>[
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

  static final $core.List<MessageType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 14);
  static MessageType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MessageType._(super.value, super.name);
}

class SetupMode extends $pb.ProtobufEnum {
  static const SetupMode OLD = SetupMode._(0, _omitEnumNames ? '' : 'OLD');
  static const SetupMode GRPC_NORMAL =
      SetupMode._(1, _omitEnumNames ? '' : 'GRPC_NORMAL');
  static const SetupMode GRPC_BACKGROUND =
      SetupMode._(2, _omitEnumNames ? '' : 'GRPC_BACKGROUND');
  static const SetupMode GRPC_NORMAL_INSECURE =
      SetupMode._(3, _omitEnumNames ? '' : 'GRPC_NORMAL_INSECURE');
  static const SetupMode GRPC_BACKGROUND_INSECURE =
      SetupMode._(4, _omitEnumNames ? '' : 'GRPC_BACKGROUND_INSECURE');

  static const $core.List<SetupMode> values = <SetupMode>[
    OLD,
    GRPC_NORMAL,
    GRPC_BACKGROUND,
    GRPC_NORMAL_INSECURE,
    GRPC_BACKGROUND_INSECURE,
  ];

  static final $core.List<SetupMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SetupMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SetupMode._(super.value, super.name);
}

class LogLevel extends $pb.ProtobufEnum {
  static const LogLevel TRACE = LogLevel._(0, _omitEnumNames ? '' : 'TRACE');
  static const LogLevel DEBUG = LogLevel._(1, _omitEnumNames ? '' : 'DEBUG');
  static const LogLevel INFO = LogLevel._(2, _omitEnumNames ? '' : 'INFO');
  static const LogLevel WARNING =
      LogLevel._(3, _omitEnumNames ? '' : 'WARNING');
  static const LogLevel ERROR = LogLevel._(4, _omitEnumNames ? '' : 'ERROR');
  static const LogLevel FATAL = LogLevel._(5, _omitEnumNames ? '' : 'FATAL');

  static const $core.List<LogLevel> values = <LogLevel>[
    TRACE,
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    FATAL,
  ];

  static final $core.List<LogLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static LogLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LogLevel._(super.value, super.name);
}

class LogType extends $pb.ProtobufEnum {
  static const LogType CORE = LogType._(0, _omitEnumNames ? '' : 'CORE');
  static const LogType SERVICE = LogType._(1, _omitEnumNames ? '' : 'SERVICE');
  static const LogType CONFIG = LogType._(2, _omitEnumNames ? '' : 'CONFIG');

  static const $core.List<LogType> values = <LogType>[
    CORE,
    SERVICE,
    CONFIG,
  ];

  static final $core.List<LogType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static LogType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LogType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
