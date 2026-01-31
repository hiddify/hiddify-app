///
//  Generated code. Do not modify.
//  source: extension/extension.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../v2/hcommon/common.pbenum.dart' as $1;
import 'extension.pbenum.dart';

export 'extension.pbenum.dart';

class ExtensionActionResult extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExtensionActionResult', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extensionId')
    ..e<$1.ResponseCode>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..hasRequiredFields = false
  ;

  ExtensionActionResult._() : super();
  factory ExtensionActionResult({
    $core.String? extensionId,
    $1.ResponseCode? code,
    $core.String? message,
  }) {
    final _result = create();
    if (extensionId != null) {
      _result.extensionId = extensionId;
    }
    if (code != null) {
      _result.code = code;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory ExtensionActionResult.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionActionResult.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionActionResult clone() => ExtensionActionResult()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionActionResult copyWith(void Function(ExtensionActionResult) updates) => super.copyWith((message) => updates(message as ExtensionActionResult)) as ExtensionActionResult; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExtensionActionResult create() => ExtensionActionResult._();
  ExtensionActionResult createEmptyInstance() => create();
  static $pb.PbList<ExtensionActionResult> createRepeated() => $pb.PbList<ExtensionActionResult>();
  @$core.pragma('dart2js:noInline')
  static ExtensionActionResult getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionActionResult>(create);
  static ExtensionActionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => clearField(1);

  @$pb.TagNumber(2)
  $1.ResponseCode get code => $_getN(1);
  @$pb.TagNumber(2)
  set code($1.ResponseCode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);
}

class ExtensionList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExtensionList', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'extension'), createEmptyInstance: create)
    ..pc<ExtensionMsg>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extensions', $pb.PbFieldType.PM, subBuilder: ExtensionMsg.create)
    ..hasRequiredFields = false
  ;

  ExtensionList._() : super();
  factory ExtensionList({
    $core.Iterable<ExtensionMsg>? extensions,
  }) {
    final _result = create();
    if (extensions != null) {
      _result.extensions.addAll(extensions);
    }
    return _result;
  }
  factory ExtensionList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionList clone() => ExtensionList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionList copyWith(void Function(ExtensionList) updates) => super.copyWith((message) => updates(message as ExtensionList)) as ExtensionList; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExtensionList create() => ExtensionList._();
  ExtensionList createEmptyInstance() => create();
  static $pb.PbList<ExtensionList> createRepeated() => $pb.PbList<ExtensionList>();
  @$core.pragma('dart2js:noInline')
  static ExtensionList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionList>(create);
  static ExtensionList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ExtensionMsg> get extensions => $_getList(0);
}

class EditExtensionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EditExtensionRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extensionId')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enable')
    ..hasRequiredFields = false
  ;

  EditExtensionRequest._() : super();
  factory EditExtensionRequest({
    $core.String? extensionId,
    $core.bool? enable,
  }) {
    final _result = create();
    if (extensionId != null) {
      _result.extensionId = extensionId;
    }
    if (enable != null) {
      _result.enable = enable;
    }
    return _result;
  }
  factory EditExtensionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EditExtensionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EditExtensionRequest clone() => EditExtensionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EditExtensionRequest copyWith(void Function(EditExtensionRequest) updates) => super.copyWith((message) => updates(message as EditExtensionRequest)) as EditExtensionRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EditExtensionRequest create() => EditExtensionRequest._();
  EditExtensionRequest createEmptyInstance() => create();
  static $pb.PbList<EditExtensionRequest> createRepeated() => $pb.PbList<EditExtensionRequest>();
  @$core.pragma('dart2js:noInline')
  static EditExtensionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EditExtensionRequest>(create);
  static EditExtensionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enable => $_getBF(1);
  @$pb.TagNumber(2)
  set enable($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEnable() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnable() => clearField(2);
}

class ExtensionMsg extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExtensionMsg', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'title')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'description')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enable')
    ..hasRequiredFields = false
  ;

  ExtensionMsg._() : super();
  factory ExtensionMsg({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.bool? enable,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (title != null) {
      _result.title = title;
    }
    if (description != null) {
      _result.description = description;
    }
    if (enable != null) {
      _result.enable = enable;
    }
    return _result;
  }
  factory ExtensionMsg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionMsg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionMsg clone() => ExtensionMsg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionMsg copyWith(void Function(ExtensionMsg) updates) => super.copyWith((message) => updates(message as ExtensionMsg)) as ExtensionMsg; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExtensionMsg create() => ExtensionMsg._();
  ExtensionMsg createEmptyInstance() => create();
  static $pb.PbList<ExtensionMsg> createRepeated() => $pb.PbList<ExtensionMsg>();
  @$core.pragma('dart2js:noInline')
  static ExtensionMsg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionMsg>(create);
  static ExtensionMsg? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enable => $_getBF(3);
  @$pb.TagNumber(4)
  set enable($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEnable() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnable() => clearField(4);
}

class ExtensionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExtensionRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extensionId')
    ..m<$core.String, $core.String>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', entryClassName: 'ExtensionRequest.DataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('extension'))
    ..hasRequiredFields = false
  ;

  ExtensionRequest._() : super();
  factory ExtensionRequest({
    $core.String? extensionId,
    $core.Map<$core.String, $core.String>? data,
  }) {
    final _result = create();
    if (extensionId != null) {
      _result.extensionId = extensionId;
    }
    if (data != null) {
      _result.data.addAll(data);
    }
    return _result;
  }
  factory ExtensionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionRequest clone() => ExtensionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionRequest copyWith(void Function(ExtensionRequest) updates) => super.copyWith((message) => updates(message as ExtensionRequest)) as ExtensionRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExtensionRequest create() => ExtensionRequest._();
  ExtensionRequest createEmptyInstance() => create();
  static $pb.PbList<ExtensionRequest> createRepeated() => $pb.PbList<ExtensionRequest>();
  @$core.pragma('dart2js:noInline')
  static ExtensionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionRequest>(create);
  static ExtensionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => clearField(1);

  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.String> get data => $_getMap(1);
}

class SendExtensionDataRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SendExtensionDataRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extensionId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'button')
    ..m<$core.String, $core.String>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', entryClassName: 'SendExtensionDataRequest.DataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('extension'))
    ..hasRequiredFields = false
  ;

  SendExtensionDataRequest._() : super();
  factory SendExtensionDataRequest({
    $core.String? extensionId,
    $core.String? button,
    $core.Map<$core.String, $core.String>? data,
  }) {
    final _result = create();
    if (extensionId != null) {
      _result.extensionId = extensionId;
    }
    if (button != null) {
      _result.button = button;
    }
    if (data != null) {
      _result.data.addAll(data);
    }
    return _result;
  }
  factory SendExtensionDataRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SendExtensionDataRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SendExtensionDataRequest clone() => SendExtensionDataRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SendExtensionDataRequest copyWith(void Function(SendExtensionDataRequest) updates) => super.copyWith((message) => updates(message as SendExtensionDataRequest)) as SendExtensionDataRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SendExtensionDataRequest create() => SendExtensionDataRequest._();
  SendExtensionDataRequest createEmptyInstance() => create();
  static $pb.PbList<SendExtensionDataRequest> createRepeated() => $pb.PbList<SendExtensionDataRequest>();
  @$core.pragma('dart2js:noInline')
  static SendExtensionDataRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendExtensionDataRequest>(create);
  static SendExtensionDataRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extensionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set extensionId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasExtensionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get button => $_getSZ(1);
  @$pb.TagNumber(2)
  set button($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasButton() => $_has(1);
  @$pb.TagNumber(2)
  void clearButton() => clearField(2);

  @$pb.TagNumber(3)
  $core.Map<$core.String, $core.String> get data => $_getMap(2);
}

class ExtensionResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExtensionResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'extension'), createEmptyInstance: create)
    ..e<ExtensionResponseType>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: ExtensionResponseType.NOTHING, valueOf: ExtensionResponseType.valueOf, enumValues: ExtensionResponseType.values)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extensionId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'jsonUi')
    ..hasRequiredFields = false
  ;

  ExtensionResponse._() : super();
  factory ExtensionResponse({
    ExtensionResponseType? type,
    $core.String? extensionId,
    $core.String? jsonUi,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (extensionId != null) {
      _result.extensionId = extensionId;
    }
    if (jsonUi != null) {
      _result.jsonUi = jsonUi;
    }
    return _result;
  }
  factory ExtensionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionResponse clone() => ExtensionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionResponse copyWith(void Function(ExtensionResponse) updates) => super.copyWith((message) => updates(message as ExtensionResponse)) as ExtensionResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExtensionResponse create() => ExtensionResponse._();
  ExtensionResponse createEmptyInstance() => create();
  static $pb.PbList<ExtensionResponse> createRepeated() => $pb.PbList<ExtensionResponse>();
  @$core.pragma('dart2js:noInline')
  static ExtensionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionResponse>(create);
  static ExtensionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ExtensionResponseType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(ExtensionResponseType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get extensionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set extensionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasExtensionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtensionId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get jsonUi => $_getSZ(2);
  @$pb.TagNumber(3)
  set jsonUi($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasJsonUi() => $_has(2);
  @$pb.TagNumber(3)
  void clearJsonUi() => clearField(3);
}

