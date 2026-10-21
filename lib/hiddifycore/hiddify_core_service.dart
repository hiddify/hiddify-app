import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_mobile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/features/log/model/log_level.dart' as config_log_level;
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';

import 'package:hiddify/hiddifycore/core_interface/core_interface_wrapper_stub.dart'
    if (dart.library.io) 'package:hiddify/hiddifycore/core_interface/core_interface_wrapper.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loggy/loggy.dart' as loggyl;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

final class HiddifyCoreInitializationException implements Exception {
  const HiddifyCoreInitializationException();

  @override
  String toString() => 'HiddifyCoreInitializationException';
}

final class _ForegroundReadinessException implements Exception {
  const _ForegroundReadinessException();
}

// Canonical gRPC status numbers, without message, metadata or private details.
const _grpcSetupEvents = [
  IosPingEvent.coreSetupGrpcOk,
  IosPingEvent.coreSetupGrpcCancelled,
  IosPingEvent.coreSetupGrpcUnknown,
  IosPingEvent.coreSetupGrpcInvalidArgument,
  IosPingEvent.coreSetupGrpcDeadlineExceeded,
  IosPingEvent.coreSetupGrpcNotFound,
  IosPingEvent.coreSetupGrpcAlreadyExists,
  IosPingEvent.coreSetupGrpcPermissionDenied,
  IosPingEvent.coreSetupGrpcResourceExhausted,
  IosPingEvent.coreSetupGrpcFailedPrecondition,
  IosPingEvent.coreSetupGrpcAborted,
  IosPingEvent.coreSetupGrpcOutOfRange,
  IosPingEvent.coreSetupGrpcUnimplemented,
  IosPingEvent.coreSetupGrpcInternal,
  IosPingEvent.coreSetupGrpcUnavailable,
  IosPingEvent.coreSetupGrpcDataLoss,
  IosPingEvent.coreSetupGrpcUnauthenticated,
];

class HiddifyCoreService with InfraLogger {
  HiddifyCoreService(this.ref);
  final Ref ref;

  // CoreHiddifyCoreService() {}
  final core = getCoreInterface();

  CoreStatus currentState = const CoreStatus.stopped();
  final statusController = BehaviorSubject<CoreStatus>();
  final logController = BehaviorSubject<List<LogMessage>>();
  final CallOptions? grpcOptions = null; //CallOptions(timeout: const Duration(milliseconds: 10000));
  final Map<String, StreamSubscription?> subscriptions = {};
  List<OutboundGroup> latest = [];

  Future<void> _lifecycle = Future.value();
  int _foregroundGeneration = 0;
  Future<bool>? _foregroundReadiness;
  int? _foregroundReadinessGeneration;
  int _pauseTraceOperationId = 0;
  StreamSubscription<CoreStatus>? _systemStatusSubscription;
  int _systemStatusRevision = 0;
  bool _systemStatusAuthoritative = false;
  bool _appStartInProgress = false;
  CoreStatus? _deferredSystemStatus;
  CoreStopped? _appStartCoreFailure;

  Future<void> pause() {
    _foregroundGeneration++;
    return _queueLifecycle(() async {
      _recordPingTrace(IosPingEvent.corePauseStatusCancel, operationId: _pauseTraceOperationId);
      await _stopSystemStatusSync();
      _recordPingTrace(IosPingEvent.corePauseCloseFront, operationId: _pauseTraceOperationId);
      await closeFront();
    }, pausing: true);
  }

  Future<void> resume() async {
    if (!core.supportsSystemStatus) return _queueLifecycle(init);
    await ensureForegroundReady();
  }

  Future<bool> ensureForegroundReady() {
    if (!core.supportsSystemStatus) {
      return _queueLifecycle(init).then((_) => true);
    }

    final generation = _foregroundGeneration;
    final current = _foregroundReadiness;
    if (current != null && _foregroundReadinessGeneration == generation) return current;

    late final Future<bool> readiness;
    readiness =
        _queueLifecycle(() async {
          if (generation != _foregroundGeneration) throw const _ForegroundReadinessException();
          final result = await setup().run();
          if (result.isLeft() || generation != _foregroundGeneration) {
            throw const _ForegroundReadinessException();
          }
          _publishCoreRestart();
        }).then((_) => true, onError: (Object _, StackTrace _) => false).whenComplete(() {
          if (identical(_foregroundReadiness, readiness)) {
            _foregroundReadiness = null;
            _foregroundReadinessGeneration = null;
          }
        });
    _foregroundReadiness = readiness;
    _foregroundReadinessGeneration = generation;
    return readiness;
  }

  Future<void> _queueLifecycle(Future<void> Function() operation, {bool pausing = false}) {
    final next = core.supportsSystemStatus
        ? _tracedLifecycleOperation(operation, pausing: pausing)
        : _lifecycle.then((_) => operation());
    // A failed request must not prevent a later resume from retrying.
    _lifecycle = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _tracedLifecycleOperation(Future<void> Function() operation, {required bool pausing}) {
    final id = _beginPingTrace(pausing ? IosPingEvent.corePauseQueued : IosPingEvent.coreResumeQueued);
    return _lifecycle.then((_) async {
      if (pausing) _pauseTraceOperationId = id;
      _recordPingTrace(pausing ? IosPingEvent.corePauseStarted : IosPingEvent.coreResumeStarted, operationId: id);
      try {
        await operation();
        _recordPingTrace(pausing ? IosPingEvent.corePauseCompleted : IosPingEvent.coreResumeCompleted, operationId: id);
      } on Object {
        _recordPingTrace(pausing ? IosPingEvent.corePauseFailed : IosPingEvent.coreResumeFailed, operationId: id);
        rethrow;
      } finally {
        if (pausing) _pauseTraceOperationId = 0;
      }
    });
  }

  int _beginPingTrace(IosPingEvent event) => core.supportsSystemStatus ? beginIosPingOperation(ref, event) : 0;

  void _recordPingTrace(IosPingEvent event, {int operationId = 0}) {
    if (core.supportsSystemStatus) recordIosPingEvent(ref, event, operationId: operationId);
  }

  void _startSystemStatusSync() {
    if (!core.supportsSystemStatus || _systemStatusSubscription != null) return;
    _systemStatusSubscription = core.systemStatusStream.listen(
      _handleSystemStatus,
      onError: (Object error, StackTrace stackTrace) {
        loggy.error("System status stream error: $error");
      },
    );
  }

  Future<void> _stopSystemStatusSync() async {
    await _systemStatusSubscription?.cancel();
    _systemStatusSubscription = null;
    _systemStatusAuthoritative = false;
    _deferredSystemStatus = null;
  }

  void _handleSystemStatus(CoreStatus status) {
    _systemStatusRevision++;
    _systemStatusAuthoritative = true;
    if (_appStartInProgress) {
      _deferredSystemStatus = status;
      return;
    }
    currentState = status;
    statusController.add(status);
  }

  Future<void> _finishAppStart(bool succeeded) async {
    CoreStatus? resolvedStatus = _deferredSystemStatus;
    if (succeeded && core.supportsSystemStatus && resolvedStatus == null) {
      final refreshRevision = _systemStatusRevision;
      try {
        final refreshedStatus = await core.getSystemStatus();
        if (_systemStatusRevision == refreshRevision && _deferredSystemStatus == null) {
          resolvedStatus = refreshedStatus;
        }
      } catch (error, stackTrace) {
        loggy.error("System status refresh after start failed: $error");
        if (_appStartCoreFailure == null) statusController.addError(error, stackTrace);
      }
    }
    resolvedStatus = _deferredSystemStatus ?? resolvedStatus;
    final coreFailure = _appStartCoreFailure;
    _appStartInProgress = false;
    _deferredSystemStatus = null;
    _appStartCoreFailure = null;
    if (coreFailure != null) {
      currentState = coreFailure;
    } else if (succeeded && resolvedStatus != null) {
      currentState = resolvedStatus;
      statusController.add(resolvedStatus);
    } else if (!succeeded && core.supportsSystemStatus && currentState is! CoreStopped) {
      statusController.add(currentState = const CoreStatus.stopped());
    }
  }

  Future<void> init({bool requireSuccess = false}) async {
    await setup()
        .mapLeft((e) {
          loggy.error(e);
          if (requireSuccess) throw const HiddifyCoreInitializationException();
          if (PlatformUtils.isIOS) return;
          statusController.add(const CoreStatus.stopped());
          ref.read(inAppNotificationControllerProvider).showErrorToast(e);
        })
        .map((_) {
          _publishCoreRestart();
        })
        .run();
  }

  void _publishCoreRestart() {
    loggy.info("Hiddify-core setup done");
    ref.read(coreRestartSignalProvider.notifier).restart();
    _recordPingTrace(IosPingEvent.coreRestarted);
  }

  /// validates config by path and save it
  ///
  /// [path] is used to save validated config
  /// [tempPath] includes base config, possibly invalid
  /// [debug] indicates if debug mode (avoid in prod)

  TaskEither<String, Unit> validateConfigByPath(String path, String tempPath, bool debug) {
    return TaskEither(() async {
      try {
        final response = await core.fgClient.parse(ParseRequest(tempPath: tempPath, configPath: path, debug: false));
        if (response.responseCode != ResponseCode.OK) return left("${response.responseCode} ${response.message}");
      } catch (e) {
        await setup().run();
        final response = await core.fgClient.parse(ParseRequest(tempPath: tempPath, configPath: path, debug: false));
        if (response.responseCode != ResponseCode.OK) return left("${response.responseCode} ${response.message}");
      }
      return right(unit);
    });
  }

  TaskEither<String, String> generateFullConfigByPath(String path) {
    return TaskEither(() async {
      final response = await core.fgClient.parse(ParseRequest(configPath: path, debug: false));
      if (response.responseCode != ResponseCode.OK) return left("${response.responseCode} ${response.message}");
      return right(response.content);
    });
  }

  TaskEither<String, Unit> setup() {
    return TaskEither(() async {
      final traceId = _beginPingTrace(IosPingEvent.coreSetupStarted);
      try {
        final directories = ref.read(appDirectoriesProvider).requireValue;
        final debug = ref.read(debugModeNotifierProvider);
        final snapshotRevision = _systemStatusRevision;
        _startSystemStatusSync();
        _recordPingTrace(IosPingEvent.coreSetupFrontRequested, operationId: traceId);
        final setupResponse = await core.setup(directories, debug, 3);

        if (setupResponse.isNotEmpty) {
          _recordPingTrace(IosPingEvent.coreSetupFailed, operationId: traceId);
          return left(setupResponse);
        }
        _recordPingTrace(IosPingEvent.coreSetupFrontReady, operationId: traceId);

        try {
          _recordPingTrace(IosPingEvent.coreSetupStatusRequested, operationId: traceId);
          final systemStatus = await core.getSystemStatus();
          _recordPingTrace(IosPingEvent.coreSetupStatusReady, operationId: traceId);
          if (systemStatus != null) {
            if (core.supportsSystemStatus) _systemStatusAuthoritative = true;
            if (_systemStatusRevision == snapshotRevision) currentState = systemStatus;
          }
        } catch (error, stackTrace) {
          statusController.addError(error, stackTrace);
          rethrow;
        }

        _recordPingTrace(IosPingEvent.coreSetupListenersRequested, operationId: traceId);
        await startListeningLogs("fg", core.fgClient);
        // await startListeningStatus("fg", core.fgClient);
        if (!core.isSingleChannel()) {
          await startListeningLogs("bg", core.bgClient);
        }
        statusController.add(currentState);
        await startListeningStatus("bg", core.bgClient);
        _recordPingTrace(IosPingEvent.coreSetupCompleted, operationId: traceId);
        // ref.read(coreRestartSignalProvider.notifier).restart();
        return right(unit);
      } catch (e) {
        if (e is IosCoreSetupException) {
          final stageEvent = switch (e.stage) {
            IosCoreSetupStage.firstHello => IosPingEvent.coreSetupFirstHelloFailed,
            IosCoreSetupStage.nativeSetup => IosPingEvent.coreSetupNativeFailed,
            IosCoreSetupStage.secondHello => IosPingEvent.coreSetupSecondHelloFailed,
            IosCoreSetupStage.unknown => null,
          };
          if (stageEvent != null) _recordPingTrace(stageEvent, operationId: traceId);
          final codeEvent = switch (e.code) {
            IosCoreSetupCode.helloTimedOut => IosPingEvent.coreSetupHelloTimedOut,
            IosCoreSetupCode.nativeSetupTimedOut => IosPingEvent.coreSetupNativeTimedOut,
            IosCoreSetupCode.nativeSetupFailed => IosPingEvent.coreSetupNativeFailed,
            IosCoreSetupCode.vpnPreferencesFailed => IosPingEvent.coreSetupPreferencesFailed,
            IosCoreSetupCode.helloFailed => IosPingEvent.coreSetupHelloFailed,
          };
          if (codeEvent != stageEvent) _recordPingTrace(codeEvent, operationId: traceId);
          final grpcCode = e.grpcStatusCode;
          if (grpcCode != null && grpcCode >= 0 && grpcCode < _grpcSetupEvents.length) {
            _recordPingTrace(_grpcSetupEvents[grpcCode], operationId: traceId);
          }
          if (e.foregroundListenerReachable case final reachable?) {
            _recordPingTrace(
              reachable ? IosPingEvent.coreSetupLoopbackReachable : IosPingEvent.coreSetupLoopbackUnreachable,
              operationId: traceId,
            );
          }
        }
        _recordPingTrace(IosPingEvent.coreSetupFailed, operationId: traceId);
        return left(e.toString());
      }
    });
  }

  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) {
    return TaskEither(() async {
      loggy.debug("changing options");
      // latestOptions = options;
      var foregroundConfigured = false;
      try {
        final res = await core.fgClient.changeHiddifySettings(
          ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())),
        );
        if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
        foregroundConfigured = true;
        await core.bgClient.changeHiddifySettings(
          ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())),
        );
      } on GrpcError catch (e) {
        if (e.code == StatusCode.unavailable) {
          if (core.supportsSystemStatus && !foregroundConfigured) return left('foreground_settings_unavailable');
          loggy.debug("background core is not started yet! $e");
        } else {
          rethrow;
        }
      }

      return right(unit);
    });
  }

  TaskEither<ConnectionFailure, Unit> start(String path, String name, bool disableMemoryLimit) {
    return TaskEither(() async {
      var succeeded = false;
      _appStartInProgress = true;
      _deferredSystemStatus = null;
      _appStartCoreFailure = null;
      statusController.add(currentState = const CoreStatus.starting());
      loggy.debug("starting");
      try {
        final CoreStatus background;
        try {
          background = await core.setupBackground(path, name);
        } on PlatformException catch (error) {
          statusController.add(currentState = const CoreStatus.stopped());
          return left(ConnectionFailure.unexpected(error));
        }
        if (background != const CoreStatus.started()) {
          statusController.add(currentState = const CoreStatus.stopped());
          return left(background.getCoreAlert() ?? const ConnectionFailure.unexpected("failed to start core"));
        }
        if (!core.isSingleChannel()) {
          await startListeningLogs("bg", core.bgClient);
          await startListeningStatus("bg", core.bgClient);
        }
        // if (latestOptions != null) {
        //   await core.bgClient.changeHiddifySettings(
        //     ChangeHiddifySettingsRequest(
        //       hiddifySettingsJson: jsonEncode(latestOptions!.toJson()),
        //     ),
        //   );
        // }
        // final content = await File(path).readAsString();
        // loggy.debug("starting with content: $content");
        try {
          final res = await core.bgClient.start(
            StartRequest(
              configPath: path,
              configName: name,
              // configContent: content,
              disableMemoryLimit: disableMemoryLimit,
            ),
          );
          ref.read(coreRestartSignalProvider.notifier).restart();
          if (res.messageType != MessageType.ALREADY_STARTED && res.messageType != MessageType.EMPTY) {
            final alert = res.message.contains("denied") ? CoreAlert.requestVPNPermission : CoreAlert.startFailed;
            currentState = CoreStatus.stopped(
              alert: alert,
              message: "failed to start core ${res.messageType} ${res.message}",
            );

            statusController.add(currentState);

            return left(
              currentState.getCoreAlert() ??
                  ConnectionFailure.unexpected("failed to start core ${res.messageType} ${res.message}"),
            );
          }
        } on GrpcError catch (e) {
          loggy.error("failed to start bg core: $e");
          ref.read(coreRestartSignalProvider.notifier).restart();
          if (e.code == StatusCode.unavailable) {
            return left(const ConnectionFailure.unexpected("background core is not started yet!"));
          }
          // throw InvalidConfig(e.message);
          // throw DioException.connectionError(requestOptions: RequestOptions(), reason: e.codeName, error: e);

          // throw DioException(requestOptions: RequestOptions(), error: e);
          return left(const ConnectionFailure.unexpected("failed to start background core"));
        }

        // if (res.messageType != MessageType.EMPTY) return left(res);

        succeeded = true;
        return right(unit);
      } finally {
        await _finishAppStart(succeeded);
      }
    });
  }

  TaskEither<String, Unit> stop() {
    return TaskEither(() async {
      loggy.debug("stopping");
      var errMsg = "";
      try {
        final res = await core.bgClient.stop(Empty());
      } on GrpcError catch (e) {
        if (e.code == StatusCode.unknown && !(e.message?.contains("HTTP/2") ?? false)) {
          errMsg = e.message ?? "failed to stop core: $e";

          loggy.error("failed to stop bg core: $e");
        }
      } catch (e) {
        loggy.error("failed to stop bg core: $e");
        // left("failed to stop core: $e");
      }
      if (!await core.stop()) {}
      statusController.add(currentState = const CoreStatus.stopped());
      if (errMsg.isNotEmpty) return left(errMsg);
      return right(unit);
    });
  }

  TaskEither<String, Unit> restart(String path, String name, bool disableMemoryLimit) {
    return TaskEither(() async {
      loggy.debug("restarting");
      // if (!await core.restart(path, name)) {
      try {
        final res = await core.bgClient.restart(
          StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit, delayStart: true),
        );
        if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
      } on GrpcError catch (e) {
        loggy.error("failed to restart bg core: $e");
        if (e.code == StatusCode.unknown && !(e.message?.contains("HTTP/2 error") ?? false)) {
          return left("${e.message}");
        }
      }

      return right(unit);
      // await stop().run();
      // return await start(path, name, disableMemoryLimit).run();
      // }
      // if (!core.isSingleChannel()) {
      //   await startListeningStatus("bg", core.bgClient);
      //   await startListeningLogs("bg", core.bgClient);
      // }
      // return right(unit);
    });
  }

  TaskEither<String, Unit> resetTunnel() {
    return TaskEither(() async {
      // only available on iOS (and macOS later)
      if (!PlatformUtils.isIOS) {
        throw UnimplementedError("reset tunnel function unavailable on platform");
      }

      // loggy.debug("resetting tunnel");
      final res = await core.resetTunnel();
      if (res) {
        return right(unit);
      }
      return left("failed to reset tunnel");
    });
  }

  // Stream<List<OutboundGroup>> watchGroups() async* {
  //   loggy.debug("watching groups");
  //   yield* core.bgClient.outboundsInfo(Empty()).map((event) => event.items);
  //   // res?.cancel();
  // }

  Stream<OutboundGroup?> watchGroup() async* {
    loggy.debug("watching group");
    // interrupt managed by core

    if (!core.isInitialized()) {
      loggy.debug("core is not initialized, returning empty group stream");
      return;
    }
    try {
      yield* core.bgClient.outboundsInfo(Empty()).map((event) => event.items.isEmpty ? null : event.items.first);
    } catch (e) {
      loggy.error("error watching group: $e");
      rethrow;
    }
    // //emitting first event immediately
    // yield* core.bgClient.outboundsInfo(Empty()).take(1).map((event) => event.items.isEmpty ? null : event.items.first);
    // //emitting other event after every 4 seconds(latest event)
    // yield* core.bgClient.outboundsInfo(Empty()).throttleTime(const Duration(seconds: 4), leading: false, trailing: true).map((event) => event.items.isEmpty ? null : event.items.first);
  }

  Stream<List<OutboundGroup>> watchActiveGroups() async* {
    loggy.info("watching active groups");

    if (!core.isInitialized()) {
      loggy.debug("core is not initialized, returning empty group stream");
      return;
    }

    try {
      yield* core.bgClient
          .mainOutboundsInfo(Empty())
          .map((event) {
            return latest = event.items;
          })
          .startWith(latest);
    } catch (e) {
      loggy.error("error watching active groups: $e");
      rethrow;
    }
  }

  //
  // Stream<SingboxStatus> watchStatus() => _status;

  ResponseStream<SystemInfo> watchStats() {
    loggy.debug("watching stats");
    try {
      return core.bgClient.getSystemInfoStream(Empty());
    } catch (e) {
      loggy.error("error watching stats: $e");
      rethrow;
    }
  }

  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither(() async {
      loggy.debug("selecting outbound");
      try {
        final res = await core.bgClient.selectOutbound(
          SelectOutboundRequest(groupTag: groupTag, outboundTag: outboundTag),
          options: CallOptions(timeout: const Duration(seconds: 1)),
        );
        if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");

        return right(unit);
      } catch (e) {
        loggy.error("error selecting outbound: $e");
        rethrow;
      }
    });
  }

  TaskEither<String, Unit> urlTest(String tag) {
    return TaskEither(() async {
      loggy.debug("url test");
      try {
        final res = await core.bgClient.urlTest(
          UrlTestRequest(tag: tag),
          options: core.supportsSystemStatus ? CallOptions(timeout: const Duration(seconds: 15)) : null,
        );
        if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");

        return right(unit);
      } catch (e) {
        loggy.error("error in url test: $e");
        rethrow;
      }
    });
  }

  List<LogMessage> logBuffer = [];

  // SingboxConfigOption? latestOptions;

  Stream<List<LogMessage>> watchLogs(String path) async* {
    if (!core.isInitialized()) {
      loggy.debug("core is not initialized, returning empty log stream");
      return;
    }
    await startListeningLogs("bg", core.bgClient);
    await startListeningLogs("fg", core.fgClient);
    try {
      yield* logController.stream;
    } catch (e) {
      loggy.error("error watching logs: $e");
      rethrow;
    }
    // Stream<List<String>> logStream(CoreClient coreClient) {
    //   return coreClient.logListener(Empty()).asBroadcastStream().map((event) => [event.message]).onErrorResume((error, stackTrace) {
    //     loggy.debug('Error in $coreClient: $error, retrying...');
    //     final delay = (currentState == const SingboxStatus.stopped()) ? 5 : 1;
    //     return const Stream<List<String>>.empty().delay(Duration(seconds: delay)).concatWith([logStream(coreClient)]);
    //   });
    // }

    // // Create streams for both fg and bg clients with retry logic
    // final fgLogStream = logStream(core.fgClient);

    // if (core.bgClient == core.fgClient) {
    //   yield* fgLogStream;
    //   return;
    // }
    // final bgLogStream = logStream(core.bgClient);
    // yield* MergeStream([bgLogStream, fgLogStream]);
  }

  TaskEither<String, Unit> clearLogs() {
    return TaskEither(() async {
      loggy.debug("clearing logs");
      logBuffer.clear();
      // final res = await core.bgClient(Empty());
      // if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");
      return right(unit);
    });
  }

  TaskEither<String, WarpResponse> generateWarpConfig({
    required String licenseKey,
    required String previousAccountId,
    required String previousAccessToken,
  }) {
    return TaskEither(() async {
      loggy.debug("generating warp config");
      final warpConfig = await core.fgClient.generateWarpConfig(
        GenerateWarpConfigRequest(
          licenseKey: licenseKey,
          accountId: previousAccountId,
          accessToken: previousAccessToken,
        ),
      );
      // if (warpConfig.code != ResponseCode.OK) return left("${warpConfig.code} ${warpConfig.message}");
      final WarpResponse warp = (
        log: warpConfig.log,
        accountId: warpConfig.account.accountId,
        accessToken: warpConfig.account.accessToken,
        wireguardConfig: jsonEncode(warpConfig.config.toProto3Json()),
      );
      return right(warp);
    });
  }

  Stream<CoreStatus> watchStatus() async* {
    await startListeningStatus("bg", core.bgClient);
    yield* statusController.stream;
    // .endWith(const CoreStatus.stopped());
  }

  Future<void> startListeningStatus(String key, CoreClient cc) async {
    await listenSingle<CoreStatus>(
      "${key}StatusListener",
      () => cc
          .coreInfoListener(Empty(), options: grpcOptions)
          .doOnCancel(() {
            loggy.error("status", "Canceld");
          })
          .doOnData((event) {
            loggy.debug("status", event);
            if (!_systemStatusAuthoritative && currentState == const CoreStatus.started()) {
              currentState = const CoreStatus.stopped();
            }
          })
          .doOnDone(() {
            loggy.error("status", "done");
            if (!_systemStatusAuthoritative && currentState == const CoreStatus.started()) {
              currentState = const CoreStatus.stopped();
            }
          })
          .endWith(CoreInfoResponse(coreState: CoreStates.STOPPED))
          .map((event) {
            final nextState = CoreStatus.fromCoreInfo(event);
            final isCoreFailure = nextState is CoreStopped && nextState.alert != null;
            if (core.supportsSystemStatus && _appStartInProgress && isCoreFailure) {
              _appStartCoreFailure = nextState;
            }
            if (!_systemStatusAuthoritative || isCoreFailure) {
              currentState = nextState;
              statusController.add(currentState);
            }
            return currentState;
          }),
      // .endWith(const CoreStatus.stopped())
      onError: (error) {
        loggy.error("Stream error in ${key}StatusListener: $error");

        // currentState = const CoreStatus.stopped();
        // statusController.add(currentState);

        // startListeningStatus(key, cc);
      },
    );
  }

  Future<void> startListeningLogs(String key, CoreClient cc) async {
    final logLevel = ref.read(ConfigOptions.logLevel);
    final coreLogLevel = getCoreLogLevel(logLevel);
    final listenKey = "${key}LogListener";
    // await stopListenSingle(listenKey);
    await listenSingle<LogMessage>(listenKey, () {
      return cc.logListener(LogRequest(level: coreLogLevel), options: grpcOptions).map((event) {
        // Handle incoming event
        logBuffer.add(event);
        if (logBuffer.length > 300) {
          logBuffer.removeAt(0);
        }
        logController.add(logBuffer);
        // loggy.log(getLogLevel(event.level), event.message);
        event.message.split('\n').forEach((line) {
          loggy.log(getLogLevel(event.level), line);
        });
        return event;
      });
    });
  }

  Future<void> stopListenSingle(String key) async {
    // Collect keys to remove first
    final keysToRemove = subscriptions.entries
        .where((entry) => entry.key.startsWith(key))
        .map((entry) => entry.key)
        .toList();

    // Cancel and remove
    for (final k in keysToRemove) {
      final sub = subscriptions[k];
      await sub?.cancel(); // cancel the subscription

      subscriptions.remove(k);
    }
  }

  Future<StreamSubscription<T>?> listenSingle<T>(
    String key,
    Stream<T> Function() stream, {
    Function(dynamic error)? onError,
  }) async {
    if (subscriptions.containsKey(key)) {
      // return subscriptions[key] as StreamSubscription<T>?;
      await stopListenSingle(key);
    }
    subscriptions[key] = null;
    subscriptions[key] = stream().listen(
      (event) {
        // loggy.debug(event);
      },
      cancelOnError: true,
      onError: (error) {
        loggy.log(loggyl.LogLevel.error, 'Stream error: $error');
        onError?.call(error);
        subscriptions[key]?.cancel();
        subscriptions.remove(key);
      },
    );
    return subscriptions[key] as StreamSubscription<T>?;
  }

  loggyl.LogLevel getLogLevel(LogLevel level) {
    return switch (level) {
      LogLevel.DEBUG => loggyl.LogLevel.debug,
      LogLevel.INFO => loggyl.LogLevel.info,
      LogLevel.WARNING => loggyl.LogLevel.warning,
      LogLevel.ERROR => loggyl.LogLevel.error,
      LogLevel.FATAL => loggyl.LogLevel.error,
      _ => loggyl.LogLevel.info, // Default case
    };
  }

  LogLevel getCoreLogLevel(config_log_level.LogLevel level) {
    return switch (level) {
      config_log_level.LogLevel.trace => LogLevel.TRACE,
      config_log_level.LogLevel.debug => LogLevel.DEBUG,
      config_log_level.LogLevel.info => LogLevel.INFO,
      config_log_level.LogLevel.warn => LogLevel.WARNING,
      config_log_level.LogLevel.error => LogLevel.ERROR,
      config_log_level.LogLevel.fatal => LogLevel.FATAL,
      config_log_level.LogLevel.panic => LogLevel.FATAL,
      _ => LogLevel.INFO, // Default case
    };
  }

  Future<void> closeFront() async {
    if (!core.isInitialized()) {
      return;
    }
    if (!core.isSingleChannel()) {
      _recordPingTrace(IosPingEvent.corePauseCancelFg, operationId: _pauseTraceOperationId);
      await stopListenSingle("fg");
      _recordPingTrace(IosPingEvent.corePauseCancelBg, operationId: _pauseTraceOperationId);
      await stopListenSingle("bg");
      try {
        _recordPingTrace(IosPingEvent.corePauseCloseNormal, operationId: _pauseTraceOperationId);
        await core.fgClient.close(CloseRequest(mode: SetupMode.GRPC_NORMAL_INSECURE));
      } catch (e) {}
      try {
        _recordPingTrace(IosPingEvent.corePauseCloseFfi, operationId: _pauseTraceOperationId);
        await core.fgClient.close(CloseRequest(mode: SetupMode.GRPC_NORMAL));
      } catch (e) {}
    }
  }
}
