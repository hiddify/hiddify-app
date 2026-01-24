import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protobuf/protobuf.dart';

class SettingCheckboxDialog extends ConsumerWidget {
  const SettingCheckboxDialog({
    super.key,
    required this.title,
    required this.values,
    required this.selectedValues,
    this.defaultValue,
    this.t,
  });

  final String title;
  final List<ProtobufEnum> values;
  final List<ProtobufEnum> selectedValues;
  final List<ProtobufEnum>? defaultValue;
  final Map<String, String>? t;

  String textWithTranslation(ProtobufEnum e) {
    if (t == null) return '$e';
    return t!['$e'] ?? '$e';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final checkboxNotififier = dialogCheckboxNotifierProvider(selectedValues);
    final current = ref.watch(checkboxNotififier);

    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: values
                .map(
                  (e) => CheckboxListTile(
                    title: Text(textWithTranslation(e)),
                    value: current.contains(e),
                    onChanged: (_) => ref.read(checkboxNotififier.notifier).update(e),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        if (defaultValue != null) TextButton(child: Text(t.common.reset), onPressed: () => context.pop(defaultValue)),
        TextButton(child: Text(t.common.cancel), onPressed: () => context.pop()),
        TextButton(child: Text(t.common.done), onPressed: () => context.pop(current)),
      ],
    );
  }
}
