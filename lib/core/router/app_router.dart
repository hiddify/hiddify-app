import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/routes.dart';
// import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  // final deepLink = ref.listen(
  //   deepLinkNotifierProvider,
  //   (_, next) async {
  //     if (next case AsyncData(value: final link?)) {
  //       await ref.state.push(HomeRoute(url: link.url).location);
  //     }
  //   },
  // );
  // final initialLink = deepLink.read();
  // String initialLocation = const HomeRoute().location;
  // if (initialLink case AsyncData(value: final link?)) {
  //   initialLocation = HomeRoute(url: link.url).location;
  // }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // initialLocation: initialLocation,
    debugLogDiagnostics: true,
    routes: $appRoutes,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [
      SentryNavigatorObserver(),
    ],
  );
}

// final tabLocations = [
//   const HomeRoute().location,
//   // const ProxiesRoute().location,
//   const ProfilesOverviewRoute().location,
//   const LogsOverviewRoute().location,
//   const ConfigOptionsRoute().location,
//   //const QuickSettingsRoute().location,
//   // const SettingsRoute().location,
//   const AboutRoute().location,
// ];

// int getCurrentIndex(BuildContext context) {
//   final String location = GoRouterState.of(context).uri.path;

//   if (location == const HomeRoute().location) return 0;
//   var index = 0;
//   for (final tab in tabLocations.sublist(1)) {
//     index++;
//     if (location.startsWith(tab)) return index;
//   }
//   return 0;
// }

// void switchTab(int index, BuildContext context) {
//   assert(index >= 0 && index < tabLocations.length);
//   final location = tabLocations[index];
//   return context.go(location);
// }

@riverpod
class RouterListenable extends _$RouterListenable with AppLogger implements Listenable {
  VoidCallback? _routerListener;
  bool _newUrlFromAppLink = false;
  // bool _introCompleted = false;

  @override
  Future<void> build() async {
    // _introCompleted = ref.watch(Preferences.introCompleted);
    ref.watch(Preferences.introCompleted);
    if (PlatformUtils.isDesktop) {
      ref
        ..watch(myAppLinksProvider)
        ..listen(myAppLinksProvider, (previous, next) => _newUrlFromAppLink = true);
    }

    ref.listenSelf((_, __) {
      if (state.isLoading) return;
      loggy.debug("triggering listener");
      _routerListener?.call();
    });
  }

// ignore: avoid_build_context_in_providers
  String? redirect(BuildContext context, GoRouterState state) {
    // if (this.state.isLoading || this.state.hasError) return null;

    final introCompleted = ref.read(Preferences.introCompleted);
    final isIntro = state.uri.path == const IntroRoute().location;
    // fix path-parameters for deep link
    String? url;
    if (state.uri.scheme == 'hiddify' && state.uri.host == 'import') {
      url = state.uri.toString().substring(17);
    } else if (PlatformUtils.isDesktop && _newUrlFromAppLink) {
      url = ref.read(myAppLinksProvider).value;
      _newUrlFromAppLink = false;
    } else if (state.uri.queryParameters['url'] != null) {
      url = state.uri.queryParameters['url'];
    }

    if (!introCompleted) {
      final introLocation = url != null ? '${const IntroRoute().location}?url=$url' : const IntroRoute().location;
      return introLocation;
    } else if (isIntro) {
      final homeLocation = url != null ? '${const HomeRoute().location}?url=$url' : const HomeRoute().location;
      return homeLocation;
    } else if (url != null) {
      return '${const HomeRoute().location}?url=$url';
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

@riverpod
Stream<String> myAppLinks(Ref ref) async* {
  yield* AppLinks().uriLinkStream.map((event) => event.toString().substring(17));
}
