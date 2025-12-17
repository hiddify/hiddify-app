import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/app_settings/widget/app_settings_page.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/config/widget/profiles_page.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/per_app_proxy/per_app_proxy.dart';
import 'package:hiddify/features/settings/widget/app_info_page.dart';
import 'package:hiddify/features/settings/widget/core_settings_page.dart';
import 'package:hiddify/features/settings/widget/privacy_policy_page.dart';
import 'package:hiddify/features/settings/widget/privacy_settings_page.dart';
import 'package:hiddify/features/settings/widget/resource_manager_page.dart';
import 'package:hiddify/features/settings/widget/settings_page.dart';
import 'package:hiddify/features/settings/widget/system_health_page.dart';
import 'package:hiddify/features/subscription/widget/subscription_management_page.dart';

part 'routes.g.dart';

@TypedShellRoute<MobileWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/', name: HomeRoute.name),
    TypedGoRoute<SettingsRoute>(
      path: '/settings',
      name: SettingsRoute.name,
      routes: [
        TypedGoRoute<GeneralSettingsRoute>(
          path: 'general',
          name: GeneralSettingsRoute.name,
        ),
        TypedGoRoute<CoreSettingsRoute>(
          path: 'core',
          name: CoreSettingsRoute.name,
        ),
        TypedGoRoute<PrivacyPolicyRoute>(
          path: 'policy',
          name: PrivacyPolicyRoute.name,
        ),
        TypedGoRoute<AppInfoRoute>(path: 'about', name: AppInfoRoute.name),
        TypedGoRoute<PrivacySettingsRoute>(
          path: 'privacy-settings',
          name: PrivacySettingsRoute.name,
        ),
        TypedGoRoute<ResourceManagerRoute>(
          path: 'resources',
          name: ResourceManagerRoute.name,
        ),
        TypedGoRoute<SystemHealthRoute>(
          path: 'health',
          name: SystemHealthRoute.name,
        ),
        TypedGoRoute<PerAppProxyRoute>(
          path: 'per-app-proxy',
          name: PerAppProxyRoute.name,
        ),
        TypedGoRoute<SubscriptionManagementRoute>(
          path: 'subscriptions',
          name: SubscriptionManagementRoute.name,
        ),
      ],
    ),
    TypedGoRoute<ProfilesRoute>(path: '/profiles', name: ProfilesRoute.name),
  ],
)
class MobileWrapperRoute extends ShellRouteData {
  const MobileWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      AdaptiveRootScaffold(navigator);
}

@TypedShellRoute<DesktopWrapperRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/', name: HomeRoute.name),
    TypedGoRoute<SettingsRoute>(
      path: '/settings',
      name: SettingsRoute.name,
      routes: [
        TypedGoRoute<GeneralSettingsRoute>(
          path: 'general',
          name: GeneralSettingsRoute.name,
        ),
        TypedGoRoute<CoreSettingsRoute>(
          path: 'core',
          name: CoreSettingsRoute.name,
        ),
        TypedGoRoute<PrivacyPolicyRoute>(
          path: 'policy',
          name: PrivacyPolicyRoute.name,
        ),
        TypedGoRoute<AppInfoRoute>(path: 'about', name: AppInfoRoute.name),
        TypedGoRoute<PrivacySettingsRoute>(
          path: 'privacy-settings',
          name: PrivacySettingsRoute.name,
        ),
        TypedGoRoute<ResourceManagerRoute>(
          path: 'resources',
          name: ResourceManagerRoute.name,
        ),
        TypedGoRoute<SystemHealthRoute>(
          path: 'health',
          name: SystemHealthRoute.name,
        ),
        TypedGoRoute<PerAppProxyRoute>(
          path: 'per-app-proxy',
          name: PerAppProxyRoute.name,
        ),
        TypedGoRoute<SubscriptionManagementRoute>(
          path: 'subscriptions',
          name: SubscriptionManagementRoute.name,
        ),
      ],
    ),
    TypedGoRoute<ProfilesRoute>(path: '/profiles', name: ProfilesRoute.name),
  ],
)
class DesktopWrapperRoute extends ShellRouteData {
  const DesktopWrapperRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      AdaptiveRootScaffold(navigator);
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  static const name = 'Home';

  @override
  material.Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage<void>(name: name, child: HomePage());
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();
  static const name = 'Settings';

  @override
  material.Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage<void>(name: name, child: SettingsPage());
}

class GeneralSettingsRoute extends GoRouteData with $GeneralSettingsRoute {
  const GeneralSettingsRoute();
  static const name = 'GeneralSettings';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const GeneralSettingsPage();
}

class CoreSettingsRoute extends GoRouteData with $CoreSettingsRoute {
  const CoreSettingsRoute();
  static const name = 'CoreSettings';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CoreSettingsPage();
}

class PrivacyPolicyRoute extends GoRouteData with $PrivacyPolicyRoute {
  const PrivacyPolicyRoute();
  static const name = 'PrivacyPolicy';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrivacyPolicyPage();
}

class AppInfoRoute extends GoRouteData with $AppInfoRoute {
  const AppInfoRoute();
  static const name = 'AppInfo';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AppInfoPage();
}

class PrivacySettingsRoute extends GoRouteData with $PrivacySettingsRoute {
  const PrivacySettingsRoute();
  static const name = 'PrivacySettings';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrivacySettingsPage();
}

class ResourceManagerRoute extends GoRouteData with $ResourceManagerRoute {
  const ResourceManagerRoute();
  static const name = 'ResourceManager';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ResourceManagerPage();
}

class SystemHealthRoute extends GoRouteData with $SystemHealthRoute {
  const SystemHealthRoute();
  static const name = 'SystemHealth';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SystemHealthPage();
}

class PerAppProxyRoute extends GoRouteData with $PerAppProxyRoute {
  const PerAppProxyRoute();
  static const name = 'PerAppProxy';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PerAppProxyPage();
}

class SubscriptionManagementRoute extends GoRouteData
    with $SubscriptionManagementRoute {
  const SubscriptionManagementRoute();
  static const name = 'SubscriptionManagement';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SubscriptionManagementPage();
}

class ProfilesRoute extends GoRouteData with $ProfilesRoute {
  const ProfilesRoute();
  static const name = 'Profiles';

  @override
  material.Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage<void>(name: name, child: ProfilesPage());
}
