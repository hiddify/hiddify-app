import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TlsfragmentTiles extends HookConsumerWidget {
  const TlsfragmentTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final canChangeOption = ref.watch(ConfigOptions.enableTlsFragment);

    return Column(
      children: [
        switchListTileAdaptive(
          context,
          title: t.config.enableTlsFragment,
          value: ref.watch(ConfigOptions.enableTlsFragment),
          onChanged: ref.read(ConfigOptions.enableTlsFragment.notifier).update,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.tlsFragmentSize),
          preferences: ref.watch(ConfigOptions.tlsFragmentSize.notifier),
          title: t.config.tlsFragmentSize,
          inputToValue: OptionalRange.tryParse,
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
          enabled: canChangeOption,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.tlsFragmentSleep),
          preferences: ref.watch(ConfigOptions.tlsFragmentSleep.notifier),
          title: t.config.tlsFragmentSleep,
          inputToValue: OptionalRange.tryParse,
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
          enabled: canChangeOption,
        ),
        switchListTileAdaptive(
          context,
          title: t.config.enableTlsMixedSniCase,
          value: ref.watch(ConfigOptions.enableTlsMixedSniCase),
          // onChanged: ref.read(ConfigOptions.enableTlsMixedSniCase.notifier).update,
          onChanged: canChangeOption ? ref.read(ConfigOptions.enableTlsMixedSniCase.notifier).update : null,
        ),
        switchListTileAdaptive(
          context,
          title: t.config.enableTlsPadding,
          value: ref.watch(ConfigOptions.enableTlsPadding),
          onChanged: canChangeOption ? ref.read(ConfigOptions.enableTlsPadding.notifier).update : null,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.tlsPaddingSize),
          preferences: ref.watch(ConfigOptions.tlsPaddingSize.notifier),
          title: t.config.tlsPaddingSize,
          inputToValue: OptionalRange.tryParse,
          presentValue: (value) => value.format(),
          formatInputValue: (value) => value.format(),
          enabled: canChangeOption,
        ),
      ],
    );
  }
}
