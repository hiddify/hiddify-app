import 'package:flutter/material.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_glass.dart';

class BlizzardDock extends StatelessWidget {
  const BlizzardDock({
    super.key,
    required this.actions,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<ShellRouteAction> actions;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context);
    final textGrowth = (MediaQuery.textScalerOf(context).scale(12) - 12 * 1.3).clamp(0.0, double.infinity);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Center(
        heightFactor: 1,
        child: SizedBox(
          key: const ValueKey('blizzard_bottom_dock'),
          width: BlizzardMetrics.dockWidth,
          height: BlizzardMetrics.dockHeight + textGrowth,
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
                      onTap: () => onDestinationSelected(index),
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
          child: SizedBox(
            width: BlizzardMetrics.dockTabWidth,
            height:
                BlizzardMetrics.dockTabHeight +
                (MediaQuery.textScalerOf(context).scale(12) - 12 * 1.3).clamp(0.0, double.infinity),
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
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
      ),
    );
  }
}
