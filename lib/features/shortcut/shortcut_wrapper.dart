import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ShortcutWrapper extends HookConsumerWidget {
  const ShortcutWrapper(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: {
        // Android TV D-pad select support
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),

        if (Platform.isLinux) ...{
          // quit app using Control+Q on Linux
          const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
              QuitAppIntent(),
        },

        if (Platform.isMacOS) ...{
          // close window using Command+W on macOS
          const SingleActivator(LogicalKeyboardKey.keyW, meta: true):
              CloseWindowIntent(),

          // open settings using Command+, on macOS
          const SingleActivator(LogicalKeyboardKey.comma, meta: true):
              OpenSettingsIntent(),
        },

        // try adding profile using Command+V and Control+V
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            PasteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
            PasteIntent(),
      },
      child: Actions(
        actions: {
          CloseWindowIntent: CallbackAction(
            onInvoke: (_) async {
              await ref.read(windowNotifierProvider.notifier).close();
              return null;
            },
          ),
          QuitAppIntent: CallbackAction(
            onInvoke: (_) async {
              await ref.read(windowNotifierProvider.notifier).quit();
              return null;
            },
          ),
          OpenSettingsIntent: CallbackAction(
            onInvoke: (_) {
              if (rootNavigatorKey.currentContext != null) {
                const SettingsRoute().go(rootNavigatorKey.currentContext!);
              }
              return null;
            },
          ),
          PasteIntent: CallbackAction(
            onInvoke: (_) async {
              if (rootNavigatorKey.currentContext != null) {
                final captureResult =
                    await Clipboard.getData(Clipboard.kTextPlain)
                        .then((value) => value?.text ?? '');
                AddProfileRoute(url: captureResult)
                    .push(rootNavigatorKey.currentContext!);
              }
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class CloseWindowIntent extends Intent {}

class QuitAppIntent extends Intent {}

class OpenSettingsIntent extends Intent {}

class PasteIntent extends Intent {}
