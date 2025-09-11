import 'package:hiddify/utils/custom_loggers.dart';

import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WindowClosingDialog extends ConsumerStatefulWidget {
  const WindowClosingDialog({super.key});

  @override
  ConsumerState<WindowClosingDialog> createState() => _WindowClosingDialogState();
}

class _WindowClosingDialogState extends ConsumerState<WindowClosingDialog> with PresLogger {
  bool remember = false;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return AlertDialog(
      title: Text(t.window.alertMessage),
      content: GestureDetector(
        onTap: () {
          if (mounted) {
            setState(() {
              remember = !remember;
            });
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Row(
          children: [
            Checkbox(
              value: remember,
              onChanged: (v) {
                remember = v ?? remember;
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(width: 16),
            Text(
              t.window.remember,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              if (remember) {
                await ref.read(Preferences.actionAtClose.notifier).update(ActionsAtClosing.exit);
              }

              // Close dialog first
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }

              // Then quit with timeout
              await ref.read(windowNotifierProvider.notifier).quit().timeout(const Duration(seconds: 2)).catchError((e) {
                // If quit fails, force exit
                loggy.warning('Quit failed, forcing exit: $e');
              });
            } catch (e) {
              loggy.error('Error in quit action: $e');
            }
          },
          child: Text(t.window.close),
        ),
        FilledButton(
          onPressed: () async {
            try {
              if (remember) {
                await ref.read(Preferences.actionAtClose.notifier).update(ActionsAtClosing.hide);
              }

              // Close dialog first
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }

              // Then hide window with timeout
              await ref.read(windowNotifierProvider.notifier).close().timeout(const Duration(seconds: 1)).catchError((e) {
                loggy.warning('Hide failed: $e');
              });
            } catch (e) {
              loggy.error('Error in hide action: $e');
            }
          },
          child: Text(t.window.hide),
        ),
      ],
    );
  }
}
