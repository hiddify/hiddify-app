import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/routing_rules/routing_rule_editor.dart';
import 'package:hiddify/singbox/model/singbox_rule.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RoutingRulesList extends HookConsumerWidget {
  const RoutingRulesList({
    super.key,
    required this.rules,
  });

  final List<SingboxRule> rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return ListView.builder(
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(_getRuleIcon(rule.outbound)),
            title: Text(_getRuleTitle(rule, t)),
            subtitle: Text(_getRuleSubtitle(rule)),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditRuleDialog(context, ref, rule, index);
                    break;
                  case 'delete':
                    _deleteRule(ref, index);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(t.general.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(t.general.delete),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getRuleIcon(RuleOutbound outbound) {
    switch (outbound) {
      case RuleOutbound.proxy:
        return Icons.vpn_key;
      case RuleOutbound.bypass:
        return Icons.direct_route;
      case RuleOutbound.block:
        return Icons.block;
    }
  }

  String _getRuleTitle(SingboxRule rule, Translations t) {
    if (rule.domains != null && rule.domains!.isNotEmpty) {
      return '${t.config.domains}: ${rule.domains}';
    } else if (rule.ip != null && rule.ip!.isNotEmpty) {
      return '${t.config.ip}: ${rule.ip}';
    } else if (rule.port != null && rule.port!.isNotEmpty) {
      return '${t.config.port}: ${rule.port}';
    } else if (rule.protocol != null && rule.protocol!.isNotEmpty) {
      return '${t.config.protocol}: ${rule.protocol}';
    }
    return t.config.customRule;
  }

  String _getRuleSubtitle(SingboxRule rule) {
    final outboundText = switch (rule.outbound) {
      RuleOutbound.proxy => 'Proxy',
      RuleOutbound.bypass => 'Direct',
      RuleOutbound.block => 'Block',
    };
    
    final networkText = switch (rule.network) {
      RuleNetwork.tcpAndUdp => 'TCP/UDP',
      RuleNetwork.tcp => 'TCP',
      RuleNetwork.udp => 'UDP',
    };

    return '$outboundText • $networkText';
  }

  void _showEditRuleDialog(BuildContext context, WidgetRef ref, SingboxRule rule, int index) {
    showDialog(
      context: context,
      builder: (context) => RoutingRuleEditor(
        initialRule: rule,
        onSave: (updatedRule) {
          final currentRules = ref.read(ConfigOptions.customRoutingRules);
          final newRules = List<SingboxRule>.from(currentRules);
          newRules[index] = updatedRule;
          ref.read(ConfigOptions.customRoutingRules.notifier).update(newRules);
        },
      ),
    );
  }

  void _deleteRule(WidgetRef ref, int index) {
    final currentRules = ref.read(ConfigOptions.customRoutingRules);
    final newRules = List<SingboxRule>.from(currentRules);
    newRules.removeAt(index);
    ref.read(ConfigOptions.customRoutingRules.notifier).update(newRules);
  }
}

