import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileLoading extends ConsumerWidget {
  const ProfileLoading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final retry = ref.watch(addProfileRetryProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.pages.profileDetails.form.loading,
            style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurface),
          ),
          if (retry != null) ...[
            const Gap(12),
            // why it takes longer: the attempt that failed, in the words of the failure dialog
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 20, color: theme.colorScheme.onErrorContainer),
                    const Gap(10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.pages.profileDetails.form.retrying(
                              failed: retry.next - 1,
                              reason: retry.failure.present(t).type,
                            ),
                            style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onErrorContainer),
                          ),
                          Text(
                            t.pages.profileDetails.form.retryingNext(next: retry.next, of: retry.of),
                            style: theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Gap(20),
          const LinearProgressIndicator(backgroundColor: Colors.transparent),
          const Gap(8),
          TextButton(
            onPressed: () {
              ref.invalidate(addProfileNotifierProvider);
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }
}
