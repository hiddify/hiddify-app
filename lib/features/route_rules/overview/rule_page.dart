import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hiddify/features/route_rules/overview/android_apps_page.dart';
import 'package:hiddify/features/route_rules/overview/generic_list_page.dart';
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
    // TODO(): PopScope logic must be transferred to onExit method of go_router
    return PopScope(
      canPop: !isRuleEdited,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isRuleEdited) {
          final shouldSave = await ref
              .read(dialogNotifierProvider.notifier)
              .showSave(
                title: t.pages.settings.routing.routeRule.rule.ruleChanged,
                description: t.pages.settings.routing.routeRule.rule.ruleChangedMsg,
              );
          if (shouldSave == null) return;
          if (shouldSave == true) {
            ref.read(ruleNotifierProvider(ruleListOrder).notifier).save();
            if (context.mounted) Navigator.of(context).pop();
          } else {
            if (context.mounted) Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.pages.settings.routing.routeRule.rule.title),
          actions: [
            IconButton(
              onPressed: isRuleEdited
                  ? () {
                      ref.read(ruleNotifierProvider(ruleListOrder).notifier).save();
                      Navigator.of(context).pop();
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.ruleSet,
                      validator: (value) {
                        if (isUrl('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validUrl;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
                useEllipsis: true,
              ),
              SettingDivider(title: t.pages.settings.routing.routeRule.rule.onlyTunMode),
              SettingGenericList<String>(
                title: RuleEnum.packageName.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.packageNames)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AndroidAppsPage(ruleListOrder: ruleListOrder),
                    fullscreenDialog: true,
                  ),
                ),
                isPackageName: true,
                showPlatformWarning: !PlatformUtils.isAndroid,
              ),
              SettingGenericList<String>(
                title: RuleEnum.processName.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.processNames)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.processName,
                      validator: (value) {
                        if (isProcessName('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validProcessName;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
                showPlatformWarning: !PlatformUtils.isDesktop,
              ),
              SettingGenericList<String>(
                title: RuleEnum.processPath.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.processPaths)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.processPath,
                      validator: (value) {
                        if (isProcessPath('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validProcessPath;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.portRange,
                      validator: (value) {
                        if (isPortOrPortRange('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validPortRange;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: RuleEnum.sourcePortRange.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourcePortRanges)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.sourcePortRange,
                      validator: (value) {
                        if (isPortOrPortRange('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validPortRange;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.ipCidr,
                      validator: (value) {
                        if (isIpCidr('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validIpCidr;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: RuleEnum.sourceIpCidr.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourceIpCidrs)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.sourceIpCidr,
                      validator: (value) {
                        if (isIpCidr('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validIpCidr;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              const SettingDivider(),
              SettingGenericList<String>(
                title: RuleEnum.domain.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domains)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.domain,
                      validator: (value) {
                        if (isDomain('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validDomain;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: RuleEnum.domainSuffix.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainSuffixes)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.domainSuffix,
                      validator: (value) {
                        if (isDomainSuffix('$value')) return null;
                        return t.pages.settings.routing.routeRule.rule.validDomainSuffix;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: RuleEnum.domainKeyword.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainKeywords)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        GenericListPage(ruleListOrder: ruleListOrder, ruleEnum: RuleEnum.domainKeyword),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: RuleEnum.domainRegex.present(t),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainRegexes)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(ruleListOrder: ruleListOrder, ruleEnum: RuleEnum.domainRegex),
                    fullscreenDialog: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
