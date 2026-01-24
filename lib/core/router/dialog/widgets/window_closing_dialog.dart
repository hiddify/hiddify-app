import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class _WindowClosingDialogState extends ConsumerState<WindowClosingDialog> {
  bool remember = false;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;

    return AlertDialog(
      title: Text(t.dialogs.windowClosing.alertMessage),
      content: GestureDetector(
        onTap: () => setState(() {
          remember = !remember;
        }),
        behavior: HitTestBehavior.translucent,
        child: Row(
          children: [
            Checkbox(
              value: remember,
              onChanged: (v) {
                remember = v ?? remember;
                setState(() {});
              },
            ),
            const SizedBox(width: 16),
            Text(t.dialogs.windowClosing.remember, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (remember) {
              ref.read(Preferences.actionAtClose.notifier).update(ActionsAtClosing.exit);
            }
            ref.read(windowNotifierProvider.notifier).exit();
          },
          child: Text(t.common.close),
        ),
        FilledButton(
          onPressed: () async {
            if (remember) {
              ref.read(Preferences.actionAtClose.notifier).update(ActionsAtClosing.hide);
            }
            context.pop(false);
            await ref.read(windowNotifierProvider.notifier).hide();
          },
          child: Text(t.common.hide),
        ),
      ],
    );
  }
}
