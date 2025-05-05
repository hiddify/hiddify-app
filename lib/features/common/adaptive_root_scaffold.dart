import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) => Breakpoints.small.isActive(context);
}

class AdaptiveRootScaffold extends HookConsumerWidget {
  const AdaptiveRootScaffold(this.navigator, {super.key});

  final Widget navigator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    if (t == null) return const SizedBox.shrink();
    // final selectedIndex = getCurrentIndex(context);
    final allnavigationItems = [
      NavigationItem(
        icon: FluentIcons.power_20_filled,
        title: t.home.pageTitle,
        page: const HomeRoute(),
      ),
      NavigationItem(
        icon: Icons.switch_account_rounded,
        title: t.profile.overviewPageTitle,
        page: const ProfilesOverviewRoute(),
        showOnMobile: false,
        showOnDesktop: ref.watch(activeProfileProvider).value != null,
      ),
      // NavigationItem(
      //   icon: Icons.extension,
      //   title: 'Extensions',
      //   page: ExtensionPage(),
      //   showOnDesktop: true,
      //   showOnMobile: true,
      // ),
      NavigationItem(
        icon: FluentIcons.settings_20_filled, //Icons.settings,
        title: t.config.pageTitle,
        page: const ConfigOptionsRoute(),
      ),
      NavigationItem(
        icon: FluentIcons.document_text_20_filled,
        title: t.logs.pageTitle,
        page: const LogsOverviewRoute(),
        showOnMobile: false,
      ),
      NavigationItem(
        icon: FluentIcons.info_20_filled, //Icons.info,
        title: t.about.pageTitle,
        page: const AboutRoute(),
        showOnMobile: false,
      ),
    ];

    final navigationItems = allnavigationItems.where((item) => Breakpoints.small.isActive(context) ? item.showOnMobile : item.showOnDesktop).toList();
    // .map((item) => PersistentBottomNavBarItem(icon: Icon(item.icon), title: item.title)).toList();

    // final pageController = usePageController();
    // final pageController = useMemoized(() => PageController());

    // final notchController = useNotchBottomBarController();
    // final theme = Theme.of(context);

    return _CustomAdaptiveScaffold(
      // pageController: pageController,
      // tabController: tabController,
      // notchController: notchController,
      // selectedIndex: selectedIndex,
      onSelectedIndexChange: (index) {
        RootScaffold.stateKey.currentState?.closeDrawer();

        // switchTab(index, context);
        return context.go(navigationItems[index].page.getLocation());
      },
      destinations: navigationItems,
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
    // required this.pageController,
    // required this.tabController,
    // required this.notchController,
    // required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.destinations,
    this.sidebarTrailing,
    required this.body,
  });

  // final int selectedIndex;
  final Function(int) onSelectedIndexChange;
  final List<NavigationItem> destinations;

  final Widget? sidebarTrailing;
  final Widget body;
  // final PageController pageController;
  // final NotchBottomBarController notchController;
  // final PersistentTabController tabController;
  int getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    if (location == const HomeRoute().location) return 0;
    var index = 0;
    for (final tab in destinations.sublist(1)) {
      index++;
      if (location.startsWith(tab.page.getLocation())) return index;
    }
    return 0;
  }

  void onPageChanged(int index) {
    onSelectedIndexChange(index);
    // currentIndex.value = index;
    // final neighborPage = (currentIndex.value - index).abs() <= 1;
    // currentIndex.value = index;
    // if (neighborPage) {
    //   pageController.animateToPage(currentIndex.value, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubicEmphasized);
    // } else {
    //   pageController.jumpToPage(currentIndex.value);
    // }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = getCurrentIndex(context);
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    final bodyScopeNode = useFocusScopeNode();
    useEffect(() {
      HardwareKeyboard.instance.addHandler(
        (event) {
          final arrows = Breakpoints.small.isActive(context) ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
          if (!arrows.contains(event.logicalKey)) return false;
          if (event is KeyDownEvent) {
            primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
          } else {
            // focus node does not change => true.
            if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
              if (bodyScopeNode.hasFocus) {
                navScopeNode.requestFocus();
              } else {
                bodyScopeNode.requestFocus();
              }
            }
          }
          return true;
        },
      );
      return null;
    }, []);
    return Material(
      child: AdaptiveLayout(
        key: RootScaffold.stateKey,
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => FocusScope(
                node: navScopeNode,
                child: AdaptiveScaffold.standardNavigationRail(
                  selectedIndex: currentIndex,
                  destinations: destinations.map((item) => NavigationRailDestination(icon: Icon(item.icon), label: Text(item.title))).toList(),
                  onDestinationSelected: onPageChanged,
                ),
              ),
            ),
            Breakpoints.mediumLargeAndUp: SlotLayout.from(
              key: const Key('primaryNavigation1'),
              builder: (_) => FocusScope(
                node: navScopeNode,
                child: AdaptiveScaffold.standardNavigationRail(
                  extended: true,
                  selectedIndex: currentIndex,
                  destinations: destinations.map((item) => NavigationRailDestination(icon: Icon(item.icon), label: Text(item.title))).toList(),
                  onDestinationSelected: onPageChanged,
                  trailing: sidebarTrailing,
                ),
              ),
            ),
          },
        ),
        bottomNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.small: SlotLayout.from(
              key: const Key('bottomNavigation'),
              builder: (_) => FocusScope(
                node: navScopeNode,
                child: NavigationBar(
                  animationDuration: const Duration(milliseconds: 300),
                  selectedIndex: currentIndex,
                  destinations: destinations.map((item) => NavigationDestination(icon: Icon(item.icon), label: item.title)).toList(),
                  onDestinationSelected: onPageChanged,
                ),
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
              builder: (context) => FocusScope(
                node: bodyScopeNode,
                child: body,
              ),
            ),
          },
        ),
      ),
    );
    // final theme = Theme.of(context);
    // return Scaffold(
    //     key: RootScaffold.stateKey,
    //     // drawer: Breakpoints.small.isActive(context) && destinationsSlice(drawerDestinationRange).isNotEmpty
    //     //     ? Drawer(
    //     //         width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
    //     //         child: NavigationRail(
    //     //           extended: true,
    //     //           selectedIndex: selectedWithOffset(drawerDestinationRange),
    //     //           destinations: destinationsSlice(drawerDestinationRange).map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
    //     //           onDestinationSelected: (index) => selectWithOffset(index, drawerDestinationRange),
    //     //         ),
    //     //       )
    //     //     : null,
    //     body: AdaptiveLayout(
    //       primaryNavigation: SlotLayout(
    //         config: <Breakpoint, SlotLayoutConfig>{
    //           Breakpoints.medium: SlotLayout.from(
    //             key: const Key('primaryNavigation'),
    //             builder: (_) => AdaptiveScaffold.standardNavigationRail(
    //               selectedIndex: currentIndex,
    //               destinations: destinations.map((item) => NavigationRailDestination(icon: Icon(item.icon), label: Text(item.title))).toList(),
    //               onDestinationSelected: onPageChanged,
    //             ),
    //           ),
    //           Breakpoints.mediumLargeAndUp: SlotLayout.from(
    //             key: const Key('primaryNavigation1'),
    //             builder: (_) => AdaptiveScaffold.standardNavigationRail(
    //               extended: true,
    //               selectedIndex: currentIndex,
    //               destinations: destinations.map((item) => NavigationRailDestination(icon: Icon(item.icon), label: Text(item.title))).toList(),
    //               onDestinationSelected: onPageChanged,
    //               trailing: sidebarTrailing,
    //             ),
    //           ),
    //         },
    //       ),
    //       // body: SlotLayout(
    //       //   config: <Breakpoint, SlotLayoutConfig?>{
    //       //     Breakpoints.standard: SlotLayout.from(
    //       //       key: const Key('body'),
    //       //       inAnimation: AdaptiveScaffold.fadeIn,
    //       //       outAnimation: AdaptiveScaffold.fadeOut,
    //       //       builder: (context) => PageView(
    //       //         controller: pageController,
    //       //         // physics: const NeverScrollableScrollPhysics(),
    //       //         onPageChanged: onPageChanged,
    //       //         children: destinations.values.map((dest) => dest.page.build(context, GoRouterState.of(context))).toList(),
    //       //       ),
    //       //     ),
    //       //   },
    //       body: SlotLayout(
    //         config: <Breakpoint, SlotLayoutConfig?>{
    //           Breakpoints.standard: SlotLayout.from(
    //             key: const Key('body'),
    //             inAnimation: AdaptiveScaffold.fadeIn,
    //             outAnimation: AdaptiveScaffold.fadeOut,
    //             builder: (context) => body,
    //           ),
    //         },
    //       ),
    //     ),
    //     bottomNavigationBar: Breakpoints.small.isActive(context)
    //         ?
    //         // BottomNavyBar(
    //         //     selectedIndex: currentIndex.value,
    //         //     // showElevation: true, // use this to remove appBar's elevation
    //         //     onItemSelected: onPageChanged,
    //         //     items: destinations.map((item) => BottomNavyBarItem(icon: Icon(item.icon), title: Text(item.title))).toList(),
    //         //     backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
    //         //   )
    //         NavigationBar(
    //             animationDuration: const Duration(milliseconds: 300),
    //             selectedIndex: currentIndex,
    //             destinations: destinations.map((item) => NavigationDestination(icon: Icon(item.icon), label: item.title)).toList(),
    //             onDestinationSelected: onPageChanged,
    //           )
    //         : null
    //     // ? PersistentTabView(
    //     //     context,
    //     //     controller: tabController,
    //     //     screens: destinations.map((dest) => dest.page).toList(),
    //     //     items: destinations.map((item) => PersistentBottomNavBarItem(icon: Icon(item.icon), title: item.title)).toList(),
    //     //     navBarStyle: NavBarStyle.style6,
    //     //     animationSettings: const NavBarAnimationSettings(
    //     //       navBarItemAnimation: ItemAnimationSettings(
    //     //         // duration: Duration(milliseconds: 300),
    //     //         curve: Curves.linear,
    //     //       ),
    //     //       screenTransitionAnimation: ScreenTransitionAnimationSettings(
    //     //         animateTabTransition: true,
    //     //         curve: Curves.linear,
    //     //         // duration: const Duration(milliseconds: 300),
    //     //       ),
    //     //     ),
    //     //   )
    //     // : null
    //     // AnimatedNotchBottomBar(
    //     //   kBottomRadius: 0,
    //     //   // removeMargins: true,
    //     //   kIconSize: 24,
    //     //   notchBottomBarController: notchController,
    //     //   // color: Colors.white,
    //     //   color: theme.colorScheme.secondaryContainer,
    //     //   notchColor: theme.colorScheme.secondaryContainer,
    //     //   // removeMargins: false,
    //     //   // showTopRadius: false,
    //     //   // bottomBarWidth: 500,
    //     //   // durationInMilliSeconds: 600,
    //     //   bottomBarItems: destinations
    //     //       .map((dest) => BottomBarItem(
    //     //             inActiveItem: Icon(dest.icon, color: theme.colorScheme.secondary),
    //     //             activeItem: Icon(dest.icon, color: theme.colorScheme.primary),
    //     //             itemLabel: dest.title,
    //     //           ))
    //     //       .toList(),
    //     //   onTap: (index) {
    //     //     isBottomBarTap.value = true;
    //     //     pageController.jumpToPage(
    //     //       index,
    //     //       // duration: const Duration(milliseconds: 300),
    //     //       // curve: Curves.easeInOut,
    //     //     );

    //     //     Future.delayed(Duration(milliseconds: 600), () {
    //     //       isBottomBarTap.value = false;
    //     //     });
    //     //   },

    //     //   // shadowElevation: 1
    //     //   // ,
    //     //   showBottomRadius: false,
    //     //   showBlurBottomBar: true,
    //     // )
    //     // : null,
    //     );
  }
}
