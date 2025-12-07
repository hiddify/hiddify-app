import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/settings/widget/core_settings_page.dart';

part 'routes.g.dart';

GlobalKey<NavigatorState>? get _dynamicRootKey =>
    useMobileRouter ? rootNavigatorKey : null;

@TypedShellRoute<MobileWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(
      path: "/",
      name: HomeRoute.name,
    ),
  ],
)
class MobileWrapperRoute extends ShellRouteData {
  const MobileWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return AdaptiveRootScaffold(navigator);
  }
}

@TypedShellRoute<DesktopWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(
      path: "/",
      name: HomeRoute.name,
      routes: [
         TypedGoRoute<CoreSettingsRoute>(
          path: "settings",
          name: CoreSettingsRoute.name,
        ),
      ]
    ),
  ],
)
class DesktopWrapperRoute extends ShellRouteData {
  const DesktopWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return AdaptiveRootScaffold(navigator);
  }
}

class CoreSettingsRoute extends GoRouteData {
   const CoreSettingsRoute();
   static const name = "CoreSettings";
   
   @override
   Page<void> buildPage(BuildContext context, GoRouterState state) {
     return const MaterialPage<void>(name: name, child: CoreSettingsPage());
   }
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  static const name = "Home";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage<void>(name: name, child: HomePage());
  }
}

