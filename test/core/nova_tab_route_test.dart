import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/router/adaptive_layout/nova_tab_route.dart';
import 'package:hiddify/core/widget/nova_glass_tab_bar.dart';

void main() {
  test('maps production routes to the four Nova destinations', () {
    expect(novaTabForLocation('/home'), NovaTab.home);
    expect(novaTabForLocation('/home/proxies'), NovaTab.servers);
    expect(novaTabForLocation('/settings/routing-options'), NovaTab.rules);
    expect(novaTabForLocation('/settings/routing-options/rule/0'), NovaTab.rules);
    expect(novaTabForLocation('/settings'), NovaTab.settings);
    expect(novaTabForLocation('/settings/general'), NovaTab.settings);
  });
}
