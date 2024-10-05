import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';
import 'package:hiddify/singbox/model/singbox_stats.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class WebSingboxService with InfraLogger implements SingboxService {
  @override
  Future<void> init() async {
    throw UnsupportedError('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> setup(Directories directories, bool debug) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> validateConfigByPath(String path, String tempPath, bool debug) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, String> generateFullConfigByPath(String path) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> start(String path, String name, bool disableMemoryLimit) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> stop() {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> restart(String path, String name, bool disableMemoryLimit) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> resetTunnel() {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchGroups() {
    return Stream.error('Singbox is not supported on the web');
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchActiveGroups() {
    return Stream.error('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> urlTest(String groupTag) {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  Stream<SingboxStatus> watchStatus() {
    return Stream.error('Singbox is not supported on the web');
  }

  @override
  Stream<SingboxStats> watchStats() {
    return Stream.error('Singbox is not supported on the web');
  }

  @override
  Stream<List<String>> watchLogs(String path) {
    return Stream.error('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, Unit> clearLogs() {
    return TaskEither.left('Singbox is not supported on the web');
  }

  @override
  TaskEither<String, WarpResponse> generateWarpConfig({
    required String licenseKey,
    required String previousAccountId,
    required String previousAccessToken,
  }) {
    return TaskEither.left('Singbox is not supported on the web');
  }
}
