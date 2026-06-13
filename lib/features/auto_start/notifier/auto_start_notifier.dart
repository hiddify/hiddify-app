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
    launchAtStartup.setup(
      appName: appInfo.name,
      appPath: Platform.resolvedExecutable,
      packageName: "Hiddify.HiddifyNext",
    );
    final isEnabled = await _isEnabledSafe();
    loggy.info("auto start is [${isEnabled ? "Enabled" : "Disabled"}]");
    _startTimer();
    ref.onDispose(() => _timer?.cancel());
    return isEnabled;
  }

  /// Reads the launch-at-startup status, treating a read failure as disabled.
  ///
  /// On a fresh Windows install the relevant registry key may not exist yet,
  /// in which case `launchAtStartup.isEnabled()` throws instead of returning
  /// false. A missing key means auto start is not registered, so treat any
  /// read failure as disabled rather than letting it propagate.
  Future<bool> _isEnabledSafe() async {
    try {
      return await launchAtStartup.isEnabled();
    } catch (e, stackTrace) {
      loggy.warning("failed to read auto start status, assuming disabled", e, stackTrace);
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) => updateStatus());
  }

  Future<bool> updateStatus() async {
    loggy.debug("update auto start status");
    final isEnabled = await _isEnabledSafe();
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
