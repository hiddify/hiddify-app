///
//  Generated code. Do not modify.
//  source: extension/extension_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import '../v2/hcommon/common.pb.dart' as $1;
import 'extension.pb.dart' as $6;
export 'extension_service.pb.dart';

class ExtensionHostServiceClient extends $grpc.Client {
  static final _$listExtensions =
      $grpc.ClientMethod<$1.Empty, $6.ExtensionList>(
          '/extension.ExtensionHostService/ListExtensions',
          ($1.Empty value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $6.ExtensionList.fromBuffer(value));
  static final _$connect =
      $grpc.ClientMethod<$6.ExtensionRequest, $6.ExtensionResponse>(
          '/extension.ExtensionHostService/Connect',
          ($6.ExtensionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $6.ExtensionResponse.fromBuffer(value));
  static final _$editExtension =
      $grpc.ClientMethod<$6.EditExtensionRequest, $6.ExtensionActionResult>(
          '/extension.ExtensionHostService/EditExtension',
          ($6.EditExtensionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $6.ExtensionActionResult.fromBuffer(value));
  static final _$submitForm =
      $grpc.ClientMethod<$6.SendExtensionDataRequest, $6.ExtensionActionResult>(
          '/extension.ExtensionHostService/SubmitForm',
          ($6.SendExtensionDataRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $6.ExtensionActionResult.fromBuffer(value));
  static final _$close =
      $grpc.ClientMethod<$6.ExtensionRequest, $6.ExtensionActionResult>(
          '/extension.ExtensionHostService/Close',
          ($6.ExtensionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $6.ExtensionActionResult.fromBuffer(value));
  static final _$getUI =
      $grpc.ClientMethod<$6.ExtensionRequest, $6.ExtensionActionResult>(
          '/extension.ExtensionHostService/GetUI',
          ($6.ExtensionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $6.ExtensionActionResult.fromBuffer(value));

  ExtensionHostServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$6.ExtensionList> listExtensions($1.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listExtensions, request, options: options);
  }

  $grpc.ResponseStream<$6.ExtensionResponse> connect(
      $6.ExtensionRequest request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(
        _$connect, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$6.ExtensionActionResult> editExtension(
      $6.EditExtensionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$editExtension, request, options: options);
  }

  $grpc.ResponseFuture<$6.ExtensionActionResult> submitForm(
      $6.SendExtensionDataRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$submitForm, request, options: options);
  }

  $grpc.ResponseFuture<$6.ExtensionActionResult> close(
      $6.ExtensionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$close, request, options: options);
  }

  $grpc.ResponseFuture<$6.ExtensionActionResult> getUI(
      $6.ExtensionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getUI, request, options: options);
  }
}

abstract class ExtensionHostServiceBase extends $grpc.Service {
  $core.String get $name => 'extension.ExtensionHostService';

  ExtensionHostServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $6.ExtensionList>(
        'ListExtensions',
        listExtensions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($6.ExtensionList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.ExtensionRequest, $6.ExtensionResponse>(
        'Connect',
        connect_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $6.ExtensionRequest.fromBuffer(value),
        ($6.ExtensionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$6.EditExtensionRequest, $6.ExtensionActionResult>(
            'EditExtension',
            editExtension_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $6.EditExtensionRequest.fromBuffer(value),
            ($6.ExtensionActionResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.SendExtensionDataRequest,
            $6.ExtensionActionResult>(
        'SubmitForm',
        submitForm_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $6.SendExtensionDataRequest.fromBuffer(value),
        ($6.ExtensionActionResult value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$6.ExtensionRequest, $6.ExtensionActionResult>(
            'Close',
            close_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $6.ExtensionRequest.fromBuffer(value),
            ($6.ExtensionActionResult value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$6.ExtensionRequest, $6.ExtensionActionResult>(
            'GetUI',
            getUI_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $6.ExtensionRequest.fromBuffer(value),
            ($6.ExtensionActionResult value) => value.writeToBuffer()));
  }

  $async.Future<$6.ExtensionList> listExtensions_Pre(
      $grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return listExtensions(call, await request);
  }

  $async.Stream<$6.ExtensionResponse> connect_Pre($grpc.ServiceCall call,
      $async.Future<$6.ExtensionRequest> request) async* {
    yield* connect(call, await request);
  }

  $async.Future<$6.ExtensionActionResult> editExtension_Pre(
      $grpc.ServiceCall call,
      $async.Future<$6.EditExtensionRequest> request) async {
    return editExtension(call, await request);
  }

  $async.Future<$6.ExtensionActionResult> submitForm_Pre($grpc.ServiceCall call,
      $async.Future<$6.SendExtensionDataRequest> request) async {
    return submitForm(call, await request);
  }

  $async.Future<$6.ExtensionActionResult> close_Pre($grpc.ServiceCall call,
      $async.Future<$6.ExtensionRequest> request) async {
    return close(call, await request);
  }

  $async.Future<$6.ExtensionActionResult> getUI_Pre($grpc.ServiceCall call,
      $async.Future<$6.ExtensionRequest> request) async {
    return getUI(call, await request);
  }

  $async.Future<$6.ExtensionList> listExtensions(
      $grpc.ServiceCall call, $1.Empty request);
  $async.Stream<$6.ExtensionResponse> connect(
      $grpc.ServiceCall call, $6.ExtensionRequest request);
  $async.Future<$6.ExtensionActionResult> editExtension(
      $grpc.ServiceCall call, $6.EditExtensionRequest request);
  $async.Future<$6.ExtensionActionResult> submitForm(
      $grpc.ServiceCall call, $6.SendExtensionDataRequest request);
  $async.Future<$6.ExtensionActionResult> close(
      $grpc.ServiceCall call, $6.ExtensionRequest request);
  $async.Future<$6.ExtensionActionResult> getUI(
      $grpc.ServiceCall call, $6.ExtensionRequest request);
}
