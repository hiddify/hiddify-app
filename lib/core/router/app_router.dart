import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/routes.dart';
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
  VoidCallback? _routerListener; // ignore: unused_field

  @override
  Future<void> build() async {
    // No intro logic anymore
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
        Scaffold(body: navigationShell), // Navigation handle by AdaptiveRootScaffold within pages or external wrapper? 
        // Wait, AdaptiveRootScaffold wraps the child in routes.dart. 
        // Here we just return the shell. 
        // If we use TypedShellRoute in routes.dart, we shouldn't manually build the shell here unless we are overriding.
        // But since we are using _buildMobileStatefulShell in app_router.dart instead of $mobileWrapperRoute, we must define it fully.
        // Ideally we should use $mobileWrapperRoute if possible.
        // But let's stick to consistent manual definition for now if that's what was there.
        // Actually, routes.dart defines MobileWrapperRoute which RETURN AdaptiveRootScaffold.
        // So the shell builder here should just return the child if the wrapper handles scaffolding.
        
    branches: [
      // Home branch
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: const HomeRoute().location, // '/'
            name: HomeRoute.name,
            pageBuilder: (context, state) =>
                const HomeRoute().buildPage(context, state),
          ),
        ],
      ),
      // Settings branch
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
    ],
  );
