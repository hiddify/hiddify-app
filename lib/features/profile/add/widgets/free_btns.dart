import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/profile/add/widgets/free_btn.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FreeBtns extends ConsumerWidget {
  const FreeBtns({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue.profile.add;
    final freeProfiles = ref.watch(freeProfilesProvider);
    final theme = Theme.of(context);
    final locale = ref.watch(localePreferencesProvider);
    final isFa = locale.name == AppLocale.fa.name;

    return switch (freeProfiles) {
      AsyncLoading() => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 64),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      AsyncError() => Center(
          child: Text(
            t.fialed_to_load,
            style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
      AsyncValue() => freeProfiles.value!.isNotEmpty
          ? ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                itemCount: freeProfiles.value!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width <= BottomSheetConst.maxWidth || freeProfiles.value!.length < 2 ? 1 : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 72,
                ),
                itemBuilder: (context, index) {
                  final profile = freeProfiles.value![index];
                  return FreeBtn(
                    freeProfile: profile,
                    onTap: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(isFa ? profile.title.fa : profile.title.en),
                          content: ConstrainedBox(
                            constraints: AlertDialogConst.boxConstraints,
                            child: MarkdownBody(
                              data: isFa ? profile.contest.fa : profile.contest.en,
                              onTapLink: (text, href, title) => UriUtils.tryLaunch(Uri.parse(href!)),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text(t.cancel),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: Text(t.kContinue),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                      );
                      if (result == true) ref.read(addProfileProvider.notifier).add(profile.sublink);
                    },
                  );
                },
              ),
            )
          : Center(
              child: Text(
                t.no_free_subscription_found,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
    };
  }
}
