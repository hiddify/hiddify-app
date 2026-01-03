import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) =>
      Breakpoints.small.isActive(context);
}

class AdaptiveRootScaffold extends HookConsumerWidget {
  const AdaptiveRootScaffold(this.navigator, {super.key});

  final Widget navigator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final selectedIndex = getCurrentIndex(context);

    final destinations = [
      NavigationDestination(
        icon: const Icon(FluentIcons.power_20_filled),
        label: t.home.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.filter_20_filled),
        label: t.proxies.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.box_edit_20_filled),
        label: t.config.pageTitle,
      ),
      // Settings hidden for Go-Bull
      // NavigationDestination(
      //   icon: const Icon(FluentIcons.settings_20_filled),
      //   label: t.settings.pageTitle,
      // ),
      NavigationDestination(
        icon: const Icon(FluentIcons.document_text_20_filled),
        label: t.logs.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.info_20_filled),
        label: t.about.pageTitle,
      ),
    ];

    return _CustomAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onSelectedIndexChange: (index) {
        RootScaffold.stateKey.currentState?.closeDrawer();
        switchTab(index, context);
      },
      destinations: destinations,
      drawerDestinationRange: useMobileRouter ? (2, null) : (0, null),
      bottomDestinationRange: (0, 2),
      useBottomSheet: useMobileRouter,
      sidebarTrailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SideBarStatsOverview(),
        ),
      ),
      body: navigator,
    );
  }
}

class _CustomAdaptiveScaffold extends HookConsumerWidget {
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

  List<NavigationDestination> destinationsSlice((int, int?) range) =>
      destinations.sublist(range.$1, range.$2);

  int? selectedWithOffset((int, int?) range) {
    final index = selectedIndex - range.$1;
    return index < 0 || (range.$2 != null && index > (range.$2! - 1))
        ? null
        : index;
  }

  void selectWithOffset(int index, (int, int?) range) =>
      onSelectedIndexChange(index + range.$1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: RootScaffold.stateKey,
      drawer: Breakpoints.small.isActive(context)
          ? Drawer(
              width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedWithOffset(drawerDestinationRange),
                destinations: destinationsSlice(drawerDestinationRange)
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: (index) =>
                    selectWithOffset(index, drawerDestinationRange),
              ),
            )
          : null,
      body: AdaptiveLayout(
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                selectedIndex: selectedIndex,
                destinations: destinations
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: onSelectedIndexChange,
              ),
            ),
            Breakpoints.large: SlotLayout.from(
              key: const Key('primaryNavigation1'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                extended: true,
                selectedIndex: selectedIndex,
                destinations: destinations
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: onSelectedIndexChange,
                trailing: sidebarTrailing,
              ),
            ),
          },
        ),
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              inAnimation: AdaptiveScaffold.fadeIn,
              outAnimation: AdaptiveScaffold.fadeOut,
              builder: (context) => body,
            ),
          },
        ),
      ),
      // AdaptiveLayout bottom sheet has accessibility issues
      bottomNavigationBar: useBottomSheet && Breakpoints.small.isActive(context)
          ? NavigationBar(
              selectedIndex: selectedWithOffset(bottomDestinationRange) ?? 0,
              destinations: destinationsSlice(bottomDestinationRange),
              onDestinationSelected: (index) =>
                  selectWithOffset(index, bottomDestinationRange),
            )
          : null,
    );
  }
}
