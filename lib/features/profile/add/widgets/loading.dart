import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Loading extends ConsumerWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.profile.add.addingProfileMsg,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(20),
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
            ),
            const Gap(8),
            TextButton(
              onPressed: () {
                ref.invalidate(addProfileProvider);
              },
              child: Text(
                MaterialLocalizations.of(context).cancelButtonLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
