// This is a generated file - do not edit.
//
// Generated from extension/extension.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../v2/hcommon/common.pbenum.dart' as $0;
import 'extension.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'extension.pbenum.dart';

class ExtensionActionResult extends $pb.GeneratedMessage {
  factory ExtensionActionResult({
    $core.String? extensionId,
    $0.ResponseCode? code,
    $core.String? message,
  }) {
    final result = create();
    if (extensionId != null) result.extensionId = extensionId;
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  ExtensionActionResult._();

  factory ExtensionActionResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionActionResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionActionResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..aE<$0.ResponseCode>(2, _omitFieldNames ? '' : 'code',
        enumValues: $0.ResponseCode.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionActionResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionActionResult copyWith(
          void Function(ExtensionActionResult) updates) =>
      super.copyWith((message) => updates(message as ExtensionActionResult))
          as ExtensionActionResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionActionResult create() => ExtensionActionResult._();
  @$core.override
  ExtensionActionResult createEmptyInstance() => create();
  static $pb.PbList<ExtensionActionResult> createRepeated() =>
      $pb.PbList<ExtensionActionResult>();
  @$core.pragma('dart2js:noInline')
  static ExtensionActionResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionActionResult>(create);
  static ExtensionActionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.ResponseCode get code => $_getN(1);
  @$pb.TagNumber(2)
  set code($0.ResponseCode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class ExtensionList extends $pb.GeneratedMessage {
  factory ExtensionList({
    $core.Iterable<ExtensionMsg>? extensions,
  }) {
    final result = create();
    if (extensions != null) result.extensions.addAll(extensions);
    return result;
  }

  ExtensionList._();

  factory ExtensionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'),
      createEmptyInstance: create)
    ..pPM<ExtensionMsg>(1, _omitFieldNames ? '' : 'extensions',
        subBuilder: ExtensionMsg.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionList copyWith(void Function(ExtensionList) updates) =>
      super.copyWith((message) => updates(message as ExtensionList))
          as ExtensionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionList create() => ExtensionList._();
  @$core.override
  ExtensionList createEmptyInstance() => create();
  static $pb.PbList<ExtensionList> createRepeated() =>
      $pb.PbList<ExtensionList>();
  @$core.pragma('dart2js:noInline')
  static ExtensionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionList>(create);
  static ExtensionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ExtensionMsg> get extensions => $_getList(0);
}

class EditExtensionRequest extends $pb.GeneratedMessage {
  factory EditExtensionRequest({
    $core.String? extensionId,
    $core.bool? enable,
  }) {
    final result = create();
    if (extensionId != null) result.extensionId = extensionId;
    if (enable != null) result.enable = enable;
    return result;
  }

  EditExtensionRequest._();

  factory EditExtensionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EditExtensionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditExtensionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..aOB(2, _omitFieldNames ? '' : 'enable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditExtensionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditExtensionRequest copyWith(void Function(EditExtensionRequest) updates) =>
      super.copyWith((message) => updates(message as EditExtensionRequest))
          as EditExtensionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EditExtensionRequest create() => EditExtensionRequest._();
  @$core.override
  EditExtensionRequest createEmptyInstance() => create();
  static $pb.PbList<EditExtensionRequest> createRepeated() =>
      $pb.PbList<EditExtensionRequest>();
  @$core.pragma('dart2js:noInline')
  static EditExtensionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditExtensionRequest>(create);
  static EditExtensionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enable => $_getBF(1);
  @$pb.TagNumber(2)
  set enable($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnable() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnable() => $_clearField(2);
}

class ExtensionMsg extends $pb.GeneratedMessage {
  factory ExtensionMsg({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.bool? enable,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (enable != null) result.enable = enable;
    return result;
  }

  ExtensionMsg._();

  factory ExtensionMsg.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionMsg.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionMsg',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOB(4, _omitFieldNames ? '' : 'enable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionMsg clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionMsg copyWith(void Function(ExtensionMsg) updates) =>
      super.copyWith((message) => updates(message as ExtensionMsg))
          as ExtensionMsg;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionMsg create() => ExtensionMsg._();
  @$core.override
  ExtensionMsg createEmptyInstance() => create();
  static $pb.PbList<ExtensionMsg> createRepeated() =>
      $pb.PbList<ExtensionMsg>();
  @$core.pragma('dart2js:noInline')
  static ExtensionMsg getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionMsg>(create);
  static ExtensionMsg? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enable => $_getBF(3);
  @$pb.TagNumber(4)
  set enable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnable() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnable() => $_clearField(4);
}

class ExtensionRequest extends $pb.GeneratedMessage {
  factory ExtensionRequest({
    $core.String? extensionId,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? data,
  }) {
    final result = create();
    if (extensionId != null) result.extensionId = extensionId;
    if (data != null) result.data.addEntries(data);
    return result;
  }

  ExtensionRequest._();

  factory ExtensionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'data',
        entryClassName: 'ExtensionRequest.DataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('extension'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionRequest copyWith(void Function(ExtensionRequest) updates) =>
      super.copyWith((message) => updates(message as ExtensionRequest))
          as ExtensionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionRequest create() => ExtensionRequest._();
  @$core.override
  ExtensionRequest createEmptyInstance() => create();
  static $pb.PbList<ExtensionRequest> createRepeated() =>
      $pb.PbList<ExtensionRequest>();
  @$core.pragma('dart2js:noInline')
  static ExtensionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionRequest>(create);
  static ExtensionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get data => $_getMap(1);
}

class SendExtensionDataRequest extends $pb.GeneratedMessage {
  factory SendExtensionDataRequest({
    $core.String? extensionId,
    $core.String? button,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? data,
  }) {
    final result = create();
    if (extensionId != null) result.extensionId = extensionId;
    if (button != null) result.button = button;
    if (data != null) result.data.addEntries(data);
    return result;
  }

  SendExtensionDataRequest._();

  factory SendExtensionDataRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendExtensionDataRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendExtensionDataRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..aOS(2, _omitFieldNames ? '' : 'button')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'data',
        entryClassName: 'SendExtensionDataRequest.DataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('extension'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendExtensionDataRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendExtensionDataRequest copyWith(
          void Function(SendExtensionDataRequest) updates) =>
      super.copyWith((message) => updates(message as SendExtensionDataRequest))
          as SendExtensionDataRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendExtensionDataRequest create() => SendExtensionDataRequest._();
  @$core.override
  SendExtensionDataRequest createEmptyInstance() => create();
  static $pb.PbList<SendExtensionDataRequest> createRepeated() =>
      $pb.PbList<SendExtensionDataRequest>();
  @$core.pragma('dart2js:noInline')
  static SendExtensionDataRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendExtensionDataRequest>(create);
  static SendExtensionDataRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get button => $_getSZ(1);
  @$pb.TagNumber(2)
  set button($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasButton() => $_has(1);
  @$pb.TagNumber(2)
  void clearButton() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get data => $_getMap(2);
}

class ExtensionResponse extends $pb.GeneratedMessage {
  factory ExtensionResponse({
    ExtensionResponseType? type,
    $core.String? extensionId,
    $core.String? jsonUi,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (extensionId != null) result.extensionId = extensionId;
    if (jsonUi != null) result.jsonUi = jsonUi;
    return result;
  }

  ExtensionResponse._();

  factory ExtensionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'),
      createEmptyInstance: create)
    ..aE<ExtensionResponseType>(1, _omitFieldNames ? '' : 'type',
        enumValues: ExtensionResponseType.values)
    ..aOS(2, _omitFieldNames ? '' : 'extensionId')
    ..aOS(3, _omitFieldNames ? '' : 'jsonUi')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionResponse copyWith(void Function(ExtensionResponse) updates) =>
      super.copyWith((message) => updates(message as ExtensionResponse))
          as ExtensionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionResponse create() => ExtensionResponse._();
  @$core.override
  ExtensionResponse createEmptyInstance() => create();
  static $pb.PbList<ExtensionResponse> createRepeated() =>
      $pb.PbList<ExtensionResponse>();
  @$core.pragma('dart2js:noInline')
  static ExtensionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionResponse>(create);
  static ExtensionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ExtensionResponseType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(ExtensionResponseType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get extensionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set extensionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExtensionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtensionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get jsonUi => $_getSZ(2);
  @$pb.TagNumber(3)
  set jsonUi($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasJsonUi() => $_has(2);
  @$pb.TagNumber(3)
  void clearJsonUi() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
