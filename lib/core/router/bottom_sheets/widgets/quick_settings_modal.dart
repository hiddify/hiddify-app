import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuickSettingsModal extends HookConsumerWidget {
  const QuickSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = BlizzardPresentation.themeOf(context);
    final blizzard =
        BlizzardPresentation.isActive(context) || (theme.extension<BlizzardEligibility>()?.applied ?? false);

    return BlizzardPresentation(
      child: ColoredBox(
        color: BlizzardPresentation.isActive(context)
            ? BlizzardPresentation.themeOf(context).colorScheme.surface
            : Colors.transparent,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (blizzard)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(t.pages.home.quickSettings, style: theme.textTheme.titleLarge),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: blizzard ? 0 : 16),
                  child: SizedBox(
                    height: blizzard ? 44 : null,
                    child: SegmentedButton(
                      showSelectedIcon: false,
                      // A non-null zero inset opts into equal-width expanded segments.
                      expandedInsets: blizzard ? EdgeInsets.zero : null,
                      style: blizzard
                          ? ButtonStyle(
                              shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
                              side: WidgetStatePropertyAll(BorderSide(color: theme.colorScheme.outline)),
                            )
                          : null,
                      segments: ServiceMode.choices
                          .map(
                            (e) => ButtonSegment(
                              value: e,
                              label: Padding(
                                padding: EdgeInsets.symmetric(vertical: blizzard ? 0 : 8),
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
                ),
                Gap(blizzard ? 18 : 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: blizzard ? 16 : 0),
                  child: SizedBox(
                    height: blizzard && MediaQuery.textScalerOf(context).scale(16) <= 20 ? 66 : null,
                    child: ListTile(
                      minTileHeight: blizzard ? 66 : null,
                      minVerticalPadding: blizzard ? 0 : null,
                      dense: blizzard ? true : null,
                      contentPadding: blizzard ? const EdgeInsets.symmetric(horizontal: 16) : null,
                      horizontalTitleGap: blizzard ? 16 : null,
                      leading: Icon(Icons.settings_outlined, size: blizzard ? 22 : null),
                      title: Text(
                        ref.watch(ConfigOptions.warpDetourMode).presentExplain(t),
                        style: blizzard ? theme.textTheme.bodyMedium?.copyWith(fontSize: 16) : null,
                      ),
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
        ),
      ),
    );
  }
}
