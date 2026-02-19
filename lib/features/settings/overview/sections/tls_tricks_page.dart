import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TlsTricksPage extends HookConsumerWidget {
  const TlsTricksPage({super.key});
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
