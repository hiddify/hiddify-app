import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class WindowWrapper extends StatefulHookConsumerWidget {
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
    if (rootNavKey.currentContext == null) {
      await ref.read(windowNotifierProvider.notifier).hide();
      return;
    }

    switch (ref.read(Preferences.actionAtClose)) {
      case ActionsAtClosing.ask:
        if (isWindowClosingDialogOpened) return;
        isWindowClosingDialogOpened = true;
        await ref.read(dialogNotifierProvider.notifier).showWindowClosing();
        isWindowClosingDialogOpened = false;

      case ActionsAtClosing.hide:
        await ref.read(windowNotifierProvider.notifier).hide();

      case ActionsAtClosing.exit:
        await ref.read(windowNotifierProvider.notifier).exit();
    }
  }

  @override
  Future<void> onWindowResized() async {
    await ref.read(windowNotifierProvider.notifier).saveWindowState();
  }

  @override
  Future<void> onWindowMoved() async {
    await ref.read(windowNotifierProvider.notifier).saveWindowState();
  }

  @override
  Future<void> onWindowMaximize() async {
    await ref.read(windowNotifierProvider.notifier).saveWindowState();
  }

  @override
  Future<void> onWindowUnmaximize() async {
    await ref.read(windowNotifierProvider.notifier).saveWindowState();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }
}
