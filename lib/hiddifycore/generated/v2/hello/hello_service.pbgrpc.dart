///
//  Generated code. Do not modify.
//  source: v2/hello/hello_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'hello.pb.dart' as $3;
export 'hello_service.pb.dart';

class HelloClient extends $grpc.Client {
  static final _$sayHello =
      $grpc.ClientMethod<$3.HelloRequest, $3.HelloResponse>(
          '/hello.Hello/SayHello',
          ($3.HelloRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $3.HelloResponse.fromBuffer(value));
  static final _$sayHelloStream =
      $grpc.ClientMethod<$3.HelloRequest, $3.HelloResponse>(
          '/hello.Hello/SayHelloStream',
          ($3.HelloRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $3.HelloResponse.fromBuffer(value));

  HelloClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$3.HelloResponse> sayHello($3.HelloRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sayHello, request, options: options);
  }

  $grpc.ResponseStream<$3.HelloResponse> sayHelloStream(
      $async.Stream<$3.HelloRequest> request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$sayHelloStream, request, options: options);
  }
}

abstract class HelloServiceBase extends $grpc.Service {
  $core.String get $name => 'hello.Hello';

  HelloServiceBase() {
    $addMethod($grpc.ServiceMethod<$3.HelloRequest, $3.HelloResponse>(
        'SayHello',
        sayHello_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.HelloRequest.fromBuffer(value),
        ($3.HelloResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.HelloRequest, $3.HelloResponse>(
        'SayHelloStream',
        sayHelloStream,
        true,
        true,
        ($core.List<$core.int> value) => $3.HelloRequest.fromBuffer(value),
        ($3.HelloResponse value) => value.writeToBuffer()));
  }

  $async.Future<$3.HelloResponse> sayHello_Pre(
      $grpc.ServiceCall call, $async.Future<$3.HelloRequest> request) async {
    return sayHello(call, await request);
  }

  $async.Future<$3.HelloResponse> sayHello(
      $grpc.ServiceCall call, $3.HelloRequest request);
  $async.Stream<$3.HelloResponse> sayHelloStream(
      $grpc.ServiceCall call, $async.Stream<$3.HelloRequest> request);
}
