import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/router/adaptive_layout/nova_tab_route.dart';
import 'package:hiddify/core/widget/nova_glass_tab_bar.dart';

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
}
