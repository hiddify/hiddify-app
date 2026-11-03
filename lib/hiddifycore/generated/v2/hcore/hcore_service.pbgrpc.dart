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

import '../hcommon/common.pb.dart' as $1;
import 'hcore.pb.dart' as $0;

export 'hcore_service.pb.dart';

@$pb.GrpcServiceName('hcore.Core')
class CoreClient extends $grpc.Client {
  static final _$start = $grpc.ClientMethod<$0.StartRequest, $0.CoreInfoResponse>(
      '/hcore.Core/Start',
      ($0.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreInfoResponse.fromBuffer(value));
  static final _$coreInfoListener = $grpc.ClientMethod<$1.Empty, $0.CoreInfoResponse>(
      '/hcore.Core/CoreInfoListener',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreInfoResponse.fromBuffer(value));
  static final _$outboundsInfo = $grpc.ClientMethod<$1.Empty, $0.OutboundGroupList>(
      '/hcore.Core/OutboundsInfo',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.OutboundGroupList.fromBuffer(value));
  static final _$mainOutboundsInfo = $grpc.ClientMethod<$1.Empty, $0.OutboundGroupList>(
      '/hcore.Core/MainOutboundsInfo',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.OutboundGroupList.fromBuffer(value));
  static final _$getSystemInfo = $grpc.ClientMethod<$1.Empty, $0.SystemInfo>(
      '/hcore.Core/GetSystemInfo',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SystemInfo.fromBuffer(value));
  static final _$getSystemInfoStream = $grpc.ClientMethod<$1.Empty, $0.SystemInfo>(
      '/hcore.Core/GetSystemInfoStream',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SystemInfo.fromBuffer(value));
  static final _$setup = $grpc.ClientMethod<$0.SetupRequest, $1.Response>(
      '/hcore.Core/Setup',
      ($0.SetupRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$parse = $grpc.ClientMethod<$0.ParseRequest, $0.ParseResponse>(
      '/hcore.Core/Parse',
      ($0.ParseRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ParseResponse.fromBuffer(value));
  static final _$changeHiddifySettings = $grpc.ClientMethod<$0.ChangeHiddifySettingsRequest, $0.CoreInfoResponse>(
      '/hcore.Core/ChangeHiddifySettings',
      ($0.ChangeHiddifySettingsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreInfoResponse.fromBuffer(value));
  static final _$startService = $grpc.ClientMethod<$0.StartRequest, $0.CoreInfoResponse>(
      '/hcore.Core/StartService',
      ($0.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreInfoResponse.fromBuffer(value));
  static final _$stop = $grpc.ClientMethod<$1.Empty, $0.CoreInfoResponse>(
      '/hcore.Core/Stop',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreInfoResponse.fromBuffer(value));
  static final _$restart = $grpc.ClientMethod<$0.StartRequest, $0.CoreInfoResponse>(
      '/hcore.Core/Restart',
      ($0.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreInfoResponse.fromBuffer(value));
  static final _$hotReload = $grpc.ClientMethod<$0.StartRequest, $0.CoreInfoResponse>(
      '/hcore.Core/HotReload',
      ($0.StartRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreInfoResponse.fromBuffer(value));
  static final _$selectOutbound = $grpc.ClientMethod<$0.SelectOutboundRequest, $1.Response>(
      '/hcore.Core/SelectOutbound',
      ($0.SelectOutboundRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$urlTest = $grpc.ClientMethod<$0.UrlTestRequest, $1.Response>(
      '/hcore.Core/UrlTest',
      ($0.UrlTestRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$urlTestActive = $grpc.ClientMethod<$1.Empty, $1.Response>(
      '/hcore.Core/UrlTestActive',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$uploadTest = $grpc.ClientMethod<$0.SpeedTestRequest, $1.Response>(
      '/hcore.Core/UploadTest',
      ($0.SpeedTestRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$downloadTest = $grpc.ClientMethod<$0.SpeedTestRequest, $1.Response>(
      '/hcore.Core/DownloadTest',
      ($0.SpeedTestRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$clearSpeedTests = $grpc.ClientMethod<$1.Empty, $1.Response>(
      '/hcore.Core/ClearSpeedTests',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$generateWarpConfig = $grpc.ClientMethod<$0.GenerateWarpConfigRequest, $0.WarpGenerationResponse>(
      '/hcore.Core/GenerateWarpConfig',
      ($0.GenerateWarpConfigRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.WarpGenerationResponse.fromBuffer(value));
  static final _$getSystemProxyStatus = $grpc.ClientMethod<$1.Empty, $0.SystemProxyStatus>(
      '/hcore.Core/GetSystemProxyStatus',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SystemProxyStatus.fromBuffer(value));
  static final _$setSystemProxyEnabled = $grpc.ClientMethod<$0.SetSystemProxyEnabledRequest, $1.Response>(
      '/hcore.Core/SetSystemProxyEnabled',
      ($0.SetSystemProxyEnabledRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$logListener = $grpc.ClientMethod<$0.LogRequest, $0.LogMessage>(
      '/hcore.Core/LogListener',
      ($0.LogRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.LogMessage.fromBuffer(value));
  static final _$close = $grpc.ClientMethod<$0.CloseRequest, $1.Empty>(
      '/hcore.Core/Close',
      ($0.CloseRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$getLANIP = $grpc.ClientMethod<$1.Empty, $0.LANIPResponse>(
      '/hcore.Core/GetLANIP',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.LANIPResponse.fromBuffer(value));
  static final _$isAdmin = $grpc.ClientMethod<$1.Empty, $0.IsAdminResponse>(
      '/hcore.Core/IsAdmin',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.IsAdminResponse.fromBuffer(value));
  static final _$needAdminBgService = $grpc.ClientMethod<$0.NeedAdminBgServiceRequest, $0.NeedAdminBgServiceResponse>(
      '/hcore.Core/NeedAdminBgService',
      ($0.NeedAdminBgServiceRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.NeedAdminBgServiceResponse.fromBuffer(value));
  static final _$ensureAdminBgService = $grpc.ClientMethod<$0.EnsureAdminBgServiceRequest, $0.EnsureAdminBgServiceEvent>(
      '/hcore.Core/EnsureAdminBgService',
      ($0.EnsureAdminBgServiceRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.EnsureAdminBgServiceEvent.fromBuffer(value));
  static final _$listCrashReports = $grpc.ClientMethod<$1.Empty, $0.CrashReportList>(
      '/hcore.Core/ListCrashReports',
      ($1.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CrashReportList.fromBuffer(value));
  static final _$exportDiagnostics = $grpc.ClientMethod<$0.ExportDiagnosticsRequest, $0.ExportDiagnosticsResponse>(
      '/hcore.Core/ExportDiagnostics',
      ($0.ExportDiagnosticsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ExportDiagnosticsResponse.fromBuffer(value));

  CoreClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.CoreInfoResponse> start($0.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$start, request, options: options);
  }

  $grpc.ResponseStream<$0.CoreInfoResponse> coreInfoListener($1.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$coreInfoListener, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseStream<$0.OutboundGroupList> outboundsInfo($1.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$outboundsInfo, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseStream<$0.OutboundGroupList> mainOutboundsInfo($1.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$mainOutboundsInfo, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.SystemInfo> getSystemInfo($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getSystemInfo, request, options: options);
  }

  $grpc.ResponseStream<$0.SystemInfo> getSystemInfoStream($1.Empty request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$getSystemInfoStream, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$1.Response> setup($0.SetupRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setup, request, options: options);
  }

  $grpc.ResponseFuture<$0.ParseResponse> parse($0.ParseRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$parse, request, options: options);
  }

  $grpc.ResponseFuture<$0.CoreInfoResponse> changeHiddifySettings($0.ChangeHiddifySettingsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$changeHiddifySettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.CoreInfoResponse> startService($0.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$startService, request, options: options);
  }

  $grpc.ResponseFuture<$0.CoreInfoResponse> stop($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$stop, request, options: options);
  }

  $grpc.ResponseFuture<$0.CoreInfoResponse> restart($0.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$restart, request, options: options);
  }

  $grpc.ResponseFuture<$0.CoreInfoResponse> hotReload($0.StartRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$hotReload, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> selectOutbound($0.SelectOutboundRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$selectOutbound, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> urlTest($0.UrlTestRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$urlTest, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> urlTestActive($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$urlTestActive, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> uploadTest($0.SpeedTestRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$uploadTest, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> downloadTest($0.SpeedTestRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$downloadTest, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> clearSpeedTests($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$clearSpeedTests, request, options: options);
  }

  $grpc.ResponseFuture<$0.WarpGenerationResponse> generateWarpConfig($0.GenerateWarpConfigRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$generateWarpConfig, request, options: options);
  }

  $grpc.ResponseFuture<$0.SystemProxyStatus> getSystemProxyStatus($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getSystemProxyStatus, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> setSystemProxyEnabled($0.SetSystemProxyEnabledRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setSystemProxyEnabled, request, options: options);
  }

  $grpc.ResponseStream<$0.LogMessage> logListener($0.LogRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$logListener, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$1.Empty> close($0.CloseRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$close, request, options: options);
  }

  $grpc.ResponseFuture<$0.LANIPResponse> getLANIP($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getLANIP, request, options: options);
  }

  $grpc.ResponseFuture<$0.IsAdminResponse> isAdmin($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$isAdmin, request, options: options);
  }

  $grpc.ResponseFuture<$0.NeedAdminBgServiceResponse> needAdminBgService($0.NeedAdminBgServiceRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$needAdminBgService, request, options: options);
  }

  $grpc.ResponseStream<$0.EnsureAdminBgServiceEvent> ensureAdminBgService($0.EnsureAdminBgServiceRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$ensureAdminBgService, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.CrashReportList> listCrashReports($1.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listCrashReports, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExportDiagnosticsResponse> exportDiagnostics($0.ExportDiagnosticsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$exportDiagnostics, request, options: options);
  }
}

@$pb.GrpcServiceName('hcore.Core')
abstract class CoreServiceBase extends $grpc.Service {
  $core.String get $name => 'hcore.Core';

  CoreServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StartRequest, $0.CoreInfoResponse>(
        'Start',
        start_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartRequest.fromBuffer(value),
        ($0.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.CoreInfoResponse>(
        'CoreInfoListener',
        coreInfoListener_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.OutboundGroupList>(
        'OutboundsInfo',
        outboundsInfo_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.OutboundGroupList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.OutboundGroupList>(
        'MainOutboundsInfo',
        mainOutboundsInfo_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.OutboundGroupList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.SystemInfo>(
        'GetSystemInfo',
        getSystemInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.SystemInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.SystemInfo>(
        'GetSystemInfoStream',
        getSystemInfoStream_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.SystemInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetupRequest, $1.Response>(
        'Setup',
        setup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetupRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ParseRequest, $0.ParseResponse>(
        'Parse',
        parse_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ParseRequest.fromBuffer(value),
        ($0.ParseResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangeHiddifySettingsRequest, $0.CoreInfoResponse>(
        'ChangeHiddifySettings',
        changeHiddifySettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ChangeHiddifySettingsRequest.fromBuffer(value),
        ($0.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartRequest, $0.CoreInfoResponse>(
        'StartService',
        startService_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartRequest.fromBuffer(value),
        ($0.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.CoreInfoResponse>(
        'Stop',
        stop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartRequest, $0.CoreInfoResponse>(
        'Restart',
        restart_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartRequest.fromBuffer(value),
        ($0.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartRequest, $0.CoreInfoResponse>(
        'HotReload',
        hotReload_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartRequest.fromBuffer(value),
        ($0.CoreInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SelectOutboundRequest, $1.Response>(
        'SelectOutbound',
        selectOutbound_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SelectOutboundRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UrlTestRequest, $1.Response>(
        'UrlTest',
        urlTest_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UrlTestRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $1.Response>(
        'UrlTestActive',
        urlTestActive_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SpeedTestRequest, $1.Response>(
        'UploadTest',
        uploadTest_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SpeedTestRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SpeedTestRequest, $1.Response>(
        'DownloadTest',
        downloadTest_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SpeedTestRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $1.Response>(
        'ClearSpeedTests',
        clearSpeedTests_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GenerateWarpConfigRequest, $0.WarpGenerationResponse>(
        'GenerateWarpConfig',
        generateWarpConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GenerateWarpConfigRequest.fromBuffer(value),
        ($0.WarpGenerationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.SystemProxyStatus>(
        'GetSystemProxyStatus',
        getSystemProxyStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.SystemProxyStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetSystemProxyEnabledRequest, $1.Response>(
        'SetSystemProxyEnabled',
        setSystemProxyEnabled_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetSystemProxyEnabledRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LogRequest, $0.LogMessage>(
        'LogListener',
        logListener_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.LogRequest.fromBuffer(value),
        ($0.LogMessage value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CloseRequest, $1.Empty>(
        'Close',
        close_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CloseRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.LANIPResponse>(
        'GetLANIP',
        getLANIP_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.LANIPResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.IsAdminResponse>(
        'IsAdmin',
        isAdmin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.IsAdminResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NeedAdminBgServiceRequest, $0.NeedAdminBgServiceResponse>(
        'NeedAdminBgService',
        needAdminBgService_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NeedAdminBgServiceRequest.fromBuffer(value),
        ($0.NeedAdminBgServiceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EnsureAdminBgServiceRequest, $0.EnsureAdminBgServiceEvent>(
        'EnsureAdminBgService',
        ensureAdminBgService_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.EnsureAdminBgServiceRequest.fromBuffer(value),
        ($0.EnsureAdminBgServiceEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.CrashReportList>(
        'ListCrashReports',
        listCrashReports_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.CrashReportList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExportDiagnosticsRequest, $0.ExportDiagnosticsResponse>(
        'ExportDiagnostics',
        exportDiagnostics_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExportDiagnosticsRequest.fromBuffer(value),
        ($0.ExportDiagnosticsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CoreInfoResponse> start_Pre($grpc.ServiceCall call, $async.Future<$0.StartRequest> request) async {
    return start(call, await request);
  }

  $async.Stream<$0.CoreInfoResponse> coreInfoListener_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async* {
    yield* coreInfoListener(call, await request);
  }

  $async.Stream<$0.OutboundGroupList> outboundsInfo_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async* {
    yield* outboundsInfo(call, await request);
  }

  $async.Stream<$0.OutboundGroupList> mainOutboundsInfo_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async* {
    yield* mainOutboundsInfo(call, await request);
  }

  $async.Future<$0.SystemInfo> getSystemInfo_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return getSystemInfo(call, await request);
  }

  $async.Stream<$0.SystemInfo> getSystemInfoStream_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async* {
    yield* getSystemInfoStream(call, await request);
  }

  $async.Future<$1.Response> setup_Pre($grpc.ServiceCall call, $async.Future<$0.SetupRequest> request) async {
    return setup(call, await request);
  }

  $async.Future<$0.ParseResponse> parse_Pre($grpc.ServiceCall call, $async.Future<$0.ParseRequest> request) async {
    return parse(call, await request);
  }

  $async.Future<$0.CoreInfoResponse> changeHiddifySettings_Pre($grpc.ServiceCall call, $async.Future<$0.ChangeHiddifySettingsRequest> request) async {
    return changeHiddifySettings(call, await request);
  }

  $async.Future<$0.CoreInfoResponse> startService_Pre($grpc.ServiceCall call, $async.Future<$0.StartRequest> request) async {
    return startService(call, await request);
  }

  $async.Future<$0.CoreInfoResponse> stop_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return stop(call, await request);
  }

  $async.Future<$0.CoreInfoResponse> restart_Pre($grpc.ServiceCall call, $async.Future<$0.StartRequest> request) async {
    return restart(call, await request);
  }

  $async.Future<$0.CoreInfoResponse> hotReload_Pre($grpc.ServiceCall call, $async.Future<$0.StartRequest> request) async {
    return hotReload(call, await request);
  }

  $async.Future<$1.Response> selectOutbound_Pre($grpc.ServiceCall call, $async.Future<$0.SelectOutboundRequest> request) async {
    return selectOutbound(call, await request);
  }

  $async.Future<$1.Response> urlTest_Pre($grpc.ServiceCall call, $async.Future<$0.UrlTestRequest> request) async {
    return urlTest(call, await request);
  }

  $async.Future<$1.Response> urlTestActive_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return urlTestActive(call, await request);
  }

  $async.Future<$1.Response> uploadTest_Pre($grpc.ServiceCall call, $async.Future<$0.SpeedTestRequest> request) async {
    return uploadTest(call, await request);
  }

  $async.Future<$1.Response> downloadTest_Pre($grpc.ServiceCall call, $async.Future<$0.SpeedTestRequest> request) async {
    return downloadTest(call, await request);
  }

  $async.Future<$1.Response> clearSpeedTests_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return clearSpeedTests(call, await request);
  }

  $async.Future<$0.WarpGenerationResponse> generateWarpConfig_Pre($grpc.ServiceCall call, $async.Future<$0.GenerateWarpConfigRequest> request) async {
    return generateWarpConfig(call, await request);
  }

  $async.Future<$0.SystemProxyStatus> getSystemProxyStatus_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return getSystemProxyStatus(call, await request);
  }

  $async.Future<$1.Response> setSystemProxyEnabled_Pre($grpc.ServiceCall call, $async.Future<$0.SetSystemProxyEnabledRequest> request) async {
    return setSystemProxyEnabled(call, await request);
  }

  $async.Stream<$0.LogMessage> logListener_Pre($grpc.ServiceCall call, $async.Future<$0.LogRequest> request) async* {
    yield* logListener(call, await request);
  }

  $async.Future<$1.Empty> close_Pre($grpc.ServiceCall call, $async.Future<$0.CloseRequest> request) async {
    return close(call, await request);
  }

  $async.Future<$0.LANIPResponse> getLANIP_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return getLANIP(call, await request);
  }

  $async.Future<$0.IsAdminResponse> isAdmin_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return isAdmin(call, await request);
  }

  $async.Future<$0.NeedAdminBgServiceResponse> needAdminBgService_Pre($grpc.ServiceCall call, $async.Future<$0.NeedAdminBgServiceRequest> request) async {
    return needAdminBgService(call, await request);
  }

  $async.Stream<$0.EnsureAdminBgServiceEvent> ensureAdminBgService_Pre($grpc.ServiceCall call, $async.Future<$0.EnsureAdminBgServiceRequest> request) async* {
    yield* ensureAdminBgService(call, await request);
  }

  $async.Future<$0.CrashReportList> listCrashReports_Pre($grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return listCrashReports(call, await request);
  }

  $async.Future<$0.ExportDiagnosticsResponse> exportDiagnostics_Pre($grpc.ServiceCall call, $async.Future<$0.ExportDiagnosticsRequest> request) async {
    return exportDiagnostics(call, await request);
  }

  $async.Future<$0.CoreInfoResponse> start($grpc.ServiceCall call, $0.StartRequest request);
  $async.Stream<$0.CoreInfoResponse> coreInfoListener($grpc.ServiceCall call, $1.Empty request);
  $async.Stream<$0.OutboundGroupList> outboundsInfo($grpc.ServiceCall call, $1.Empty request);
  $async.Stream<$0.OutboundGroupList> mainOutboundsInfo($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$0.SystemInfo> getSystemInfo($grpc.ServiceCall call, $1.Empty request);
  $async.Stream<$0.SystemInfo> getSystemInfoStream($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$1.Response> setup($grpc.ServiceCall call, $0.SetupRequest request);
  $async.Future<$0.ParseResponse> parse($grpc.ServiceCall call, $0.ParseRequest request);
  $async.Future<$0.CoreInfoResponse> changeHiddifySettings($grpc.ServiceCall call, $0.ChangeHiddifySettingsRequest request);
  $async.Future<$0.CoreInfoResponse> startService($grpc.ServiceCall call, $0.StartRequest request);
  $async.Future<$0.CoreInfoResponse> stop($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$0.CoreInfoResponse> restart($grpc.ServiceCall call, $0.StartRequest request);
  $async.Future<$0.CoreInfoResponse> hotReload($grpc.ServiceCall call, $0.StartRequest request);
  $async.Future<$1.Response> selectOutbound($grpc.ServiceCall call, $0.SelectOutboundRequest request);
  $async.Future<$1.Response> urlTest($grpc.ServiceCall call, $0.UrlTestRequest request);
  $async.Future<$1.Response> urlTestActive($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$1.Response> uploadTest($grpc.ServiceCall call, $0.SpeedTestRequest request);
  $async.Future<$1.Response> downloadTest($grpc.ServiceCall call, $0.SpeedTestRequest request);
  $async.Future<$1.Response> clearSpeedTests($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$0.WarpGenerationResponse> generateWarpConfig($grpc.ServiceCall call, $0.GenerateWarpConfigRequest request);
  $async.Future<$0.SystemProxyStatus> getSystemProxyStatus($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$1.Response> setSystemProxyEnabled($grpc.ServiceCall call, $0.SetSystemProxyEnabledRequest request);
  $async.Stream<$0.LogMessage> logListener($grpc.ServiceCall call, $0.LogRequest request);
  $async.Future<$1.Empty> close($grpc.ServiceCall call, $0.CloseRequest request);
  $async.Future<$0.LANIPResponse> getLANIP($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$0.IsAdminResponse> isAdmin($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$0.NeedAdminBgServiceResponse> needAdminBgService($grpc.ServiceCall call, $0.NeedAdminBgServiceRequest request);
  $async.Stream<$0.EnsureAdminBgServiceEvent> ensureAdminBgService($grpc.ServiceCall call, $0.EnsureAdminBgServiceRequest request);
  $async.Future<$0.CrashReportList> listCrashReports($grpc.ServiceCall call, $1.Empty request);
  $async.Future<$0.ExportDiagnosticsResponse> exportDiagnostics($grpc.ServiceCall call, $0.ExportDiagnosticsRequest request);
}
