// This is a generated file - do not edit.
//
// Generated from v2/hcore/tunnelservice/tunnel_service.proto.

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

import '../../hcommon/common.pb.dart' as $1;
import 'tunnel.pb.dart' as $0;

export 'tunnel_service.pb.dart';

@$pb.GrpcServiceName('tunnelservice.TunnelService')
class TunnelServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TunnelServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.TunnelResponse> start(
    $0.TunnelStartRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$start, request, options: options);
  }

  $grpc.ResponseFuture<$0.TunnelResponse> stop(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stop, request, options: options);
  }

  $grpc.ResponseFuture<$0.TunnelResponse> status(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$status, request, options: options);
  }

  $grpc.ResponseFuture<$0.TunnelResponse> exit(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exit, request, options: options);
  }

  // method descriptors

  static final _$start =
      $grpc.ClientMethod<$0.TunnelStartRequest, $0.TunnelResponse>(
          '/tunnelservice.TunnelService/Start',
          ($0.TunnelStartRequest value) => value.writeToBuffer(),
          $0.TunnelResponse.fromBuffer);
  static final _$stop = $grpc.ClientMethod<$1.Empty, $0.TunnelResponse>(
      '/tunnelservice.TunnelService/Stop',
      ($1.Empty value) => value.writeToBuffer(),
      $0.TunnelResponse.fromBuffer);
  static final _$status = $grpc.ClientMethod<$1.Empty, $0.TunnelResponse>(
      '/tunnelservice.TunnelService/Status',
      ($1.Empty value) => value.writeToBuffer(),
      $0.TunnelResponse.fromBuffer);
  static final _$exit = $grpc.ClientMethod<$1.Empty, $0.TunnelResponse>(
      '/tunnelservice.TunnelService/Exit',
      ($1.Empty value) => value.writeToBuffer(),
      $0.TunnelResponse.fromBuffer);
}

@$pb.GrpcServiceName('tunnelservice.TunnelService')
abstract class TunnelServiceBase extends $grpc.Service {
  $core.String get $name => 'tunnelservice.TunnelService';

  TunnelServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.TunnelStartRequest, $0.TunnelResponse>(
        'Start',
        start_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.TunnelStartRequest.fromBuffer(value),
        ($0.TunnelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.TunnelResponse>(
        'Stop',
        stop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.TunnelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.TunnelResponse>(
        'Status',
        status_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.TunnelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.TunnelResponse>(
        'Exit',
        exit_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.TunnelResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.TunnelResponse> start_Pre($grpc.ServiceCall $call,
      $async.Future<$0.TunnelStartRequest> $request) async {
    return start($call, await $request);
  }

  $async.Future<$0.TunnelResponse> start(
      $grpc.ServiceCall call, $0.TunnelStartRequest request);

  $async.Future<$0.TunnelResponse> stop_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return stop($call, await $request);
  }

  $async.Future<$0.TunnelResponse> stop(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.TunnelResponse> status_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return status($call, await $request);
  }

  $async.Future<$0.TunnelResponse> status(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.TunnelResponse> exit_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return exit($call, await $request);
  }

  $async.Future<$0.TunnelResponse> exit(
      $grpc.ServiceCall call, $1.Empty request);
}
