import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
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
    // a built-in rule is shown as it is: its content comes from the app, so nothing here can be changed
    final readOnly = BuiltinRule.of(ref.watch(ruleNotifierProvider(ruleListOrder))) != null;
    // a tap on a read-only rule shakes a red "cannot be changed" notice in under the bar
    final locked = useState(false);
    final shakes = useState(0);
    void lock() {
      locked.value = true;
      shakes.value++;
    }

    useEffect(() {
      if (!locked.value) return null;
      final hide = Timer(const Duration(milliseconds: 2500), () => locked.value = false);
      return hide.cancel;
    }, [locked.value, shakes.value]);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          readOnly ? t.pages.settings.routing.builtinRules.tag : t.pages.settings.routing.routeRule.rule.title,
        ),
        actions: [
          if (readOnly)
            TextButton.icon(
              onPressed: () async {
                final order = await ref.read(rulesNotifierProvider.notifier).duplicateRule(ruleListOrder!);
                if (!context.mounted) return;
                ref
                    .read(inAppNotificationControllerProvider)
                    .showSuccessToast(t.pages.settings.routing.routeRule.duplicated);
                context.pushReplacementNamed('rule', pathParameters: {'orderId': order.toString()});
              },
              icon: const Icon(Icons.copy_rounded),
              label: Text(t.pages.settings.routing.routeRule.duplicate),
            ),
          if (!readOnly)
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
      body: Column(
        children: [
          if (readOnly)
            _LockedNotice(
              visible: locked.value,
              shake: shakes.value,
              text: t.pages.settings.routing.routeRule.rule.builtinReadOnly,
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _Guarded(
                    locked: readOnly,
                    onLockedTap: lock,
                    child: SettingText(
                      title: RuleEnum.name.present(t),
                      value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.name)),
                      setValue: (value) =>
                          ref.read(ruleNotifierProvider(ruleListOrder).notifier).update<String>(RuleEnum.name, value),
                    ),
                  ),
                  _Guarded(
                    locked: readOnly,
                    onLockedTap: lock,
                    child: SettingRadio<Outbound>(
                      title: RuleEnum.outbound.present(t),
                      values: Outbound.values,
                      value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.outbound)),
                      setValue: (value) => ref
                          .read(ruleNotifierProvider(ruleListOrder).notifier)
                          .update<Outbound>(RuleEnum.outbound, value),
                      defaultValue: Outbound.direct,
                      t: t.pages.settings.routing.routeRule.rule.outbound,
                    ),
                  ),
                  const SettingDivider(),
                  SettingGenericList<String>(
                    title: RuleEnum.ruleSet.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.ruleSets)),
                    expandable: true,
                    useEllipsis: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.ruleSet.name,
                            },
                          ),
                  ),
                  SettingDivider(title: t.pages.settings.routing.routeRule.rule.onlyTunMode),
                  SettingGenericList<String>(
                    title: RuleEnum.packageName.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.packageNames)),
                    expandable: true,
                    // other platforms can't list the installed apps, so they edit the names as text
                    onTap: readOnly
                        ? null
                        : () => PlatformUtils.isAndroid
                              ? context.pushNamed(
                                  'packageNames',
                                  pathParameters: {'orderId': ruleListOrder?.toString() ?? 'new'},
                                )
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
                    expandable: true,
                    showPlatformWarning: !PlatformUtils.isDesktop,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.processName.name,
                            },
                          ),
                  ),
                  SettingGenericList<String>(
                    title: RuleEnum.processPath.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.processPaths)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.processPath.name,
                            },
                          ),
                    showPlatformWarning: !PlatformUtils.isDesktop,
                  ),
                  const SettingDivider(),
                  _Guarded(
                    locked: readOnly,
                    onLockedTap: lock,
                    child: SettingRadio<Network>(
                      title: RuleEnum.network.present(t),
                      values: Network.values,
                      value: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.network)),
                      setValue: (value) => ref
                          .read(ruleNotifierProvider(ruleListOrder).notifier)
                          .update<Network>(RuleEnum.network, value),
                      defaultValue: Network.all,
                      t: t.pages.settings.routing.routeRule.rule.network,
                    ),
                  ),
                  SettingGenericList<String>(
                    title: RuleEnum.portRange.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.portRanges)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.portRange.name,
                            },
                          ),
                  ),
                  SettingGenericList<String>(
                    title: RuleEnum.sourcePortRange.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourcePortRanges)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.sourcePortRange.name,
                            },
                          ),
                  ),
                  _Guarded(
                    locked: readOnly,
                    onLockedTap: lock,
                    child: SettingCheckbox(
                      title: RuleEnum.protocol.present(t),
                      values: Protocol.values,
                      selectedValues: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.protocols)),
                      setValue: (value) => ref
                          .read(ruleNotifierProvider(ruleListOrder).notifier)
                          .update<List<ProtobufEnum>>(RuleEnum.protocol, value),
                      t: t.pages.settings.routing.routeRule.rule.protocol,
                    ),
                  ),
                  const SettingDivider(),
                  SettingGenericList<String>(
                    title: RuleEnum.ipCidr.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.ipCidrs)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.ipCidr.name,
                            },
                          ),
                  ),
                  SettingGenericList<String>(
                    title: RuleEnum.sourceIpCidr.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.sourceIpCidrs)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.sourceIpCidr.name,
                            },
                          ),
                  ),
                  const SettingDivider(),
                  SettingGenericList<String>(
                    title: RuleEnum.domain.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domains)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.domain.name,
                            },
                          ),
                  ),
                  SettingGenericList<String>(
                    title: RuleEnum.domainSuffix.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainSuffixes)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.domainSuffix.name,
                            },
                          ),
                  ),
                  SettingGenericList<String>(
                    title: RuleEnum.domainKeyword.present(t),
                    values: ref.watch(ruleNotifierProvider(ruleListOrder).select((value) => value.domainKeywords)),
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
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
                    expandable: true,
                    onTap: readOnly
                        ? null
                        : () => context.pushNamed(
                            'genericList',
                            pathParameters: {
                              'orderId': ruleListOrder?.toString() ?? 'new',
                              'ruleEnum': RuleEnum.domainRegex.name,
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The red notice that a built-in rule cannot be changed: slides in and shakes on each tap, then fades.
class _LockedNotice extends HookWidget {
  const _LockedNotice({required this.visible, required this.shake, required this.text});

  final bool visible;
  final int shake;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = useAnimationController(duration: const Duration(milliseconds: 400));
    useEffect(() {
      if (visible) controller.forward(from: 0);
      return null;
    }, [shake, visible]);
    final offset = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
    );
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: visible
            ? Transform.translate(
                offset: Offset(offset, 0),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 18, color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Guarded extends StatelessWidget {
  const _Guarded({required this.locked, required this.onLockedTap, required this.child});

  final bool locked;
  final VoidCallback onLockedTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onLockedTap,
      child: AbsorbPointer(child: child),
    );
  }
}
