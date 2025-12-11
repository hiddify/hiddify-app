import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/settings/widget/settings_page.dart';

part 'routes.g.dart';

// Reserved for future use
// GlobalKey<NavigatorState>? get _dynamicRootKey =>
//     useMobileRouter ? rootNavigatorKey : null;

@TypedShellRoute<MobileWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(
      path: '/',
      name: HomeRoute.name,
    ),
    TypedGoRoute<SettingsRoute>(
      path: '/settings',
      name: SettingsRoute.name,
    ),
  ],
)
class MobileWrapperRoute extends ShellRouteData {
  const MobileWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) => AdaptiveRootScaffold(navigator);
}

@TypedShellRoute<DesktopWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(
      path: '/',
      name: HomeRoute.name,
    ),
    TypedGoRoute<SettingsRoute>(
      path: '/settings',
      name: SettingsRoute.name,
    ),
  ],
)
class DesktopWrapperRoute extends ShellRouteData {
  const DesktopWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) => AdaptiveRootScaffold(navigator);
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  static const name = 'Home';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => const NoTransitionPage<void>(name: name, child: HomePage());
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();
  static const name = 'Settings';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => const NoTransitionPage<void>(name: name, child: SettingsPage());
}
