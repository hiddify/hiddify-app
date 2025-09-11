import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';
import 'package:hiddify/singbox/model/singbox_stats.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';
import 'package:hiddify/singbox/service/ffi_singbox_service.dart';
import 'package:hiddify/singbox/service/platform_singbox_service.dart';

abstract interface class SingboxService {
  factory SingboxService() {
    if (Platform.isAndroid || Platform.isIOS) {
      return PlatformSingboxService();
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return FFISingboxService();
    }
    throw Exception("unsupported platform");
  }

  Future<void> init();

  /// setup directories and other initial platform services
  TaskEither<String, Unit> setup(
    Directories directories,
    bool debug,
  );

  /// validates config by path and save it
  ///
  /// [path] is used to save validated config
  /// [tempPath] includes base config, possibly invalid
  /// [debug] indicates if debug mode (avoid in prod)
  TaskEither<String, Unit> validateConfigByPath(
    String path,
    String tempPath,
    bool debug,
  );

  TaskEither<String, Unit> changeOptions(SingboxConfigOption options);

  /// generates full sing-box configuration
  ///
  /// [path] is the path to the base config file
  /// returns full patched json config file as string
  TaskEither<String, String> generateFullConfigByPath(String path);

  /// start sing-box service
  ///
  /// [path] is the path to the base config file (to be patched by previously set [SingboxConfigOption])
  /// [name] is the name of the active profile (not unique, used for presentation in platform specific ui)
  /// [disableMemoryLimit] is used to disable service memory limit (mostly used in mobile platforms i.e. iOS)
  TaskEither<String, Unit> start(
    String path,
    String name,
    bool disableMemoryLimit,
  );

  TaskEither<String, Unit> stop();

  /// similar to [start], but uses platform dependent behavior to restart the service
  TaskEither<String, Unit> restart(
    String path,
    String name,
    bool disableMemoryLimit,
  );

  TaskEither<String, Unit> resetTunnel();

  Stream<List<SingboxOutboundGroup>> watchGroups();

  Stream<List<SingboxOutboundGroup>> watchActiveGroups();

  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag);

  TaskEither<String, Unit> urlTest(String groupTag);

  /// watch status of sing-box service (started, starting, etc.)
  Stream<SingboxStatus> watchStatus();

  /// watch stats of sing-box service (uplink, downlink, etc.)
  Stream<SingboxStats> watchStats();

  Stream<List<String>> watchLogs(String path);

  TaskEither<String, Unit> clearLogs();

  TaskEither<String, WarpResponse> generateWarpConfig({
    required String licenseKey,
    required String previousAccountId,
    required String previousAccessToken,
  });
}
