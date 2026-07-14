import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/core/widget/nova_grouped_scaffold.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/features/route_rules/widget/rule_tile.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RoutingOptionsPage extends HookConsumerWidget {
  const RoutingOptionsPage({super.key, required this.routeRule});

  // Import route rule from deep link
  final String? routeRule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final perAppProxy = ref.watch(Preferences.perAppProxyMode).enabled;
    final rules = ref.watch(rulesNotifierProvider);
    final showGeneralOptions = ref.watch(Preferences.showRouteGeneralOptions);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
      initialValue: showGeneralOptions ? 1.0 : 0.0,
    );

    useEffect(() {
      if (showGeneralOptions) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [showGeneralOptions]);

    final menuItems = <PopupMenuEntry>[
      PopupMenuItem(
        onTap: ref.read(rulesNotifierProvider.notifier).importRulesFromClipboard,
        child: Text(t.pages.settings.routing.routeRule.options.import.clipboard),
      ),
      PopupMenuItem(
        onTap: ref.read(rulesNotifierProvider.notifier).importRulesFromJsonFile,
        child: Text(t.pages.settings.routing.routeRule.options.import.file),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        onTap: () async => await ref.read(rulesNotifierProvider.notifier).exportJsonToClipboard(),
        child: Text(t.pages.settings.routing.routeRule.options.export.clipboard),
      ),
      PopupMenuItem(
        onTap: () async => await ref.read(rulesNotifierProvider.notifier).saveRulesAsJsonFile(),
        child: Text(t.pages.settings.routing.routeRule.options.export.file),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        onTap: ref.read(rulesNotifierProvider.notifier).resetRules,
        child: Text(t.pages.settings.routing.routeRule.options.reset),
      ),
    ];

    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (routeRule != null && context.mounted) {
          await ref.read(rulesNotifierProvider.notifier).importRulesFromDeepLink(routeRule!);
        }
      });
    });
    return NovaGroupedScaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.routing.title),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) => rules.isEmpty ? menuItems.getRange(0, 2).toList() : menuItems,
          ),
          const Gap(8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (rules.isNotEmpty)
                  Positioned.fill(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 56 + 16 + 16),
                      buildDefaultDragHandles: false,
                      onReorder: ref.read(rulesNotifierProvider.notifier).reorder,
                      itemBuilder: (context, index) => RuleTile(key: Key('$index'), index: index, rule: rules[index]),
                      itemCount: rules.length,
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        t.pages.settings.routing.routeRule.empty,
                        style: theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                _ExpandableFab(
                  children: [
                    _FabMenuItem(
                      icon: Icons.rule_rounded,
                      label: t.pages.settings.routing.routeRule.create,
                      onTap: () => context.goNamed('rule', pathParameters: {'orderId': 'new'}),
                    ),
                    _FabMenuItem(
                      icon: Icons.view_list_rounded,
                      label: t.pages.settings.routing.predefinedRules.title,
                      onTap: ref.read(bottomSheetsNotifierProvider.notifier).showPredefinedRules,
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Material(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          onTap: () =>
                              ref.read(Preferences.showRouteGeneralOptions.notifier).update(!showGeneralOptions),
                          child: RoutingTapTarget(
                            key: const ValueKey('routing_general_options_target'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Gap(16),
                                Text(t.pages.settings.routing.generalOptions.title),
                                const Gap(4),
                                Icon(
                                  showGeneralOptions ? Icons.arrow_drop_down_rounded : Icons.arrow_drop_up_rounded,
                                  size: 16,
                                ),
                                const Gap(8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
            axisAlignment: -1,
            child: Column(
              children: [
                Divider(height: 4, thickness: 4, color: theme.colorScheme.primaryContainer),
                ChoicePreferenceWidget(
                  selected: ref.watch(ConfigOptions.region),
                  preferences: ref.watch(ConfigOptions.region.notifier),
                  choices: Region.values,
                  title: t.pages.settings.routing.generalOptions.region,
                  showFlag: true,
                  icon: Icons.place_rounded,
                  presentChoice: (value) => value.present(t),
                  onChanged: (val) async {
                    await ref.read(ConfigOptions.directDnsAddress.notifier).reset();
                    final autoRegion = ref.read(Preferences.autoAppsSelectionRegion);
                    final mode = ref.read(Preferences.perAppProxyMode).toAppProxy();
                    if (autoRegion != val &&
                        autoRegion != null &&
                        val != Region.other &&
                        mode != null &&
                        PlatformUtils.isAndroid) {
                      await ref
                          .read(dialogNotifierProvider.notifier)
                          .showOk(
                            t.pages.settings.routing.generalOptions.perAppProxy.autoSelection.dialog.title,
                            t.pages.settings.routing.generalOptions.perAppProxy.autoSelection.dialog.msg(
                              region: val.name,
                            ),
                          );
                      await ref.read(PerAppProxyProvider(mode).notifier).clearAutoSelected();
                    }
                  },
                ),
                if (PlatformUtils.isAndroid)
                  ListTile(
                    title: Text(t.pages.settings.routing.generalOptions.perAppProxy.title),
                    leading: const Icon(Icons.apps_rounded),
                    trailing: Switch(
                      value: perAppProxy,
                      onChanged: (value) async {
                        final newMode = perAppProxy ? PerAppProxyMode.off : PerAppProxyMode.exclude;
                        await ref.read(Preferences.perAppProxyMode.notifier).update(newMode);
                        if (!perAppProxy && context.mounted) context.goNamed('perAppProxy');
                      },
                    ),
                    onTap: () async {
                      if (!perAppProxy) {
                        await ref.read(Preferences.perAppProxyMode.notifier).update(PerAppProxyMode.exclude);
                      }
                      if (context.mounted) context.goNamed('perAppProxy');
                    },
                  ),
                ChoicePreferenceWidget(
                  title: t.pages.settings.routing.generalOptions.balancerStrategy.title,
                  icon: Icons.balance_rounded,
                  selected: ref.watch(ConfigOptions.balancerStrategy),
                  preferences: ref.watch(ConfigOptions.balancerStrategy.notifier),
                  choices: BalancerStrategy.values,
                  presentChoice: (value) => value.present(t),
                ),
                SwitchListTile.adaptive(
                  title: Text(t.pages.settings.routing.generalOptions.resolveDestination),
                  secondary: const Icon(Icons.find_replace_rounded),
                  value: ref.watch(ConfigOptions.resolveDestination),
                  onChanged: ref.read(ConfigOptions.resolveDestination.notifier).update,
                ),
                ChoicePreferenceWidget(
                  selected: ref.watch(ConfigOptions.ipv6Mode),
                  preferences: ref.watch(ConfigOptions.ipv6Mode.notifier),
                  choices: IPv6Mode.values,
                  title: t.pages.settings.routing.generalOptions.ipv6Route,
                  icon: Icons.looks_6_rounded,
                  presentChoice: (value) => value.present(t),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FabMenuItem {
  const _FabMenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ExpandableFab extends StatefulWidget {
  // ignore: unused_element_parameter
  const _ExpandableFab({this.isExtended = false, this.extendedLabel = '', required this.children});

  final bool isExtended;
  final String extendedLabel;
  final List<_FabMenuItem> children;

  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Positioned.fill(
      child: Stack(
        alignment: isRtl ? AlignmentDirectional.bottomStart : AlignmentDirectional.bottomEnd,
        clipBehavior: Clip.none,
        children: [
          // Scrim
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) =>
                      ColoredBox(color: Colors.black.withValues(alpha: 0.50 * _controller.value)),
                ),
              ),
            ),
          // Mini FABs
          ..._buildMenuItems(theme, isRtl),
          // Main FAB
          Positioned(
            bottom: 16,
            right: isRtl ? null : 16,
            left: isRtl ? 16 : null,
            child: widget.isExtended
                ? FloatingActionButton.extended(
                    onPressed: _toggle,
                    label: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) =>
                          Text(_isOpen ? '' : widget.extendedLabel, maxLines: 1, overflow: TextOverflow.clip),
                    ),
                    icon: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Transform.rotate(
                        angle: _controller.value * 0.75 * 3.14159,
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  )
                : FloatingActionButton(
                    onPressed: _toggle,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Transform.rotate(
                        angle: _controller.value * 0.75 * 3.14159,
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(ThemeData theme, bool isRtl) {
    final items = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      final child = widget.children[i];
      final reverseIndex = widget.children.length - 1 - i;
      final intervalStart = reverseIndex * 0.1;
      final intervalEnd = (intervalStart + 0.6).clamp(0.0, 1.0);

      final animation = CurvedAnimation(
        parent: _controller,
        curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
      );

      items.add(
        Positioned(
          bottom: 16 + 56 + 12 + (i * (44 + 12)),
          right: isRtl ? null : 16 + 4,
          left: isRtl ? 16 + 4 : null,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Opacity(
                opacity: animation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - animation.value)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isRtl) _buildLabel(theme, child.label, animation),
                      if (!isRtl) const Gap(12),
                      RoutingTapTarget(
                        key: ValueKey('routing_fab_menu_target_$i'),
                        width: 48,
                        child: Material(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 3,
                          shadowColor: theme.colorScheme.shadow,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _close();
                              child.onTap();
                            },
                            child: Icon(child.icon, color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ),
                      if (isRtl) const Gap(12),
                      if (isRtl) _buildLabel(theme, child.label, animation),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return items;
  }

  Widget _buildLabel(ThemeData theme, String label, Animation<double> animation) {
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface)),
      ),
    );
  }
}

class RoutingTapTarget extends StatelessWidget {
  const RoutingTapTarget({super.key, this.width, required this.child});

  final double? width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: NovaDockTokens.minimumTarget,
        minHeight: NovaDockTokens.minimumTarget,
      ),
      child: width == null ? child : SizedBox(width: width, child: child),
    );
  }
}
