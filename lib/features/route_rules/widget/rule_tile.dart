import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/features/route_rules/widget/setting_detail_chips.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
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
    final theme = Theme.of(context);
    final builtin = BuiltinRule.of(rule);
    final region = ref.watch(ConfigOptions.region);
    final scrollController = useScrollController();
    ref.listen(rulesNotifierProvider, (_, _) {
      if (scrollController.offset > 0) scrollController.jumpTo(0);
    });
    return Material(
      child: InkWell(
        // a built-in rule can only be switched and moved
        onTap: builtin != null
            ? null
            : () => context.goNamed('rule', pathParameters: {'orderId': rule.listOrder.toString()}),
        onLongPress: builtin != null ? null : () async => await handleDelete(context, ref),
        onSecondaryTapUp: builtin == null && PlatformUtils.isDesktop
            ? (details) {
                final offset = details.globalPosition;
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx, offset.dy),
                  items: [
                    PopupMenuItem(
                      child: Text(t.pages.settings.routing.routeRule.delete),
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
                style: theme.textTheme.labelMedium,
              ),
              // one line: a long name ends in "…", and the built-in tag always shows whole after it
              subtitle: Row(
                children: [
                  Flexible(
                    child: Text(
                      builtin?.present(t, region) ?? rule.name,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (builtin != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.lock_outline_rounded, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      t.pages.settings.routing.builtinRules.tag,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ],
              ),
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
