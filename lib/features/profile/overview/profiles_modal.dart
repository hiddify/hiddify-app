import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_backdrop.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
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
    final theme = BlizzardPresentation.themeOf(context);
    final blizzard =
        BlizzardPresentation.isActive(context) || (theme.extension<BlizzardEligibility>()?.applied ?? false);
    Widget protectFallback(Widget child) => blizzard
        ? SafeArea(left: false, top: false, right: false, child: child)
        : child;

    ref.listen(profilesNotifierProvider, (_, next) {
      if (next.hasValue && next.value!.isEmpty) {
        if (context.canPop()) context.pop();
      }
    });

    final initialSize = blizzard
        ? (223 / MediaQuery.sizeOf(context).height).clamp(.20, .85)
        : PlatformUtils.isDesktop
        ? .60
        : .35;
    return Theme(
      data: theme,
      child: SafeArea(
        bottom: !blizzard,
        child: asyncProfiles.when(
          data: (data) => DraggableScrollableSheet(
            initialChildSize: initialSize,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) => ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: blizzard
                  ? ColoredBox(
                      color: theme.colorScheme.surface,
                      child: SafeArea(
                        left: false,
                        top: false,
                        right: false,
                        child: _ProfilesSheetContent(
                          data: data,
                          scrollController: scrollController,
                          blizzard: true,
                          t: t,
                        ),
                      ),
                    )
                  : BlizzardBackdrop(
                      child: _ProfilesSheetContent(
                        data: data,
                        scrollController: scrollController,
                        blizzard: false,
                        t: t,
                      ),
                    ),
            ),
          ),
          loading: () => protectFallback(const Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => protectFallback(Text(t.presentShortError(error))),
        ),
      ),
    );
  }
}

class _ProfilesSheetContent extends ConsumerWidget {
  const _ProfilesSheetContent({
    required this.data,
    required this.scrollController,
    required this.blizzard,
    required this.t,
  });

  final List<ProfileEntity> data;
  final ScrollController scrollController;
  final bool blizzard;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void showSortProfiles() => ref.read(dialogNotifierProvider.notifier).showSortProfiles();
    void updateSubscriptions() => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger();
    return Column(
      children: [
        if (blizzard)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text(t.pages.profiles.title, style: Theme.of(context).textTheme.titleLarge)),
                IconButton(tooltip: t.common.sort, icon: const Icon(Icons.sort_rounded), onPressed: showSortProfiles),
                IconButton(
                  tooltip: t.pages.profiles.updateSubscriptions,
                  icon: const Icon(Icons.update_rounded),
                  onPressed: updateSubscriptions,
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: blizzard ? const EdgeInsets.fromLTRB(32, 8, 32, 18) : const EdgeInsets.all(12),
            separatorBuilder: (context, index) => Gap(blizzard ? 8 : 12),
            controller: scrollController,
            itemBuilder: (context, index) => ProfileTile(profile: data[index]),
            itemCount: data.length,
          ),
        ),
        if (!blizzard)
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
                  onPressed: showSortProfiles,
                ),
                FilledButton.icon(
                  label: Text(t.pages.profiles.updateSubscriptions, maxLines: 1, overflow: TextOverflow.ellipsis),
                  icon: const Icon(Icons.update_rounded),
                  onPressed: updateSubscriptions,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
