import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/logger/core_logger.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/log/model/log_level.dart' as config_log_level;
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_wrapper_stub.dart'
    if (dart.library.io) 'package:hiddify/hiddifycore/core_interface/core_interface_wrapper.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart' as logging;
import 'package:rxdart/rxdart.dart';

class HiddifyCoreService with InfraLogger {
  HiddifyCoreService(this.ref);
  final Ref ref;

  // CoreHiddifyCoreService() {}
  final core = getCoreInterface();

  CoreStatus currentState = const CoreStatus.stopped();
  final statusController = BehaviorSubject<CoreStatus>();
  final CallOptions? grpcOptions = null; //CallOptions(timeout: const Duration(milliseconds: 10000));
  final Map<String, StreamSubscription?> subscriptions = {};
  OutboundGroupList latest = OutboundGroupList();

  // Counts the stops the app sent, so a start knows when a stop came after it.
  final _stopRequests = BehaviorSubject<int>.seeded(0);

  // Numbers the status listeners. Setting the core up again (when the app comes back) moves it on
  // before the old channel is closed, so the end of the old listener's stream isn't taken for the
  // core stopping; the new listener reports the core's real state first thing.
  int _statusListener = 0;

  Future<void> init() async {
    await setup()
        .mapLeft((e) {
          loggy.error(e);
          if (PlatformUtils.isIOS) return;
          statusController.add(const CoreStatus.stopped());
          ref.read(inAppNotificationControllerProvider).showErrorToast(e);
        })
        .map((_) {
          loggy.info("Hiddify-core setup done");
          ref.read(coreRestartSignalProvider.notifier).restart();
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
      // the status listener in place stops counting before its channel is replaced
      _statusListener++;
      try {
        final directories = ref.read(appDirectoriesProvider).requireValue;
        final debug = kDebugMode || ref.read(ConfigOptions.logLevel).isVerbose;
        // 1 = GRPC_NORMAL (mTLS); 3 = GRPC_NORMAL_INSECURE
        final setupResponse = await core.setup(directories, debug, 1);

        if (setupResponse.isNotEmpty) {
          return left(setupResponse);
        }

        await startListeningLogs("fg", core.fgClient);
        if (core.clientChanges != null && !subscriptions.containsKey('managedClients')) {
          subscriptions['managedClients'] = core.clientChanges!.listen((_) async {
            await startListeningLogs('bg', core.bgClient);
            ref.read(coreRestartSignalProvider.notifier).restart();
          });
        }
        // await startListeningStatus("fg", core.fgClient);
        if (!core.isSingleChannel()) {
          await startListeningLogs("bg", core.bgClient);
        }
        // Prefer managedStatus (already seeded from native VPN sync on mobile) over
        // replaying a stale currentState; publishing Stopped here made the home
        // connect button jump on resume from Recent Apps.
        if (core.managedStatus == null) {
          statusController.add(currentState);
        }
        await startListeningStatus("bg", core.bgClient);
        // ref.read(coreRestartSignalProvider.notifier).restart();
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
        if (core.managesLifecycle) {
          await core.setOptions(options);
          return right(unit);
        }
        final res = await core.fgClient.changeHiddifySettings(
          ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())),
        );
        if (res.messageType != MessageType.EMPTY) return left("${res.messageType} ${res.message}");
        await core.bgClient.changeHiddifySettings(
          ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())),
        );
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

  TaskEither<ConnectionFailure, Unit> start(String path, String name, bool disableMemoryLimit) {
    return TaskEither(() async {
      final stops = _stopRequests.value;
      // the last connection's list, or a new one would first show its proxies and flags
      latest = OutboundGroupList();
      statusController.add(currentState = const CoreStatus.starting());
      loggy.debug("starting");
      if (core.managesLifecycle) {
        try {
          await core.startManaged(path, name, disableMemoryLimit);
          await startListeningLogs('bg', core.bgClient);
          ref.read(coreRestartSignalProvider.notifier).restart();
          return right(unit);
        } catch (error, stackTrace) {
          final failure = ConnectionFailure.fromError(error, stackTrace);
          statusController.add(currentState = const CoreStatus.stopped());
          return left(failure);
        }
      }
      final background = await core.setupBackground(path, name);
      if (background != const CoreStatus.started()) {
        statusController.add(currentState = const CoreStatus.stopped());
        // the user disconnected while the background core was starting, which stopped it: the start
        // was cancelled, it did not fail
        if (_stopRequests.value != stops) return right(unit);
        return left(background.getCoreAlert() ?? const ConnectionFailure.unexpected("failed to start core"));
      }
      // Armed again on every connect, not only when there are two channels.
      // listenSingle drops a subscription for good when its stream errors, and
      // a gRPC connection being terminated does exactly that, so a listener
      // armed once at setup does not survive the engine restarting. Re-listening
      // is idempotent: listenSingle cancels the previous one for the same key.
      await startListeningLogs("fg", core.fgClient);
      if (!core.isSingleChannel()) await startListeningLogs("bg", core.bgClient);
      // the start's outcome arrives only on the status stream, so it must be listened to
      if (!core.isSingleChannel() || !subscriptions.containsKey("bgStatusListener")) {
        await startListeningStatus("bg", core.bgClient);
      }
      // the user disconnected while the start was being prepared
      if (_stopRequests.value != stops) return right(unit);
      try {
        final outcome = await _startAndWait(
          stops,
          () => core.bgClient.start(
            StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit),
          ),
        );
        ref.read(coreRestartSignalProvider.notifier).restart();
        if (outcome case CoreStopped(alert: _?)) return left(_startFailure(outcome));
      } on GrpcError catch (e) {
        loggy.error("failed to start bg core: $e");
        ref.read(coreRestartSignalProvider.notifier).restart();
        if (e.code == StatusCode.unavailable) {
          return left(const ConnectionFailure.unexpected("background core is not started yet!"));
        }
        return left(ConnectionFailure.unexpected(e.message ?? "failed to start background core"));
      }

      return right(unit);
    });
  }

  /// Sends a start or restart and returns how it ended. The core answers at once and reports the
  /// outcome only on the status stream: STARTING, then STARTED or STOPPED. A restart stops first,
  /// so a STOPPED before STARTING is not the outcome. A stop the app sends after [stops] ends the
  /// wait as stopped: the core then drops the start, possibly without reporting STARTING.
  Future<CoreStatus> _startAndWait(int stops, Future<CoreInfoResponse> Function() send) async {
    final outcome = Completer<CoreStatus>();
    void complete(CoreStatus status) {
      if (!outcome.isCompleted) outcome.complete(status);
    }

    var starting = false;
    // skips the status the subject replays: it is from before this request
    final statuses = statusController.stream.skip(statusController.hasValue ? 1 : 0).listen((status) {
      if (status is CoreStarting) starting = true;
      // the service is up once it is waiting for a ping; the core goes on to started by itself
      if (status is CoreStarted ||
          status is CoreWaiting ||
          status is CoreNoAvailableProxies ||
          (starting && status is CoreStopped)) {
        complete(status);
      }
    });
    final stopped = _stopRequests.where((n) => n != stops).listen((_) => complete(const CoreStatus.stopped()));
    try {
      final res = await send();
      // the core is started only once it is stopped; the app asks again after it reports STOPPED
      if (res.messageType == MessageType.INSTANCE_NOT_STOPPED) {
        return CoreStatus.stopped(alert: CoreAlert.alreadyStarted, message: res.message);
      }
      if (res.messageType == MessageType.ALREADY_STARTED) {
        if (res.coreState == CoreStates.STARTED) return const CoreStatus.started();
        if (res.coreState == CoreStates.WAITING) return const CoreStatus.waiting();
        if (res.coreState == CoreStates.NO_AVAILABLE_PROXIES) return const CoreStatus.noAvailableProxies();
        // a start queued earlier will report the outcome; its STARTING may have gone already
        starting = true;
      }
      return await outcome.future;
    } finally {
      await statuses.cancel();
      await stopped.cancel();
    }
  }

  /// The failure for a start that ended stopped with an alert.
  ConnectionFailure _startFailure(CoreStopped stopped) {
    final message = stopped.message ?? "";
    // Go words Windows errors in English, so the two texts below match on every system language.
    // Windows refuses the TUN adapter to a process that is not elevated.
    if (message.contains("start inbound/tun[tun-in]: configure tun interface: Access is denied.")) {
      return const ConnectionFailure.missingPrivilege();
    }
    // Another adapter already has the address the core gives its TUN (172.19.0.1).
    if (message.contains(
      "start inbound/tun[tun-in]: configure tun interface: set ipv4 address: The object already exists.",
    )) {
      return const ConnectionFailure.tunAddressInUse();
    }
    final alert = message.contains("denied") ? CoreAlert.requestVPNPermission : stopped.alert;
    return CoreStatus.stopped(alert: alert, message: message).getCoreAlert() ??
        ConnectionFailure.unexpected("failed to start core: $message");
  }

  TaskEither<String, Unit> stop() {
    return TaskEither(() async {
      loggy.debug("stopping");
      // a start still waiting gives up, whoever manages the core
      _stopRequests.add(_stopRequests.value + 1);
      // Mobile (and macOS) publish status via managedStatus from the platform VPN
      // service. Waiting on gRPC stop *before* the platform stop deadlocks: the
      // EventChannel only emits Stopped after MethodChannel stop runs (#2395).
      if (core.managesLifecycle || core.managedStatus != null) {
        try {
          // Bound like _stopAndWait: a hung VPN channel must not leave Disconnecting forever.
          await core.stop().timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              loggy.warning("managed core stop timed out after 12s");
              return false;
            },
          );
          statusController.add(currentState = const CoreStatus.stopped());
          return right(unit);
        } catch (error) {
          statusController.add(currentState = const CoreStatus.stopped());
          return left(error.toString());
        }
      }
      var errMsg = "";
      try {
        await _stopAndWait();
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

  /// Sends a stop and waits for the core to report STOPPED; the core answers the call at once.
  /// The wait is bounded, so a core that stops reporting cannot leave the app disconnecting.
  Future<void> _stopAndWait() async {
    final stopped = statusController.stream.skip(statusController.hasValue ? 1 : 0).whereType<CoreStopped>().first;
    final res = await core.bgClient
        .stop(Empty())
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            loggy.warning("gRPC stop timed out after 8s");
            return CoreInfoResponse(messageType: MessageType.EMPTY, coreState: CoreStates.STOPPED);
          },
        );
    // ALREADY_STOPPED while a stop is still running: its STOPPED is yet to come
    if (res.messageType == MessageType.ALREADY_STOPPED && res.coreState == CoreStates.STOPPED) return;
    await stopped.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        loggy.warning("core did not report stopped in time");
        return const CoreStopped();
      },
    );
  }

  /// Applies a changed config to the running core: first as a hot reload, which keeps the core
  /// (and its connections) running; when the core cannot hot reload it (e.g. the TUN inbound
  /// changed) or the hot reload fails, the core is restarted instead.
  TaskEither<String, Unit> reload(String path, String name, bool disableMemoryLimit) {
    return TaskEither(() async {
      loggy.debug("hot reloading");
      try {
        final res = await core.bgClient.hotReload(
          StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit),
        );
        if (res.messageType == MessageType.EMPTY) return right(unit);
        loggy.info("hot reload not applied, restarting: ${res.messageType} ${res.message}");
      } on GrpcError catch (e) {
        loggy.warning("hot reload failed, restarting: $e");
      }
      return restart(path, name, disableMemoryLimit).run();
    });
  }

  TaskEither<String, Unit> restart(String path, String name, bool disableMemoryLimit) {
    return TaskEither(() async {
      loggy.debug("restarting");
      if (core.managesLifecycle) {
        try {
          await core.startManaged(path, name, disableMemoryLimit);
          await startListeningLogs('bg', core.bgClient);
          ref.read(coreRestartSignalProvider.notifier).restart();
          return right(unit);
        } catch (error) {
          statusController.add(currentState = CoreStatus.stopped(message: error.toString()));
          return left(error.toString());
        }
      }
      // if (!await core.restart(path, name)) {
      try {
        final outcome = await _startAndWait(
          _stopRequests.value,
          () => core.bgClient.restart(
            StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit, delayStart: true),
          ),
        );
        if (outcome case CoreStopped(alert: _?, :final message)) return left(message ?? "failed to restart core");
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
      if (!PlatformUtils.isIOS && !PlatformUtils.isMacOS) {
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

  Stream<OutboundGroupList> watchActiveGroups() async* {
    loggy.info("watching active groups");

    if (!core.isInitialized()) {
      loggy.debug("core is not initialized, returning empty group stream");
      return;
    }

    try {
      yield* core.bgClient.mainOutboundsInfo(Empty()).map((event) => latest = event).startWith(latest);
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
        final res = await core.bgClient.urlTest(UrlTestRequest(tag: tag));
        if (res.code != ResponseCode.OK) return left("${res.code} ${res.message}");

        return right(unit);
      } catch (e) {
        loggy.error("error in url test: $e");
        rethrow;
      }
    });
  }

  // The 300-message buffer and its BehaviorSubject are gone. They existed so
  // the logs page could show history when it opened, and only ever held the
  // engine's lines. The in-memory ring in core/logger does that for every
  // category, so the page reads it instead.

  // TaskEither<String, WarpResponse> generateWarpConfig({
  //   required String licenseKey,
  //   required String previousAccountId,
  //   required String previousAccessToken,
  // }) {
  //   return TaskEither(() async {
  //     loggy.debug("generating warp config");
  //     final warpConfig = await core.fgClient.generateWarpConfig(
  //       GenerateWarpConfigRequest(
  //         licenseKey: licenseKey,
  //         accountId: previousAccountId,
  //         accessToken: previousAccessToken,
  //       ),
  //     );
  //     // if (warpConfig.code != ResponseCode.OK) return left("${warpConfig.code} ${warpConfig.message}");
  //     final WarpResponse warp = (
  //       log: warpConfig.log,
  //       accountId: warpConfig.account.accountId,
  //       accessToken: warpConfig.account.accessToken,
  //       wireguardConfig: jsonEncode(warpConfig.config.toProto3Json()),
  //     );
  //     return right(warp);
  //   });
  // }

  Stream<CoreStatus> watchStatus() async* {
    await startListeningStatus("bg", core.bgClient);
    yield* statusController.stream;
    // .endWith(const CoreStatus.stopped());
  }

  Future<void> startListeningStatus(String key, CoreClient cc) async {
    if (core.managedStatus != null) {
      if (subscriptions.containsKey('managedStatus')) return;
      subscriptions['managedStatus'] = core.managedStatus!.listen((status) {
        final wasStarted = _platformStatus is CoreStarted;
        _platformStatus = status;
        if (status is CoreStarted) {
          // The platform knows only that its service is up; the core is starting until it says
          // otherwise, then waiting for a ping, and so on. The core reports a state when it
          // changes, so a stream that was open across a gap in the platform's status (the app
          // coming back to the foreground re-reads the VPN) has nothing to tell: a new one
          // answers with the state at once.
          if (!wasStarted) _stopFollowingCore();
          _followCoreWhilePlatformStarted();
          status = _coreReported ?? const CoreStatus.starting();
        } else {
          _coreReported = null;
          _stopFollowingCore();
        }
        statusController.add(currentState = status);
      });
      return;
    }
    final listener = ++_statusListener;
    await listenSingle<CoreStatus>(
      "${key}StatusListener",
      () => cc
          .coreInfoListener(Empty(), options: grpcOptions)
          .doOnCancel(() => loggy.debug("status listener cancelled"))
          .doOnData((event) => loggy.debug("status", event))
          .doOnDone(() => loggy.debug("status stream ended"))
          // the core ending the stream means it stopped
          .endWith(CoreInfoResponse(coreState: CoreStates.STOPPED))
          // ...unless the stream belongs to a listener set up again since: its channel was closed
          // and replaced, which says nothing about the core
          .where((_) => listener == _statusListener)
          .map((event) {
            currentState = CoreStatus.fromCoreInfo(event);
            statusController.add(currentState);
            return currentState;
          }),
      // .endWith(const CoreStatus.stopped())
      onError: (error) {
        // expected when the app comes back and the old channel is closed
        loggy.debug("Stream error in ${key}StatusListener: $error");

        // currentState = const CoreStatus.stopped();
        // statusController.add(currentState);

        // startListeningStatus(key, cc);
      },
    );
  }

  /// What the platform says about the VPN it manages.
  CoreStatus _platformStatus = const CoreStatus.stopped();

  /// The last state the core reported while the platform said its service is up.
  CoreStatus? _coreReported;
  StreamSubscription<CoreInfoResponse>? _coreInfoSubscription;

  /// The platform reports the tunnel up; waiting and started come from the core's own status
  /// stream. It is opened again while the tunnel stays up, since the core may not listen yet, or
  /// the client may be replaced.
  void _followCoreWhilePlatformStarted() {
    if (_coreInfoSubscription != null) return;
    late final StreamSubscription<CoreInfoResponse> subscription;
    void retry() {
      // a stream that was replaced or stopped on purpose must not clear the one that replaced it
      if (!identical(_coreInfoSubscription, subscription)) return;
      _coreInfoSubscription = null;
      if (_platformStatus is CoreStarted) Future.delayed(const Duration(seconds: 1), _followCoreWhilePlatformStarted);
    }

    _coreInfoSubscription = subscription = core.bgClient
        .coreInfoListener(Empty(), options: grpcOptions)
        .listen(
          (event) {
            if (_platformStatus is! CoreStarted) return;
            switch (event.coreState) {
              case CoreStates.STARTING:
                statusController.add(currentState = _coreReported = const CoreStatus.starting());
              case CoreStates.WAITING ||
                  CoreStates.STARTED ||
                  CoreStates.NO_AVAILABLE_PROXIES ||
                  CoreStates.HOT_RELOADING:
                statusController.add(currentState = _coreReported = CoreStatus.fromCoreInfo(event));
              default:
                // stopped and stopping are the platform's to report
                break;
            }
          },
          onError: (Object error) {
            loggy.debug("core status stream error: $error");
            retry();
          },
          onDone: retry,
        );
  }

  void _stopFollowingCore() {
    unawaited(_coreInfoSubscription?.cancel());
    _coreInfoSubscription = null;
  }

  Future<void> startListeningLogs(String key, CoreClient cc) async {
    final logLevel = ref.read(ConfigOptions.logLevel);
    final coreLogLevel = getCoreLogLevel(logLevel);
    final listenKey = "${key}LogListener";
    // await stopListenSingle(listenKey);
    await listenSingle<LogMessage>(listenKey, () {
      return cc.logListener(LogRequest(level: coreLogLevel), options: grpcOptions).map((event) {
        // Handle incoming event
        // One message becomes one record. The old code split on newlines
        // first, but the engine already sends one line per message, so the
        // split only allocated a list and multiplied the work per burst.
        coreLogFor(event.type).log(getLogLevel(event.level), event.message);
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
    late final StreamSubscription<T> subscription;
    subscriptions[key] = subscription = stream().listen(
      (event) {
        // loggy.debug(event);
      },
      // an ended stream is not listened to anymore, so the next listenSingle arms it again
      onDone: () {
        if (identical(subscriptions[key], subscription)) subscriptions.remove(key);
      },
      cancelOnError: true,
      onError: (error) {
        loggy.error('Stream error: $error');
        onError?.call(error);
        subscriptions[key]?.cancel();
        subscriptions.remove(key);
      },
    );
    return subscriptions[key] as StreamSubscription<T>?;
  }

  /// Six engine levels onto six logging levels, nothing merged.
  ///
  /// TRACE used to have no case here and fell into the default, so trace lines
  /// arrived looking as important as info and could not be filtered out. FATAL
  /// used to collapse into error because loggy had nothing above it.
  logging.Level getLogLevel(LogLevel level) {
    return switch (level) {
      LogLevel.TRACE => logging.Level.FINEST,
      LogLevel.DEBUG => logging.Level.FINE,
      LogLevel.INFO => logging.Level.INFO,
      LogLevel.WARNING => logging.Level.WARNING,
      LogLevel.ERROR => logging.Level.SEVERE,
      LogLevel.FATAL => logging.Level.SHOUT,
      // the proto enum is a generated class, so a default is unavoidable
      _ => logging.Level.INFO,
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
    };
  }

  Future<void> closeFront() async {
    if (!core.isInitialized()) {
      return;
    }
    if (!core.isSingleChannel()) {
      await stopListenSingle("fg");
      await stopListenSingle("bg");
      // Only one of the two modes matches how the channel was opened, so the
      // other one always throws. Both are attempted and the failure is logged.
      try {
        await core.fgClient.close(CloseRequest(mode: SetupMode.GRPC_NORMAL_INSECURE));
      } catch (e) {
        loggy.debug("closing fg client in insecure mode failed: $e");
      }
      try {
        await core.fgClient.close(CloseRequest(mode: SetupMode.GRPC_NORMAL));
      } catch (e) {
        loggy.debug("closing fg client in normal mode failed: $e");
      }
    }
  }

  TaskEither<String, LANIPResponse> getLANIP() {
    return TaskEither(() async {
      try {
        final response = await core.fgClient.getLANIP(Empty());
        return right(response);
      } catch (e) {
        loggy.error("failed to get LAN IP: $e");
        return left(e.toString());
      }
    });
  }
}
