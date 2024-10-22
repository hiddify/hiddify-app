import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';

import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart' as hcore;
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pbenum.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';
import 'package:hiddify/singbox/model/singbox_proxy_type.dart';
import 'package:hiddify/singbox/model/singbox_stats.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';
import 'package:hiddify/singbox/service/core_interface/core_interface.dart';
import 'package:hiddify/singbox/service/core_interface/core_interface_wrapper_stub.dart' if (dart.library.io) 'package:hiddify/singbox/service/core_interface/core_interface_wrapper.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:rxdart/rxdart.dart';
import 'package:loggy/loggy.dart' as loggyl;

class CoreSingboxService with InfraLogger implements SingboxService {
  // CoreSingboxService() {}
  CoreInterface core = getCoreInterface();

  SingboxStatus currentState = const SingboxStatus.stopped();
  final statusController = BehaviorSubject<SingboxStatus>();
  final logController = BehaviorSubject<List<LogMessage>>();
  final CallOptions? grpcOptions = null; //CallOptions(timeout: const Duration(milliseconds: 2000));

  @override
  Future<void> init() async {
    statusController.add(currentState);
  }

  /// validates config by path and save it
  ///
  /// [path] is used to save validated config
  /// [tempPath] includes base config, possibly invalid
  /// [debug] indicates if debug mode (avoid in prod)

  @override
  TaskEither<String, Unit> validateConfigByPath(
    String path,
    String tempPath,
    bool debug,
  ) {
    return TaskEither(
      () async {
        final response = await core.fgClient.parse(
          ParseRequest(tempPath: tempPath, configPath: path, debug: false),
        );
        if (response.responseCode != ResponseCode.OK) return left("${response.responseCode} ${response.message}");
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, String> generateFullConfigByPath(String path) {
    return TaskEither(
      () async {
        final response = await core.fgClient.parse(
          ParseRequest(configPath: path, debug: false),
        );
        if (response.responseCode != ResponseCode.OK) return left("${response.responseCode} ${response.message}");
        return right(response.content);
      },
    );
  }

  @override
  TaskEither<String, Unit> setup(Directories directories, bool debug) {
    return TaskEither(
      () async {
        try {
          final setupResponse = await core.setup(directories, debug, 3);

          if (setupResponse.isNotEmpty) {
            return left(setupResponse);
          }
          startListeningLogs(core.fgClient);
          startListeningStatus(core.fgClient);

          return right(unit);
        } catch (e) {
          return left(e.toString());
        }
      },
    );
  }

  @override
  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) {
    return TaskEither(
      () async {
        loggy.debug("changing options");
        try {
          final res = await core.fgClient.changeHiddifySettings(
            ChangeHiddifySettingsRequest(
              hiddifySettingsJson: jsonEncode(options.toJson()),
            ),
          );
          if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
          await core.bgClient.changeHiddifySettings(
            ChangeHiddifySettingsRequest(
              hiddifySettingsJson: jsonEncode(options.toJson()),
            ),
          );
        } on GrpcError catch (e) {
          if (e.code == StatusCode.unavailable) {
            loggy.debug("background core is not started yet! $e");
          } else {
            rethrow;
          }
        }

        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> start(String path, String name, bool disableMemoryLimit) {
    return TaskEither(
      () async {
        statusController.add(currentState = const SingboxStatus.starting());
        loggy.debug("starting");
        startListeningLogs(core.bgClient);
        startListeningStatus(core.bgClient);
        if (!await core.start(path, name)) {
          final res = await core.bgClient.start(
            StartRequest(
              configPath: path,
              disableMemoryLimit: disableMemoryLimit,
            ),
          );

          if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
        }

        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> stop() {
    return TaskEither(
      () async {
        loggy.debug("stopping");
        if (!await core.stop()) {
          final res = await core.bgClient.stop(Empty());
          if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> restart(String path, String name, bool disableMemoryLimit) {
    return TaskEither(
      () async {
        loggy.debug("restarting");
        if (!await core.restart(path, name)) {
          final res = await core.bgClient.restart(
            StartRequest(
              configPath: path,
              disableMemoryLimit: disableMemoryLimit,
            ),
          );
          if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
        }
        startListeningStatus(core.bgClient);
        startListeningLogs(core.bgClient);
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> resetTunnel() {
    return TaskEither(
      () async {
        // only available on iOS (and macOS later)
        // if (!Platform.isIOS) {
        throw UnimplementedError(
          "reset tunnel function unavailable on platform",
        );
        // }

        // loggy.debug("resetting tunnel");
        // final res = await core.bgClient.resetTunnel();
        // if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");

        // return right(unit);
      },
    );
  }

  @override
  Stream<List<OutboundGroup>> watchGroups() async* {
    loggy.debug("watching groups");

    final res = core.bgClient.outboundsInfo(Empty());
    yield* res.map((event) {
      return event.items;
      // .map((p) {
      //   return SingboxOutboundGroup(
      //     selected: p.selected,
      //     tag: p.tag,
      //     type: ProxyType.fromJson(p.type),
      //     items: p.items.map((e) => SingboxOutboundGroupItem(tag: e.tag, type: ProxyType.fromJson(e.type), urlTestDelay: e.urlTestDelay)).toList(),
      //   );
      // }).toList();
    });
    // return res.asBroadcastStream().map(
    //   (event) {
    //     return event.items.map(e=>
    //            SingboxOutboundGroup.fromGrpc(e).toList();

    //   },
    // );
  }

  @override
  Stream<List<OutboundGroup>> watchActiveGroups() async* {
    loggy.debug("watching active groups");

    final res = core.bgClient.mainOutboundsInfo(Empty());
    yield* res.map((event) {
      return event.items;
      // return event.items.map((p) {
      //   return SingboxOutboundGroup(
      //     selected: p.selected,
      //     tag: p.tag,
      //     type: ProxyType.fromJson(p.type),
      //     items: p.items.map((e) => SingboxOutboundGroupItem(tag: e.tag, type: ProxyType.fromJson(e.type), urlTestDelay: e.urlTestDelay)).toList(),
      //   );
      // }).toList();
    });
  }

  // @override
  // Stream<SingboxStatus> watchStatus() => _status;

  @override
  Stream<SingboxStats> watchStats() {
    loggy.debug("watching stats");
    final res = core.bgClient.coreInfoListener(Empty());
    return res.asBroadcastStream().map(
      (event) {
        return SingboxStats.fromJson(event.writeToJsonMap());
      },
    );
  }

  @override
  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither(
      () async {
        loggy.debug("selecting outbound");
        final res = await core.bgClient.selectOutbound(
          SelectOutboundRequest(
            groupTag: groupTag,
            outboundTag: outboundTag,
          ),
        );
        if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");

        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> urlTest(String groupTag) {
    return TaskEither(
      () async {
        loggy.debug("url test");
        final res = await core.bgClient.urlTest(
          UrlTestRequest(
            groupTag: groupTag,
          ),
        );
        if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");
        return right(unit);
      },
    );
  }

  List<LogMessage> logBuffer = [];
  @override
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

  @override
  TaskEither<String, Unit> clearLogs() {
    return TaskEither(
      () async {
        loggy.debug("clearing logs");
        // final res = await core.bgClient(Empty());
        // if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, WarpResponse> generateWarpConfig({
    required String licenseKey,
    required String previousAccountId,
    required String previousAccessToken,
  }) {
    return TaskEither(
      () async {
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
      },
    );
  }

  @override
  Stream<SingboxStatus> watchStatus() async* {
    yield* statusController.stream.endWith(const SingboxStatus.stopped());
  }

  void startListeningStatus(CoreClient cc) {
    listenWithRetry(
      cc.coreInfoListener(Empty(), options: grpcOptions).map(
        (event) {
          currentState = SingboxStatus.fromCoreInfo(event);
          statusController.add(currentState);
          return currentState;
        },
      ).endWith(const SingboxStatus.stopped()),
      // onDone: () {
      //   statusController.add(currentState = const SingboxStatus.stopped());
      //   print('Stream finished');
      // },
      // onError: (error) {
      //   // Handle any error
      //   print('Stream encountered an error: $error');
      // },
      onlyWaitToConnect: true,
    );
  }

  void startListeningLogs(CoreClient cc) {
    listenWithRetry(
      cc.logListener(Empty(), options: grpcOptions).map((event) {
        // Handle incoming event
        logBuffer.add(event);
        if (logBuffer.length > 300) {
          logBuffer.removeAt(0);
        }
        logController.add(logBuffer);
        event.message.split('\n').forEach((line) {
          loggy.log(getLogLevel(event.level), line);
        });

        return event;
      }),
      onlyWaitToConnect: true,
    );
  }

  Future<void> listenWithRetry(Stream stream, {bool onlyWaitToConnect = false, void Function()? onDone, Function? onError}) async {
    const maxRetries = 0;
    const initialDelay = Duration(milliseconds: 10);
    int retryCount = 0;
    Duration delay = initialDelay;
    bool started = false;
    // while (true) {
    try {
      await stream.listen(
        (event) {
          // Successfully received an event
          retryCount = onlyWaitToConnect ? maxRetries : 0; // stop retrying
          delay = initialDelay; // Reset delay
          started = true;
        },
        cancelOnError: true,
      ).asFuture(); // Convert subscription to Future
    } catch (error) {
      loggy.log(loggyl.LogLevel.error, 'Stream error: $error');
      if (started) {
        onDone?.call();
        onError?.call(error);
      }
      if (retryCount >= maxRetries) {
        loggy.log(loggyl.LogLevel.error, 'Max retries reached. Stopping reconnection attempts.');
        // break;
      }

      retryCount++;
      loggy.log(loggyl.LogLevel.warning, 'Reconnecting in ${delay.inSeconds} seconds... (Attempt $retryCount/$maxRetries)');

      await Future.delayed(delay);
      delay *= 1.2; // Exponential backoff
    }
    // }
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
}
