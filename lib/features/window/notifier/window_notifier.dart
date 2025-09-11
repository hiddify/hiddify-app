import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'window_notifier.g.dart';

const minimumWindowSize = Size(368, 568);
const defaultWindowSize = Size(868, 668);

@Riverpod(keepAlive: true)
class WindowNotifier extends _$WindowNotifier with AppLogger {
  @override
  Future<void> build() async {
    if (!PlatformUtils.isDesktop) return;

    // if (Platform.isWindows) {
    //   loggy.debug("ensuring single instance");
    //   await WindowsSingleInstance.ensureSingleInstance([], "Hiddify");
    // }

    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(minimumWindowSize);
    await windowManager.setSize(defaultWindowSize);
  }

  Future<void> open({bool focus = true}) async {
    await windowManager.waitUntilReadyToShow();
    await windowManager.show();
    if (focus) await windowManager.focus();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(false);
    }
  }

  // TODO add option to quit or minimize to tray
  Future<void> close() async {
    await windowManager.hide();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(true);
    }
  }

  // Enhanced quit method with proper cleanup and timeout handling
  Future<void> quit() async {
    loggy.info("Initiating safe quit...");

    try {
      // Set a shorter timeout for connection cleanup
      await ref.read(connectionNotifierProvider.notifier).abortConnection().timeout(const Duration(milliseconds: 1500), // Reduced from 2 seconds
          onTimeout: () {
        loggy.warning("Connection abort timed out, forcing quit");
      });

      // Ensure window is properly hidden first
      await windowManager.hide();

      // Force close any remaining resources
      loggy.info("Forcing application exit...");

      // Use exit(0) to ensure the process terminates completely
      await windowManager.destroy();

      // As a last resort, force exit the process
      exit(0);
    } catch (e) {
      loggy.error("Error during quit sequence: $e");
      // Emergency exit if normal quit fails
      exit(1);
    }
  }
}
