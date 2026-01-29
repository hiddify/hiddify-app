///
//  Generated code. Do not modify.
//  source: v2/hcore/tunnelservice/tunnel_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'tunnel.pb.dart' as $2;
import '../../hcommon/common.pb.dart' as $1;
export 'tunnel_service.pb.dart';

class TunnelServiceClient extends $grpc.Client {
  static final _$start =
      $grpc.ClientMethod<$2.TunnelStartRequest, $2.TunnelResponse>(
          '/tunnelservice.TunnelService/Start',
          ($2.TunnelStartRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $2.TunnelResponse.fromBuffer(value));
  static final _$stop = $grpc.ClientMethod<$1.Empty, $2.TunnelResponse>(
      '/tunnelservice.TunnelService/Stop',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.TunnelResponse.fromBuffer(value));
  static final _$status = $grpc.ClientMethod<$1.Empty, $2.TunnelResponse>(
      '/tunnelservice.TunnelService/Status',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.TunnelResponse.fromBuffer(value));
  static final _$exit = $grpc.ClientMethod<$1.Empty, $2.TunnelResponse>(
      '/tunnelservice.TunnelService/Exit',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.TunnelResponse.fromBuffer(value));

  TunnelServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$2.TunnelResponse> start($2.TunnelStartRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$start, request, options: options);
  }

  $grpc.ResponseFuture<$2.TunnelResponse> stop($1.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$stop, request, options: options);
  }

  $grpc.ResponseFuture<$2.TunnelResponse> status($1.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$status, request, options: options);
  }

  $grpc.ResponseFuture<$2.TunnelResponse> exit($1.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$exit, request, options: options);
  }
}

abstract class TunnelServiceBase extends $grpc.Service {
  $core.String get $name => 'tunnelservice.TunnelService';

  TunnelServiceBase() {
    $addMethod($grpc.ServiceMethod<$2.TunnelStartRequest, $2.TunnelResponse>(
        'Start',
        start_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.TunnelStartRequest.fromBuffer(value),
        ($2.TunnelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $2.TunnelResponse>(
        'Stop',
        stop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($2.TunnelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $2.TunnelResponse>(
        'Status',
        status_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($2.TunnelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $2.TunnelResponse>(
        'Exit',
        exit_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($2.TunnelResponse value) => value.writeToBuffer()));
  }

  $async.Future<$2.TunnelResponse> start_Pre($grpc.ServiceCall call,
      $async.Future<$2.TunnelStartRequest> request) async {
    return start(call, await request);
  }

  $async.Future<$2.TunnelResponse> stop_Pre(
      $grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return stop(call, await request);
  }

  $async.Future<$2.TunnelResponse> status_Pre(
      $grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return status(call, await request);
  }

  $async.Future<$2.TunnelResponse> exit_Pre(
      $grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return exit(call, await request);
  }

  $async.Future<$2.TunnelResponse> start(
      $grpc.ServiceCall call, $2.TunnelStartRequest request);
  $async.Future<$2.TunnelResponse> stop(
      $grpc.ServiceCall call, $1.Empty request);
  $async.Future<$2.TunnelResponse> status(
      $grpc.ServiceCall call, $1.Empty request);
  $async.Future<$2.TunnelResponse> exit(
      $grpc.ServiceCall call, $1.Empty request);
}
