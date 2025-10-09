import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) => Breakpoints.small.isActive(context);
}

class AdaptiveRootScaffold extends HookConsumerWidget with AppLogger {
  const AdaptiveRootScaffold(this.navigator, {super.key, this.navigationShell});

  final Widget navigator;
  final StatefulNavigationShell? navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final selectedIndex = getCurrentIndex(context);

    final destinations = [
      NavigationDestination(icon: const Icon(FluentIcons.power_20_filled), label: t.home.pageTitle),
      NavigationDestination(icon: const Icon(FluentIcons.filter_20_filled), label: t.proxies.pageTitle),
      NavigationDestination(icon: const Icon(FluentIcons.box_edit_20_filled), label: t.config.pageTitle),
      NavigationDestination(icon: const Icon(FluentIcons.settings_20_filled), label: t.settings.pageTitle),
      NavigationDestination(icon: const Icon(FluentIcons.document_text_20_filled), label: t.logs.pageTitle),
      NavigationDestination(icon: const Icon(FluentIcons.info_20_filled), label: t.about.pageTitle),
    ];

    loggy.debug("root build selectedIndex=$selectedIndex useMobileRouter=$useMobileRouter");
    return _CustomAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onSelectedIndexChange: (index) {
        RootScaffold.stateKey.currentState?.closeDrawer();
        final shell = navigationShell;
        if (shell != null) {
          loggy.debug("switch tab via shell index=$index");
          shell.goBranch(index);
        } else {
          loggy.debug("switch tab direct index=$index");
          switchTab(index, context);
        }
      },
      destinations: destinations,
      drawerDestinationRange: useMobileRouter ? (2, null) : (0, null),
      bottomDestinationRange: (0, 2),
      useBottomSheet: useMobileRouter,
      sidebarTrailing: const SideBarStatsOverview(),
      body: navigator,
    );
  }
}

class _CustomAdaptiveScaffold extends HookConsumerWidget with AppLogger {
  const _CustomAdaptiveScaffold({
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.destinations,
    required this.drawerDestinationRange,
    required this.bottomDestinationRange,
    this.useBottomSheet = false,
    this.sidebarTrailing,
    required this.body,
  });

  final int selectedIndex;
  final Function(int) onSelectedIndexChange;
  final List<NavigationDestination> destinations;
  final (int, int?) drawerDestinationRange;
  final (int, int?) bottomDestinationRange;
  final bool useBottomSheet;
  final Widget? sidebarTrailing;
  final Widget body;

  List<NavigationDestination> destinationsSlice((int, int?) range) => destinations.sublist(range.$1, range.$2);

  int? selectedWithOffset((int, int?) range) {
    final index = selectedIndex - range.$1;
    return index < 0 || (range.$2 != null && index > (range.$2! - 1)) ? null : index;
  }

  void selectWithOffset(int index, (int, int?) range) => onSelectedIndexChange(index + range.$1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    // thresholds aligned with Material guidance (approx)
    final isSmall = w < 600;
    final isMedium = w >= 600 && w < 840;
    final isLarge = w >= 840 && w < 1200;
    final isXl = w >= 1200;
    // keep extended only on very wide windows to avoid content overflow
    final isExtended = w >= 1400;
    loggy.debug("rail build w=${w.toStringAsFixed(0)} h=${size.height.toStringAsFixed(0)} brk[s=$isSmall,m=$isMedium,l=$isLarge,xl=$isXl] extended=$isExtended selected=$selectedIndex");
    final railDestinations = destinations
        .map((dest) => NavigationRailDestination(
              icon: dest.icon,
              label: Text(dest.label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ))
        .toList();
    final railWidth = isExtended ? 288.0 : 80.0;
    final railKey = GlobalKey();
    final rail = Material(
      key: railKey,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SizedBox(
        width: railWidth,
        child: NavigationRail(
          extended: isExtended,
          selectedIndex: selectedIndex,
          destinations: railDestinations,
          onDestinationSelected: onSelectedIndexChange,
          // trailing moved to overlay to avoid overflow
          labelType: isExtended ? null : NavigationRailLabelType.none,
          minWidth: railWidth,
          minExtendedWidth: railWidth,
        ),
      ),
    );

    return Scaffold(
      key: RootScaffold.stateKey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double dividerWidth = 2.0;
            final railPad = railWidth + dividerWidth; // rail + divider space
            loggy.debug("layout w=${constraints.maxWidth.toStringAsFixed(0)} pad=$railPad");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final box = railKey.currentContext?.findRenderObject() as RenderBox?;
              final rs = box?.size;
              loggy.debug("rail render size=${rs?.width.toStringAsFixed(0)}x${rs?.height.toStringAsFixed(0)} visible=${rs != null && rs.width > 0}");
            });
            final trailing = sidebarTrailing;
            return Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: railPad),
                  child: body,
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: railPad,
                  child: Row(children: [rail, const VerticalDivider(width: dividerWidth)]),
                ),
                if (trailing != null && isExtended)
                  Positioned(
                    left: 0,
                    bottom: 8,
                    width: railWidth,
                    child: SafeArea(
                      minimum: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: size.height * 0.4),
                        child: SingleChildScrollView(child: trailing),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
