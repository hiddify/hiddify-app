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
  late GoRouter router;
  
  String initialLocation = const HomeRoute().location;

  return router = GoRouter(
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
];

int getCurrentIndex(BuildContext context) {
  return 0; 
}

void switchTab(int index, BuildContext context) {
  if (index == 0) {
     context.go(tabLocations[0]);
  }
}

@riverpod
class RouterListenable extends _$RouterListenable
    with AppLogger
    implements Listenable {
  VoidCallback? _routerListener;

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

RouteBase _buildMobileStatefulShell() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        Scaffold(body: navigationShell), // Simplification: remove AdaptiveRootScaffold dependecy if it depended on deleted widgets?
        // Wait, AdaptiveRootScaffold is in features/common/adaptive_root_scaffold.dart. 
        // I kept features/common in Step 457.
        // So I can use it.
        // AdaptiveRootScaffold(navigationShell, navigationShell: navigationShell),
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
    ],
  );
}

