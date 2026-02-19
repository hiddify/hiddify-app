import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/warp_option/warp_option_notifier.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuickSettingsModal extends HookConsumerWidget {
  const QuickSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
              child: SegmentedButton(
                showSelectedIcon: false,
                segments: ServiceMode.choices
                    .map(
                      (e) => ButtonSegment(
                        value: e,
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(e.presentShort(t), textAlign: TextAlign.center),
                        ),
                        // tooltip: e.isExperimental ? t.settings.experimental : null,
                      ),
                    )
                    .toList(),
                selected: {ref.watch(ConfigOptions.serviceMode)},
                onSelectionChanged: (newSet) => ref.read(ConfigOptions.serviceMode.notifier).update(newSet.first),
              ),
            ),
            const Gap(12),
            ListTile(
              leading: const Icon(Icons.cloud_rounded),
              title: Text(ref.watch(ConfigOptions.warpDetourMode).presentExplain(t)),
              onLongPress: () {
                context.pop();
                context.goNamed('warpOptions');
              },
              onTap: () async {
                final value = ref.watch(ConfigOptions.enableWarp);
                await ref.read(ConfigOptions.enableWarp.notifier).update(!value);
              },
              trailing: Switch.adaptive(
                value: ref.watch(ConfigOptions.enableWarp),
                onChanged: (value) async {
                  await ref.read(ConfigOptions.enableWarp.notifier).update(value);
                  // await ref.read(warpOptionNotifierProvider.notifier).genWarps();
                },
              ),
            ),
            // ListTile(

            //   leading: const Icon(Icons.content_cut_rounded),
            //   title: Text(t.pages.settings.tlsTricks.title),
            //   onTap: () {
            //     context.pop();
            //     context.goNamed('tlsTricks');
            //   },
            //   trailing: Switch.adaptive(
            //     value: ref.watch(ConfigOptions.enableTlsFragment),
            //     onChanged: ref.read(ConfigOptions.enableTlsFragment.notifier).update,
            //   ),
            // ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}
