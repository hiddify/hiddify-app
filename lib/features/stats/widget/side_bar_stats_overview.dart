import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/stats/model/stats_entity.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/features/stats/widget/connection_stats_card.dart';
import 'package:hiddify/features/stats/widget/stats_card.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final showAllSidebarStatsProvider = PreferencesNotifier.createAutoDispose(
  "show_all_sidebar_stats",
  false,
);

class SideBarStatsOverview extends HookConsumerWidget {
  const SideBarStatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final stats =
        ref.watch(statsNotifierProvider).asData?.value ?? StatsEntity.empty();
    final showAll = ref.watch(showAllSidebarStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: SizedBox(
              height: 18,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: Theme.of(context).textTheme.labelSmall,
                ),
                onPressed: () {
                  ref
                      .read(showAllSidebarStatsProvider.notifier)
                      .update(!showAll);
                },
                icon: AnimatedRotation(
                  turns: showAll ? 1 : 0.5,
                  duration: kAnimationDuration,
                  child: const Icon(
                    FluentIcons.chevron_down_16_regular,
                    size: 16,
                  ),
                ),
                label: AnimatedText(
                  showAll ? t.general.showLess : t.general.showMore,
                ),
              ),
            ),
          ),
          const ConnectionStatsCard(),
          const Gap(8),
          AnimatedCrossFade(
            crossFadeState:
                showAll ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: kAnimationDuration,
            firstChild: StatsCard(
              title: t.stats.traffic,
              stats: [
                (
                  label: const Icon(FluentIcons.arrow_download_16_regular),
                  data: Text(stats.downlink.speed()),
                  semanticLabel: t.stats.speed,
                ),
                (
                  label: const Icon(
                    FluentIcons.arrow_bidirectional_up_down_16_regular,
                  ),
                  data: Text(stats.downlinkTotal.size()),
                  semanticLabel: t.stats.totalTransferred,
                ),
              ],
            ),
            secondChild: Column(
              children: [
                StatsCard(
                  title: t.stats.trafficLive,
                  stats: [
                    (
                      label: const Text(
                        "↑",
                        style: TextStyle(color: Colors.green),
                      ),
                      data: Text(stats.uplink.speed()),
                      semanticLabel: t.stats.uplink,
                    ),
                    (
                      label: Text(
                        "↓",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      data: Text(stats.downlink.speed()),
                      semanticLabel: t.stats.downlink,
                    ),
                  ],
                ),
                const Gap(8),
                StatsCard(
                  title: t.stats.trafficTotal,
                  stats: [
                    (
                      label: const Text(
                        "↑",
                        style: TextStyle(color: Colors.green),
                      ),
                      data: Text(stats.uplinkTotal.size()),
                      semanticLabel: t.stats.uplink,
                    ),
                    (
                      label: Text(
                        "↓",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      data: Text(stats.downlinkTotal.size()),
                      semanticLabel: t.stats.downlink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
