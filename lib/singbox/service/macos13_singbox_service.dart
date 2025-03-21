import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:combine/combine.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';
import 'package:hiddify/singbox/model/singbox_stats.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:loggy/loggy.dart';
import 'package:rxdart/rxdart.dart';
import 'package:watcher/watcher.dart';

final _logger = Loggy('MacOS13SingboxService');

class MethodChannelPort {
  final String channelName;
  final MethodChannel _methodChannel;

  StreamController<dynamic>? _streamController;

  MethodChannelPort(this.channelName) : _methodChannel = MethodChannel(channelName) {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'sendMessage':
        print("MethodChannelPort: ${call.arguments}");
        _streamController?.add(call.arguments);
        break;
      default:
        throw PlatformException(code: 'Unimplemented', details: 'Method not implemented in Dart: ${call.method}');
    }
  }

  Stream<dynamic> asBroadcastStream({
    void Function()? onListen,
    void Function()? onCancel,
  }) {
    _streamController = StreamController<dynamic>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
    );

    return _streamController!.stream;
  }

  void close() {
    _methodChannel.setMethodCallHandler(null);
    _streamController?.close();
  }
}

class MacOS13SingboxService with InfraLogger implements SingboxService {
  late final ValueStream<SingboxStatus> _status;
  late final MethodChannelPort _statusReceiver;
  Stream<SingboxStats>? _serviceStatsStream;
  Stream<List<SingboxOutboundGroup>>? _outboundsStream;

  static const platform = MethodChannel('app.hiddify.com.macos');

  @override
  Future<void> init() async {
    loggy.debug("initializing");

    // TODO: implement status receiver
    _statusReceiver = MethodChannelPort('app.hiddify.com.macos/serviceStatus');
    final source = _statusReceiver.asBroadcastStream().map((event) => jsonDecode(event as String)).map(SingboxStatus.fromEvent);
    _status = ValueConnectableStream.seeded(
      source,
      const SingboxStopped(),
    ).autoConnect();
  }

  @override
  TaskEither<String, Unit> setup(
    Directories directories,
    bool debug,
  ) {
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          await platform.invokeMethod('setupOnce');

          final Map<String, dynamic> args = {
            'baseDir': directories.baseDir.path,
            'workingDir': directories.workingDir.path,
            'tempDir': directories.tempDir.path,
            'debug': debug,
          };

          final String? error = await platform.invokeMethod<String>('setup', args);

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> validateConfigByPath(
    String path,
    String tempPath,
    bool debug,
  ) {
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {
            'path': path,
            'tempPath': tempPath,
            'debug': debug,
          };

          final String? error = await platform.invokeMethod<String>('parse', args);

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) {
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final json = jsonEncode(options.toJson());
          final Map<String, dynamic> args = {
            'options': json,
          };

          final String? error = await platform.invokeMethod<String>('changeHiddifyOptions', args);

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, String> generateFullConfigByPath(
    String path,
  ) {
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {
            'path': path,
          };

          final String? response = await platform.invokeMethod<String>('generateConfig', args);

          if (response == null || response.isEmpty) {
            return left("null response");
          }
          if (response.startsWith("error")) {
            return left(response.replaceFirst("error", ""));
          }
          return right(response);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> start(
    String configPath,
    String name,
    bool disableMemoryLimit,
  ) {
    loggy.debug("starting, memory limit: [${!disableMemoryLimit}]");
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {
            'path': configPath,
            'disableMemoryLimit': disableMemoryLimit,
          };

          final String? error = await platform.invokeMethod<String>('start', args);

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> stop() {
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {};
          final String? error = await platform.invokeMethod<String>(
            'stop',
            args,
          );

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> restart(
    String configPath,
    String name,
    bool disableMemoryLimit,
  ) {
    loggy.debug("restarting, memory limit: [${!disableMemoryLimit}]");
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {
            'path': configPath,
            'disableMemoryLimit': disableMemoryLimit,
          };

          final String? error = await platform.invokeMethod<String>(
            'restart',
            args,
          );

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> resetTunnel() {
    throw UnimplementedError(
      "reset tunnel function unavailable on platform",
    );
  }

  @override
  Stream<SingboxStatus> watchStatus() => _status;

  @override
  Stream<SingboxStats> watchStats() {
    if (_serviceStatsStream != null) return _serviceStatsStream!;
    final receiver = MethodChannelPort('app.hiddify.com.macos/stats');
    final statusStream = receiver.asBroadcastStream(
      onCancel: () async {
        _logger.debug("stopping stats command client");

        final Map<String, dynamic> args = {
          'id': 1,
        };
        final String? error = await platform.invokeMethod<String>('stopCommandClient', args);

        if (error != null && error.isNotEmpty) {
          _logger.error("error stopping stats client");
        }
        receiver.close();
        _serviceStatsStream = null;
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            loggy.error("[service stats client] error received: $event");
            throw event.replaceFirst('error:', "");
          }
          return SingboxStats.fromJson(
            jsonDecode(event) as Map<String, dynamic>,
          );
        }
        loggy.error("[service status client] unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    Future<void> startStream() async {
      final Map<String, dynamic> args = {
        'id': 1,
        'port': 1,
      };
      final String? error = await platform.invokeMethod<String>('startCommandClient', args);

      if (error != null && error.isNotEmpty) {
        loggy.error("error starting status command: $error");
        throw error;
      }
    }

    unawaited(startStream());

    return _serviceStatsStream = statusStream;
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchGroups() {
    final logger = newLoggy("watchGroups");
    if (_outboundsStream != null) return _outboundsStream!;
    final receiver = MethodChannelPort('app.hiddify.com.macos/groups');
    final outboundsStream = receiver.asBroadcastStream(
      onCancel: () async {
        logger.debug("stopping");
        receiver.close();
        _outboundsStream = null;

        final Map<String, dynamic> args = {
          'id': 5,
        };
        final String? error = await platform.invokeMethod<String>('stopCommandClient', args);
        if (error != null && error.isNotEmpty) {
          logger.error("error stopping group client: $error");
          throw error;
        }
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            logger.error("error received: $event");
            throw event.replaceFirst('error:', "");
          }

          return (jsonDecode(event) as List).map((e) {
            return SingboxOutboundGroup.fromJson(e as Map<String, dynamic>);
          }).toList();
        }
        logger.error("unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    Future<void> startStream() async {
      try {
        final Map<String, dynamic> args = {
          'id': 5,
          'port': 2,
        };

        final String? error = await platform.invokeMethod<String>('startCommandClient', args);

        if (error != null && error.isNotEmpty) {
          logger.error("error starting group command: $error");
          throw error;
        }
      } catch (e) {
        receiver.close();
        rethrow;
      }
    }

    unawaited(startStream());

    return _outboundsStream = outboundsStream;
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchActiveGroups() {
    final logger = newLoggy("[ActiveGroupsClient]");
    final receiver = MethodChannelPort('app.hiddify.com.macos/activeGroups');
    final outboundsStream = receiver.asBroadcastStream(
      onCancel: () async {
        logger.debug("stopping");
        receiver.close();

        final Map<String, dynamic> args = {'id': 13};
        final String? error = await platform.invokeMethod<String>('stopCommandClient', args);

        if (error != null && error.isNotEmpty) {
          logger.error("failed stopping: $error");
        }
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            logger.error(event);
            throw event.replaceFirst('error:', "");
          }

          return (jsonDecode(event) as List).map((e) {
            return SingboxOutboundGroup.fromJson(e as Map<String, dynamic>);
          }).toList();
        }
        logger.error("unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    Future<void> startStream() async {
      try {
        final Map<String, dynamic> args = {
          'id': 13,
          'port': 3,
        };

        final String? error = await platform.invokeMethod<String>('startCommandClient', args);

        if (error != null && error.isNotEmpty) {
          logger.error("error starting: $error");
          throw error;
        }
      } catch (e) {
        receiver.close();
        rethrow;
      }
    }

    unawaited(startStream());

    return outboundsStream;
  }

  @override
  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {
            'groupTag': groupTag,
            'outboundTag': outboundTag,
          };

          final String? error = await platform.invokeMethod<String>('selectOutbound', args);

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> urlTest(String groupTag) {
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {
            'groupTag': groupTag,
          };

          final String? error = await platform.invokeMethod<String>('urlTest', args);

          if (error != null && error.isNotEmpty) {
            return left(error);
          }
          return right(unit);
        },
      ),
    );
  }

  final _logBuffer = <String>[];
  int _logFilePosition = 0;

  @override
  Stream<List<String>> watchLogs(String path) async* {
    yield await _readLogFile(File(path));
    yield* Watcher(path, pollingDelay: const Duration(seconds: 1)).events.asyncMap((event) async {
      if (event.type == ChangeType.MODIFY) {
        await _readLogFile(File(path));
      }
      return _logBuffer;
    });
  }

  @override
  TaskEither<String, Unit> clearLogs() {
    return TaskEither(
      () => CombineWorker().execute(
        () {
          _logBuffer.clear();
          return right(unit);
        },
      ),
    );
  }

  Future<List<String>> _readLogFile(File file) async {
    if (_logFilePosition == 0 && file.lengthSync() == 0) return [];
    final content = await file.openRead(_logFilePosition).transform(utf8.decoder).join();
    _logFilePosition = file.lengthSync();
    final lines = const LineSplitter().convert(content);
    if (lines.length > 300) {
      lines.removeRange(0, lines.length - 300);
    }
    for (final line in lines) {
      _logBuffer.add(line);
      if (_logBuffer.length > 300) {
        _logBuffer.removeAt(0);
      }
    }
    return _logBuffer;
  }

  @override
  TaskEither<String, WarpResponse> generateWarpConfig({
    required String licenseKey,
    required String previousAccountId,
    required String previousAccessToken,
  }) {
    loggy.debug("generating warp config");
    return TaskEither(
      () => CombineWorker().execute(
        () async {
          final Map<String, dynamic> args = {
            'licenseKey': licenseKey,
            'previousAccountId': previousAccountId,
            'previousAccessToken': previousAccessToken,
          };
          final String? response = await platform.invokeMethod<String>('generateWarpConfig', args);

          if (response == null || response.isEmpty) {
            return left("Failed to generate warp config");
          }

          if (response.startsWith("error:")) {
            return left(response.replaceFirst('error:', ""));
          }
          return right(warpFromJson(jsonDecode(response)));
        },
      ),
    );
  }
}
