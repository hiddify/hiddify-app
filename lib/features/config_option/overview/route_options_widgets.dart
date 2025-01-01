import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/core/widget/custom_alert_dialog.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/warp_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hiddify/utils/validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RouteOptionsTiles extends HookConsumerWidget {
  const RouteOptionsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    final perAppProxy = ref.watch(Preferences.perAppProxyMode).enabled;

    return Column(
      children: [
        if (PlatformUtils.isAndroid)
          ListTile(
            title: Text(t.settings.network.perAppProxyPageTitle),
            leading: const Icon(FluentIcons.apps_list_detail_24_regular),
            trailing: Switch(
              value: perAppProxy,
              onChanged: (value) async {
                final newMode = perAppProxy ? PerAppProxyMode.off : PerAppProxyMode.exclude;
                await ref.read(Preferences.perAppProxyMode.notifier).update(newMode);
                if (!perAppProxy && context.mounted) {
                  const PerAppProxyRoute().go(context);
                }
              },
            ),
            onTap: () async {
              if (!perAppProxy) {
                await ref.read(Preferences.perAppProxyMode.notifier).update(PerAppProxyMode.exclude);
              }
              // if (context.mounted) await const PerAppProxyRoute().push(context);
            },
          ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.region),
          preferences: ref.watch(ConfigOptions.region.notifier),
          choices: Region.values,
          title: t.settings.general.region,
          presentChoice: (value) => value.present(t),
          onChanged: (val) => ref.read(ConfigOptions.directDnsAddress.notifier).reset(),
        ),
        switchListTileAdaptive(
          context,
          title: experimental(t.config.blockAds),
          value: ref.watch(ConfigOptions.blockAds),
          onChanged: ref.read(ConfigOptions.blockAds.notifier).update,
        ),
        switchListTileAdaptive(
          context,
          title: experimental(t.config.bypassLan),
          value: ref.watch(ConfigOptions.bypassLan),
          onChanged: ref.read(ConfigOptions.bypassLan.notifier).update,
        ),
        switchListTileAdaptive(
          context,
          title: t.config.resolveDestination,
          value: ref.watch(ConfigOptions.resolveDestination),
          onChanged: ref.read(ConfigOptions.resolveDestination.notifier).update,
        ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.ipv6Mode),
          preferences: ref.watch(ConfigOptions.ipv6Mode.notifier),
          choices: IPv6Mode.values,
          title: t.config.ipv6Mode,
          presentChoice: (value) => value.present(t),
        ),
      ],
    );
  }
}
