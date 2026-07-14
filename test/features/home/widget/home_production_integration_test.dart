import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/home/widget/home_page.dart';

void main() {
  test('production tree integrates both Nova controls', () {
    final router = File('lib/core/router/go_router/routing_config_notifier.dart').readAsStringSync();
    final home = File('lib/features/home/widget/home_page.dart').readAsStringSync();
    final connection = File('lib/features/home/widget/connection_button.dart').readAsStringSync();
    final adaptive = File('lib/core/router/adaptive_layout/my_adaptive_layout.dart').readAsStringSync();

    expect(router, contains('child: const HomePage()'));
    expect(home, contains('child: const ConnectionButton()'));
    expect(connection, contains('return NovaConnectionControl('));
    expect(adaptive, contains('NovaGlassTabBar('));
  });

  test('preserves Home server-card route decisions', () {
    expect(novaHomeServerAction(hasProfile: false, hasProxy: false), NovaHomeServerAction.addProfile);
    expect(novaHomeServerAction(hasProfile: true, hasProxy: false), NovaHomeServerAction.showProfiles);
    expect(novaHomeServerAction(hasProfile: true, hasProxy: true), NovaHomeServerAction.showProxies);
  });

  test('preserves quick-settings and profile actions without raw Nova palette access', () {
    final home = File('lib/features/home/widget/home_page.dart').readAsStringSync();
    final dock = File('lib/core/widget/nova_glass_tab_bar.dart').readAsStringSync();
    final connection = File('lib/features/home/widget/nova_connection_control.dart').readAsStringSync();
    final ritual = File('lib/features/home/widget/nova_ritual_hero.dart').readAsStringSync();

    expect(home, contains('showQuickSettings()'));
    expect(home, contains('showAddProfile()'));
    expect(home, contains('showProfilesOverview()'));
    expect(home, isNot(contains('NovaColors.')));
    expect(dock, isNot(contains('NovaColors.')));
    expect(connection, isNot(contains('NovaColors.')));
    expect(ritual, isNot(contains('NovaColors.')));
  });

  test('preserves connection provider decisions in the production adapter', () {
    final connection = File('lib/features/home/widget/connection_button.dart').readAsStringSync();

    expect(connection, contains('ref.watch(connectionNotifierProvider)'));
    expect(connection, contains('ref.watch(activeProxyNotifierProvider)'));
    expect(connection, contains('ref.watch(configOptionNotifierProvider)'));
    expect(connection, contains('ref.read(activeProfileProvider.future)'));
    expect(connection, contains('toggleConnection()'));
    expect(connection, contains('reconnect(activeProfile)'));
    expect(connection, contains('showNoActiveProfile()'));
    expect(connection, contains('showExperimentalFeatureNotice()'));
  });
}
