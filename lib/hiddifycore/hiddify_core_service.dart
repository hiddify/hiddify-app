import 'dart:async';
import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';

import 'package:hiddify/hiddifycore/core_interface/core_interface_wrapper_stub.dart' if (dart.library.io) 'package:hiddify/hiddifycore/core_interface/core_interface_wrapper.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loggy/loggy.dart' as loggyl;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

class HiddifyCoreService with InfraLogger {
  // CoreHiddifyCoreService() {}
  CoreInterface core = getCoreInterface();

  CoreStatus currentState = const CoreStatus.stopped();
  final statusController = BehaviorSubject<CoreStatus>();
  final logController = BehaviorSubject<List<LogMessage>>();
  final CallOptions? grpcOptions = null; //CallOptions(timeout: const Duration(milliseconds: 2000));
  final Map<String, StreamSubscription?> subscriptions = {};

  Future<void> init({ProviderContainer? ref}) async {
    statusController.add(currentState);
    if (ref == null) return;
    final dirs = ref.read(appDirectoriesProvider).requireValue;
    final debug = ref.read(debugModeNotifierProvider);
    setup(dirs, debug)
        .mapLeft((e) {
          loggy.error(e);
          ref.read(inAppNotificationControllerProvider).showErrorToast(e);
        })
        .map((_) {
          loggy.info("Hiddify-core setup done");
        })
        .run();
  }

  /// validates config by path and save it
  ///
  /// [path] is used to save validated config
  /// [tempPath] includes base config, possibly invalid
  /// [debug] indicates if debug mode (avoid in prod)

  TaskEither<String, Unit> validateConfigByPath(String path, String tempPath, bool debug) {
    return TaskEither(() async {
      final response = await core.fgClient.parse(ParseRequest(tempPath: tempPath, configPath: path, debug: false));
      if (response.responseCode != ResponseCode.OK) return left("${response.responseCode} ${response.message}");
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

  TaskEither<String, Unit> setup(Directories directories, bool debug) {
    return TaskEither(() async {
      try {
        final setupResponse = await core.setup(directories, debug, 3);

        if (setupResponse.isNotEmpty) {
          return left(setupResponse);
        }
        await startListeningLogs("fg", core.fgClient);
        // await startListeningStatus("fg", core.fgClient);
        if (!core.isSingleChannel()) {
          await startListeningLogs("bg", core.bgClient);
        }
        await startListeningStatus("bg", core.bgClient);

        return right(unit);
      } catch (e) {
        return left(e.toString());
      }
    });
  }

  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) {
    return TaskEither(() async {
      loggy.debug("changing options");
      // latestOptions = options;
      try {
        final res = await core.fgClient.changeHiddifySettings(ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())));
        if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
        await core.bgClient.changeHiddifySettings(ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())));
      } on GrpcError catch (e) {
        if (e.code == StatusCode.unavailable) {
          loggy.debug("background core is not started yet! $e");
        } else {
          rethrow;
        }
      }

      return right(unit);
    });
  }

  TaskEither<String, Unit> start(String path, String name, bool disableMemoryLimit) {
    return TaskEither(() async {
      statusController.add(currentState = const CoreStatus.starting());
      loggy.debug("starting");

      if (await core.start(path, name) == const CoreStatus.stopped()) {
        statusController.add(currentState = const CoreStatus.stopped());
        return left("failed to start core");
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
        if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
      } on GrpcError catch (e) {
        loggy.error("failed to start bg core: $e");
        if (e.code == StatusCode.unavailable) {
          return left("background core is not started yet!");
        }
        // throw InvalidConfig(e.message);
        // throw DioException.connectionError(requestOptions: RequestOptions(), reason: e.codeName, error: e);

        // throw DioException(requestOptions: RequestOptions(), error: e);
        return left("${e.message}");
      }

      // if (res.messageType != MessageType.EMPTY) return left(res);

      return right(unit);
    });
  }

  TaskEither<String, Unit> stop() {
    return TaskEither(() async {
      loggy.debug("stopping");
      try {
        final res = await core.bgClient.stop(Empty());
      } catch (e) {
        loggy.error("failed to stop bg core: $e");
      }
      if (!await core.stop()) {}
      statusController.add(currentState = const CoreStatus.stopped());

      return right(unit);
    });
  }

  TaskEither<String, Unit> restart(String path, String name, bool disableMemoryLimit) {
    return TaskEither(() async {
      loggy.debug("restarting");
      // if (!await core.restart(path, name)) {
      final res = await core.bgClient.restart(StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit, delayStart: true));
      if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
      await stop().run();
      await start(path, name, disableMemoryLimit).run();
      // }
      // if (!core.isSingleChannel()) {
      //   await startListeningStatus("bg", core.bgClient);
      //   await startListeningLogs("bg", core.bgClient);
      // }
      return right(unit);
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
    yield* core.bgClient.outboundsInfo(Empty()).map((event) => event.items.isEmpty ? null : event.items.first);
    // //emitting first event immediately
    // yield* core.bgClient.outboundsInfo(Empty()).take(1).map((event) => event.items.isEmpty ? null : event.items.first);
    // //emitting other event after every 4 seconds(latest event)
    // yield* core.bgClient.outboundsInfo(Empty()).throttleTime(const Duration(seconds: 4), leading: false, trailing: true).map((event) => event.items.isEmpty ? null : event.items.first);
  }

  @riverpod
  Stream<List<OutboundGroup>> watchActiveGroups() async* {
    loggy.debug("watching active groups");

    yield* core.bgClient.mainOutboundsInfo(Empty()).map((event) => event.items);
  }

  //
  // Stream<SingboxStatus> watchStatus() => _status;

  @riverpod
  ResponseStream<SystemInfo> watchStats() {
    loggy.debug("watching stats");
    final res = core.bgClient.getSystemInfo(Empty());
    return res;
  }

  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither(() async {
      loggy.debug("selecting outbound");
      final res = await core.bgClient.selectOutbound(SelectOutboundRequest(groupTag: groupTag, outboundTag: outboundTag));
      if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");

      return right(unit);
    });
  }

  TaskEither<String, Unit> urlTest(String groupTag) {
    return TaskEither(() async {
      loggy.debug("url test");
      final res = await core.bgClient.urlTest(UrlTestRequest(groupTag: groupTag));
      if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");
      return right(unit);
    });
  }

  List<LogMessage> logBuffer = [];

  // SingboxConfigOption? latestOptions;

  Stream<List<LogMessage>> watchLogs(String path) async* {
    yield* logController.stream;
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

  TaskEither<String, WarpResponse> generateWarpConfig({required String licenseKey, required String previousAccountId, required String previousAccessToken}) {
    return TaskEither(() async {
      loggy.debug("generating warp config");
      final warpConfig = await core.fgClient.generateWarpConfig(GenerateWarpConfigRequest(licenseKey: licenseKey, accountId: previousAccountId, accessToken: previousAccessToken));
      // if (warpConfig.code != ResponseCode.OK) return left("${warpConfig.code} ${warpConfig.message}");
      final WarpResponse warp = (log: warpConfig.log, accountId: warpConfig.account.accountId, accessToken: warpConfig.account.accessToken, wireguardConfig: jsonEncode(warpConfig.config.toProto3Json()));
      return right(warp);
    });
  }

  Stream<CoreStatus> watchStatus() async* {
    yield* statusController.stream.endWith(const CoreStatus.stopped());
  }

  Future<void> startListeningStatus(String key, CoreClient cc) async {
    await listenSingle<CoreStatus>(
      "${key}StatusListener",
      () => cc
          .coreInfoListener(Empty(), options: grpcOptions)
          .map((event) {
            currentState = CoreStatus.fromCoreInfo(event);
            statusController.add(currentState);
            return currentState;
          })
          .endWith(const CoreStatus.stopped()),
    );
  }

  Future<void> startListeningLogs(String key, CoreClient cc) async {
    await listenSingle<LogMessage>(
      "${key}LogListener",
      () => cc.logListener(Empty(), options: grpcOptions).map((event) {
        // Handle incoming event
        logBuffer.add(event);
        if (logBuffer.length > 300) {
          logBuffer.removeAt(0);
        }
        logController.add(logBuffer);
        loggy.log(getLogLevel(event.level), event.message);
        event.message.split('\n').forEach((line) {
          loggy.log(getLogLevel(event.level), line);
        });
        return event;
      }),
    );
  }

  Future<void> stopListenSingle(String key) async {
    // Collect keys to remove first
    final keysToRemove = subscriptions.entries.where((entry) => entry.key.startsWith(key)).map((entry) => entry.key).toList();

    // Cancel and remove
    for (final k in keysToRemove) {
      final sub = subscriptions[k];
      await sub?.cancel(); // cancel the subscription
      subscriptions.remove(k);
    }
  }

  Future<StreamSubscription<T>?> listenSingle<T>(String key, Stream<T> Function() stream) async {
    if (subscriptions.containsKey(key)) {
      return subscriptions[key] as StreamSubscription<T>?;
    }
    subscriptions[key] = null;
    subscriptions[key] = stream().listen(
      (event) {},
      cancelOnError: true,
      onError: (error) {
        loggy.log(loggyl.LogLevel.error, 'Stream error: $error');
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

  Future<void> pause() async {
    if (!core.isSingleChannel()) {
      await stopListenSingle("fg");
      try {
        await core.fgClient.pause(PauseRequest(mode: SetupMode.GRPC_NORMAL_INSECURE));
      } catch (e) {}
      try {
        await core.fgClient.pause(PauseRequest(mode: SetupMode.GRPC_NORMAL));
      } catch (e) {}
    }
  }
}
