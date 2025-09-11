// @dart=3.0
//
//  Generated code. Do not modify.
//  source: core.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ParseConfigRequest extends $pb.GeneratedMessage {
  factory ParseConfigRequest({
    $core.String? tempPath,
    $core.String? path,
    $core.bool? debug,
  }) {
    final $result = create();
    if (tempPath != null) {
      $result.tempPath = tempPath;
    }
    if (path != null) {
      $result.path = path;
    }
    if (debug != null) {
      $result.debug = debug;
    }
    return $result;
  }
  ParseConfigRequest._() : super();
  factory ParseConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseConfigRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'ConfigOptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tempPath', protoName: 'tempPath')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOB(3, _omitFieldNames ? '' : 'debug')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParseConfigRequest clone() => ParseConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParseConfigRequest copyWith(void Function(ParseConfigRequest) updates) => super.copyWith((message) => updates(message as ParseConfigRequest)) as ParseConfigRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseConfigRequest create() => ParseConfigRequest._();
  ParseConfigRequest createEmptyInstance() => create();
  static $pb.PbList<ParseConfigRequest> createRepeated() => $pb.PbList<ParseConfigRequest>();
  @$core.pragma('dart2js:noInline')
  static ParseConfigRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseConfigRequest>(create);
  static ParseConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tempPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set tempPath($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTempPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearTempPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get debug => $_getBF(2);
  @$pb.TagNumber(3)
  set debug($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDebug() => $_has(2);
  @$pb.TagNumber(3)
  void clearDebug() => clearField(3);
}

class ParseConfigResponse extends $pb.GeneratedMessage {
  factory ParseConfigResponse({
    $core.String? error,
  }) {
    final $result = create();
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ParseConfigResponse._() : super();
  factory ParseConfigResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseConfigResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseConfigResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'ConfigOptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParseConfigResponse clone() => ParseConfigResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParseConfigResponse copyWith(void Function(ParseConfigResponse) updates) => super.copyWith((message) => updates(message as ParseConfigResponse)) as ParseConfigResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseConfigResponse create() => ParseConfigResponse._();
  ParseConfigResponse createEmptyInstance() => create();
  static $pb.PbList<ParseConfigResponse> createRepeated() => $pb.PbList<ParseConfigResponse>();
  @$core.pragma('dart2js:noInline')
  static ParseConfigResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseConfigResponse>(create);
  static ParseConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get error => $_getSZ(0);
  @$pb.TagNumber(1)
  set error($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => clearField(1);
}

class GenerateConfigRequest extends $pb.GeneratedMessage {
  factory GenerateConfigRequest({
    $core.String? path,
    $core.bool? debug,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (debug != null) {
      $result.debug = debug;
    }
    return $result;
  }
  GenerateConfigRequest._() : super();
  factory GenerateConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateConfigRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'ConfigOptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOB(2, _omitFieldNames ? '' : 'debug')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GenerateConfigRequest clone() => GenerateConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
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
  set path($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get debug => $_getBF(1);
  @$pb.TagNumber(2)
  set debug($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDebug() => $_has(1);
  @$pb.TagNumber(2)
  void clearDebug() => clearField(2);
}

class GenerateConfigResponse extends $pb.GeneratedMessage {
  factory GenerateConfigResponse({
    $core.String? config,
    $core.String? error,
  }) {
    final $result = create();
    if (config != null) {
      $result.config = config;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  GenerateConfigResponse._() : super();
  factory GenerateConfigResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenerateConfigResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GenerateConfigResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'ConfigOptions'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'config')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GenerateConfigResponse clone() => GenerateConfigResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
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
  $core.String get config => $_getSZ(0);
  @$pb.TagNumber(1)
  set config($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
