import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/utils/placeholders.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilesOverviewModal extends HookConsumerWidget {
  const ProfilesOverviewModal({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final asyncProfiles = ref.watch(profilesOverviewNotifierProvider);

    ref.listen(
      foregroundProfilesUpdateNotifierProvider,
      (_, next) {
        if (next case AsyncData(:final value?)) {
          final t = ref.read(translationsProvider).requireValue;
          final notification = ref.read(inAppNotificationControllerProvider);
          if (value.success) {
            notification.showSuccessToast(
              t.profile.update.namedSuccessMsg(name: value.name),
            );
          } else {
            notification.showErrorToast(
              t.profile.update.namedFailureMsg(name: value.name),
            );
          }
        }
      },
    );
    final appBar = NestedAppBar(
      title: Text(t.profile.overviewPageTitle),
      actions: [
        IconButton(
          onPressed: () => const AddProfileRoute().push(context),
          icon: const Icon(FluentIcons.add_24_filled),
          tooltip: t.profile.add.shortBtnTxt, // Tooltip for accessibility
        ),
        IconButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) {
              return const ProfilesSortModal();
            },
          ),
          icon: const Icon(FluentIcons.arrow_sort_24_filled),
          tooltip: t.general.sort,
        ),
        IconButton(
          onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
          icon: const Icon(FluentIcons.arrow_sync_24_filled),
          tooltip: t.profile.update.updateSubscriptions,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') {
              ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger();
            } else if (value == 'sort') {
              showDialog(
                context: context,
                builder: (context) {
                  return const ProfilesSortModal();
                },
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: Text(t.profile.update.updateSubscriptions),
            ),
            PopupMenuItem(
              value: 'sort',
              child: Text(t.general.sort),
            ),
          ],
        ),
      ],
    );
    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          appBar,
          // SliverPadding(
          //   // padding: const EdgeInsets.symmetric(vertical: 8),
          //   sliver: SliverToBoxAdapter(
          //     child: Wrap(
          //       alignment: WrapAlignment.center,
          //       spacing: 8,
          //       children: [],
          //     ),
          //   ),
          // ),
          const SliverGap(10),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              // final width = constraints.crossAxisExtent;
              // final crossAxisCount = max(1, (width / 400).floor());
              return switch (asyncProfiles) {
                AsyncData(value: final profiles) => SliverList.builder(
                    // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    //   crossAxisCount: crossAxisCount,
                    //   mainAxisExtent: 80,
                    // ),
                    itemBuilder: (context, index) {
                      // if (index >= profiles.length) {
                      // return const Text("Test");
                      // }
                      final profile = profiles[index];
                      return ProfileTile(profile: profile);
                    },
                    itemCount: profiles.length,
                  ),
                AsyncError(:final error) => SliverErrorBodyPlaceholder(
                    t.presentShortError(error),
                  ),
                AsyncLoading() => const SliverLoadingBodyPlaceholder(),
                _ => const SliverToBoxAdapter(),
              };
            },
          ),
        ],
      ),
    );
  }
}

class ProfilesSortModal extends HookConsumerWidget {
  const ProfilesSortModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final sortNotifier = ref.watch(profilesOverviewSortNotifierProvider.notifier);

    return AlertDialog(
      title: Text(t.general.sortBy),
      content: Consumer(
        builder: (context, ref, child) {
          final sort = ref.watch(profilesOverviewSortNotifierProvider);
          return SingleChildScrollView(
            child: Column(
              children: [
                ...ProfilesSort.values.map(
                  (e) {
                    final selected = sort.by == e;
                    final double arrowTurn = sort.mode == SortMode.ascending ? 0 : 0.5;

                    return ListTile(
                      title: Text(e.present(t)),
                      onTap: () {
                        if (selected) {
                          sortNotifier.toggleMode();
                        } else {
                          sortNotifier.changeSort(e);
                        }
                      },
                      selected: selected,
                      leading: Icon(e.icon),
                      trailing: selected
                          ? IconButton(
                              onPressed: () {
                                sortNotifier.toggleMode();
                              },
                              icon: AnimatedRotation(
                                turns: arrowTurn,
                                duration: const Duration(milliseconds: 100),
                                child: Icon(
                                  FluentIcons.arrow_sort_up_24_regular,
                                  semanticLabel: sort.mode.name,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
