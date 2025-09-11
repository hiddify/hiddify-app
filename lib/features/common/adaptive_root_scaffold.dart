import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) => MediaQuery.of(context).size.width < 600;
}

// Helper class for responsive breakpoints
class AppBreakpoints {
  static const double smallWidth = 600;
  static const double mediumWidth = 840;
  static const double largeWidth = 1200;

  static bool isSmall(BuildContext context) => MediaQuery.of(context).size.width < smallWidth;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallWidth && width < largeWidth;
  }

  static bool isLarge(BuildContext context) => MediaQuery.of(context).size.width >= largeWidth;
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
        icon: Icon(
          FluentIcons.home_24_filled,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedIcon: Icon(
          FluentIcons.home_24_filled,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: t.home.pageTitle,
      ),
      NavigationDestination(
        icon: Icon(
          FluentIcons.server_24_regular,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedIcon: Icon(
          FluentIcons.server_24_filled,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: t.proxies.pageTitle,
      ),
      NavigationDestination(
        icon: Icon(
          FluentIcons.wrench_24_regular,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedIcon: Icon(
          FluentIcons.wrench_24_filled,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: t.config.pageTitle,
      ),
      NavigationDestination(
        icon: Icon(
          FluentIcons.settings_24_regular,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedIcon: Icon(
          FluentIcons.settings_24_filled,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: t.settings.pageTitle,
      ),
      NavigationDestination(
        icon: Icon(
          FluentIcons.document_text_24_regular,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedIcon: Icon(
          FluentIcons.document_text_24_filled,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: t.logs.pageTitle,
      ),
      NavigationDestination(
        icon: Icon(
          FluentIcons.info_24_regular,
          size: 24,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedIcon: Icon(
          FluentIcons.info_24_filled,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
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

  List<NavigationDestination> destinationsSlice((int, int?) range) => destinations.sublist(range.$1, range.$2);

  int? selectedWithOffset((int, int?) range) {
    final index = selectedIndex - range.$1;
    return index < 0 || (range.$2 != null && index > (range.$2! - 1)) ? null : index;
  }

  void selectWithOffset(int index, (int, int?) range) => onSelectedIndexChange(index + range.$1);

  NavigationRailDestination _toRailDestination(NavigationDestination dest) {
    return NavigationRailDestination(
      icon: dest.icon,
      selectedIcon: dest.selectedIcon,
      label: Text(dest.label),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSmall = AppBreakpoints.isSmall(context);
    final isMedium = AppBreakpoints.isMedium(context);
    final isLarge = AppBreakpoints.isLarge(context);

    return Scaffold(
      key: RootScaffold.stateKey,
      drawer: isSmall
          ? Drawer(
              width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedWithOffset(drawerDestinationRange),
                destinations: destinationsSlice(drawerDestinationRange).map(_toRailDestination).toList(),
                onDestinationSelected: (index) => selectWithOffset(index, drawerDestinationRange),
              ),
            )
          : null,
      body: Row(
        children: [
          // Navigation Rail for medium and large screens
          if (isMedium || isLarge)
            NavigationRail(
              extended: isLarge,
              selectedIndex: selectedIndex,
              destinations: destinations.map(_toRailDestination).toList(),
              onDestinationSelected: onSelectedIndexChange,
              trailing: isLarge ? sidebarTrailing : null,
            ),
          // Main content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: body,
            ),
          ),
        ],
      ),
      bottomNavigationBar: useBottomSheet && isSmall
          ? NavigationBar(
              selectedIndex: selectedWithOffset(bottomDestinationRange) ?? 0,
              destinations: destinationsSlice(bottomDestinationRange),
              onDestinationSelected: (index) => selectWithOffset(index, bottomDestinationRange),
            )
          : null,
    );
  }
}
