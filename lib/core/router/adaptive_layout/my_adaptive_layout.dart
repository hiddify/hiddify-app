import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_glass.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });
  // managed by go router(Shell Route)
  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // focus switch management
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else {
          // focus node does not change => true.
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
            if (branchesScope.values.any((node) => node.hasFocus)) {
              navScopeNode.requestFocus();
            } else if (navScopeNode.hasFocus) {
              branchesScope[getNameOfBranch(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex)]
                  ?.requestFocus();
            }
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () {
        HardwareKeyboard.instance.removeHandler(handler);
      };
    }, [isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex]);
    final blizzard = BlizzardPresentation.isActive(context);
    return BlizzardPresentation(
      child: Material(
        child: Scaffold(
          body: isMobileBreakpoint
              ? navigationShell
              : Row(
                  children: [
                    FocusScope(
                      node: navScopeNode,
                      child: NavigationRail(
                        extended: Breakpoint(context).isDesktop(),
                        destinations: _navRailDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                        selectedIndex: navigationShell.currentIndex,
                        onDestinationSelected: (index) => _onTap(context, index),
                        trailing: Breakpoint(context).isDesktop()
                            ? const Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SizedBox(width: 220, child: SideBarStatsOverview()),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Expanded(child: navigationShell),
                  ],
                ),
          bottomNavigationBar: isMobileBreakpoint
              ? Builder(
                  builder: (dockContext) => FocusScope(
                    node: navScopeNode,
                    child: blizzard
                        ? _BlizzardDock(
                            actions: _actions(t, showProfilesAction, isMobileBreakpoint),
                            selectedIndex: navigationShell.currentIndex <= 1 ? navigationShell.currentIndex : 0,
                            onSelected: (index) => _onTap(context, index),
                          )
                        : NavigationBar(
                            selectedIndex: navigationShell.currentIndex <= 1 ? navigationShell.currentIndex : 0,
                            destinations: _navDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                            onDestinationSelected: (index) => _onTap(context, index),
                          ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // shell route action onTap
  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.power_settings_new_rounded, t.pages.home.title),
    if (showProfilesAction && !isMobileBreakpoint) ShellRouteAction(Icons.view_list_rounded, t.pages.profiles.title),
    ShellRouteAction(Icons.settings_rounded, t.pages.settings.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.description_rounded, t.pages.logs.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_rounded, t.pages.about.title),
  ];

  List<NavigationDestination> _navDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationDestination(icon: Icon(e.icon), label: e.title)).toList();
  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationRailDestination(icon: Icon(e.icon), label: Text(e.title))).toList();
}

class _BlizzardDock extends StatelessWidget {
  const _BlizzardDock({required this.actions, required this.selectedIndex, required this.onSelected});

  final List<ShellRouteAction> actions;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: SizedBox(
          key: const ValueKey('blizzard_bottom_dock'),
          width: BlizzardMetrics.dockWidth,
          height: BlizzardMetrics.dockHeight,
          child: BlizzardGlass(
            active: true,
            radius: BlizzardRadii.dock,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0) const SizedBox(width: 4),
                    _BlizzardDockTab(
                      key: ValueKey('blizzard_bottom_dock_tab_$index'),
                      action: actions[index],
                      icon: index == 0 ? Icons.home_rounded : actions[index].icon,
                      selected: index == selectedIndex,
                      reduceMotion: reduceMotion,
                      onTap: () => onSelected(index),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlizzardDockTab extends StatelessWidget {
  const _BlizzardDockTab({
    super.key,
    required this.action,
    required this.icon,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final ShellRouteAction action;
  final IconData icon;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? BlizzardPalette.accent : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: action.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BlizzardRadii.tab),
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
            width: BlizzardMetrics.dockTabWidth,
            height: BlizzardMetrics.dockTabHeight,
            decoration: BoxDecoration(
              color: selected ? BlizzardPalette.selected.withValues(alpha: 0.72) : Colors.transparent,
              borderRadius: BorderRadius.circular(BlizzardRadii.tab),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 2),
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
