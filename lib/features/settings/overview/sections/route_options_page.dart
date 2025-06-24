import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RouteOptionsPage extends HookConsumerWidget {
  const RouteOptionsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    final perAppProxy = ref.watch(Preferences.perAppProxyMode).enabled;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.config.section.route),
      ),
      body: ListView(
        children: [
          if (PlatformUtils.isAndroid)
            ListTile(
              title: Text(t.settings.network.perAppProxyPageTitle),
              leading: const Icon(Icons.apps_rounded),
              trailing: Switch(
                value: perAppProxy,
                onChanged: (value) async {
                  final newMode = perAppProxy ? PerAppProxyMode.off : PerAppProxyMode.exclude;
                  await ref.read(Preferences.perAppProxyMode.notifier).update(newMode);
                  if (!perAppProxy && context.mounted) context.goNamed('perAppProxy');
                },
              ),
              onTap: () async {
                if (!perAppProxy) {
                  await ref.read(Preferences.perAppProxyMode.notifier).update(PerAppProxyMode.exclude);
                }
                if (context.mounted) context.goNamed('perAppProxy');
              },
            ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.region),
            preferences: ref.watch(ConfigOptions.region.notifier),
            choices: Region.values,
            title: t.settings.general.region,
            icon: Icons.place_rounded,
            presentChoice: (value) => value.present(t),
            onChanged: (val) => ref.read(ConfigOptions.directDnsAddress.notifier).reset(),
          ),
          SwitchListTile.adaptive(
            title: Text(experimental(t.config.blockAds)),
            secondary: const Icon(Icons.block_rounded),
            value: ref.watch(ConfigOptions.blockAds),
            onChanged: ref.read(ConfigOptions.blockAds.notifier).update,
          ),
          SwitchListTile.adaptive(
            title: Text(experimental(t.config.bypassLan)),
            secondary: const Icon(Icons.call_split_rounded),
            value: ref.watch(ConfigOptions.bypassLan),
            onChanged: ref.read(ConfigOptions.bypassLan.notifier).update,
          ),
          SwitchListTile.adaptive(
            title: Text(t.config.resolveDestination),
            secondary: const Icon(Icons.security_rounded),
            value: ref.watch(ConfigOptions.resolveDestination),
            onChanged: ref.read(ConfigOptions.resolveDestination.notifier).update,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.ipv6Mode),
            preferences: ref.watch(ConfigOptions.ipv6Mode.notifier),
            choices: IPv6Mode.values,
            title: t.config.ipv6Mode,
            icon: Icons.looks_6_rounded,
            presentChoice: (value) => value.present(t),
          ),
        ],
      ),
    );
  }
}
