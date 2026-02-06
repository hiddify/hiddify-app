import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/adaptive_scaffold.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/routing_rules/routing_rule_editor.dart';
import 'package:hiddify/features/config_option/routing_rules/routing_rules_list.dart';
import 'package:hiddify/singbox/model/singbox_rule.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RoutingRulesPage extends HookConsumerWidget {
  const RoutingRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final customRules = ref.watch(ConfigOptions.customRoutingRules);

    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(t.config.customRoutingRules),
        actions: [
          IconButton(
            onPressed: () {
              _showAddRuleDialog(context, ref);
            },
            icon: const Icon(Icons.add),
            tooltip: t.general.add,
          ),
        ],
      ),
      body: customRules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.config.noCustomRules,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.config.addCustomRuleHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RoutingRulesList(rules: customRules),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => RoutingRuleEditor(
        onSave: (rule) {
          final currentRules = ref.read(ConfigOptions.customRoutingRules);
          ref.read(ConfigOptions.customRoutingRules.notifier).update([
            ...currentRules,
            rule,
          ]);
        },
      ),
    );
  }
}

