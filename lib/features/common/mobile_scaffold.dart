import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';

import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_page.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/features/settings/about/about_page.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) => Breakpoints.small.isActive(context);
}

class MobileAdaptiveRootScaffold extends HookConsumerWidget {
  MobileAdaptiveRootScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final pageController = usePageController();
    final notchController = useNotchBottomBarController();

    final destinations = [
      (
        icon: const Icon(FluentIcons.home_24_filled),
        label: t.home.pageTitle,
        page: const HomePage(),
      ),
      // (
      //   icon: const Icon(FluentIcons.filter_20_filled),
      //   label: t.proxies.pageTitle,
      //   page: const ProxiesOverviewPage(),
      // ),
      (
        icon: const Icon(Icons.switch_account_rounded),
        label: t.profile.overviewPageTitle,
        page: const ProfilesOverviewModal(),
      ),
      (
        icon: const Icon(FluentIcons.settings_20_filled),
        label: t.config.pageTitle,
        page: ConfigOptionsPage(),
      ),
      // (
      //   icon: const Icon(FluentIcons.info_20_filled),
      //   label: t.about.pageTitle,
      //   page: const AboutPage(),
      // ),
    ];

    return _CustomAdaptiveScaffold(
      pageController: pageController,
      notchController: notchController,
      destinations: destinations,
      drawerDestinationRange: useMobileRouter ? (3, null) : (0, null),
      bottomDestinationRange: (0, 5),
      useBottomSheet: useMobileRouter,
      sidebarTrailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SideBarStatsOverview(),
        ),
      ),
    );
  }
}

class _CustomAdaptiveScaffold extends HookConsumerWidget {
  _CustomAdaptiveScaffold({
    required this.pageController,
    required this.notchController,
    required this.destinations,
    required this.drawerDestinationRange,
    required this.bottomDestinationRange,
    this.useBottomSheet = false,
    this.sidebarTrailing,
  });

  final PageController pageController;
  final NotchBottomBarController notchController;
  final List<({Icon icon, String label, Widget page})> destinations;
  final (int, int?) drawerDestinationRange;
  final (int, int?) bottomDestinationRange;
  final bool useBottomSheet;
  final Widget? sidebarTrailing;

  List<({Icon icon, String label, Widget page})> destinationsSlice((int, int?) range) => destinations.sublist(range.$1, range.$2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final isBottomBarTap = useState(false);

    void onPageChanged(int index) {
      currentIndex.value = index;
      if (isBottomBarTap.value) return;
      notchController.jumpTo(index);
    }

    final theme = Theme.of(context);
    return Scaffold(
      key: RootScaffold.stateKey,
      drawer: Breakpoints.small.isActive(context) && destinationsSlice(drawerDestinationRange).isNotEmpty
          ? Drawer(
              width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
              child: NavigationRail(
                extended: true,
                selectedIndex: currentIndex.value,
                destinations: destinationsSlice(drawerDestinationRange).map((dest) => NavigationRailDestination(icon: dest.icon, label: Text(dest.label))).toList(),
                onDestinationSelected: (index) {
                  pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            )
          : null,
      body: AdaptiveLayout(
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => NavigationRail(
                selectedIndex: currentIndex.value,
                destinations: destinations.map((dest) => NavigationRailDestination(icon: dest.icon, label: Text(dest.label))).toList(),
                onDestinationSelected: (index) {
                  pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            Breakpoints.large: SlotLayout.from(
              key: const Key('primaryNavigation1'),
              builder: (_) => NavigationRail(
                extended: true,
                selectedIndex: currentIndex.value,
                destinations: destinations.map((dest) => NavigationRailDestination(icon: dest.icon, label: Text(dest.label))).toList(),
                onDestinationSelected: (index) {
                  pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
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
              builder: (context) => PageView(
                controller: pageController,
                // physics: const NeverScrollableScrollPhysics(),
                onPageChanged: onPageChanged,
                children: destinations.map((dest) => dest.page).toList(),
              ),
            ),
          },
        ),
      ),
      bottomNavigationBar: useBottomSheet && Breakpoints.small.isActive(context)
          ? AnimatedNotchBottomBar(
              kBottomRadius: 32,

              kIconSize: 24,
              notchBottomBarController: notchController,
              // color: Colors.white,
              color: theme.colorScheme.primaryContainer,
              showLabel: true,
              notchColor: theme.colorScheme.primaryContainer,
              // removeMargins: false,
              // showTopRadius: false,
              // bottomBarWidth: 500,
              // durationInMilliSeconds: 600,
              bottomBarItems: destinations
                  .map((dest) => BottomBarItem(
                        inActiveItem: dest.icon,
                        activeItem: dest.icon,
                        itemLabel: dest.label,
                      ))
                  .toList(),
              onTap: (index) {
                isBottomBarTap.value = true;
                pageController.jumpToPage(
                  index,
                  // duration: const Duration(milliseconds: 300),
                  // curve: Curves.easeInOut,
                );

                Future.delayed(Duration(milliseconds: 600), () {
                  isBottomBarTap.value = false;
                });
              },
              // shadowElevation: 1
              // ,
              showBlurBottomBar: true,
            )
          : null,
    );
  }
}

PageController usePageController() {
  return use(const _PageControllerHook());
}

class _PageControllerHook extends Hook<PageController> {
  const _PageControllerHook();

  @override
  _PageControllerHookState createState() => _PageControllerHookState();
}

class _PageControllerHookState extends HookState<PageController, _PageControllerHook> {
  late final PageController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = PageController();
  }

  @override
  PageController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

NotchBottomBarController useNotchBottomBarController() {
  return use(const _NotchBottomBarControllerHook());
}

class _NotchBottomBarControllerHook extends Hook<NotchBottomBarController> {
  const _NotchBottomBarControllerHook();

  @override
  _NotchBottomBarControllerHookState createState() => _NotchBottomBarControllerHookState();
}

class _NotchBottomBarControllerHookState extends HookState<NotchBottomBarController, _NotchBottomBarControllerHook> {
  late final NotchBottomBarController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = NotchBottomBarController();
  }

  @override
  NotchBottomBarController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
