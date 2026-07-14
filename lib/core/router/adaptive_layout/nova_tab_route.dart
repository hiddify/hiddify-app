import 'package:hiddify/core/widget/nova_glass_tab_bar.dart';

enum NovaTabReselectionAction { resetShellBranch, goToProxiesRoot, goToRoutingOptionsRoot }

NovaTab novaTabForLocation(String location) {
  if (location.startsWith('/home/proxies')) return NovaTab.servers;
  if (location.startsWith('/settings/routing-options')) return NovaTab.rules;
  if (location.startsWith('/settings')) return NovaTab.settings;
  return NovaTab.home;
}

bool shouldResetNovaBranch({required NovaTab current, required NovaTab requested}) => current == requested;

NovaTabReselectionAction novaTabReselectionAction(NovaTab tab) => switch (tab) {
  NovaTab.home || NovaTab.settings => NovaTabReselectionAction.resetShellBranch,
  NovaTab.servers => NovaTabReselectionAction.goToProxiesRoot,
  NovaTab.rules => NovaTabReselectionAction.goToRoutingOptionsRoot,
};
