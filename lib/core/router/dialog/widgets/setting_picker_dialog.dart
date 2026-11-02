import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/arrow_keys_move_focus.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingPickerDialog<T> extends HookConsumerWidget with PresLogger {
  const SettingPickerDialog({
    super.key,
    required this.title,
    this.showFlag = false,
    required this.selected,
    required this.options,
    required this.getTitle,
    this.onReset,
    this.getSecondary,
  });

  final String title;
  final bool showFlag;
  final T selected;
  final List<T> options;
  final String Function(T e) getTitle;
  final VoidCallback? onReset;

  /// A picture at the end of an option's row, such as a flag; [showFlag] reads one from the title.
  final Widget? Function(T e)? getSecondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: RadioGroup<T>(
          groupValue: selected,
          onChanged: (value) => context.pop(value),
          child: ArrowKeysMoveFocus(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((e) {
                final title = getTitle(e);
                return RadioListTile<T>(
                  title: Text(title),
                  secondary: getSecondary?.call(e) ?? (showFlag ? ChoicePreferenceWidget.flagByTitle(title) : null),
                  value: e,
                  // the remote starts on the current choice
                  autofocus: e == selected,
                );
              }).toList(),
            ),
          ),
        ),
      ),
      actions: [
        if (onReset != null)
          TextButton(
            onPressed: () {
              onReset!();
              context.pop();
            },
            child: Text(t.common.reset),
          ),
        TextButton(onPressed: () => context.pop(), child: Text(t.common.cancel)),
      ],
      // scrollable: true,
    );
  }
}
