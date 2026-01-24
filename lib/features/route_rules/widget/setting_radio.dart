import 'package:flutter/material.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingRadio<T> extends ConsumerWidget {
  const SettingRadio({
    super.key,
    required this.title,
    required this.values,
    required this.value,
    required this.setValue,
    this.defaultValue,
    this.t,
  });

  final String title;
  final List<T> values;
  final T value;
  final Function(T value) setValue;
  final T? defaultValue;
  final Map<String, String>? t;

  String textWithTranslation(T e) {
    if (t == null) return '$e';
    return t!['$e'] ?? '$e';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(title),
      subtitle: Text(textWithTranslation(value)),
      onTap: () async {
        final result = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingRadio<T>(title: title, values: values, value: value, defaultValue: defaultValue, t: t);
        if (result is T) setValue(result);
      },
    );
  }
}
