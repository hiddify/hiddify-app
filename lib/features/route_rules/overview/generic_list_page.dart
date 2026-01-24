import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/generic_list_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:text_scroll/text_scroll.dart';

class GenericListPage extends HookConsumerWidget {
  const GenericListPage({super.key, this.ruleListOrder, required this.ruleEnum, this.validator});

  final int? ruleListOrder;
  final RuleEnum ruleEnum;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final provider = genericListNotifierProvider(ruleListOrder, ruleEnum);
    final list = ref.watch(provider);

    Future<void> addNewValue() async {
      final result = await ref
          .read(dialogNotifierProvider.notifier)
          .showSettingText(lable: t.pages.settings.routing.routeRule.genericList.addNew, validator: validator);
      if (result is String) ref.read(provider.notifier).add(result);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ruleEnum.present(t)),
        actions: [
          IconButton(
            onPressed: list.isEmpty
                ? null
                : () async {
                    final result = await ref
                        .read(dialogNotifierProvider.notifier)
                        .showConfirmation(
                          title: t.pages.settings.routing.routeRule.genericList.clearList,
                          message: t.pages.settings.routing.routeRule.genericList.clearListMsg,
                        );
                    if (result == true) ref.read(provider.notifier).reset();
                  },
            icon: const Icon(Icons.clear_all),
          ),
          const Gap(8),
        ],
      ),
      floatingActionButton: list.isNotEmpty
          ? FloatingActionButton(onPressed: addNewValue, child: const Icon(Icons.add_rounded))
          : FloatingActionButton.extended(
              onPressed: addNewValue,
              label: Text(t.pages.settings.routing.routeRule.genericList.addNew),
              icon: const Icon(Icons.add_rounded),
            ),
      body: ListView.builder(
        itemBuilder: (context, index) => GenericListTile(
          value: list[index],
          onRemove: () => ref.read(provider.notifier).remove(index),
          onUpdate: () async {
            final result = await ref
                .read(dialogNotifierProvider.notifier)
                .showSettingText(
                  lable: t.pages.settings.routing.routeRule.genericList.update,
                  value: '${list[index]}',
                  validator: validator,
                );
            if (result is String) ref.read(provider.notifier).update(index, result);
          },
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
      trailing: IconButton(onPressed: onRemove, icon: const Icon(Icons.remove)),
    );
  }
}
