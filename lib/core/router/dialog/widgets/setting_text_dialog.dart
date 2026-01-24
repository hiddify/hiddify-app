import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
            decoration: InputDecoration(label: Text(lable)),
            controller: tController,
            validator: (value) {
              if (value == null || value.isEmpty) return t.pages.settings.routing.routeRule.rule.canNotBeEmpty;
              if (validator == null) return null;
              return validator!.call(value);
            },
            autofocus: true,
          ),
        ),
      ),
      actions: [
        if (defaultValue != null) TextButton(child: Text(t.common.reset), onPressed: () => context.pop(defaultValue)),
        TextButton(child: Text(t.common.cancel), onPressed: () => context.pop()),
        TextButton(
          child: Text(t.common.ok),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              context.pop(tController.text.trim());
            }
          },
        ),
      ],
    );
  }
}
