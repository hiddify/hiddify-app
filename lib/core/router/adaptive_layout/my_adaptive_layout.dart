import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({super.key, required this.navigationShell, required this.isSmallActive, required this.showProfilesAction});
  // managed by go router(Shell Route)
  final StatefulNavigationShell navigationShell;
  final bool isSmallActive;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    branchNavKey = navigatorKeys[getNameOfBranch(isSmallActive, showProfilesAction, navigationShell.currentIndex)]!;
    final t = ref.watch(translationsProvider).requireValue;
    final popupIsShowing = ref.watch(popupCountNotifierProvider) != 0;
    // animations management
    final isLTR = Directionality.of(context) == TextDirection.ltr;
    final navInAnimation = isLTR ? AdaptiveScaffold.leftOutIn : AdaptiveScaffold.rightOutIn;
    const outAnimation = AdaptiveScaffold.fadeOut;
    const inDuration = Duration(milliseconds: 200);
    const outDuration = Duration(milliseconds: 100);
    // focus switch management
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = Breakpoints.small.isActive(context) ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else {
          // focus node does not change => true.
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
            if (branchesScope.values.any((node) => node.hasFocus)) {
              navScopeNode.requestFocus();
            } else if (navScopeNode.hasFocus) {
              branchesScope[getNameOfBranch(isSmallActive, showProfilesAction, navigationShell.currentIndex)]?.requestFocus();
            }
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () {
        HardwareKeyboard.instance.removeHandler(handler);
      };
    }, [
      isSmallActive,
      showProfilesAction,
      navigationShell.currentIndex,
    ]);
    return Material(
      child: AdaptiveLayout(
        internalAnimations: false,
        primaryNavigation: SlotLayout(
          config: popupIsShowing
              ? {}
              : <Breakpoint, SlotLayoutConfig>{
                  Breakpoints.medium: SlotLayout.from(
                    key: const Key('primaryNavigation'),
                    inAnimation: navInAnimation,
                    outAnimation: outAnimation,
                    inDuration: inDuration,
                    outDuration: outDuration,
                    builder: (_) => FocusScope(
                      node: navScopeNode,
                      child: AdaptiveScaffold.standardNavigationRail(
                        padding: EdgeInsets.zero,
                        selectedIndex: navigationShell.currentIndex,
                        destinations: _navRailDests(_actions(t, showProfilesAction, isSmallActive)),
                        onDestinationSelected: (index) => _onTap(context, index),
                      ),
                    ),
                  ),
                  Breakpoints.mediumLargeAndUp: SlotLayout.from(
                    key: const Key('primaryNavigationExtended'),
                    inAnimation: navInAnimation,
                    outAnimation: outAnimation,
                    inDuration: inDuration,
                    outDuration: outDuration,
                    builder: (_) => FocusScope(
                      node: navScopeNode,
                      child: AdaptiveScaffold.standardNavigationRail(
                        padding: EdgeInsets.zero,
                        extended: true,
                        selectedIndex: navigationShell.currentIndex,
                        destinations: _navRailDests(_actions(t, showProfilesAction, isSmallActive)),
                        onDestinationSelected: (index) => _onTap(context, index),
                        trailing: Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SideBarStatsOverview(disabled: popupIsShowing),
                          ),
                        ),
                      ),
                    ),
                  ),
                },
        ),
        bottomNavigation: SlotLayout(
          config: popupIsShowing
              ? {}
              : <Breakpoint, SlotLayoutConfig>{
                  Breakpoints.small: SlotLayout.from(
                    key: const Key('bottomNavigation'),
                    inAnimation: AdaptiveScaffold.bottomToTop,
                    outAnimation: outAnimation,
                    inDuration: inDuration,
                    outDuration: outDuration,
                    builder: (_) => FocusScope(
                      node: navScopeNode,
                      child: AdaptiveScaffold.standardBottomNavigationBar(
                        currentIndex: navigationShell.currentIndex <= 1 ? navigationShell.currentIndex : null,
                        destinations: _navDests(_actions(t, showProfilesAction, isSmallActive)),
                        onDestinationSelected: (index) => _onTap(context, index),
                      ),
                    ),
                  ),
                },
        ),
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              builder: (_) => navigationShell,
            ),
          },
        ),
      ),
    );
  }

  // shell route action onTap
  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isSmallActive) => [
        ShellRouteAction(Icons.power_settings_new_rounded, t.home.pageTitle),
        if (showProfilesAction && !isSmallActive) ShellRouteAction(Icons.view_list_rounded, t.profile.overviewPageTitle),
        ShellRouteAction(Icons.settings_rounded, t.config.pageTitle),
        if (!isSmallActive) ShellRouteAction(Icons.description_rounded, t.logs.pageTitle),
        if (!isSmallActive) ShellRouteAction(Icons.info_rounded, t.about.pageTitle),
      ];

  List<NavigationDestination> _navDests(List<ShellRouteAction> actions) => actions
      .map((e) => NavigationDestination(
            icon: Icon(e.icon),
            label: e.title,
          ))
      .toList();
  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions) => actions
      .map((e) => NavigationRailDestination(
            icon: Icon(e.icon),
            label: Text(e.title),
          ))
      .toList();
}
