import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';

class CoreInterface {
  late CoreClient fgClient;
  late CoreClient bgClient;

  bool get managesLifecycle => false;
  bool get persistsAfterAppExit => false;
  Stream<CoreStatus>? get managedStatus => null;
  Stream<void>? get clientChanges => null;

  Future<void> setOptions(SingboxConfigOption options) async {}
  Future<void> dispose() async {}
  Future<void> startManaged(String path, String name, bool disableMemoryLimit) async {
    throw UnimplementedError();
  }

  Future<String> setup(Directories directories, bool debug, int mode) async {
    return "";
  }

  Future<CoreStatus> setupBackground(String path, String name) async {
    return const CoreStarted();
  }

  Future<bool> restart(String path, String name) async {
    return false;
  }

  Future<bool> stop() async {
    return false;
  }

  Future<bool> isBgClientAvailable() async {
    return true;
  }

  bool isSingleChannel() {
    // return true;
    return fgClient == bgClient;
  }

  Future<bool> resetTunnel() async {
    return false;
  }

  Future<bool> isActiveFg() async {
    return true;
  }

  Future<bool> isActiveBg() async {
    return true;
  }

  bool isInitialized() {
    try {
      bgClient; // touch it
      return true;
    } catch (_) {
      return false;
    }
  }
}
