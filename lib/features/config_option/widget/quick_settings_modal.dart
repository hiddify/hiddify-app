import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/custom_text_scroll.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/overview/PlatformListSection.dart';
import 'package:hiddify/features/config_option/overview/tlsfragment_widgets.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuickSettingsModal extends HookConsumerWidget {
  const QuickSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final warpLabel = (ref.watch(ConfigOptions.warpDetourMode) == WarpDetourMode.warpOverProxy) ? t.config.enableWarpSecure : t.config.enableWarpForProxy;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
              child: SegmentedButton(
                segments: ServiceMode.choices
                    .map(
                      (e) => ButtonSegment(
                        value: e,
                        label: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: CustomTextScroll(
                            e.presentShort(t),
                          ),
                        ),
                        tooltip: e.isExperimental ? t.settings.experimental : null,
                      ),
                    )
                    .toList(),
                selected: {ref.watch(ConfigOptions.serviceMode)},
                onSelectionChanged: (newSet) => ref.read(ConfigOptions.serviceMode.notifier).update(newSet.first),
              ),
            ),
            const Gap(12),
            PlatformListSection(
              sectionIcon: const Icon(FontAwesomeIcons.cloudflare),
              sectionTitle: warpLabel,
              title: SwitchListTile.adaptive(
                value: ref.watch(ConfigOptions.enableWarp),
                onChanged: ref.watch(ConfigOptions.enableWarp.notifier).update,
                title: Text(warpLabel),
              ),
              items: const [
                WarpOptionsTiles(),
              ],
              bottomSheet: true,
            ),
            PlatformListSection(
              sectionIcon: const Icon(FontAwesomeIcons.expeditedssl),
              sectionTitle: t.config.section.tlsTricks,
              title: SwitchListTile.adaptive(
                value: ref.watch(ConfigOptions.enableTlsFragment),
                onChanged: ref.watch(ConfigOptions.enableTlsFragment.notifier).update,
                title: Text(t.config.enableTlsFragment),
              ),
              items: const [
                TlsfragmentTiles(),
              ],
              bottomSheet: true,
            ),
            // const AboutPage()

            // GestureDetector(
            //   onLongPress: () {
            //     ConfigOptionsRoute(section: ConfigOptionSection.warp.name).go(context);
            //   },
            //   child:
            // )
            // else
            //   ListTile(
            //     title: Text(t.config.setupWarp),
            //     trailing: const Icon(FluentIcons.chevron_right_24_regular),
            //     onTap: () => ConfigOptionsRoute(section: ConfigOptionSection.warp.name).go(context),
            //   ),

            // SwitchListTile.adaptive(
            //   value: ref.watch(ConfigOptions.enableMux),
            //   onChanged: ref.watch(ConfigOptions.enableMux.notifier).update,
            //   title: Text(t.config.enableMux),
            // ),
            // PlatformListSection(
            //   sectionIcon: const Icon(FluentIcons.settings_20_filled),
            //   sectionTitle: t.config.allOptions,
            //   items: [
            //     ConfigOptionsPage(),
            //   ],
            // ),

            const Gap(16),
          ],
        ),
      ),
    );
  }
}
