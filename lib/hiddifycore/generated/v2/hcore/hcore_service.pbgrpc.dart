//
//  Generated code. Do not modify.
//  source: v2/hcore/hcore_service.proto
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

import '../hcommon/common.pb.dart' as $2;
import 'hcore.pb.dart' as $1;

export 'hcore_service.pb.dart';

@$pb.GrpcServiceName('hcore.Core')
class CoreClient extends $grpc.Client {
  static final _$start = $grpc.ClientMethod<$1.StartRequest, $1.CoreInfoResponse>(
      '/hcore.Core/Start',
      ($1.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.CoreInfoResponse.fromBuffer(value));
  static final _$coreInfoListener = $grpc.ClientMethod<$2.Empty, $1.CoreInfoResponse>(
      '/hcore.Core/CoreInfoListener',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.CoreInfoResponse.fromBuffer(value));
  static final _$outboundsInfo = $grpc.ClientMethod<$2.Empty, $1.OutboundGroupList>(
      '/hcore.Core/OutboundsInfo',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.OutboundGroupList.fromBuffer(value));
  static final _$mainOutboundsInfo = $grpc.ClientMethod<$2.Empty, $1.OutboundGroupList>(
      '/hcore.Core/MainOutboundsInfo',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.OutboundGroupList.fromBuffer(value));
  static final _$getSystemInfo = $grpc.ClientMethod<$2.Empty, $1.SystemInfo>(
      '/hcore.Core/GetSystemInfo',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.SystemInfo.fromBuffer(value));
  static final _$getSystemInfoStream = $grpc.ClientMethod<$2.Empty, $1.SystemInfo>(
      '/hcore.Core/GetSystemInfoStream',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.SystemInfo.fromBuffer(value));
  static final _$setup = $grpc.ClientMethod<$1.SetupRequest, $2.Response>(
      '/hcore.Core/Setup',
      ($1.SetupRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.Response.fromBuffer(value));
  static final _$parse = $grpc.ClientMethod<$1.ParseRequest, $1.ParseResponse>(
      '/hcore.Core/Parse',
      ($1.ParseRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.ParseResponse.fromBuffer(value));
  static final _$changeHiddifySettings = $grpc.ClientMethod<$1.ChangeHiddifySettingsRequest, $1.CoreInfoResponse>(
      '/hcore.Core/ChangeHiddifySettings',
      ($1.ChangeHiddifySettingsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.CoreInfoResponse.fromBuffer(value));
  static final _$startService = $grpc.ClientMethod<$1.StartRequest, $1.CoreInfoResponse>(
      '/hcore.Core/StartService',
      ($1.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.CoreInfoResponse.fromBuffer(value));
  static final _$stop = $grpc.ClientMethod<$2.Empty, $1.CoreInfoResponse>(
      '/hcore.Core/Stop',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.CoreInfoResponse.fromBuffer(value));
  static final _$restart = $grpc.ClientMethod<$1.StartRequest, $1.CoreInfoResponse>(
      '/hcore.Core/Restart',
      ($1.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.CoreInfoResponse.fromBuffer(value));
  static final _$hotReload = $grpc.ClientMethod<$1.StartRequest, $1.CoreInfoResponse>(
      '/hcore.Core/HotReload',
      ($1.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.CoreInfoResponse.fromBuffer(value));
  static final _$selectOutbound = $grpc.ClientMethod<$1.SelectOutboundRequest, $2.Response>(
      '/hcore.Core/SelectOutbound',
      ($1.SelectOutboundRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.Response.fromBuffer(value));
  static final _$urlTest = $grpc.ClientMethod<$1.UrlTestRequest, $2.Response>(
      '/hcore.Core/UrlTest',
      ($1.UrlTestRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.Response.fromBuffer(value));
  static final _$urlTestActive = $grpc.ClientMethod<$2.Empty, $2.Response>(
      '/hcore.Core/UrlTestActive',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.Response.fromBuffer(value));
  static final _$generateWarpConfig = $grpc.ClientMethod<$1.GenerateWarpConfigRequest, $1.WarpGenerationResponse>(
      '/hcore.Core/GenerateWarpConfig',
      ($1.GenerateWarpConfigRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.WarpGenerationResponse.fromBuffer(value));
  static final _$getSystemProxyStatus = $grpc.ClientMethod<$2.Empty, $1.SystemProxyStatus>(
      '/hcore.Core/GetSystemProxyStatus',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.SystemProxyStatus.fromBuffer(value));
  static final _$setSystemProxyEnabled = $grpc.ClientMethod<$1.SetSystemProxyEnabledRequest, $2.Response>(
      '/hcore.Core/SetSystemProxyEnabled',
      ($1.SetSystemProxyEnabledRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.Response.fromBuffer(value));
  static final _$logListener = $grpc.ClientMethod<$1.LogRequest, $1.LogMessage>(
      '/hcore.Core/LogListener',
      ($1.LogRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.LogMessage.fromBuffer(value));
  static final _$close = $grpc.ClientMethod<$1.CloseRequest, $2.Empty>(
      '/hcore.Core/Close',
      ($1.CloseRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.Empty.fromBuffer(value));
  static final _$getLANIP = $grpc.ClientMethod<$2.Empty, $1.LANIPResponse>(
      '/hcore.Core/GetLANIP',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.LANIPResponse.fromBuffer(value));
  static final _$isAdmin = $grpc.ClientMethod<$2.Empty, $1.IsAdminResponse>(
      '/hcore.Core/IsAdmin',
      ($2.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.IsAdminResponse.fromBuffer(value));
  static final _$needAdminBgService = $grpc.ClientMethod<$1.NeedAdminBgServiceRequest, $1.NeedAdminBgServiceResponse>(
      '/hcore.Core/NeedAdminBgService',
      ($1.NeedAdminBgServiceRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.NeedAdminBgServiceResponse.fromBuffer(value));
  static final _$ensureAdminBgService = $grpc.ClientMethod<$1.EnsureAdminBgServiceRequest, $1.EnsureAdminBgServiceEvent>(
      '/hcore.Core/EnsureAdminBgService',
      ($1.EnsureAdminBgServiceRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.EnsureAdminBgServiceEvent.fromBuffer(value));

  CoreClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$1.CoreInfoResponse> start($1.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$start, request, options: options);
  }

  $grpc.ResponseStream<$1.CoreInfoResponse> coreInfoListener($2.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$coreInfoListener, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseStream<$1.OutboundGroupList> outboundsInfo($2.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$outboundsInfo, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseStream<$1.OutboundGroupList> mainOutboundsInfo($2.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$mainOutboundsInfo, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$1.SystemInfo> getSystemInfo($2.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getSystemInfo, request, options: options);
  }

  $grpc.ResponseStream<$1.SystemInfo> getSystemInfoStream($2.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$getSystemInfoStream, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$2.Response> setup($1.SetupRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setup, request, options: options);
  }

  $grpc.ResponseFuture<$1.ParseResponse> parse($1.ParseRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$parse, request, options: options);
  }

  $grpc.ResponseFuture<$1.CoreInfoResponse> changeHiddifySettings($1.ChangeHiddifySettingsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$changeHiddifySettings, request, options: options);
  }

  $grpc.ResponseFuture<$1.CoreInfoResponse> startService($1.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$startService, request, options: options);
  }

  $grpc.ResponseFuture<$1.CoreInfoResponse> stop($2.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$stop, request, options: options);
  }

  $grpc.ResponseFuture<$1.CoreInfoResponse> restart($1.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$restart, request, options: options);
  }

  $grpc.ResponseFuture<$1.CoreInfoResponse> hotReload($1.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$hotReload, request, options: options);
  }

  $grpc.ResponseFuture<$2.Response> selectOutbound($1.SelectOutboundRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$selectOutbound, request, options: options);
  }

  $grpc.ResponseFuture<$2.Response> urlTest($1.UrlTestRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$urlTest, request, options: options);
  }

  $grpc.ResponseFuture<$2.Response> urlTestActive($2.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$urlTestActive, request, options: options);
  }

  $grpc.ResponseFuture<$1.WarpGenerationResponse> generateWarpConfig($1.GenerateWarpConfigRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$generateWarpConfig, request, options: options);
  }

  $grpc.ResponseFuture<$1.SystemProxyStatus> getSystemProxyStatus($2.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getSystemProxyStatus, request, options: options);
  }

  $grpc.ResponseFuture<$2.Response> setSystemProxyEnabled($1.SetSystemProxyEnabledRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setSystemProxyEnabled, request, options: options);
  }

  $grpc.ResponseStream<$1.LogMessage> logListener($1.LogRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$logListener, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$2.Empty> close($1.CloseRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$close, request, options: options);
  }

  $grpc.ResponseFuture<$1.LANIPResponse> getLANIP($2.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getLANIP, request, options: options);
  }

  $grpc.ResponseFuture<$1.IsAdminResponse> isAdmin($2.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$isAdmin, request, options: options);
  }

  $grpc.ResponseFuture<$1.NeedAdminBgServiceResponse> needAdminBgService($1.NeedAdminBgServiceRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$needAdminBgService, request, options: options);
  }

  $grpc.ResponseStream<$1.EnsureAdminBgServiceEvent> ensureAdminBgService($1.EnsureAdminBgServiceRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$ensureAdminBgService, $async.Stream.fromIterable([request]), options: options);
  }
}

@$pb.GrpcServiceName('hcore.Core')
abstract class CoreServiceBase extends $grpc.Service {
  $core.String get $name => 'hcore.Core';

  CoreServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.StartRequest, $1.CoreInfoResponse>(
        'Start',
        start_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.StartRequest.fromBuffer(value),
        ($1.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.CoreInfoResponse>(
        'CoreInfoListener',
        coreInfoListener_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.OutboundGroupList>(
        'OutboundsInfo',
        outboundsInfo_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.OutboundGroupList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.OutboundGroupList>(
        'MainOutboundsInfo',
        mainOutboundsInfo_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.OutboundGroupList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.SystemInfo>(
        'GetSystemInfo',
        getSystemInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.SystemInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.SystemInfo>(
        'GetSystemInfoStream',
        getSystemInfoStream_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.SystemInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SetupRequest, $2.Response>(
        'Setup',
        setup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SetupRequest.fromBuffer(value),
        ($2.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ParseRequest, $1.ParseResponse>(
        'Parse',
        parse_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.ParseRequest.fromBuffer(value),
        ($1.ParseResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ChangeHiddifySettingsRequest, $1.CoreInfoResponse>(
        'ChangeHiddifySettings',
        changeHiddifySettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.ChangeHiddifySettingsRequest.fromBuffer(value),
        ($1.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StartRequest, $1.CoreInfoResponse>(
        'StartService',
        startService_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.StartRequest.fromBuffer(value),
        ($1.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.CoreInfoResponse>(
        'Stop',
        stop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StartRequest, $1.CoreInfoResponse>(
        'Restart',
        restart_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.StartRequest.fromBuffer(value),
        ($1.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StartRequest, $1.CoreInfoResponse>(
        'HotReload',
        hotReload_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.StartRequest.fromBuffer(value),
        ($1.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SelectOutboundRequest, $2.Response>(
        'SelectOutbound',
        selectOutbound_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SelectOutboundRequest.fromBuffer(value),
        ($2.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.UrlTestRequest, $2.Response>(
        'UrlTest',
        urlTest_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.UrlTestRequest.fromBuffer(value),
        ($2.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $2.Response>(
        'UrlTestActive',
        urlTestActive_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($2.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GenerateWarpConfigRequest, $1.WarpGenerationResponse>(
        'GenerateWarpConfig',
        generateWarpConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GenerateWarpConfigRequest.fromBuffer(value),
        ($1.WarpGenerationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.SystemProxyStatus>(
        'GetSystemProxyStatus',
        getSystemProxyStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.SystemProxyStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SetSystemProxyEnabledRequest, $2.Response>(
        'SetSystemProxyEnabled',
        setSystemProxyEnabled_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SetSystemProxyEnabledRequest.fromBuffer(value),
        ($2.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.LogRequest, $1.LogMessage>(
        'LogListener',
        logListener_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.LogRequest.fromBuffer(value),
        ($1.LogMessage value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.CloseRequest, $2.Empty>(
        'Close',
        close_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.CloseRequest.fromBuffer(value),
        ($2.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.LANIPResponse>(
        'GetLANIP',
        getLANIP_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.LANIPResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $1.IsAdminResponse>(
        'IsAdmin',
        isAdmin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($1.IsAdminResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.NeedAdminBgServiceRequest, $1.NeedAdminBgServiceResponse>(
        'NeedAdminBgService',
        needAdminBgService_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.NeedAdminBgServiceRequest.fromBuffer(value),
        ($1.NeedAdminBgServiceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.EnsureAdminBgServiceRequest, $1.EnsureAdminBgServiceEvent>(
        'EnsureAdminBgService',
        ensureAdminBgService_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.EnsureAdminBgServiceRequest.fromBuffer(value),
        ($1.EnsureAdminBgServiceEvent value) => value.writeToBuffer()));
  }

  $async.Future<$1.CoreInfoResponse> start_Pre($grpc.ServiceCall call, $async.Future<$1.StartRequest> request) async {
    return start(call, await request);
  }

  $async.Stream<$1.CoreInfoResponse> coreInfoListener_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async* {
    yield* coreInfoListener(call, await request);
  }

  $async.Stream<$1.OutboundGroupList> outboundsInfo_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async* {
    yield* outboundsInfo(call, await request);
  }

  $async.Stream<$1.OutboundGroupList> mainOutboundsInfo_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async* {
    yield* mainOutboundsInfo(call, await request);
  }

  $async.Future<$1.SystemInfo> getSystemInfo_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async {
    return getSystemInfo(call, await request);
  }

  $async.Stream<$1.SystemInfo> getSystemInfoStream_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async* {
    yield* getSystemInfoStream(call, await request);
  }

  $async.Future<$2.Response> setup_Pre($grpc.ServiceCall call, $async.Future<$1.SetupRequest> request) async {
    return setup(call, await request);
  }

  $async.Future<$1.ParseResponse> parse_Pre($grpc.ServiceCall call, $async.Future<$1.ParseRequest> request) async {
    return parse(call, await request);
  }

  $async.Future<$1.CoreInfoResponse> changeHiddifySettings_Pre($grpc.ServiceCall call, $async.Future<$1.ChangeHiddifySettingsRequest> request) async {
    return changeHiddifySettings(call, await request);
  }

  $async.Future<$1.CoreInfoResponse> startService_Pre($grpc.ServiceCall call, $async.Future<$1.StartRequest> request) async {
    return startService(call, await request);
  }

  $async.Future<$1.CoreInfoResponse> stop_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async {
    return stop(call, await request);
  }

  $async.Future<$1.CoreInfoResponse> restart_Pre($grpc.ServiceCall call, $async.Future<$1.StartRequest> request) async {
    return restart(call, await request);
  }

  $async.Future<$1.CoreInfoResponse> hotReload_Pre($grpc.ServiceCall call, $async.Future<$1.StartRequest> request) async {
    return hotReload(call, await request);
  }

  $async.Future<$2.Response> selectOutbound_Pre($grpc.ServiceCall call, $async.Future<$1.SelectOutboundRequest> request) async {
    return selectOutbound(call, await request);
  }

  $async.Future<$2.Response> urlTest_Pre($grpc.ServiceCall call, $async.Future<$1.UrlTestRequest> request) async {
    return urlTest(call, await request);
  }

  $async.Future<$2.Response> urlTestActive_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async {
    return urlTestActive(call, await request);
  }

  $async.Future<$1.WarpGenerationResponse> generateWarpConfig_Pre($grpc.ServiceCall call, $async.Future<$1.GenerateWarpConfigRequest> request) async {
    return generateWarpConfig(call, await request);
  }

  $async.Future<$1.SystemProxyStatus> getSystemProxyStatus_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async {
    return getSystemProxyStatus(call, await request);
  }

  $async.Future<$2.Response> setSystemProxyEnabled_Pre($grpc.ServiceCall call, $async.Future<$1.SetSystemProxyEnabledRequest> request) async {
    return setSystemProxyEnabled(call, await request);
  }

  $async.Stream<$1.LogMessage> logListener_Pre($grpc.ServiceCall call, $async.Future<$1.LogRequest> request) async* {
    yield* logListener(call, await request);
  }

  $async.Future<$2.Empty> close_Pre($grpc.ServiceCall call, $async.Future<$1.CloseRequest> request) async {
    return close(call, await request);
  }

  $async.Future<$1.LANIPResponse> getLANIP_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async {
    return getLANIP(call, await request);
  }

  $async.Future<$1.IsAdminResponse> isAdmin_Pre($grpc.ServiceCall call, $async.Future<$2.Empty> request) async {
    return isAdmin(call, await request);
  }

  $async.Future<$1.NeedAdminBgServiceResponse> needAdminBgService_Pre($grpc.ServiceCall call, $async.Future<$1.NeedAdminBgServiceRequest> request) async {
    return needAdminBgService(call, await request);
  }

  $async.Stream<$1.EnsureAdminBgServiceEvent> ensureAdminBgService_Pre($grpc.ServiceCall call, $async.Future<$1.EnsureAdminBgServiceRequest> request) async* {
    yield* ensureAdminBgService(call, await request);
  }

  $async.Future<$1.CoreInfoResponse> start($grpc.ServiceCall call, $1.StartRequest request);
  $async.Stream<$1.CoreInfoResponse> coreInfoListener($grpc.ServiceCall call, $2.Empty request);
  $async.Stream<$1.OutboundGroupList> outboundsInfo($grpc.ServiceCall call, $2.Empty request);
  $async.Stream<$1.OutboundGroupList> mainOutboundsInfo($grpc.ServiceCall call, $2.Empty request);
  $async.Future<$1.SystemInfo> getSystemInfo($grpc.ServiceCall call, $2.Empty request);
  $async.Stream<$1.SystemInfo> getSystemInfoStream($grpc.ServiceCall call, $2.Empty request);
  $async.Future<$2.Response> setup($grpc.ServiceCall call, $1.SetupRequest request);
  $async.Future<$1.ParseResponse> parse($grpc.ServiceCall call, $1.ParseRequest request);
  $async.Future<$1.CoreInfoResponse> changeHiddifySettings($grpc.ServiceCall call, $1.ChangeHiddifySettingsRequest request);
  $async.Future<$1.CoreInfoResponse> startService($grpc.ServiceCall call, $1.StartRequest request);
  $async.Future<$1.CoreInfoResponse> stop($grpc.ServiceCall call, $2.Empty request);
  $async.Future<$1.CoreInfoResponse> restart($grpc.ServiceCall call, $1.StartRequest request);
  $async.Future<$1.CoreInfoResponse> hotReload($grpc.ServiceCall call, $1.StartRequest request);
  $async.Future<$2.Response> selectOutbound($grpc.ServiceCall call, $1.SelectOutboundRequest request);
  $async.Future<$2.Response> urlTest($grpc.ServiceCall call, $1.UrlTestRequest request);
  $async.Future<$2.Response> urlTestActive($grpc.ServiceCall call, $2.Empty request);
  $async.Future<$1.WarpGenerationResponse> generateWarpConfig($grpc.ServiceCall call, $1.GenerateWarpConfigRequest request);
  $async.Future<$1.SystemProxyStatus> getSystemProxyStatus($grpc.ServiceCall call, $2.Empty request);
  $async.Future<$2.Response> setSystemProxyEnabled($grpc.ServiceCall call, $1.SetSystemProxyEnabledRequest request);
  $async.Stream<$1.LogMessage> logListener($grpc.ServiceCall call, $1.LogRequest request);
  $async.Future<$2.Empty> close($grpc.ServiceCall call, $1.CloseRequest request);
  $async.Future<$1.LANIPResponse> getLANIP($grpc.ServiceCall call, $2.Empty request);
  $async.Future<$1.IsAdminResponse> isAdmin($grpc.ServiceCall call, $2.Empty request);
  $async.Future<$1.NeedAdminBgServiceResponse> needAdminBgService($grpc.ServiceCall call, $1.NeedAdminBgServiceRequest request);
  $async.Stream<$1.EnsureAdminBgServiceEvent> ensureAdminBgService($grpc.ServiceCall call, $1.EnsureAdminBgServiceRequest request);
}
