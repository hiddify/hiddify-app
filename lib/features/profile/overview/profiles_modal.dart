import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilesModal extends HookConsumerWidget {
  const ProfilesModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final asyncProfiles = ref.watch(profilesNotifierProvider);

    ref.listen(profilesNotifierProvider, (_, next) {
      if (next.hasValue && next.value!.isEmpty) {
        if (context.canPop()) context.pop();
      }
    });

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
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        label: Text(t.common.sort, maxLines: 1, overflow: TextOverflow.ellipsis),
                        icon: const Icon(Icons.sort_rounded),
                        onPressed: () => ref.read(dialogNotifierProvider.notifier).showSortProfiles(),
                      ),
                      FilledButton.icon(
                        label: Text(t.pages.profiles.updateSubscriptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                        icon: const Icon(Icons.update_rounded),
                        onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text(t.presentShortError(error)),
      ),
    );
  }
}
