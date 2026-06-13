// This is a generated file - do not edit.
//
// Generated from v2/ezytel/ezytel_service.proto.

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

import 'ezytel.pb.dart' as $0;

export 'ezytel_service.pb.dart';

/// Ezytel exposes the Telegram public-channel viewer originally shipped as
/// the ezytel.zip PHP app. Traffic to t.me is routed through Google's
/// translate.goog domain front so it reaches users behind GFW-style filters.
@$pb.GrpcServiceName('ezytel.Ezytel')
class EzytelClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EzytelClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ChannelInfo> getChannelInfo(
    $0.ChannelInfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getChannelInfo, request, options: options);
  }

  $grpc.ResponseFuture<$0.ChannelMessagesResponse> getChannelMessages(
    $0.ChannelMessagesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getChannelMessages, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProxyImageResponse> proxyImage(
    $0.ProxyImageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$proxyImage, request, options: options);
  }

  $grpc.ResponseFuture<$0.ParseChannelsResponse> parseChannels(
    $0.ParseChannelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$parseChannels, request, options: options);
  }

  // method descriptors

  static final _$getChannelInfo =
      $grpc.ClientMethod<$0.ChannelInfoRequest, $0.ChannelInfo>(
          '/ezytel.Ezytel/GetChannelInfo',
          ($0.ChannelInfoRequest value) => value.writeToBuffer(),
          $0.ChannelInfo.fromBuffer);
  static final _$getChannelMessages =
      $grpc.ClientMethod<$0.ChannelMessagesRequest, $0.ChannelMessagesResponse>(
          '/ezytel.Ezytel/GetChannelMessages',
          ($0.ChannelMessagesRequest value) => value.writeToBuffer(),
          $0.ChannelMessagesResponse.fromBuffer);
  static final _$proxyImage =
      $grpc.ClientMethod<$0.ProxyImageRequest, $0.ProxyImageResponse>(
          '/ezytel.Ezytel/ProxyImage',
          ($0.ProxyImageRequest value) => value.writeToBuffer(),
          $0.ProxyImageResponse.fromBuffer);
  static final _$parseChannels =
      $grpc.ClientMethod<$0.ParseChannelsRequest, $0.ParseChannelsResponse>(
          '/ezytel.Ezytel/ParseChannels',
          ($0.ParseChannelsRequest value) => value.writeToBuffer(),
          $0.ParseChannelsResponse.fromBuffer);
}

@$pb.GrpcServiceName('ezytel.Ezytel')
abstract class EzytelServiceBase extends $grpc.Service {
  $core.String get $name => 'ezytel.Ezytel';

  EzytelServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ChannelInfoRequest, $0.ChannelInfo>(
        'GetChannelInfo',
        getChannelInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChannelInfoRequest.fromBuffer(value),
        ($0.ChannelInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChannelMessagesRequest,
            $0.ChannelMessagesResponse>(
        'GetChannelMessages',
        getChannelMessages_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChannelMessagesRequest.fromBuffer(value),
        ($0.ChannelMessagesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProxyImageRequest, $0.ProxyImageResponse>(
        'ProxyImage',
        proxyImage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ProxyImageRequest.fromBuffer(value),
        ($0.ProxyImageResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ParseChannelsRequest, $0.ParseChannelsResponse>(
            'ParseChannels',
            parseChannels_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ParseChannelsRequest.fromBuffer(value),
            ($0.ParseChannelsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ChannelInfo> getChannelInfo_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ChannelInfoRequest> $request) async {
    return getChannelInfo($call, await $request);
  }

  $async.Future<$0.ChannelInfo> getChannelInfo(
      $grpc.ServiceCall call, $0.ChannelInfoRequest request);

  $async.Future<$0.ChannelMessagesResponse> getChannelMessages_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChannelMessagesRequest> $request) async {
    return getChannelMessages($call, await $request);
  }

  $async.Future<$0.ChannelMessagesResponse> getChannelMessages(
      $grpc.ServiceCall call, $0.ChannelMessagesRequest request);

  $async.Future<$0.ProxyImageResponse> proxyImage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ProxyImageRequest> $request) async {
    return proxyImage($call, await $request);
  }

  $async.Future<$0.ProxyImageResponse> proxyImage(
      $grpc.ServiceCall call, $0.ProxyImageRequest request);

  $async.Future<$0.ParseChannelsResponse> parseChannels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ParseChannelsRequest> $request) async {
    return parseChannels($call, await $request);
  }

  $async.Future<$0.ParseChannelsResponse> parseChannels(
      $grpc.ServiceCall call, $0.ParseChannelsRequest request);
}
