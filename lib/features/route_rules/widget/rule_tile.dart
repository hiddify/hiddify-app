import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/features/route_rules/overview/rule_page.dart';
import 'package:hiddify/features/route_rules/widget/setting_detail_chips.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hiddify/utils/platform_utils.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protobuf/protobuf.dart';

class RuleTile extends HookConsumerWidget {
  const RuleTile({super.key, required this.index, required this.rule});

  final Rule rule;
  final int index;

  Map detailChipsValue() {
    final map = rule.toProto3Json()! as Map<String, dynamic>;
    map.removeWhere((key, value) => ['list_order', 'enabled', 'name', 'outbound'].contains(key));
    map.updateAll(
      (key, value) => value is List
          ? value.length
          : value is ProtobufEnum
          ? value.name
          : value,
    );
    return map;
  }

  Map<String, String> mergeTranslation(List<Map<String, String>> translations) {
    return Map.fromEntries(translations.expand((map) => map.entries).toList());
  }

  Future handleDelete(BuildContext context, WidgetRef ref) async {
    final t = ref.watch(translationsProvider).requireValue;
    final result = await ref
        .read(dialogNotifierProvider.notifier)
        .showConfirmation(
          title: t.dialogs.confirmation.routeRule.delete.title,
          message: t.dialogs.confirmation.routeRule.delete.msg(rulename: rule.name),
          positiveBtnTxt: t.common.delete,
        );
    if (result == true) {
      await ref.read(rulesNotifierProvider.notifier).deleteRule(rule.listOrder);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final scrollController = useScrollController();
    ref.listen(rulesNotifierProvider, (_, _) {
      if (scrollController.offset > 0) scrollController.jumpTo(0);
    });
    return Material(
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => RulePage(ruleListOrder: rule.listOrder))),
        onLongPress: () async => await handleDelete(context, ref),
        onSecondaryTapUp: PlatformUtils.isDesktop
            ? (details) {
                final offset = details.globalPosition;
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx, offset.dy),
                  items: [
                    PopupMenuItem(
                      child: Text(t.pages.settings.routing.routeRule.deleteRule),
                      onTap: () async => await handleDelete(context, ref),
                    ),
                  ],
                );
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                t.pages.settings.routing.routeRule.rule.outbound[rule.outbound.name] ?? rule.outbound.name,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              subtitle: Text(rule.name, style: Theme.of(context).textTheme.bodyLarge),
              leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle_rounded)),
              trailing: Switch(
                value: rule.enabled,
                onChanged: (value) async =>
                    await ref.read(rulesNotifierProvider.notifier).updateEnabled(value, rule.listOrder),
              ),
            ),
            SettingDetailChips<MapEntry>(
              values: detailChipsValue().entries.toList(),
              scrollController: scrollController,
              t: mergeTranslation([
                t.pages.settings.routing.routeRule.rule.tileTitle,
                t.pages.settings.routing.routeRule.rule.network,
                t.pages.settings.routing.routeRule.rule.outbound,
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
