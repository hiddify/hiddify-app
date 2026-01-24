import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingPickerDialog<T> extends HookConsumerWidget with PresLogger {
  const SettingPickerDialog({
    super.key,
    required this.title,
    required this.selected,
    required this.options,
    required this.getTitle,
    this.onReset,
  });

  final String title;
  final T selected;
  final List<T> options;
  final String Function(T e) getTitle;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (e) => RadioListTile(
                  title: Text(getTitle(e)),
                  value: e,
                  groupValue: selected,
                  onChanged: (value) => context.pop(e),
                ),
              )
              .toList(),
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
