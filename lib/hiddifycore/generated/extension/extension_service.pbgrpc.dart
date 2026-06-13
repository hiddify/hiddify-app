// This is a generated file - do not edit.
//
// Generated from extension/extension_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import '../v2/hcommon/common.pb.dart' as $0;
import 'extension.pb.dart' as $1;

export 'extension_service.pb.dart';

@$pb.GrpcServiceName('extension.ExtensionHostService')
class ExtensionHostServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ExtensionHostServiceClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.ExtensionList> listExtensions(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listExtensions, request, options: options);
  }

  $grpc.ResponseStream<$1.ExtensionResponse> connect(
    $1.ExtensionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$connect, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$1.ExtensionActionResult> editExtension(
    $1.EditExtensionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$editExtension, request, options: options);
  }

  $grpc.ResponseFuture<$1.ExtensionActionResult> submitForm(
    $1.SendExtensionDataRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$submitForm, request, options: options);
  }

  $grpc.ResponseFuture<$1.ExtensionActionResult> close(
    $1.ExtensionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$close, request, options: options);
  }

  $grpc.ResponseFuture<$1.ExtensionActionResult> getUI(
    $1.ExtensionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUI, request, options: options);
  }

  // method descriptors

  static final _$listExtensions =
      $grpc.ClientMethod<$0.Empty, $1.ExtensionList>(
          '/extension.ExtensionHostService/ListExtensions',
          ($0.Empty value) => value.writeToBuffer(),
          $1.ExtensionList.fromBuffer);
  static final _$connect =
      $grpc.ClientMethod<$1.ExtensionRequest, $1.ExtensionResponse>(
          '/extension.ExtensionHostService/Connect',
          ($1.ExtensionRequest value) => value.writeToBuffer(),
          $1.ExtensionResponse.fromBuffer);
  static final _$editExtension =
      $grpc.ClientMethod<$1.EditExtensionRequest, $1.ExtensionActionResult>(
          '/extension.ExtensionHostService/EditExtension',
          ($1.EditExtensionRequest value) => value.writeToBuffer(),
          $1.ExtensionActionResult.fromBuffer);
  static final _$submitForm =
      $grpc.ClientMethod<$1.SendExtensionDataRequest, $1.ExtensionActionResult>(
          '/extension.ExtensionHostService/SubmitForm',
          ($1.SendExtensionDataRequest value) => value.writeToBuffer(),
          $1.ExtensionActionResult.fromBuffer);
  static final _$close =
      $grpc.ClientMethod<$1.ExtensionRequest, $1.ExtensionActionResult>(
          '/extension.ExtensionHostService/Close',
          ($1.ExtensionRequest value) => value.writeToBuffer(),
          $1.ExtensionActionResult.fromBuffer);
  static final _$getUI =
      $grpc.ClientMethod<$1.ExtensionRequest, $1.ExtensionActionResult>(
          '/extension.ExtensionHostService/GetUI',
          ($1.ExtensionRequest value) => value.writeToBuffer(),
          $1.ExtensionActionResult.fromBuffer);
}

@$pb.GrpcServiceName('extension.ExtensionHostService')
abstract class ExtensionHostServiceBase extends $grpc.Service {
  $core.String get $name => 'extension.ExtensionHostService';

  ExtensionHostServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.ExtensionList>(
        'ListExtensions',
        listExtensions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.ExtensionList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ExtensionRequest, $1.ExtensionResponse>(
        'Connect',
        connect_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.ExtensionRequest.fromBuffer(value),
        ($1.ExtensionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.EditExtensionRequest, $1.ExtensionActionResult>(
            'EditExtension',
            editExtension_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.EditExtensionRequest.fromBuffer(value),
            ($1.ExtensionActionResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SendExtensionDataRequest,
            $1.ExtensionActionResult>(
        'SubmitForm',
        submitForm_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.SendExtensionDataRequest.fromBuffer(value),
        ($1.ExtensionActionResult value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.ExtensionRequest, $1.ExtensionActionResult>(
            'Close',
            close_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.ExtensionRequest.fromBuffer(value),
            ($1.ExtensionActionResult value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.ExtensionRequest, $1.ExtensionActionResult>(
            'GetUI',
            getUI_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.ExtensionRequest.fromBuffer(value),
            ($1.ExtensionActionResult value) => value.writeToBuffer()));
  }

  $async.Future<$1.ExtensionList> listExtensions_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listExtensions($call, await $request);
  }

  $async.Future<$1.ExtensionList> listExtensions(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.ExtensionResponse> connect_Pre($grpc.ServiceCall $call,
      $async.Future<$1.ExtensionRequest> $request) async* {
    yield* connect($call, await $request);
  }

  $async.Stream<$1.ExtensionResponse> connect(
      $grpc.ServiceCall call, $1.ExtensionRequest request);

  $async.Future<$1.ExtensionActionResult> editExtension_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.EditExtensionRequest> $request) async {
    return editExtension($call, await $request);
  }

  $async.Future<$1.ExtensionActionResult> editExtension(
      $grpc.ServiceCall call, $1.EditExtensionRequest request);

  $async.Future<$1.ExtensionActionResult> submitForm_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.SendExtensionDataRequest> $request) async {
    return submitForm($call, await $request);
  }

  $async.Future<$1.ExtensionActionResult> submitForm(
      $grpc.ServiceCall call, $1.SendExtensionDataRequest request);

  $async.Future<$1.ExtensionActionResult> close_Pre($grpc.ServiceCall $call,
      $async.Future<$1.ExtensionRequest> $request) async {
    return close($call, await $request);
  }

  $async.Future<$1.ExtensionActionResult> close(
      $grpc.ServiceCall call, $1.ExtensionRequest request);

  $async.Future<$1.ExtensionActionResult> getUI_Pre($grpc.ServiceCall $call,
      $async.Future<$1.ExtensionRequest> $request) async {
    return getUI($call, await $request);
  }

  $async.Future<$1.ExtensionActionResult> getUI(
      $grpc.ServiceCall call, $1.ExtensionRequest request);
}
