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

class DnsOptionsTiles extends HookConsumerWidget {
  const DnsOptionsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    return Column(
      children: [
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.remoteDnsAddress),
          preferences: ref.watch(ConfigOptions.remoteDnsAddress.notifier),
          title: t.config.remoteDnsAddress,
        ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
          preferences: ref.watch(ConfigOptions.remoteDnsDomainStrategy.notifier),
          choices: DomainStrategy.values,
          title: t.config.remoteDnsDomainStrategy,
          presentChoice: (value) => value.displayName,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.directDnsAddress),
          preferences: ref.watch(ConfigOptions.directDnsAddress.notifier),
          title: t.config.directDnsAddress,
        ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.directDnsDomainStrategy),
          preferences: ref.watch(ConfigOptions.directDnsDomainStrategy.notifier),
          choices: DomainStrategy.values,
          title: t.config.directDnsDomainStrategy,
          presentChoice: (value) => value.displayName,
        ),
        switchListTileAdaptive(
          context,
          title: t.config.enableDnsRouting,
          value: ref.watch(ConfigOptions.enableDnsRouting),
          onChanged: ref.read(ConfigOptions.enableDnsRouting.notifier).update,
        ),
        // const SettingsDivider(),
        // SettingsSection(experimental(t.config.section.mux)),
        // switchListTileAdaptive(
        // context,
        //   title: t.config.enableMux,
        //   value: ref.watch(ConfigOptions.enableMux),
        //   onChanged:
        //       ref.watch(ConfigOptions.enableMux.notifier).update,
        // ),
        // ChoicePreferenceWidget(
        //   selected: ref.watch(ConfigOptions.muxProtocol),
        //   preferences: ref.watch(ConfigOptions.muxProtocol.notifier),
        //   choices: MuxProtocol.values,
        //   title: t.config.muxProtocol,
        //   presentChoice: (value) => value.name,
        // ),
        // ValuePreferenceWidget(
        //   value: ref.watch(ConfigOptions.muxMaxStreams),
        //   preferences:
        //       ref.watch(ConfigOptions.muxMaxStreams.notifier),
        //   title: t.config.muxMaxStreams,
        //   inputToValue: int.tryParse,
        //   digitsOnly: true,
        // ),
      ],
    );
  }
}
