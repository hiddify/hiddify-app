import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
// import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Breakpoints and layout tokens aligned with Material 3 guidance
const double _smallBreakpoint = 600;

/// Abstract interface for root scaffold utilities.
/// Provides static methods and keys for scaffold management.
abstract interface class RootScaffold {
  /// Global key for accessing the scaffold state.
  static final stateKey = GlobalKey<ScaffoldState>();

  /// Determines if the drawer can be shown based on screen width.
  /// Returns true if the screen width is less than the small breakpoint.
  static bool canShowDrawer(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _smallBreakpoint;
}

/// Adaptive root scaffold widget that adjusts layout based on screen size.
/// Supports compact (mobile), medium (tablet), and expanded (desktop) layouts.
/// Uses Material 3 design principles for responsive navigation.
class AdaptiveRootScaffold extends HookConsumerWidget with AppLogger {
  /// Creates an adaptive root scaffold.
  /// [navigator] is the main content widget.
  /// [navigationShell] is optional for handling tab navigation with GoRouter.
  const AdaptiveRootScaffold(this.navigator, {super.key, this.navigationShell});

  final Widget navigator;
  final StatefulNavigationShell? navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final selectedIndex = getCurrentIndex(context);

    // Define navigation destinations with icons and localized labels
    final destinations = <NavigationDestination>[
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
      NavigationDestination(
        icon: const Icon(FluentIcons.settings_20_filled),
        label: t.settings.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.document_text_20_filled),
        label: t.logs.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.info_20_filled),
        label: t.about.pageTitle,
      ),
    ];

    void onDestinationSelected(int index) {
      final shell = navigationShell;
      if (shell != null) {
        shell.goBranch(index);
      } else {
        switchTab(index, context);
      }
    }

    // Always use mobile layout with bottom navigation for now
    // to avoid NavigationRail rendering bug in Flutter 3.35
    return Scaffold(
      key: RootScaffold.stateKey,
      body: navigator,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
