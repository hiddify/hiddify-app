import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/features/config_option/widget/quick_settings_modal.dart';

import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/intro/widget/intro_page.dart';
import 'package:hiddify/features/log/overview/logs_overview_page.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_page.dart';
import 'package:hiddify/features/profile/add/add_profile_modal.dart';
import 'package:hiddify/features/profile/details/profile_details_page.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_page.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/features/settings/about/about_page.dart';
import 'package:hiddify/features/settings/overview/settings_overview_page.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'routes.g.dart';

GlobalKey<NavigatorState>? _dynamicRootKey = null;

@TypedShellRoute<DesktopWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(
      path: "/",
      name: HomeRoute.name,
      routes: [
        TypedGoRoute<ProxiesRoute>(path: "proxies", name: ProxiesRoute.name),
        TypedGoRoute<QuickSettingsRoute>(path: "quick-settings", name: QuickSettingsRoute.name),
      ],
    ),
    TypedGoRoute<ProfilesOverviewRoute>(path: "/profiles", name: ProfilesOverviewRoute.name, routes: [
      TypedGoRoute<AddProfileRoute>(path: "profiles/add", name: AddProfileRoute.name),
      TypedGoRoute<NewProfileRoute>(path: "profiles/new", name: NewProfileRoute.name),
      TypedGoRoute<ProfileDetailsRoute>(path: "profiles/:id", name: ProfileDetailsRoute.name),
    ]),
    TypedGoRoute<ConfigOptionsRoute>(path: "/config-options", name: ConfigOptionsRoute.name),
    TypedGoRoute<LogsOverviewRoute>(path: "/logs", name: LogsOverviewRoute.name),
    TypedGoRoute<SettingsRoute>(
      path: "/settings",
      name: SettingsRoute.name,
      routes: [],
    ),
    TypedGoRoute<PerAppProxyRoute>(path: "/per-app-proxy", name: PerAppProxyRoute.name),
    TypedGoRoute<AboutRoute>(path: "/about", name: AboutRoute.name),
    TypedGoRoute<IntroRoute>(path: "/intro", name: IntroRoute.name)
  ],
)
class DesktopWrapperRoute extends ShellRouteData {
  const DesktopWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    // return AdaptiveRootScaffold();
    // navigationItems.clear();
    // ProviderScope.containerOf(context).read(provider).watch();
    // navigationItems.addAll
    return AdaptiveRootScaffold(navigator);
  }
}

abstract class HRouteData extends GoRouteData {
  const HRouteData();
  String getName();
  String getLocation();
}

class IntroRoute extends HRouteData {
  const IntroRoute();
  static const name = "Intro";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      // fullscreenDialog: true,
      name: name,
      child: IntroPage(),
    );
  }

  @override
  String getName() => IntroRoute.name;

  @override
  String getLocation() => location;
}

class HomeRoute extends HRouteData {
  const HomeRoute();
  static const name = "Home";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return platformPage(
      context: context,
      name: name,
      child: HomePage(),
    );
  }

  @override
  String getName() => HomeRoute.name;
  @override
  String getLocation() => location;
}

class ProxiesRoute extends HRouteData {
  const ProxiesRoute();
  static const name = "Proxies";
  // static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return platformPage(
      context: context,
      // fullscreenDialog: true,
      name: name,
      child: const ProxiesOverviewPage(),
    );
    // return platformPage(context:context,
    //   name: name,
    //   child: ProxiesOverviewPage(),
    // );
  }

  @override
  String getName() => ProxiesRoute.name;
  @override
  String getLocation() => location;
}

class AddProfileRoute extends HRouteData {
  const AddProfileRoute({this.url});

  final String? url;

  static const name = "Add Profile";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return BottomSheetPage(
      fixed: true,
      name: name,
      builder: (controller) => AddProfileModal(
        url: url,
        scrollController: controller,
      ),
    );
  }

  @override
  String getName() => AddProfileRoute.name;
  @override
  String getLocation() => location;
}

class ProfilesOverviewRoute extends HRouteData {
  const ProfilesOverviewRoute();
  static const name = "Profiles";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return platformPage(
      context: context,
      name: name,
      child: ProfilesOverviewModal(),
    );
    // return BottomSheetPage(
    //   name: name,
    //   builder: (controller) => ProfilesOverviewModal(scrollController: controller),
    // );
  }

  @override
  String getName() => ProfilesOverviewRoute.name;
  @override
  String getLocation() => location;
}

class NewProfileRoute extends HRouteData {
  const NewProfileRoute();
  static const name = "New Profile";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return platformPage(
      context: context,
      fullscreenDialog: true,
      name: name,
      child: ProfileDetailsPage("new"),
    );
  }

  @override
  String getName() => NewProfileRoute.name;
  @override
  String getLocation() => location;
}

class ProfileDetailsRoute extends HRouteData {
  const ProfileDetailsRoute(this.id);
  final String id;
  static const name = "Profile Details";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return platformPage(
      context: context,
      fullscreenDialog: true,
      name: name,
      child: ProfileDetailsPage(id),
    );
  }

  @override
  String getName() => ProfileDetailsRoute.name;
  @override
  String getLocation() => location;
}

class LogsOverviewRoute extends HRouteData {
  const LogsOverviewRoute();
  static const name = "Logs";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // if (useMobileRouter) {
    //   return NoTransitionPage(
    //     // context: context,
    //     name: name,
    //     child: const LogsOverviewPage(),
    //   );
    // }
    return platformPage(context: context, name: name, child: const LogsOverviewPage());
  }

  @override
  String getName() => LogsOverviewRoute.name;
  @override
  String getLocation() => location;
}

class QuickSettingsRoute extends HRouteData {
  const QuickSettingsRoute();
  static const name = "Quick Settings";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return BottomSheetPage(
      fixed: true,
      name: name,
      builder: (controller) => const QuickSettingsModal(),
    );
  }

  @override
  String getName() => QuickSettingsRoute.name;
  @override
  String getLocation() => location;
}

class SettingsRoute extends HRouteData {
  const SettingsRoute();
  static const name = "Settings";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (useMobileRouter) {
      return platformPage(
        context: context,
        name: name,
        child: const SettingsOverviewPage(),
      );
    }
    return platformPage(context: context, name: name, child: SettingsOverviewPage());
  }

  @override
  String getName() => SettingsRoute.name;
  @override
  String getLocation() => location;
}

class ConfigOptionsRoute extends HRouteData {
  const ConfigOptionsRoute({this.section});
  final String? section;
  static const name = "Config Options";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // if (useMobileRouter) {
    //   return platformPage(
    //     context: context,
    //     name: name,
    //     child: ConfigOptionsPage(section: section),
    //   );
    // }
    return NoTransitionPage(
      name: name,
      child: ConfigOptionsPage(section: section),
    );
  }

  @override
  String getName() => ConfigOptionsRoute.name;
  @override
  String getLocation() => location;
}

class PerAppProxyRoute extends GoRouteData {
  const PerAppProxyRoute();
  static const name = "Per-app Proxy";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = null;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return platformPage(
      context: context,
      // fullscreenDialog: true,
      name: name,
      child: const PerAppProxyPage(),
    );
  }

  // @override
  String getName() => PerAppProxyRoute.name;
  @override
  String getLocation() => location;
}

class AboutRoute extends HRouteData {
  const AboutRoute();
  static const name = "About";

  // static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // if (useMobileRouter) {
    //   return platformPage(
    //     context: context,
    //     name: name,
    //     child: const AboutPage(),
    //   );
    // }
    return platformPage(context: context, name: name, child: AboutPage());
  }

  @override
  String getName() => AboutRoute.name;
  @override
  String getLocation() => location;
}

// Helper class to define navigation items
class NavigationItem {
  final IconData icon;
  final String title;
  final HRouteData page;

  final bool showOnDesktop;
  final bool showOnMobile;

  NavigationItem({
    required this.icon,
    required this.title,
    required this.page,
    this.showOnDesktop = true,
    this.showOnMobile = true,
    // this.showInDrawer = true,
  });
}
