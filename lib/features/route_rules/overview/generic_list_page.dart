import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/confirmation_dialogs.dart';
import 'package:hiddify/features/route_rules/notifier/generic_list_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hiddify/features/route_rules/widget/setting_text.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:recase/recase.dart';
import 'package:text_scroll/text_scroll.dart';

class GenericListPage extends HookConsumerWidget {
  const GenericListPage({super.key, this.ruleListOrder, required this.ruleEnum, this.validator});

  final int? ruleListOrder;
  final RuleEnum ruleEnum;
  final FormFieldValidator<String>? validator;

  String getTitle(Map<String, String> t, RuleEnum key) => t[key.name.snakeCase] ?? key.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final tGenericList = t.settings.routeRule.genericList;
    final provider = genericListNotifierProvider(ruleListOrder, ruleEnum);
    final list = ref.watch(provider);

    Future<void> addNewValue() => showDialog(
          context: context,
          builder: (context) => SettingTextDialog(lable: tGenericList.addNew, validator: validator),
        ).then((value) => ref.read(provider.notifier).add(value));

    return Scaffold(
      appBar: AppBar(
        title: Text(getTitle(t.settings.routeRule.rule.tileTitle, ruleEnum)),
        actions: [
          IconButton(
            onPressed: list.isEmpty
                ? null
                : () async {
                    final result = await showConfirmationDialog(
                      context,
                      title: tGenericList.clearList,
                      message: tGenericList.clearListMsg,
                    );
                    if (result == true) ref.read(provider.notifier).reset();
                  },
            icon: const Icon(Icons.clear_all),
          ),
          const Gap(8),
        ],
      ),
      floatingActionButton: list.isNotEmpty
          ? FloatingActionButton(
              onPressed: addNewValue,
              child: const Icon(Icons.add_rounded),
            )
          : FloatingActionButton.extended(
              onPressed: addNewValue,
              label: Text(tGenericList.addNew),
              icon: const Icon(Icons.add_rounded),
            ),
      body: ListView.builder(
        itemBuilder: (context, index) => GenericListTile(
          value: list[index],
          onRemove: () => ref.read(provider.notifier).remove(index),
          onUpdate: () => showDialog(
            context: context,
            builder: (context) => SettingTextDialog(
              lable: tGenericList.update,
              value: '${list[index]}',
              validator: validator,
            ),
          ).then((value) => ref.read(provider.notifier).update(index, value)),
        ),
        itemCount: list.length,
      ),
    );
  }
}

class GenericListTile extends ConsumerWidget {
  const GenericListTile({super.key, required this.value, required this.onRemove, required this.onUpdate});

  final dynamic value;
  final VoidCallback? onRemove;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: onUpdate,
      title: TextScroll(
        '$value',
        mode: TextScrollMode.bouncing,
        velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
        pauseOnBounce: const Duration(seconds: 2),
        pauseBetween: const Duration(seconds: 2),
      ),
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.remove),
      ),
    );
  }
}
