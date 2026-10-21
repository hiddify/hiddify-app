import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hiddify/features/route_rules/widget/setting_checkbox.dart';
import 'package:hiddify/features/route_rules/widget/setting_divider.dart';
import 'package:hiddify/features/route_rules/widget/setting_generic_list.dart';
import 'package:hiddify/features/route_rules/widget/setting_radio.dart';
import 'package:hiddify/features/route_rules/widget/setting_text.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protobuf/protobuf.dart';
import 'package:recase/recase.dart';

class RulePage extends HookConsumerWidget {
  const RulePage({super.key, this.ruleListOrder});

  final int? ruleListOrder;

  String getTitle(Map<String, String> t, RuleEnum key) => t[key.name.snakeCase] ?? key.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final isRuleEdited = ref.watch(IsRuleEditedProvider(ruleListOrder));
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.routing.routeRule.rule.title),
        actions: [
          IconButton(
            onPressed: isRuleEdited
                ? () async {
                    await ref.read(ruleNotifierProvider(ruleListOrder).notifier).save();
                    if (context.mounted) context.pop();
                  }
                : null,
            icon: const Icon(Icons.check),
          ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SettingText(
              title: RuleEnum.name.present(t),
              value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.name)),
              setValue: (value) =>
                  ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<String>(RuleEnum.name, value),
            ),
            SettingRadio<Outbound>(
              title: RuleEnum.outbound.present(t),
              values: Outbound.values,
              value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.outbound)),
              setValue: (value) =>
                  ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<Outbound>(RuleEnum.outbound, value),
              defaultValue: Outbound.direct,
              t: t.pages.settings.routing.routeRule.rule.outbound,
            ),
            const SettingDivider(),
            SettingGenericList<String>(
              title: RuleEnum.ruleSet.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.ruleSets)),
              useEllipsis: true,
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.ruleSet.name},
              ),
            ),
            SettingDivider(title: t.pages.settings.routing.routeRule.rule.onlyTunMode),
            SettingGenericList<String>(
              title: RuleEnum.packageName.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.packageNames)),
              // other platforms can't list the installed apps, so they edit the names as text
              onTap: () => PlatformUtils.isAndroid
                  ? context.pushNamed('packageNames', pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new'})
                  : context.pushNamed(
                      'genericList',
                      pathParameters: {
                        'orderId': ruleListOrder?.toString() ?? 'new',
                        'ruleEnum': RuleEnum.packageName.name,
                      },
                    ),
              isPackageName: true,
              showPlatformWarning: !PlatformUtils.isAndroid,
            ),
            SettingGenericList<String>(
              title: RuleEnum.processName.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.processNames)),
              showPlatformWarning: !PlatformUtils.isDesktop,
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.processName.name},
              ),
            ),
            SettingGenericList<String>(
              title: RuleEnum.processPath.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.processPaths)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.processPath.name},
              ),
              showPlatformWarning: !PlatformUtils.isDesktop,
            ),
            const SettingDivider(),
            SettingRadio<Network>(
              title: RuleEnum.network.present(t),
              values: Network.values,
              value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.network)),
              setValue: (value) =>
                  ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<Network>(RuleEnum.network, value),
              defaultValue: Network.all,
              t: t.pages.settings.routing.routeRule.rule.network,
            ),
            SettingGenericList<String>(
              title: RuleEnum.portRange.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.portRanges)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.portRange.name},
              ),
            ),
            SettingGenericList<String>(
              title: RuleEnum.sourcePortRange.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourcePortRanges)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {
                  'orderId': ruleListOrder?.toString() ?? 'new',
                  'ruleEnum': RuleEnum.sourcePortRange.name,
                },
              ),
            ),
            SettingCheckbox(
              title: RuleEnum.protocol.present(t),
              values: Protocol.values,
              selectedValues: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.protocols)),
              setValue: (value) => ref
                  .read(ruleNotifierProvider(ruleListOrder).notifier)
                  .update<List<ProtobufEnum>>(RuleEnum.protocol, value),
              t: t.pages.settings.routing.routeRule.rule.protocol,
            ),
            const SettingDivider(),
            SettingGenericList<String>(
              title: RuleEnum.ipCidr.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.ipCidrs)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.ipCidr.name},
              ),
            ),
            SettingGenericList<String>(
              title: RuleEnum.sourceIpCidr.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourceIpCidrs)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.sourceIpCidr.name},
              ),
            ),
            const SettingDivider(),
            SettingGenericList<String>(
              title: RuleEnum.domain.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domains)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.domain.name},
              ),
            ),
            SettingGenericList<String>(
              title: RuleEnum.domainSuffix.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainSuffixes)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.domainSuffix.name},
              ),
            ),
            SettingGenericList<String>(
              title: RuleEnum.domainKeyword.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainKeywords)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {
                  'orderId': ruleListOrder?.toString() ?? 'new',
                  'ruleEnum': RuleEnum.domainKeyword.name,
                },
              ),
            ),
            SettingGenericList<String>(
              title: RuleEnum.domainRegex.present(t),
              values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainRegexes)),
              onTap: () => context.pushNamed(
                'genericList',
                pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new', 'ruleEnum': RuleEnum.domainRegex.name},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
