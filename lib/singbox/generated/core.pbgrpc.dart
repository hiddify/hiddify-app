//
//  Generated code. Do not modify.
//  source: core.proto
//
// @dart = 3.0

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:hiddify/singbox/generated/core.pb.dart' as $0;
import 'package:protobuf/protobuf.dart' as $pb;

export 'core.pb.dart';

@$pb.GrpcServiceName('ConfigOptions.CoreService')
class CoreServiceClient extends $grpc.Client {
  static final _$parseConfig =
      $grpc.ClientMethod<$0.ParseConfigRequest, $0.ParseConfigResponse>(
          '/ConfigOptions.CoreService/ParseConfig',
          ($0.ParseConfigRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.ParseConfigResponse.fromBuffer(value));
  static final _$generateFullConfig =
      $grpc.ClientMethod<$0.GenerateConfigRequest, $0.GenerateConfigResponse>(
          '/ConfigOptions.CoreService/GenerateFullConfig',
          ($0.GenerateConfigRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.GenerateConfigResponse.fromBuffer(value));

  CoreServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.ParseConfigResponse> parseConfig(
      $0.ParseConfigRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$parseConfig, request, options: options);
  }

  $grpc.ResponseFuture<$0.GenerateConfigResponse> generateFullConfig(
      $0.GenerateConfigRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$generateFullConfig, request, options: options);
  }
}

@$pb.GrpcServiceName('ConfigOptions.CoreService')
abstract class CoreServiceBase extends $grpc.Service {
  $core.String get $name => 'ConfigOptions.CoreService';

  CoreServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ParseConfigRequest, $0.ParseConfigResponse>(
            'ParseConfig',
            parseConfig_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ParseConfigRequest.fromBuffer(value),
            ($0.ParseConfigResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GenerateConfigRequest,
            $0.GenerateConfigResponse>(
        'GenerateFullConfig',
        generateFullConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GenerateConfigRequest.fromBuffer(value),
        ($0.GenerateConfigResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ParseConfigResponse> parseConfig_Pre($grpc.ServiceCall call,
      $async.Future<$0.ParseConfigRequest> request) async {
    return parseConfig(call, await request);
  }

  $async.Future<$0.GenerateConfigResponse> generateFullConfig_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.GenerateConfigRequest> request) async {
    return generateFullConfig(call, await request);
  }

  $async.Future<$0.ParseConfigResponse> parseConfig(
      $grpc.ServiceCall call, $0.ParseConfigRequest request);
  $async.Future<$0.GenerateConfigResponse> generateFullConfig(
      $grpc.ServiceCall call, $0.GenerateConfigRequest request);
}
