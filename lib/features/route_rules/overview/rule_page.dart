import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
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
    final tRule = t.settings.routeRule.rule;
    final tTileTitle = tRule.tileTitle;
    final isRuleEdited = ref.watch(IsRuleEditedProvider(ruleListOrder));

    return PopScope(
      canPop: !isRuleEdited,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isRuleEdited) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(tRule.ruleChanged),
              content: ConstrainedBox(
                constraints: AlertDialogConst.boxConstraints,
                child: Text(tRule.ruleChangedMsg),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(tRule.discard),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(tRule.save),
                ),
              ],
            ),
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
          title: Text(t.settings.routeRule.rule.pageTitle),
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
                title: getTitle(tTileTitle, RuleEnum.name),
                value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.name)),
                setValue: (value) => ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<String>(RuleEnum.name, value),
              ),
              SettingRadio<Outbound>(
                title: getTitle(tTileTitle, RuleEnum.outbound),
                values: Outbound.values,
                value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.outbound)),
                setValue: (value) => ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<Outbound>(RuleEnum.outbound, value),
                defaultValue: Outbound.direct,
                t: tRule.outbound,
              ),
              const SettingDivider(),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.ruleSet),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.ruleSets)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.ruleSet,
                      validator: (value) {
                        if (isUrl('$value')) return null;
                        return tRule.validUrl;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
                useEllipsis: true,
              ),
              SettingDivider(title: tRule.onlyTunMode),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.packageName),
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
                title: getTitle(tTileTitle, RuleEnum.processName),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.processNames)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.processName,
                      validator: (value) {
                        if (isProcessName('$value')) return null;
                        return tRule.validProcessName;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
                showPlatformWarning: !PlatformUtils.isDesktop,
              ),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.processPath),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.processPaths)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.processPath,
                      validator: (value) {
                        if (isProcessPath('$value')) return null;
                        return tRule.validProcessPath;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
                showPlatformWarning: !PlatformUtils.isDesktop,
              ),
              const SettingDivider(),
              SettingRadio<Network>(
                title: getTitle(tTileTitle, RuleEnum.network),
                values: Network.values,
                value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.network)),
                setValue: (value) => ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<Network>(RuleEnum.network, value),
                defaultValue: Network.all,
                t: tRule.network,
              ),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.portRange),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.portRanges)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.portRange,
                      validator: (value) {
                        if (isPortOrPortRange('$value')) return null;
                        return tRule.validPortRange;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.sourcePortRange),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourcePortRanges)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.sourcePortRange,
                      validator: (value) {
                        if (isPortOrPortRange('$value')) return null;
                        return tRule.validPortRange;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingCheckbox(
                title: getTitle(tTileTitle, RuleEnum.protocol),
                values: Protocol.values,
                selectedValues: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.protocols)),
                setValue: (value) => ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<List<ProtobufEnum>>(RuleEnum.protocol, value),
                t: tRule.protocol,
              ),
              const SettingDivider(),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.ipCidr),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.ipCidrs)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.ipCidr,
                      validator: (value) {
                        if (isIpCidr('$value')) return null;
                        return tRule.validIpCidr;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.sourceIpCidr),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourceIpCidrs)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.sourceIpCidr,
                      validator: (value) {
                        if (isIpCidr('$value')) return null;
                        return tRule.validIpCidr;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              const SettingDivider(),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.domain),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domains)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.domain,
                      validator: (value) {
                        if (isDomain('$value')) return null;
                        return tRule.validDomain;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.domainSuffix),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainSuffixes)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(
                      ruleListOrder: ruleListOrder,
                      ruleEnum: RuleEnum.domainSuffix,
                      validator: (value) {
                        if (isDomainSuffix('$value')) return null;
                        return tRule.validDomainSuffix;
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.domainKeyword),
                values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainKeywords)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenericListPage(ruleListOrder: ruleListOrder, ruleEnum: RuleEnum.domainKeyword),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              SettingGenericList<String>(
                title: getTitle(tTileTitle, RuleEnum.domainRegex),
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
