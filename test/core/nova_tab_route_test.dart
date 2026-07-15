import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/adaptive_layout/my_adaptive_layout.dart';
import 'package:hiddify/core/router/adaptive_layout/nova_tab_route.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('maps production routes to the four Nova destinations', () {
    expect(novaTabForLocation('/home'), NovaTab.home);
    expect(novaTabForLocation('/home/proxies'), NovaTab.servers);
    expect(novaTabForLocation('/home/proxies/detail'), NovaTab.servers);
    expect(novaTabForLocation('/settings/routing-options'), NovaTab.rules);
    expect(novaTabForLocation('/settings/routing-options/rule/0'), NovaTab.rules);
    expect(novaTabForLocation('/settings'), NovaTab.settings);
    expect(novaTabForLocation('/settings/general'), NovaTab.settings);
  });

  test('resets the current shell branch only when the selected Nova tab is reselected', () {
    expect(shouldResetNovaBranch(current: NovaTab.home, requested: NovaTab.home), isTrue);
    expect(shouldResetNovaBranch(current: NovaTab.home, requested: NovaTab.servers), isFalse);
  });

  test('chooses a destination-aware action when each selected tab is reselected', () {
    expect(novaTabReselectionAction(NovaTab.home), NovaTabReselectionAction.resetShellBranch);
    expect(novaTabReselectionAction(NovaTab.servers), NovaTabReselectionAction.goToProxiesRoot);
    expect(novaTabReselectionAction(NovaTab.rules), NovaTabReselectionAction.goToRoutingOptionsRoot);
    expect(novaTabReselectionAction(NovaTab.settings), NovaTabReselectionAction.resetShellBranch);
  });

  testWidgets('production-style shell opens a destination and resets a reselected nested tab', (tester) async {
    final translations = await AppLocale.en.build();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MyAdaptiveLayout(navigationShell: navigationShell, isMobileBreakpoint: true, showProfilesAction: false),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) => const Text('home-root'),
                  routes: [
                    GoRoute(
                      path: 'proxies',
                      name: 'proxies',
                      builder: (context, state) => const Text('proxies-root'),
                      routes: [GoRoute(path: 'detail', builder: (context, state) => const Text('proxy-detail'))],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  name: 'settings',
                  builder: (context, state) => const Text('settings-root'),
                  routes: [
                    GoRoute(
                      path: 'routing-options',
                      name: 'routingOptions',
                      builder: (context, state) => const Text('routing-root'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => translations)],
        child: MaterialApp.router(
          theme: ThemeData(extensions: const [NovaThemeData.dark]),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Proxies'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/home/proxies');
    expect(find.text('proxies-root'), findsOneWidget);

    router.go('/home/proxies/detail');
    await tester.pumpAndSettle();
    expect(find.text('proxy-detail'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Proxies'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/home/proxies');
    expect(find.text('proxies-root'), findsOneWidget);
  });
}
