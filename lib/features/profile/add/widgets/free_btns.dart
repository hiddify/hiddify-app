import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/add/widgets/free_btn.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FreeBtns extends ConsumerWidget {
  const FreeBtns({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final freeProfiles = ref.watch(freeProfilesNotifierProvider);
    final freeProfilesFilteredByRegion = ref.watch(freeProfilesFilteredByRegionProvider);
    final theme = Theme.of(context);
    final locale = ref.watch(localePreferencesProvider);
    final isFa = locale.name == AppLocale.fa.name;
    return freeProfilesFilteredByRegion.when(
      data: (data) => data.isNotEmpty
          ? ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                itemCount: freeProfiles.value!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width <= BottomSheetConst.maxWidth || freeProfiles.value!.length < 2
                      ? 1
                      : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 72,
                ),
                itemBuilder: (context, index) {
                  final profile = freeProfiles.value![index];
                  return FreeBtn(
                    freeProfile: profile,
                    onTap: () async {
                      final title = isFa ? profile.title.fa : profile.title.en;
                      final consent = isFa ? profile.consent.fa : profile.consent.en;
                      final result = await ref
                          .read(dialogNotifierProvider.notifier)
                          .showFreeProfileConsent(title: title, consent: consent);
                      if (result == true) {
                        await ref
                            .read(addProfileNotifierProvider.notifier)
                            .addManual(
                              url: profile.sublink,
                              userOverride: UserOverride(
                                name: title,
                                updateInterval: 12,
                                enableWarp: profile.neededFeatures?.contains('warp_over_proxies'),
                                enableFragment: profile.neededFeatures?.contains('fragment'),
                              ),
                            );
                      }
                    },
                  );
                },
              ),
            )
          : Center(
              child: Text(
                (freeProfiles.value?.isEmpty ?? true)
                    ? t.pages.profiles.freeSubNotFound
                    : t.pages.profiles.freeSubNotFoundForRegion(region: ref.watch(ConfigOptions.region).name),
                style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurface),
              ),
            ),
      error: (error, stackTrace) => Center(
        child: Text(
          t.pages.profiles.failedToLoad,
          style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurface),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
