import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingText extends ConsumerWidget {
  const SettingText({super.key, required this.title, required this.value, required this.setValue, this.defaultValue, this.validator});

  final String title;
  final String value;
  final Function(String value) setValue;
  final String? defaultValue;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return ListTile(
      title: Text(title),
      subtitle: Text(value.isEmpty ? t.general.empty : value),
      onTap: () async {
        final result = await showDialog(
          context: context,
          builder: (context) => SettingTextDialog(
            lable: title,
            value: value,
            defaultValue: defaultValue,
            validator: validator,
          ),
        );
        if (result is String) setValue(result);
      },
    );
  }
}

class SettingTextDialog extends HookConsumerWidget {
  const SettingTextDialog({super.key, required this.lable, this.value = '', this.defaultValue, this.validator});

  final String lable;
  final String value;
  final String? defaultValue;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final tController = useTextEditingController(text: value);
    return AlertDialog(
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: Form(
          key: formKey,
          child: TextFormField(
            decoration: InputDecoration(
              label: Text(lable),
            ),
            controller: tController,
            validator: (value) {
              if (value == null || value.isEmpty) return t.settings.routeRule.rule.canNotBeEmpty;
              if (validator == null) return null;
              return validator!.call(value);
            },
            autofocus: true,
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
        TextButton(
          child: Text(t.general.ok),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(tController.text.trim());
            }
          },
        ),
      ],
    );
  }
}
