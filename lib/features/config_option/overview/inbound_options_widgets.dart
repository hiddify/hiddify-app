import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InboundOptionsTiles extends HookConsumerWidget {
  const InboundOptionsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    return Column(
      children: [
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.serviceMode),
          preferences: ref.watch(ConfigOptions.serviceMode.notifier),
          choices: ServiceMode.choices,
          title: t.config.serviceMode,
          presentChoice: (value) => value.present(t),
        ),
        switchListTileAdaptive(
          context,
          title: t.config.strictRoute,
          value: ref.watch(ConfigOptions.strictRoute),
          onChanged: ref.read(ConfigOptions.strictRoute.notifier).update,
        ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.tunImplementation),
          preferences: ref.watch(ConfigOptions.tunImplementation.notifier),
          choices: TunImplementation.values,
          title: t.config.tunImplementation,
          presentChoice: (value) => value.name,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.mixedPort),
          preferences: ref.watch(ConfigOptions.mixedPort.notifier),
          title: t.config.mixedPort,
          inputToValue: int.tryParse,
          digitsOnly: true,
          validateInput: isPort,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.tproxyPort),
          preferences: ref.watch(ConfigOptions.tproxyPort.notifier),
          title: t.config.tproxyPort,
          inputToValue: int.tryParse,
          digitsOnly: true,
          validateInput: isPort,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.localDnsPort),
          preferences: ref.watch(ConfigOptions.localDnsPort.notifier),
          title: t.config.localDnsPort,
          inputToValue: int.tryParse,
          digitsOnly: true,
          validateInput: isPort,
        ),
        switchListTileAdaptive(
          context,
          title: experimental(t.config.allowConnectionFromLan),
          value: ref.watch(ConfigOptions.allowConnectionFromLan),
          onChanged: ref.read(ConfigOptions.allowConnectionFromLan.notifier).update,
        ),
      ],
    );
  }
}
