import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/warp_option/warp_option_notifier.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WarpOptionsPage extends HookConsumerWidget {
  const WarpOptionsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final warpOptions = ref.watch(warpOptionNotifierProvider);
    final isWarpEnabled = ref.watch(ConfigOptions.enableWarp);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.config.section.warp),
      ),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: Text(t.config.enableWarp),
            value: isWarpEnabled,
            onChanged: (value) async {
              await ref.read(ConfigOptions.enableWarp.notifier).update(value);
              if (value) await ref.read(warpOptionNotifierProvider.notifier).genWarps();
            },
          ),
          ListTile(
            title: Text(t.config.generateWarpConfig),
            subtitle: !isWarpEnabled
                ? null
                : warpOptions.when(
                    loading: () => null,
                    data: (_) => null,
                    error: (_, __) => Text(
                      t.config.missingWarpConfig,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
            trailing: warpOptions.isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()) : null,
            leading: const Icon(Icons.build_rounded),
            enabled: isWarpEnabled && !warpOptions.isLoading,
            onTap: warpOptions.isLoading
                ? null
                : () async {
                    await ref.read(warpOptionNotifierProvider.notifier).genWarps();
                  },
          ),
          ChoicePreferenceWidget(
            selected: ref.watch(ConfigOptions.warpDetourMode),
            preferences: ref.watch(ConfigOptions.warpDetourMode.notifier),
            enabled: isWarpEnabled,
            choices: WarpDetourMode.values,
            title: t.config.warpDetourMode,
            icon: Icons.alt_route_rounded,
            presentChoice: (value) => value.present(t),
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpLicenseKey),
            preferences: ref.watch(ConfigOptions.warpLicenseKey.notifier),
            enabled: isWarpEnabled,
            title: t.config.warpLicenseKey,
            icon: Icons.key_rounded,
            presentValue: (value) => value.isEmpty ? t.general.notSet : value,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpCleanIp),
            preferences: ref.watch(ConfigOptions.warpCleanIp.notifier),
            enabled: isWarpEnabled,
            title: t.config.warpCleanIp,
            icon: Icons.auto_awesome_rounded,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpPort),
            preferences: ref.watch(ConfigOptions.warpPort.notifier),
            enabled: isWarpEnabled,
            title: t.config.warpPort,
            icon: Icons.device_hub_rounded,
            inputToValue: int.tryParse,
            validateInput: isPort,
            digitsOnly: true,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoise),
            preferences: ref.watch(ConfigOptions.warpNoise.notifier),
            enabled: isWarpEnabled,
            title: t.config.warpNoise,
            icon: Icons.web_stories_rounded,
            inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoiseMode),
            preferences: ref.watch(ConfigOptions.warpNoiseMode.notifier),
            enabled: isWarpEnabled,
            title: t.config.warpNoiseMode,
            icon: Icons.mode_standby_rounded,
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoiseSize),
            preferences: ref.watch(ConfigOptions.warpNoiseSize.notifier),
            enabled: isWarpEnabled,
            title: t.config.warpNoiseSize,
            icon: Icons.settings_ethernet_rounded,
            inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
          ),
          ValuePreferenceWidget(
            value: ref.watch(ConfigOptions.warpNoiseDelay),
            preferences: ref.watch(ConfigOptions.warpNoiseDelay.notifier),
            enabled: isWarpEnabled,
            title: t.config.warpNoiseDelay,
            icon: Icons.schedule_rounded,
            inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
            presentValue: (value) => value.present(t),
            formatInputValue: (value) => value.format(),
          ),
        ],
      ),
    );
  }
}
