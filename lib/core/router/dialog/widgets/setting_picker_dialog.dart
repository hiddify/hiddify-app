import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
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
  });

  final String title;
  final bool showFlag;
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
          children: options.map((e) {
            final title = getTitle(e);
            final countryCode = title.substring(title.length - 3, title.length - 1);
            return RadioListTile(
              title: Text(title),
              secondary: showFlag ? IPCountryFlag(countryCode: countryCode, size: 32) : null,
              value: e,
              groupValue: selected,
              onChanged: (value) => context.pop(e),
            );
          }).toList(),
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
