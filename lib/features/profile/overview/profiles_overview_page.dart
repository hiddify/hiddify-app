import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilesOverviewPage extends HookConsumerWidget {
  const ProfilesOverviewPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile.overviewPageTitle),
        actions: [
          IconButton(
            onPressed: () => ref.read(buttomSheetsNotifierProvider.notifier).showAddProfile(),
            icon: const Icon(FluentIcons.add_24_filled),
            tooltip: t.profile.add.shortBtnTxt, // Tooltip for accessibility
          ),
          IconButton(
            onPressed: () => ref.read(dialogNotifierProvider.notifier).showSortProfiles(),
            icon: const Icon(FluentIcons.arrow_sort_24_filled),
            tooltip: t.general.sort,
          ),
          IconButton(
            onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
            icon: const Icon(FluentIcons.arrow_sync_24_filled),
            tooltip: t.profile.update.updateSubscriptions,
          ),
          const Gap(8),
        ],
        automaticallyImplyLeading: false,
      ),
      body: asyncProfiles.when(
        data: (data) => ListView.separated(
          padding: const EdgeInsets.all(12),
          separatorBuilder: (context, index) => const Gap(12),
          itemBuilder: (context, index) => ProfileTile(profile: data[index]),
          itemCount: data.length,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Text(t.presentShortError(error)),
      ),
    );
  }
}

class ProfilesOverviewModal extends ConsumerWidget {
  const ProfilesOverviewModal({super.key});

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
    final initialSize = PlatformUtils.isDesktop ? .60 : .35;
    return SafeArea(
      child: asyncProfiles.when(
        data: (data) => DraggableScrollableSheet(
          initialChildSize: initialSize,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    separatorBuilder: (context, index) => const Gap(12),
                    // shrinkWrap: true,
                    controller: scrollController,
                    itemBuilder: (context, index) => ProfileTile(profile: data[index]),
                    itemCount: data.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4).copyWith(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => ref.read(buttomSheetsNotifierProvider.notifier).showAddProfile(),
                        icon: const Icon(FluentIcons.add_24_filled),
                        tooltip: t.profile.add.shortBtnTxt, // Tooltip for accessibility
                      ),
                      IconButton(
                        onPressed: () => ref.read(dialogNotifierProvider.notifier).showSortProfiles(),
                        icon: const Icon(FluentIcons.arrow_sort_24_filled),
                        tooltip: t.general.sort,
                      ),
                      IconButton(
                        onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
                        icon: const Icon(FluentIcons.arrow_sync_24_filled),
                        tooltip: t.profile.update.updateSubscriptions,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Text(t.presentShortError(error)),
      ),
    );
  }
}

class SortProfilesDialog extends HookConsumerWidget {
  const SortProfilesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final sort = ref.watch(profilesOverviewSortNotifierProvider);

    return AlertDialog(
      title: Text(t.general.sortBy),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
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
                        ref.read(profilesOverviewSortNotifierProvider.notifier).toggleMode();
                        } else {
                        ref.read(profilesOverviewSortNotifierProvider.notifier).changeSort(e);
                        }
                      },
                      selected: selected,
                      leading: Icon(e.icon),
                      trailing: selected
                          ? IconButton(
                              onPressed: () {
                              ref.read(profilesOverviewSortNotifierProvider.notifier).toggleMode();
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
        ),
      ),
    );
  }
}
