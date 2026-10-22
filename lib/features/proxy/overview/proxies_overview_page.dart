import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_backdrop.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    final activeProfileName = ref.watch(activeProfileProvider).valueOrNull?.name;
    final presentationTheme = BlizzardPresentation.themeOf(context);
    final blizzard =
        BlizzardPresentation.isActive(context) ||
        (presentationTheme.extension<BlizzardEligibility>()?.applied ?? false);
    final delayTestAction = FloatingActionButton.extended(
      key: blizzard ? const ValueKey('servers_test_delay_button') : null,
      onPressed: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest("select"),
      tooltip: t.pages.proxies.testDelay,
      isExtended: blizzard,
      icon: blizzard ? null : const Icon(FluentIcons.flash_24_filled),
      label: blizzard ? Text(t.pages.proxies.testDelay) : const SizedBox.shrink(),
      foregroundColor: blizzard ? BlizzardPalette.accent : null,
      backgroundColor: blizzard ? BlizzardPalette.elevated : null,
      elevation: blizzard ? 0 : null,
      shape: blizzard ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(BlizzardRadii.row)) : null,
    );

    // final selectActiveProxyMutation = useMutation(
    //   initialOnFailure: (error) => CustomToast.error(t.presentShortError(error)).show(context),
    // );

    return BlizzardPresentation(
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: blizzard ? 68 : null,
          leading: blizzard
              ? const Padding(
                  padding: EdgeInsetsDirectional.only(start: 12, top: 4, bottom: 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox.square(
                      dimension: 48,
                      child: Material(
                        key: ValueKey('servers_back_button'),
                        color: BlizzardPalette.surface,
                        shape: CircleBorder(side: BorderSide(color: BlizzardPalette.separator)),
                        clipBehavior: Clip.antiAlias,
                        child: BackButton(),
                      ),
                    ),
                  ),
                )
              : null,
          title: Text(blizzard ? _serversTitle(t.$meta.locale) : t.pages.proxies.title),
          actions: [
            PopupMenuButton<ProxiesSort>(
              initialValue: sortBy,
              onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
              icon: const Icon(FluentIcons.arrow_sort_24_regular),
              tooltip: t.pages.proxies.sort,
              itemBuilder: (context) {
                return [...ProxiesSort.values.map((e) => PopupMenuItem(value: e, child: Text(e.present(t))))];
              },
            ),
            const Gap(8),
          ],
        ),
        floatingActionButton: blizzard ? null : delayTestAction,
        body: BlizzardBackdrop(
          child: proxies.when(
            data: (group) => group != null
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = PlatformUtils.isMobile && width < 600 ? 1 : max(1, (width / 268).floor());
                      final grid = GridView.builder(
                        key: const ValueKey('servers_grid'),
                        padding: blizzard
                            ? const EdgeInsets.fromLTRB(20, 0, 20, 112)
                            : const EdgeInsets.only(bottom: 86),
                        itemCount: group.items.length + (blizzard ? 1 : 0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: blizzard ? max(80, 48 + MediaQuery.textScalerOf(context).scale(29)) : 72,
                        ),
                        itemBuilder: (context, index) {
                          if (index == group.items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: SizedBox(width: double.infinity, child: delayTestAction),
                            );
                          }
                          final proxy = group.items[index];
                          return ProxyTile(
                            proxy,
                            selected: group.selected == proxy.tag,
                            grouped: blizzard,
                            firstInGroup: index == 0,
                            lastInGroup: index == group.items.length - 1,
                            onTap: () async {
                              await ref
                                  .read(proxiesOverviewNotifierProvider.notifier)
                                  .changeProxy(group.tag, proxy.tag);
                              // if (selectActiveProxyMutation.state.isInProgress) return;
                              // selectActiveProxyMutation.setFuture(
                              // );
                            },
                          );
                        },
                      );
                      if (!blizzard) return grid;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            key: const ValueKey('servers_profile_summary'),
                            padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 16),
                            child: Text(
                              _profileServerSummary(t.$meta.locale, activeProfileName, group.items.length),
                              style: presentationTheme.textTheme.bodySmall?.copyWith(color: BlizzardPalette.secondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(child: grid),
                        ],
                      );
                    },
                  )
                : Center(child: Text(t.pages.proxies.empty)),
            error: (error, stackTrace) => Center(child: Text(t.presentShortError(error))),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

String _serversTitle(AppLocale locale) => locale == AppLocale.ru ? 'Серверы' : 'Servers';

String _profileServerSummary(AppLocale locale, String? profileName, int count) {
  final countLabel = locale == AppLocale.ru
      ? _russianServerCount(count)
      : '$count ${count == 1 ? 'server' : 'servers'}';
  return [profileName?.trim() ?? '', countLabel].where((value) => value.isNotEmpty).join(' · ');
}

String _russianServerCount(int count) {
  final mod100 = count % 100;
  final mod10 = count % 10;
  final noun = mod100 >= 11 && mod100 <= 14
      ? 'серверов'
      : mod10 == 1
      ? 'сервер'
      : mod10 >= 2 && mod10 <= 4
      ? 'сервера'
      : 'серверов';
  return '$count $noun';
}
