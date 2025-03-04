import 'dart:convert';

import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/gen/proto/route_rule/route_rule.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protobuf/protobuf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rule_notifier.g.dart';

enum RuleEnum { listOrder, enabled, name, outbound, ruleSet, packageName, processName, processPath, network, portRange, sourcePortRange, protocol, ipCidr, sourceIpCidr, domain, domainSuffix, domainKeyword, domainRegex }

@riverpod
class RuleNotifier extends _$RuleNotifier {
  bool isEditMode = false;

  @override
  Rule build(int? listOrder) {
    if (listOrder == null) {
      return Rule(
        name: 'Rule Name',
        outbound: Outbound.direct,
        network: Network.all,
      );
    } else {
      isEditMode = true;
      return ref.read(rulesNotifierProvider).where((rule) => rule.listOrder == listOrder).first;
    }
  }

  void update<T>(RuleEnum key, T value) {
    final map = state.writeToJsonMap();
    map['${key.index + 1}'] = value is ProtobufEnum
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
  return ref.watch(RuleNotifierProvider(listOrder)) != ref.watch(rulesNotifierProvider.select((value) => value.where((rule) => rule.listOrder == listOrder))).first;
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
