import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingRadio<T> extends ConsumerWidget {
  const SettingRadio({super.key, required this.title, required this.values, required this.value, required this.setValue, this.defaultValue, this.t});

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
        final result = await showDialog(
          context: context,
          builder: (context) => SettingRadioDialog(
            title: title,
            values: values,
            value: value,
            defaultValue: defaultValue,
            t: t,
          ),
        );
        if (result is T) setValue(result);
      },
    );
  }
}

class SettingRadioDialog<T> extends ConsumerWidget {
  const SettingRadioDialog({super.key, required this.title, required this.values, required this.value, this.defaultValue, this.t});

  final String title;
  final List<T> values;
  final T value;
  final T? defaultValue;
  final Map<String, String>? t;

  String textWithTranslation(T e) {
    if (t == null) return '$e';
    return t!['$e'] ?? '$e';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: values
                .map(
                  (e) => RadioListTile<T>(
                    title: Text(textWithTranslation(e)),
                    value: e,
                    groupValue: value,
                    onChanged: (value) => Navigator.of(context).pop(e),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        if (defaultValue != null)
          TextButton(
            child: Text(t.general.reset),
            onPressed: () => Navigator.of(context).pop(defaultValue),
          ),
        TextButton(
          child: Text(t.general.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
