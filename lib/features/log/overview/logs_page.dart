import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/log/overview/logs_overview_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class LogsPage extends HookConsumerWidget with PresLogger {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final state = ref.watch(logsOverviewNotifierProvider);
    final notifier = ref.watch(logsOverviewNotifierProvider.notifier);

    final debug = ref.watch(debugModeNotifierProvider);
    final pathResolver = ref.watch(logPathResolverProvider);

    final filterController = useTextEditingController(text: state.filter);

    final List<PopupMenuEntry> popupButtons = debug || PlatformUtils.isDesktop
        ? [
            PopupMenuItem(
              child: Text(t.pages.logs.shareCoreLogs),
              onTap: () async {
                await UriUtils.tryShareOrLaunchFile(
                  Uri.parse(pathResolver.coreFile().path),
                  fileOrDir: pathResolver.directory.uri,
                );
              },
            ),
            PopupMenuItem(
              child: Text(t.pages.logs.shareAppLogs),
              onTap: () async {
                await UriUtils.tryShareOrLaunchFile(
                  Uri.parse(pathResolver.appFile().path),
                  fileOrDir: pathResolver.directory.uri,
                );
              },
            ),
          ]
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.logs.title),
        actions: [
          if (state.paused)
            IconButton(
              onPressed: notifier.resume,
              icon: const Icon(FluentIcons.play_20_regular),
              tooltip: t.common.resume,
              iconSize: 20,
            )
          else
            IconButton(
              onPressed: notifier.pause,
              icon: const Icon(FluentIcons.pause_20_regular),
              tooltip: t.common.pause,
              iconSize: 20,
            ),
          IconButton(
            onPressed: notifier.clear,
            icon: const Icon(FluentIcons.delete_lines_20_regular),
            tooltip: t.common.clear,
            iconSize: 20,
          ),
          if (popupButtons.isNotEmpty)
            PopupMenuButton(
              icon: Icon(AdaptiveIcon(context).more),
              itemBuilder: (context) {
                return popupButtons;
              },
            ),
          const Gap(8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: MultiSliver(
                children: [
                  // NestedAppBar(
                  //   forceElevated: innerBoxIsScrolled,
                  // ),
                  SliverPinnedHeader(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: filterController,
                                onChanged: notifier.filterMessage,
                                decoration: InputDecoration(isDense: true, hintText: t.common.filter),
                              ),
                            ),
                            const Gap(16),
                            DropdownButton<Option<LogLevel>>(
                              value: optionOf(state.levelFilter),
                              onChanged: (v) {
                                if (v == null) return;
                                notifier.filterLevel(v.toNullable());
                              },
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              borderRadius: BorderRadius.circular(4),
                              items: [
                                DropdownMenuItem(value: none(), child: Text(t.common.all)),
                                ...LogLevel.choices.map((e) => DropdownMenuItem(value: some(e), child: Text(e.name))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            return CustomScrollView(
              primary: false,
              reverse: true,
              slivers: <Widget>[
                switch (state.logs) {
                  AsyncData(value: final logs) => SliverList.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (log.level != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.level!.name.toUpperCase(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelMedium?.copyWith(color: log.level!.color),
                                      ),
                                      if (log.time != null)
                                        Text(log.time!.toString(), style: Theme.of(context).textTheme.labelSmall),
                                    ],
                                  ),
                                Text(extractMessage(log.message), style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (index != 0) const Divider(indent: 16, endIndent: 16, height: 4),
                        ],
                      );
                    },
                  ),
                  AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                  _ => const SliverLoadingBodyPlaceholder(),
                },
                SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}

String extractMessage(String message) {
  final parts = message.split(' ');
  return parts.length <= 2 ? parts.last : parts.sublist(2).join(' ');
}
