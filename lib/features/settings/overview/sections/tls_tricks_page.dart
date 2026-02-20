import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TlsTricksPage extends HookConsumerWidget {
  const TlsTricksPage({super.key});

  String _presentFragmentPackets(TranslationsEn t, String value) => switch (value) {
    "tlshello" => t.pages.settings.tlsTricks.packetsTlsHello,
    "1-1" => t.pages.settings.tlsTricks.packets1_1,
    "1-2" => t.pages.settings.tlsTricks.packets1_2,
    "1-3" => t.pages.settings.tlsTricks.packets1_3,
    "1-4" => t.pages.settings.tlsTricks.packets1_4,
    "1-5" => t.pages.settings.tlsTricks.packets1_5,
    _ => value,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final canChangeOption = ref.watch(ConfigOptions.enableTlsFragment);
    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.tlsTricks.title)),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.tlsTricks.enable),
            value: ref.watch(ConfigOptions.enableTlsFragment),
            secondary: const Icon(Icons.content_cut_rounded),
            onChanged: ref.read(ConfigOptions.enableTlsFragment.notifier).update,
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.fragmentPackets),
            preferences: ref.watch(ConfigOptions.fragmentPackets.notifier),
            choices: ["tlshello", "1-1", "1-2", "1-3", "1-4", "1-5"],
            title: t.pages.settings.tlsTricks.packets,
            icon: Icons.layers_rounded,
            presentChoice: (value) => _presentFragmentPackets(t, value),
            enabled: canChangeOption,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.tlsFragmentSize),
            preferences: ref.watch(ConfigOptions.tlsFragmentSize.notifier),
            title: t.pages.settings.tlsTricks.size,
            icon: Icons.straighten_rounded,
            inputToValue: OptionalRange.tryParse,
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
            enabled: canChangeOption,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.tlsFragmentSleep),
            preferences: ref.watch(ConfigOptions.tlsFragmentSleep.notifier),
            title: t.pages.settings.tlsTricks.sleep,
            icon: Icons.snooze_rounded,
            inputToValue: OptionalRange.tryParse,
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
            enabled: canChangeOption,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.tlsTricks.mixedSniCase.enable),
            value: ref.watch(ConfigOptions.enableTlsMixedSniCase),
            secondary: const Icon(Icons.text_fields_rounded),
            onChanged: canChangeOption ? ref.read(ConfigOptions.enableTlsMixedSniCase.notifier).update : null,
          ),
          SwitchListTile.adaptive(
            title: Text(t.pages.settings.tlsTricks.padding.enable),
            value: ref.watch(ConfigOptions.enableTlsPadding),
            secondary: const Icon(Icons.expand_rounded),
            onChanged: canChangeOption ? ref.read(ConfigOptions.enableTlsPadding.notifier).update : null,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.tlsPaddingSize),
            preferences: ref.watch(ConfigOptions.tlsPaddingSize.notifier),
            title: t.pages.settings.tlsTricks.padding.size,
            icon: Icons.straighten_rounded,
            inputToValue: OptionalRange.tryParse,
            presentValue: (value) => value.format(),
            formatInputValue: (value) => value.format(),
            enabled: canChangeOption,
          ),
        ],
      ),
    );
  }
}
