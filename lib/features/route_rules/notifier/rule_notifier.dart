import 'dart:convert';

import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protobuf/protobuf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rule_notifier.g.dart';

enum RuleEnum {
  listOrder,
  enabled,
  name,
  outbound,
  ruleSet,
  packageName,
  processName,
  processPath,
  network,
  portRange,
  sourcePortRange,
  protocol,
  ipCidr,
  sourceIpCidr,
  domain,
  domainSuffix,
  domainKeyword,
  domainRegex;

  int getIndex() => index + 1;

  String present(Translations t) => switch (this) {
    listOrder => this.name,
    enabled => this.name,
    name => t.pages.settings.routing.routeRule.rule.tileTitle['name']!,
    outbound => t.pages.settings.routing.routeRule.rule.tileTitle['outbound']!,
    ruleSet => t.pages.settings.routing.routeRule.rule.tileTitle['rule_set']!,
    packageName => t.pages.settings.routing.routeRule.rule.tileTitle['package_name']!,
    processName => t.pages.settings.routing.routeRule.rule.tileTitle['process_name']!,
    processPath => t.pages.settings.routing.routeRule.rule.tileTitle['process_path']!,
    network => t.pages.settings.routing.routeRule.rule.tileTitle['network']!,
    portRange => t.pages.settings.routing.routeRule.rule.tileTitle['port_range']!,
    sourcePortRange => t.pages.settings.routing.routeRule.rule.tileTitle['source_port_range']!,
    protocol => t.pages.settings.routing.routeRule.rule.tileTitle['protocol']!,
    ipCidr => t.pages.settings.routing.routeRule.rule.tileTitle['ip_cidr']!,
    sourceIpCidr => t.pages.settings.routing.routeRule.rule.tileTitle['source_ip_cidr']!,
    domain => t.pages.settings.routing.routeRule.rule.tileTitle['domain']!,
    domainSuffix => t.pages.settings.routing.routeRule.rule.tileTitle['domain_suffixe']!,
    domainKeyword => t.pages.settings.routing.routeRule.rule.tileTitle['domain_keyword']!,
    domainRegex => t.pages.settings.routing.routeRule.rule.tileTitle['domain_regex']!,
  };
}

@riverpod
class RuleNotifier extends _$RuleNotifier {
  bool isEditMode = false;

  @override
  Rule build(int? listOrder) {
    if (listOrder == null) {
      return Rule(name: 'Rule Name', outbound: Outbound.direct, network: Network.all);
    } else {
      isEditMode = true;
      return ref.read(rulesNotifierProvider).where((rule) => rule.listOrder == listOrder).first;
    }
  }

  void update<T>(RuleEnum key, T value) {
    final map = state.writeToJsonMap();
    map['${key.getIndex()}'] = value is ProtobufEnum
        ? '${value.value}'
        : value is List<ProtobufEnum>
        ? value.map((e) => '${e.value}').toList()
        : value;
    state = Rule.fromJson(jsonEncode(map));
  }

  void save() {
    assert(state.hasName() && state.hasOutbound());
    if (isEditMode) {
      assert(state.hasListOrder() && state.hasEnabled());
      ref.read(rulesNotifierProvider.notifier).updateRule(state);
    } else {
      ref.read(rulesNotifierProvider.notifier).addRule(state);
    }
  }
}

@riverpod
bool isRuleEdited(Ref ref, int? listOrder) {
  if (listOrder == null) return true;
  return ref.watch(RuleNotifierProvider(listOrder)) !=
      ref.watch(rulesNotifierProvider.select((value) => value.where((rule) => rule.listOrder == listOrder))).first;
}

@riverpod
class DialogCheckboxNotifier extends _$DialogCheckboxNotifier {
  @override
  List<ProtobufEnum> build(List<ProtobufEnum> selected) {
    return selected;
  }

  void update(ProtobufEnum value) {
    state = state.contains(value) ? state.where((element) => element != value).toList() : [...state, value];
  }
}
