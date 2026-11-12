import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top_widgets.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    // the proxies keep top left at rest, under the list: shown at first, then folded or not as the user left them
    final showResting = ref.watch(Preferences.showSleepingProxies);

    // final selectActiveProxyMutation = useMutation(
    //   initialOnFailure: (error) => CustomToast.error(t.presentShortError(error)).show(context),
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.proxies.title),
        actions: [
          const KeepTopAction(),
          PopupMenuButton<ProxiesSort>(
            initialValue: sortBy,
            onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
            icon: const Icon(FluentIcons.arrow_sort_24_regular),
            tooltip: t.pages.proxies.sort,
            itemBuilder: (context) {
              return [...ProxiesSort.values.map((e) => PopupMenuItem(value: e, child: Text(e.present(t))))];
            },
          ),
          // "Signal style" (off by default) shows pings as the signal instead of numbers
          PopupMenuButton<bool>(
            onSelected: (_) => ref.read(proxyPingStyleNotifierProvider.notifier).toggle(),
            icon: Icon(AdaptiveIcon(context).more),
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            itemBuilder: (context) => [
              // a null value would close the menu as cancelled
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Checkbox(
                      value: ref.read(proxyPingStyleNotifierProvider) == ProxyPingStyle.signal,
                      // a tap on the box itself does what a tap on the item does
                      onChanged: (_) => Navigator.pop(context, true),
                    ),
                    const Gap(8),
                    Text(t.pages.proxies.signalStyle),
                  ],
                ),
              ),
            ],
          ),
          const Gap(8),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // the speed of the proxies listed: what it tests and the data it takes show first, and
          // it starts from there
          if (proxies.valueOrNull case final group?)
            FloatingActionButton.small(
              heroTag: 'upload-test',
              onPressed: () async {
                final count = group.items.where((e) => !e.isGroup && !e.resting).length;
                if (await ref.read(dialogNotifierProvider.notifier).showSpeedTest(count: count)) {
                  await ref.read(proxiesOverviewNotifierProvider.notifier).speedTestAll();
                }
              },
              tooltip: t.pages.proxies.speedTest.title,
              child: const Icon(Icons.speed_rounded, size: 26),
            ),
          const Gap(12),
          FloatingActionButton(
            onPressed: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest("select"),
            tooltip: t.pages.proxies.testDelay,
            child: const Icon(FluentIcons.flash_24_filled),
          ),
        ],
      ),
      body: proxies.when(
        data: (group) => group != null
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // columns wide enough for a proxy's name: two on a usual window, more only when wider
                  final crossAxisCount = PlatformUtils.isMobile && width < 600 ? 1 : max(1, (width / 420).floor());
                  // the proxies in use, then, folded, the ones keep top left at rest
                  final inUse = group.items.where((e) => !e.resting).toList();
                  final resting = group.items.where((e) => e.resting).toList();
                  final listed = inUse.where((e) => e.tag != lowestGroupTag && e.tag != balanceGroupTag).length;
                  Widget grid(List<OutboundInfo> items) => SliverGrid.builder(
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 72,
                    ),
                    itemBuilder: (context, index) {
                      final proxy = items[index];
                      return ProxyTile(
                        proxy,
                        // a row keeps its own proxy when the list re-sorts, so a pop plays only on arrival
                        key: ValueKey(proxy.tag),
                        selected: group.selected == proxy.tag,
                        // selecting one at rest loads it and tests it
                        onTap: () async {
                          await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, proxy.tag);
                        },
                      );
                    },
                  );
                  // a big profile: how many of its proxies run, and what changes it
                  final keepTop = SliverToBoxAdapter(
                    child: KeepTopFooter(listed: listed, picking: group.keepTopPicking, proxies: group.items),
                  );
                  return CustomScrollView(
                    slivers: [
                      // under the proxies that run; over the ones still being tested, none of which
                      // is kept yet
                      if (group.keepTopPicking) ...[
                        keepTop,
                        const SliverPadding(padding: EdgeInsets.only(top: 12)),
                        grid(inUse),
                      ] else ...[
                        grid(inUse),
                        keepTop,
                      ],
                      if (resting.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: RestingProxiesHeader(
                            count: resting.length,
                            shown: showResting,
                            onToggle: () => ref.read(Preferences.showSleepingProxies.notifier).update(!showResting),
                          ),
                        ),
                        if (showResting) grid(resting),
                      ],
                      // room for the buttons over the list's end
                      const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                    ],
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    ref.watch(serviceRunningProvider) ? t.pages.proxies.empty : t.pages.proxies.connectToSeeProxies,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.pages.proxies.loadFailed, textAlign: TextAlign.center),
                const Gap(12),
                TextButton(
                  onPressed: () => ref.invalidate(proxiesOverviewNotifierProvider),
                  child: Text(t.connection.tapToRetry),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
