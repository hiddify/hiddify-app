//
//  Generated code. Do not modify.
//  source: v2/hello/hello_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'hello.pb.dart' as $5;

export 'hello_service.pb.dart';

@$pb.GrpcServiceName('hello.Hello')
class HelloClient extends $grpc.Client {
  static final _$sayHello = $grpc.ClientMethod<$5.HelloRequest, $5.HelloResponse>(
      '/hello.Hello/SayHello',
      ($5.HelloRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.HelloResponse.fromBuffer(value));
  static final _$sayHelloStream = $grpc.ClientMethod<$5.HelloRequest, $5.HelloResponse>(
      '/hello.Hello/SayHelloStream',
      ($5.HelloRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.HelloResponse.fromBuffer(value));

  HelloClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$5.HelloResponse> sayHello($5.HelloRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sayHello, request, options: options);
  }

  $grpc.ResponseStream<$5.HelloResponse> sayHelloStream($async.Stream<$5.HelloRequest> request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$sayHelloStream, request, options: options);
  }
}

@$pb.GrpcServiceName('hello.Hello')
abstract class HelloServiceBase extends $grpc.Service {
  $core.String get $name => 'hello.Hello';

  HelloServiceBase() {
    $addMethod($grpc.ServiceMethod<$5.HelloRequest, $5.HelloResponse>(
        'SayHello',
        sayHello_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.HelloRequest.fromBuffer(value),
        ($5.HelloResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.HelloRequest, $5.HelloResponse>(
        'SayHelloStream',
        sayHelloStream,
        true,
        true,
        ($core.List<$core.int> value) => $5.HelloRequest.fromBuffer(value),
        ($5.HelloResponse value) => value.writeToBuffer()));
  }

  $async.Future<$5.HelloResponse> sayHello_Pre($grpc.ServiceCall call, $async.Future<$5.HelloRequest> request) async {
    return sayHello(call, await request);
  }

  $async.Future<$5.HelloResponse> sayHello($grpc.ServiceCall call, $5.HelloRequest request);
  $async.Stream<$5.HelloResponse> sayHelloStream($grpc.ServiceCall call, $async.Stream<$5.HelloRequest> request);
}
