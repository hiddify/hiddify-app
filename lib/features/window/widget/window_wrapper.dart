import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/services/window_cleanup_service.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/features/window/widget/window_closing_dialog.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class WindowWrapper extends ConsumerStatefulWidget {
  const WindowWrapper(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WindowWrapperState();
}

class _WindowWrapperState extends ConsumerState<WindowWrapper> with WindowListener, AppLogger {
  late AlertDialog closeDialog;

  bool isWindowClosingDialogOpened = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(windowNotifierProvider);

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    if (PlatformUtils.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await windowManager.setPreventClose(true);
        // Set provider container for cleanup service
        WindowCleanupService().setProviderContainer(
          ProviderContainer(),
        );
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    // Prevent multiple simultaneous close attempts
    if (isWindowClosingDialogOpened) {
      loggy.debug("Window close already in progress, ignoring");
      return;
    }

    // Check if we have a valid context before proceeding with close logic
    if (!mounted) {
      loggy.debug("Widget not mounted, ignoring window close");
      return;
    }

    final scaffoldContext = RootScaffold.stateKey.currentContext;
    if (scaffoldContext == null) {
      loggy.debug("No scaffold context available, ignoring window close to prevent errors");
      return;
    }

    final action = ref.read(Preferences.actionAtClose);
    loggy.debug("Window close action: $action");

    try {
      switch (action) {
        case ActionsAtClosing.ask:
          if (!mounted) return;
          isWindowClosingDialogOpened = true;

          // Show dialog with timeout to prevent hanging
          showDialog<bool?>(
            context: scaffoldContext,
            builder: (BuildContext context) => const WindowClosingDialog(),
          ).timeout(const Duration(seconds: 5), onTimeout: () {
            loggy.warning("Close dialog timed out, forcing hide with cleanup");
            if (mounted && scaffoldContext.mounted) {
              Navigator.of(scaffoldContext).pop();
            }
            return null;
          }).catchError((e) {
            loggy.warning("Error showing close dialog: $e");
            return null;
          }).whenComplete(() {
            isWindowClosingDialogOpened = false;
          });

          break;

        case ActionsAtClosing.hide:
          // Perform cleanup before hiding
          loggy.debug("Performing cleanup before hiding window");
          await WindowCleanupService().performSafeCleanup();
          await ref.read(windowNotifierProvider.notifier).close().timeout(const Duration(seconds: 2)).catchError((e) {
            loggy.warning("Error during window hide: $e");
          });
          break;

        case ActionsAtClosing.exit:
          // Perform cleanup before exiting
          loggy.debug("Performing cleanup before exiting application");
          await WindowCleanupService().performSafeCleanup();
          await ref.read(windowNotifierProvider.notifier).quit().timeout(const Duration(seconds: 5)).catchError((e) {
            loggy.warning("Error during window quit: $e");
          });
          break;
      }
    } catch (e) {
      loggy.error("Unexpected error during window close: $e");
      // Don't perform fallback close operations that could cause gray screen
      loggy.debug("Skipping fallback close to prevent gray screen issue");
    } finally {
      isWindowClosingDialogOpened = false;
    }
  }

  @override
  void onWindowFocus() {
    if (mounted) {
      setState(() {});
    }
  }
}
