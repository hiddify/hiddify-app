import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class WindowWrapper extends StatefulHookConsumerWidget {
  const WindowWrapper(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WindowWrapperState();
}

class _WindowWrapperState extends ConsumerState<WindowWrapper> with WindowListener, AppLogger {
  late PlatformAlertDialog closeDialog;

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
    if (RootScaffold.stateKey.currentContext == null) {
      await ref.read(windowNotifierProvider.notifier).close();
      return;
    }
    final t = ref.watch(translationsProvider);

    await showDialog(
      context: RootScaffold.stateKey.currentContext!,
      builder: (BuildContext context) => PlatformAlertDialog(
        title: Text(t.window.alertMessage),
        actions: [
          TextButton(
            onPressed: () async => await ref.read(windowNotifierProvider.notifier).quit(),
            child: Text(t.window.close.toUpperCase()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).maybePop(false);
              await ref.read(windowNotifierProvider.notifier).close();
            },
            child: Text(t.window.hide.toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }
}
