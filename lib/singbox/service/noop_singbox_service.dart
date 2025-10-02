import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';
import 'package:hiddify/singbox/model/singbox_stats.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';

class NoopSingboxService implements SingboxService {
  NoopSingboxService();

  @override
  Future<void> init() async {}

  @override
  TaskEither<String, Unit> setup(Directories directories, bool debug) => TaskEither.of(unit);

  @override
  TaskEither<String, Unit> validateConfigByPath(String path, String tempPath, bool debug) => TaskEither.of(unit);

  @override
  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) => TaskEither.of(unit);

  @override
  TaskEither<String, String> generateFullConfigByPath(String path) => TaskEither.of('{}');

  @override
  TaskEither<String, Unit> start(String path, String name, bool disableMemoryLimit) => TaskEither.of(unit);

  @override
  TaskEither<String, Unit> stop() => TaskEither.of(unit);

  @override
  TaskEither<String, Unit> restart(String path, String name, bool disableMemoryLimit) => TaskEither.of(unit);

  @override
  TaskEither<String, Unit> resetTunnel() => TaskEither.of(unit);

  @override
  Stream<List<SingboxOutboundGroup>> watchGroups() => const Stream<List<SingboxOutboundGroup>>.empty();

  @override
  Stream<List<SingboxOutboundGroup>> watchActiveGroups() => const Stream<List<SingboxOutboundGroup>>.empty();

  @override
  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) => TaskEither.of(unit);

  @override
  TaskEither<String, Unit> urlTest(String groupTag) => TaskEither.of(unit);

  @override
  Stream<SingboxStatus> watchStatus() => Stream.value(const SingboxStatus.stopped());

  @override
  Stream<SingboxStats> watchStats() => Stream.value(
        const SingboxStats(
          connectionsIn: 0,
          connectionsOut: 0,
          uplink: 0,
          downlink: 0,
          uplinkTotal: 0,
          downlinkTotal: 0,
        ),
      );

  @override
  Stream<List<String>> watchLogs(String path) => const Stream<List<String>>.empty();

  @override
  TaskEither<String, Unit> clearLogs() => TaskEither.of(unit);

  @override
  TaskEither<String, WarpResponse> generateWarpConfig({
    required String licenseKey,
    required String previousAccountId,
    required String previousAccessToken,
  }) => TaskEither.of((
        log: 'noop',
        accountId: previousAccountId,
        accessToken: previousAccessToken,
        wireguardConfig: '{}',
      ));
}
