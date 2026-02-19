import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/go_router/refresh_listenable.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'go_router_notifier.g.dart';

// if 'stateful shell route' navigators not registered, this navigator key can be used for showing dialog or bottom sheet...
final rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

@Riverpod(keepAlive: true)
class GoRouterNotifer extends _$GoRouterNotifer {
  static final rConfig = ValueNotifier<RoutingConfig>(loadingConfig);
  @override
  GoRouter build() {
    ref.listen(routingConfigNotifierProvider, (_, next) => rConfig.value = next);
    return GoRouter.routingConfig(
      initialLocation: '/home',
      navigatorKey: rootNavKey,
      routingConfig: rConfig,
      refreshListenable: RefreshListenable(ref),
      errorBuilder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) => context.goNamed('home'));
        return const Material();
      },
    );
  }
}
