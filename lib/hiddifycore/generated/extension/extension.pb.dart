//
//  Generated code. Do not modify.
//  source: extension/extension.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../v2/hcommon/common.pbenum.dart' as $1;
import 'extension.pbenum.dart';

export 'extension.pbenum.dart';

class ExtensionActionResult extends $pb.GeneratedMessage {
  factory ExtensionActionResult({
    $core.String? extensionId,
    $1.ResponseCode? code,
    $core.String? message,
  }) {
    final $result = create();
    if (extensionId != null) {
      $result.extensionId = extensionId;
    }
    if (code != null) {
      $result.code = code;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  ExtensionActionResult._() : super();
  factory ExtensionActionResult.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionActionResult.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionActionResult', package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..e<$1.ResponseCode>(2, _omitFieldNames ? '' : 'code', $pb.PbFieldType.OE, defaultOrMaker: $1.ResponseCode.OK, valueOf: $1.ResponseCode.valueOf, enumValues: $1.ResponseCode.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionActionResult clone() => ExtensionActionResult()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionActionResult copyWith(void Function(ExtensionActionResult) updates) => super.copyWith((message) => updates(message as ExtensionActionResult)) as ExtensionActionResult;

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
  factory ExtensionList({
    $core.Iterable<ExtensionMsg>? extensions,
  }) {
    final $result = create();
    if (extensions != null) {
      $result.extensions.addAll(extensions);
    }
    return $result;
  }
  ExtensionList._() : super();
  factory ExtensionList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionList', package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'), createEmptyInstance: create)
    ..pc<ExtensionMsg>(1, _omitFieldNames ? '' : 'extensions', $pb.PbFieldType.PM, subBuilder: ExtensionMsg.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionList clone() => ExtensionList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionList copyWith(void Function(ExtensionList) updates) => super.copyWith((message) => updates(message as ExtensionList)) as ExtensionList;

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
  factory EditExtensionRequest({
    $core.String? extensionId,
    $core.bool? enable,
  }) {
    final $result = create();
    if (extensionId != null) {
      $result.extensionId = extensionId;
    }
    if (enable != null) {
      $result.enable = enable;
    }
    return $result;
  }
  EditExtensionRequest._() : super();
  factory EditExtensionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EditExtensionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EditExtensionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..aOB(2, _omitFieldNames ? '' : 'enable')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EditExtensionRequest clone() => EditExtensionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EditExtensionRequest copyWith(void Function(EditExtensionRequest) updates) => super.copyWith((message) => updates(message as EditExtensionRequest)) as EditExtensionRequest;

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
  factory ExtensionMsg({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.bool? enable,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (title != null) {
      $result.title = title;
    }
    if (description != null) {
      $result.description = description;
    }
    if (enable != null) {
      $result.enable = enable;
    }
    return $result;
  }
  ExtensionMsg._() : super();
  factory ExtensionMsg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionMsg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionMsg', package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOB(4, _omitFieldNames ? '' : 'enable')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionMsg clone() => ExtensionMsg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionMsg copyWith(void Function(ExtensionMsg) updates) => super.copyWith((message) => updates(message as ExtensionMsg)) as ExtensionMsg;

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
  factory ExtensionRequest({
    $core.String? extensionId,
    $core.Map<$core.String, $core.String>? data,
  }) {
    final $result = create();
    if (extensionId != null) {
      $result.extensionId = extensionId;
    }
    if (data != null) {
      $result.data.addAll(data);
    }
    return $result;
  }
  ExtensionRequest._() : super();
  factory ExtensionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'data', entryClassName: 'ExtensionRequest.DataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('extension'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionRequest clone() => ExtensionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionRequest copyWith(void Function(ExtensionRequest) updates) => super.copyWith((message) => updates(message as ExtensionRequest)) as ExtensionRequest;

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
  factory SendExtensionDataRequest({
    $core.String? extensionId,
    $core.String? button,
    $core.Map<$core.String, $core.String>? data,
  }) {
    final $result = create();
    if (extensionId != null) {
      $result.extensionId = extensionId;
    }
    if (button != null) {
      $result.button = button;
    }
    if (data != null) {
      $result.data.addAll(data);
    }
    return $result;
  }
  SendExtensionDataRequest._() : super();
  factory SendExtensionDataRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SendExtensionDataRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SendExtensionDataRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extensionId')
    ..aOS(2, _omitFieldNames ? '' : 'button')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'data', entryClassName: 'SendExtensionDataRequest.DataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('extension'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SendExtensionDataRequest clone() => SendExtensionDataRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SendExtensionDataRequest copyWith(void Function(SendExtensionDataRequest) updates) => super.copyWith((message) => updates(message as SendExtensionDataRequest)) as SendExtensionDataRequest;

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
  factory ExtensionResponse({
    ExtensionResponseType? type,
    $core.String? extensionId,
    $core.String? jsonUi,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (extensionId != null) {
      $result.extensionId = extensionId;
    }
    if (jsonUi != null) {
      $result.jsonUi = jsonUi;
    }
    return $result;
  }
  ExtensionResponse._() : super();
  factory ExtensionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtensionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'extension'), createEmptyInstance: create)
    ..e<ExtensionResponseType>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: ExtensionResponseType.NOTHING, valueOf: ExtensionResponseType.valueOf, enumValues: ExtensionResponseType.values)
    ..aOS(2, _omitFieldNames ? '' : 'extensionId')
    ..aOS(3, _omitFieldNames ? '' : 'jsonUi')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtensionResponse clone() => ExtensionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtensionResponse copyWith(void Function(ExtensionResponse) updates) => super.copyWith((message) => updates(message as ExtensionResponse)) as ExtensionResponse;

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


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
