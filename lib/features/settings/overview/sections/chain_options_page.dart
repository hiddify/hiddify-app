import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/notifier/chain_profile_notifier.dart';
import 'package:hiddify/features/chain/overview/chain_timeline.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChainOptionsPage extends HookConsumerWidget {
  const ChainOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final profiles = ref.watch(profilesNotifierProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(t.pages.settings.chain.title)),
      body: ListView(
        children: [
          const ChainTimeline(level: ChainTimelineLevel.app),
          ChainTimeline(
            level: ChainTimelineLevel.extraSecurity,
            childeren: ref.watch(ConfigOptions.chainStatus).isExtraSecurity()
                ? switch (ref.watch(ConfigOptions.extraSecurityMode)) {
                    ChainMode.psiphon => [
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.extraSecurityPsiphonRegion),
                        preferences: ref.watch(ConfigOptions.extraSecurityPsiphonRegion.notifier),
                        choices: PsiphonRegion.values,
                        title: t.pages.settings.chain.psiphon.selectServerRegion,
                        showFlag: true,
                        icon: Icons.place_rounded,
                        presentChoice: (value) => value.present(t),
                        onChanged: (val) async {
                          await ref.read(ConfigOptions.extraSecurityPsiphonRegion.notifier).update(val);
                        },
                      ),
                    ],
                    ChainMode.warp => [
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.extraSecurityWarpLicenseKey),
                        preferences: ref.watch(ConfigOptions.extraSecurityWarpLicenseKey.notifier),
                        title: t.pages.settings.chain.warp.licenseKey,
                        icon: Icons.key_rounded,
                        presentValue: (value) => value.isEmpty ? t.common.notSet : value,
                      ),
                    ],
                    ChainMode.profile => [
                      ChoicePreferenceWidget(
                        selected: ref.watch(chainProfileNotifierProvider(ChainType.extraSecurity)).value,
                        preferences: ref.watch(ConfigOptions.extraSecurityProfileId.notifier),
                        choices: profiles,
                        title: t.pages.settings.chain.profile.selectProfile,
                        icon: Icons.view_list_rounded,
                        presentChoice: (value) => (value as ProfileEntity?)?.name ?? '',
                        autoUpdate: false,
                        onChanged: (val) async {
                          if (val is ProfileEntity) {
                            await ref.read(ConfigOptions.extraSecurityProfileId.notifier).update(val.id);
                          }
                        },
                      ),
                    ],
                  }
                : [],
          ),
          ChainTimeline(
            level: ChainTimelineLevel.mainProfile,
            childeren: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Text(
                  ref.watch(activeProfileProvider).value?.name ?? t.common.notSet,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ChainTimeline(
            level: ChainTimelineLevel.unblocker,
            childeren: ref.watch(ConfigOptions.chainStatus).isUnblocker()
                ? switch (ref.watch(ConfigOptions.unblockerMode)) {
                    ChainMode.psiphon => [
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.unblockerPsiphonRegion),
                        preferences: ref.watch(ConfigOptions.unblockerPsiphonRegion.notifier),
                        choices: PsiphonRegion.values,
                        title: t.pages.settings.chain.psiphon.selectServerRegion,
                        showFlag: true,
                        icon: Icons.place_rounded,
                        presentChoice: (value) => value.present(t),
                        onChanged: (val) async {
                          await ref.read(ConfigOptions.unblockerPsiphonRegion.notifier).update(val);
                        },
                      ),
                    ],
                    ChainMode.warp => [
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.extraSecurityWarpLicenseKey),
                        preferences: ref.watch(ConfigOptions.extraSecurityWarpLicenseKey.notifier),
                        title: t.pages.settings.chain.warp.licenseKey,
                        icon: Icons.key_rounded,
                        presentValue: (value) => value.isEmpty ? t.common.notSet : value,
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.unblockerWarpCleanIp),
                        preferences: ref.watch(ConfigOptions.unblockerWarpCleanIp.notifier),
                        title: t.pages.settings.chain.warp.cleanIp,
                        icon: Icons.auto_awesome_rounded,
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.unblockerWarpPort),
                        preferences: ref.watch(ConfigOptions.unblockerWarpPort.notifier),
                        title: t.pages.settings.chain.warp.port,
                        icon: Icons.device_hub_rounded,
                        inputToValue: int.tryParse,
                        validateInput: isPort,
                        digitsOnly: true,
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.unblockerWarpNoise),
                        preferences: ref.watch(ConfigOptions.unblockerWarpNoise.notifier),
                        title: t.pages.settings.chain.warp.noise.count,
                        icon: Icons.web_stories_rounded,
                        inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
                        presentValue: (value) => value.present(t),
                        formatInputValue: (value) => value.format(),
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.unblockerWarpNoiseMode),
                        preferences: ref.watch(ConfigOptions.unblockerWarpNoiseMode.notifier),
                        title: t.pages.settings.chain.warp.noise.mode,
                        icon: Icons.mode_standby_rounded,
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.unblockerWarpNoiseSize),
                        preferences: ref.watch(ConfigOptions.unblockerWarpNoiseSize.notifier),
                        title: t.pages.settings.chain.warp.noise.size,
                        icon: Icons.settings_ethernet_rounded,
                        inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
                        presentValue: (value) => value.present(t),
                        formatInputValue: (value) => value.format(),
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.unblockerWarpNoiseDelay),
                        preferences: ref.watch(ConfigOptions.unblockerWarpNoiseDelay.notifier),
                        title: t.pages.settings.chain.warp.noise.delay,
                        icon: Icons.schedule_rounded,
                        inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
                        presentValue: (value) => value.present(t),
                        formatInputValue: (value) => value.format(),
                      ),
                    ],
                    ChainMode.profile => [
                      ChoicePreferenceWidget(
                        selected: ref.watch(chainProfileNotifierProvider(ChainType.unblocker)).value,
                        preferences: ref.watch(ConfigOptions.unblockerProfileId.notifier),
                        choices: profiles,
                        title: t.pages.settings.chain.profile.selectProfile,
                        icon: Icons.view_list_rounded,
                        presentChoice: (value) => (value as ProfileEntity?)?.name ?? '',
                        autoUpdate: false,
                        onChanged: (val) async {
                          if (val is ProfileEntity) {
                            await ref.read(ConfigOptions.unblockerProfileId.notifier).update(val.id);
                          }
                        },
                      ),
                    ],
                  }
                : [],
          ),
          const ChainTimeline(level: ChainTimelineLevel.filtering),
        ],
      ),
    );
  }
}

// SwitchListTile.adaptive(
//   title: Text(t.pages.settings.warp.enable),
//   value: isWarpEnabled,
//   secondary: const Icon(Icons.cloud_rounded),
//   onChanged: (value) async {
//     await ref.read(ConfigOptions.enableWarp.notifier).update(value);
//     if (value) await ref.read(warpOptionNotifierProvider.notifier).genWarps();
//   },
// ),
// ListTile(
//   title: Text(t.pages.settings.warp.generateConfig),
//   subtitle: !isWarpEnabled
//       ? null
//       : warpOptions.when(
//           loading: () => null,
//           data: (_) => null,
//           error: (_, _) =>
//               Text(t.pages.settings.warp.missingConfig, style: TextStyle(color: theme.colorScheme.error)),
//         ),
//   trailing: warpOptions.isLoading
//       ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
//       : null,
//   leading: const Icon(Icons.build_rounded),
//   enabled: isWarpEnabled && !warpOptions.isLoading,
//   onTap: warpOptions.isLoading
//       ? null
//       : () async {
//           await ref.read(warpOptionNotifierProvider.notifier).genWarps();
//         },
// ),
// ChoicePreferenceWidget(
//   selected: ref.watch(ConfigOptions.warpDetourMode),
//   preferences: ref.watch(ConfigOptions.warpDetourMode.notifier),
//   enabled: isWarpEnabled,
//   choices: WarpDetourMode.values,
//   title: t.pages.settings.warp.detourMode,
//   icon: Icons.alt_route_rounded,
//   presentChoice: (value) => value.present(t),
// ),
