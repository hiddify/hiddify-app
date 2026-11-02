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
    Future<void> handleDuplicate() async {
      final order = await ref.read(rulesNotifierProvider.notifier).duplicateRule(rule.listOrder);
      if (context.mounted) context.goNamed('rule', pathParameters: {'orderId': order.toString()});
    }

    void showActions(Offset offset) => showMenu(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx, offset.dy),
      items: [
        PopupMenuItem(
          onTap: handleDuplicate,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.copy_rounded),
            title: Text(t.pages.settings.routing.routeRule.duplicate),
          ),
        ),
        // a built-in rule stays: it can be duplicated, not deleted
        if (builtin == null)
          PopupMenuItem(
            onTap: () async => await handleDelete(context, ref),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(t.pages.settings.routing.routeRule.delete),
            ),
          ),
      ],
    );

    return Material(
      child: InkWell(
        // a built-in rule opens read-only: it can only be switched and moved
        onTap: () => context.goNamed('rule', pathParameters: {'orderId': rule.listOrder.toString()}),
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox?;
          final origin = box?.localToGlobal(box.size.center(Offset.zero)) ?? Offset.zero;
          showActions(origin);
        },
        onSecondaryTapUp: PlatformUtils.isDesktop ? (details) => showActions(details.globalPosition) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              // the outbound in its own colour, so direct, proxy and block tell apart at a glance
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_outboundIcon(rule.outbound), size: 14, color: _outboundColor(rule.outbound, theme)),
                  const SizedBox(width: 4),
                  Text(
                    t.pages.settings.routing.routeRule.rule.outbound[rule.outbound.name] ?? rule.outbound.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _outboundColor(rule.outbound, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                builtin?.present(t, region) ?? rule.name,
                style: theme.textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle_rounded)),
                  // a built-in rule: switch and move it, nothing else
                  if (builtin != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.lock_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ],
              ),
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

IconData _outboundIcon(Outbound outbound) => switch (outbound) {
  Outbound.block => Icons.block_rounded,
  Outbound.proxy => Icons.vpn_lock_rounded,
  _ => Icons.arrow_outward_rounded,
};

Color _outboundColor(Outbound outbound, ThemeData theme) => switch (outbound) {
  Outbound.block => theme.colorScheme.error,
  Outbound.proxy => theme.colorScheme.primary,
  _ => Colors.green.shade700,
};
