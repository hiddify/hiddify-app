import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/warp_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuickSettingsModal extends HookConsumerWidget {
  const QuickSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final warpPrefaceCompleted = ref.watch(warpOptionNotifierProvider).consentGiven;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton(
              segments: ServiceMode.choices
                  .map(
                    (e) => ButtonSegment(
                      value: e,
                      label: Text(
                        e.presentShort(t),
                        overflow: TextOverflow.ellipsis,
                      ),
                      tooltip: e.isExperimental ? t.settings.experimental : null,
                    ),
                  )
                  .toList(),
              selected: {ref.watch(ConfigOptions.serviceMode)},
              onSelectionChanged: (newSet) => ref.read(ConfigOptions.serviceMode.notifier).update(newSet.first),
            ),
          ),
          const Gap(8),
          if (warpPrefaceCompleted)
            GestureDetector(
              onLongPress: () {
                ConfigOptionsRoute(section: ConfigOptionSection.warp.name).go(context);
              },
              child: SwitchListTile.adaptive(
                value: ref.watch(ConfigOptions.enableWarp),
                onChanged: ref.watch(ConfigOptions.enableWarp.notifier).update,
                title: Text(t.config.enableWarp),
              ),
            )
          else
            PlatformListTile(
              title: Text(t.config.setupWarp),
              trailing: const Icon(FluentIcons.chevron_right_24_regular),
              onTap: () => ConfigOptionsRoute(section: ConfigOptionSection.warp.name).go(context),
            ),
          GestureDetector(
            onLongPress: () {
              ConfigOptionsRoute(section: ConfigOptionSection.fragment.name).go(context);
            },
            child: SwitchListTile.adaptive(
              value: ref.watch(ConfigOptions.enableTlsFragment),
              onChanged: ref.watch(ConfigOptions.enableTlsFragment.notifier).update,
              title: Text(t.config.enableTlsFragment),
            ),
          ),
          // SwitchListTile.adaptive(
          //   value: ref.watch(ConfigOptions.enableMux),
          //   onChanged: ref.watch(ConfigOptions.enableMux.notifier).update,
          //   title: Text(t.config.enableMux),
          // ),
          PlatformListTile(
            title: Text(t.config.allOptions),
            trailing: const Icon(FluentIcons.chevron_right_24_regular),
            material: (context, platform) => MaterialListTileData(
              dense: true,
            ),
            onTap: () => const ConfigOptionsRoute().go(context),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}
