import 'package:hiddify/core/widget/nova_glass_tab_bar.dart';

NovaTab novaTabForLocation(String location) {
  if (location.startsWith('/home/proxies')) return NovaTab.servers;
  if (location.startsWith('/settings/routing-options')) return NovaTab.rules;
  if (location.startsWith('/settings')) return NovaTab.settings;
  return NovaTab.home;
}
