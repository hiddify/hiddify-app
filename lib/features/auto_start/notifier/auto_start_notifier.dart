import 'dart:async';
import 'dart:io';

import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_start_notifier.g.dart';

@Riverpod(keepAlive: true)
class AutoStartNotifier extends _$AutoStartNotifier with InfraLogger {
  Timer? _timer;

  @override
  Future<bool> build() async {
    if (!PlatformUtils.isDesktop) return false;
    final appInfo = ref.watch(appInfoProvider).requireValue;
    // Must equal identity_name in windows/packaging/msix/make_config.yaml.
    const packageName = "Hiddify.App.Win";
    final isWindowsRegistry = Platform.isWindows && !Platform.resolvedExecutable.contains('WindowsApps');
    // An entry written by an older version has neither quotes nor --autostart: rewrite it, or
    // the switch shows off while Windows still launches it, and that launch shows the window.
    var legacyEntry = false;
    if (isWindowsRegistry) {
      launchAtStartup.setup(appName: appInfo.name, appPath: Platform.resolvedExecutable);
      legacyEntry = await launchAtStartup.isEnabled();
    }
    launchAtStartup.setup(
      appName: appInfo.name,
      // Quoted, as the Run key holds a command line and the path usually has a space in it.
      appPath: isWindowsRegistry ? '"${Platform.resolvedExecutable}"' : Platform.resolvedExecutable,
      packageName: packageName,
      // A second copy launched with it at login leaves the running app's window as it is
      // (windows/runner/main.cpp), so a silent start stays in the tray.
      args: Platform.isWindows ? const ['--autostart'] : const [],
    );
    if (legacyEntry) {
      loggy.info("rewriting the auto start entry of an older version");
      await launchAtStartup.enable();
    }
    final isEnabled = await launchAtStartup.isEnabled();
    loggy.info("auto start is [${isEnabled ? "Enabled" : "Disabled"}]");
    _startTimer();
    ref.onDispose(() => _timer?.cancel());
    return isEnabled;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) => updateStatus());
  }

  Future<bool> updateStatus() async {
    loggy.debug("update auto start status");
    final isEnabled = await launchAtStartup.isEnabled();
    state = AsyncValue.data(isEnabled);
    return isEnabled;
  }

  Future<void> enable() async {
    loggy.debug("enabling auto start");
    await launchAtStartup.enable();
    state = const AsyncValue.data(true);
  }

  Future<void> disable() async {
    loggy.debug("disabling auto start");
    await launchAtStartup.disable();
    state = const AsyncValue.data(false);
  }
}
