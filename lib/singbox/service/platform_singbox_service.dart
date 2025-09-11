import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';
import 'package:hiddify/singbox/model/singbox_stats.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:rxdart/rxdart.dart';

class PlatformSingboxService with InfraLogger implements SingboxService {
  static const channelPrefix = "com.hiddify.app";

  static const methodChannel = MethodChannel("$channelPrefix/method");
  static const statusChannel = EventChannel("$channelPrefix/service.status", JSONMethodCodec());
  static const alertsChannel = EventChannel("$channelPrefix/service.alerts", JSONMethodCodec());
  static const statsChannel = EventChannel("$channelPrefix/stats", JSONMethodCodec());
  static const groupsChannel = EventChannel("$channelPrefix/groups");
  static const activeGroupsChannel = EventChannel("$channelPrefix/active-groups");
  static const logsChannel = EventChannel("$channelPrefix/service.logs");

  late final ValueStream<SingboxStatus> _status;

  @override
  Future<void> init() async {
    loggy.debug("initializing");
    final status = statusChannel.receiveBroadcastStream().map(SingboxStatus.fromEvent);
    final alerts = alertsChannel.receiveBroadcastStream().map(SingboxStatus.fromEvent);

    _status = ValueConnectableStream(Rx.merge([status, alerts])).autoConnect();
    await _status.first;
  }

  @override
  TaskEither<String, Unit> setup(Directories directories, bool debug) {
    return TaskEither(
      () async {
        if (!Platform.isIOS) {
          return right(unit);
        }

        await methodChannel.invokeMethod("setup");
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> validateConfigByPath(
    String path,
    String tempPath,
    bool debug,
  ) {
    return TaskEither(
      () async {
        final message = await methodChannel.invokeMethod<String>(
          "parse_config",
          {"path": path, "tempPath": tempPath, "debug": debug},
        );
        if (message == null || message.isEmpty) return right(unit);
        return left(message);
      },
    );
  }

  @override
  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) {
    return TaskEither(
      () async {
        loggy.debug("changing options");
        await methodChannel.invokeMethod(
          "change_hiddify_options",
          jsonEncode(options.toJson()),
        );
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, String> generateFullConfigByPath(String path) {
    return TaskEither(
      () async {
        loggy.debug("generating full config by path");
        final configJson = await methodChannel.invokeMethod<String>(
          "generate_config",
          {"path": path},
        );
        if (configJson == null || configJson.isEmpty) {
          return left("null response");
        }
        return right(configJson);
      },
    );
  }

  @override
  TaskEither<String, Unit> start(
    String path,
    String name,
    bool disableMemoryLimit,
  ) {
    return TaskEither(
      () async {
        loggy.debug("starting");
        await methodChannel.invokeMethod(
          "start",
          {"path": path, "name": name},
        );
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> stop() {
    return TaskEither(
      () async {
        loggy.debug("stopping");
        await methodChannel.invokeMethod("stop");
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> restart(
    String path,
    String name,
    bool disableMemoryLimit,
  ) {
    return TaskEither(
      () async {
        loggy.debug("restarting");
        await methodChannel.invokeMethod(
          "restart",
          {"path": path, "name": name},
        );
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> resetTunnel() {
    return TaskEither(
      () async {
        // only available on iOS (and macOS later)
        if (!Platform.isIOS) {
          throw UnimplementedError(
            "reset tunnel function unavailable on platform",
          );
        }

        loggy.debug("resetting tunnel");
        await methodChannel.invokeMethod("reset");
        return right(unit);
      },
    );
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchGroups() {
    loggy.debug("watching groups");
    return groupsChannel.receiveBroadcastStream().map(
      (event) {
        if (event case String _) {
          return (jsonDecode(event) as List).map((e) {
            return SingboxOutboundGroup.fromJson(e as Map<String, dynamic>);
          }).toList();
        }
        loggy.error("[group client] unexpected type, msg: $event");
        throw "invalid type";
      },
    );
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchActiveGroups() {
    loggy.debug("watching active groups");
    return activeGroupsChannel.receiveBroadcastStream().map(
      (event) {
        if (event case String _) {
          return (jsonDecode(event) as List).map((e) {
            return SingboxOutboundGroup.fromJson(e as Map<String, dynamic>);
          }).toList();
        }
        loggy.error("[active group client] unexpected type, msg: $event");
        throw "invalid type";
      },
    );
  }

  @override
  Stream<SingboxStatus> watchStatus() => _status;

  @override
  Stream<SingboxStats> watchStats() {
    loggy.debug("watching stats");
    return statsChannel.receiveBroadcastStream().map(
      (event) {
        if (event case Map<String, dynamic> _) {
          return SingboxStats.fromJson(event);
        }
        loggy.error(
          "[stats client] unexpected type(${event.runtimeType}), msg: $event",
        );
        throw "invalid type";
      },
    );
  }

  @override
  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither(
      () async {
        loggy.debug("selecting outbound");
        await methodChannel.invokeMethod(
          "select_outbound",
          {"groupTag": groupTag, "outboundTag": outboundTag},
        );
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> urlTest(String groupTag) {
    return TaskEither(
      () async {
        await methodChannel.invokeMethod(
          "url_test",
          {"groupTag": groupTag},
        );
        return right(unit);
      },
    );
  }

  @override
  Stream<List<String>> watchLogs(String path) async* {
    yield* logsChannel.receiveBroadcastStream().map((event) => (event as List).map((e) => e as String).toList());
  }

  @override
  TaskEither<String, Unit> clearLogs() {
    return TaskEither(
      () async {
        await methodChannel.invokeMethod("clear_logs");
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
        final warpConfig = await methodChannel.invokeMethod(
          "generate_warp_config",
          {
            "license-key": licenseKey,
            "previous-account-id": previousAccountId,
            "previous-access-token": previousAccessToken,
          },
        );
        return right(warpFromJson(jsonDecode(warpConfig as String)));
      },
    );
  }
}
