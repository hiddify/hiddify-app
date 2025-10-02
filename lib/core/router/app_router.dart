import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'app_router.g.dart';

bool _debugMobileRouter = false;
final useMobileRouter = !PlatformUtils.isDesktop || (kDebugMode && _debugMobileRouter);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// TODO: test and improve handling of deep link
@riverpod
GoRouter router(Ref ref) {
  final notifier = ref.watch(routerListenableProvider.notifier);
  late GoRouter router;
  final deepLink = ref.listen(deepLinkProvider, (_, next) {
    if (next case AsyncData<NewProfileLink?>(value: final link?)) {
      router.push(AddProfileRoute(url: link.url).location);
    }
  });
  final initialLink = deepLink.read();
  String initialLocation = const HomeRoute().location;
  if (initialLink case AsyncData<NewProfileLink?>(value: final link?)) {
    initialLocation = AddProfileRoute(url: link.url).location;
  }

  return router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: kDebugMode,
    routes: [if (useMobileRouter) _buildMobileStatefulShell() else $desktopWrapperRoute, $introRoute],
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [SentryNavigatorObserver()],
  );
}

final tabLocations = [const HomeRoute().location, const ProxiesRoute().location, const ConfigOptionsRoute().location, const SettingsRoute().location, const LogsOverviewRoute().location, const AboutRoute().location];

int getCurrentIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location) return 0;
  var index = 0;
  for (final tab in tabLocations.sublist(1)) {
    index++;
    if (location.startsWith(tab)) return index;
  }
  return 0;
}

void switchTab(int index, BuildContext context) {
  assert(index >= 0 && index < tabLocations.length);
  final location = tabLocations[index];
  return context.go(location);
}

@riverpod
class RouterListenable extends _$RouterListenable with AppLogger implements Listenable {
  VoidCallback? _routerListener;
  bool _introCompleted = false;

  @override
  Future<void> build() async {
    _introCompleted = ref.watch(Preferences.introCompleted);

    ref.listen(Preferences.introCompleted, (prev, next) {
      if (state.isLoading) return;
      loggy.debug("triggering listener");
      _routerListener?.call();
    });
  }

  // ignore: avoid_build_context_in_providers
  String? redirect(BuildContext context, GoRouterState state) {
    // if (this.state.isLoading || this.state.hasError) return null;

    final isIntro = state.uri.path == const IntroRoute().location;

    if (!_introCompleted) {
      return const IntroRoute().location;
    } else if (isIntro) {
      return const HomeRoute().location;
    }

    return null;
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
    builder: (context, state, navigationShell) => AdaptiveRootScaffold(navigationShell, navigationShell: navigationShell),
    branches: [
      // Home branch
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: const HomeRoute().location, // '/'
            name: HomeRoute.name,
            pageBuilder: (context, state) => const HomeRoute().buildPage(context, state),
            routes: [
              GoRoute(
                path: 'add',
                name: AddProfileRoute.name,
                parentNavigatorKey: AddProfileRoute.$parentNavigatorKey,
                pageBuilder: (context, state) => AddProfileRoute(url: state.uri.queryParameters['url']).buildPage(context, state),
              ),
              GoRoute(
                path: 'profiles',
                name: ProfilesOverviewRoute.name,
                parentNavigatorKey: ProfilesOverviewRoute.$parentNavigatorKey,
                pageBuilder: (context, state) => const ProfilesOverviewRoute().buildPage(context, state),
              ),
              GoRoute(
                path: 'profiles/new',
                name: NewProfileRoute.name,
                parentNavigatorKey: NewProfileRoute.$parentNavigatorKey,
                pageBuilder: (context, state) => const NewProfileRoute().buildPage(context, state),
              ),
              GoRoute(
                path: 'profiles/:id',
                name: ProfileDetailsRoute.name,
                parentNavigatorKey: ProfileDetailsRoute.$parentNavigatorKey,
                pageBuilder: (context, state) => ProfileDetailsRoute(state.pathParameters['id']!).buildPage(context, state),
              ),
              GoRoute(
                path: 'quick-settings',
                name: QuickSettingsRoute.name,
                parentNavigatorKey: QuickSettingsRoute.$parentNavigatorKey,
                pageBuilder: (context, state) => const QuickSettingsRoute().buildPage(context, state),
              ),
            ],
          ),
        ],
      ),

      // Proxies branch
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: const ProxiesRoute().location, // '/proxies'
            name: ProxiesRoute.name,
            pageBuilder: (context, state) => const ProxiesRoute().buildPage(context, state),
          ),
        ],
      ),

      // Config Options branch
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: const ConfigOptionsRoute().location, // '/config-options'
            name: ConfigOptionsRoute.name,
            // Keep on branch navigator (do not pass parentNavigatorKey)
            pageBuilder: (context, state) => ConfigOptionsRoute(section: state.uri.queryParameters['section']).buildPage(context, state),
          ),
        ],
      ),

      // Settings branch
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: const SettingsRoute().location, // '/settings'
            name: SettingsRoute.name,
            // Keep on branch navigator (do not pass parentNavigatorKey)
            pageBuilder: (context, state) => const SettingsRoute().buildPage(context, state),
            routes: [
              GoRoute(
                path: 'per-app-proxy',
                name: PerAppProxyRoute.name,
                parentNavigatorKey: PerAppProxyRoute.$parentNavigatorKey,
                pageBuilder: (context, state) => const PerAppProxyRoute().buildPage(context, state),
              ),
            ],
          ),
        ],
      ),

      // Logs branch
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: const LogsOverviewRoute().location, // '/logs'
            name: LogsOverviewRoute.name,
            // Keep on branch navigator (do not pass parentNavigatorKey)
            pageBuilder: (context, state) => const LogsOverviewRoute().buildPage(context, state),
          ),
        ],
      ),

      // About branch
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: const AboutRoute().location, // '/about'
            name: AboutRoute.name,
            // Keep on branch navigator (do not pass parentNavigatorKey)
            pageBuilder: (context, state) => const AboutRoute().buildPage(context, state),
          ),
        ],
      ),
    ],
  );
}
