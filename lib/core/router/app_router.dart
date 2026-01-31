import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/features.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'app_router.g.dart';

bool _debugMobileRouter = true;
final useMobileRouter =
    !PlatformUtils.isDesktop || (kDebugMode && _debugMobileRouter);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(Ref ref) {
  final notifier = ref.watch(routerListenableProvider.notifier);
  final initialLocation = const HomeRoute().location;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: kDebugMode,
    routes: [
      if (useMobileRouter)
        _buildMobileStatefulShell()
      else
        $desktopWrapperRoute,
    ],
    refreshListenable: notifier,
    observers: [SentryNavigatorObserver()],
  );
}

final tabLocations = [
  const HomeRoute().location,
  const SettingsRoute().location,
  const ProfilesRoute().location,
];

int getCurrentIndex(BuildContext context) {
  final location = GoRouterState.of(context).uri.path;
  final index = tabLocations.indexWhere(location.startsWith);
  return index < 0 ? 0 : index;
}

void switchTab(int index, BuildContext context) {
  if (index >= 0 && index < tabLocations.length) {
    context.go(tabLocations[index]);
  }
}

@riverpod
class RouterListenable extends _$RouterListenable
    with AppLogger
    implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {}

  /// Notifies listeners that the router state has changed.
  void notifyListeners() {
    _routerListener?.call();
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }
}

RouteBase _buildMobileStatefulShell() => StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      AdaptiveRootScaffold(navigationShell, navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: const HomeRoute().location, 
          name: HomeRoute.name,
          pageBuilder: (context, state) =>
              const HomeRoute().buildPage(context, state),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: const SettingsRoute().location,
          name: SettingsRoute.name,
          pageBuilder: (context, state) =>
              const SettingsRoute().buildPage(context, state),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: const ProfilesRoute().location,
          name: ProfilesRoute.name,
          pageBuilder: (context, state) =>
              const ProfilesRoute().buildPage(context, state),
        ),
      ],
    ),
  ],
);
