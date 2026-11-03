import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/app_update/notifier/app_updater.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A new release: "update now" downloads it and starts its installer where this install can
/// (AppUpdater), and opens the release page where it can not, or when the update failed.
class NewVersionDialog extends HookConsumerWidget with PresLogger {
  NewVersionDialog(this.currentVersion, this.newVersion, {super.key, this.canIgnore = true});

  final String currentVersion;
  final RemoteVersionEntity newVersion;
  final bool canIgnore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.newVersion;
    final theme = Theme.of(context);
    final updater = ref.watch(appUpdaterProvider);
    final busy = updater is AppUpdaterDownloading || updater is AppUpdaterInstalling;

    Future<void> openPage() => UriUtils.tryLaunch(Uri.parse(newVersion.url));
    Future<void> update() async {
      final updating = await ref.read(appUpdaterProvider.notifier).update(newVersion);
      if (!updating) await openPage();
    }

    return PopScope(
      // the download goes on only while the dialog shows it
      canPop: !busy,
      child: AlertDialog(
        title: Text(text.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text.msg),
            const Gap(8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "${text.currentVersion} ", style: theme.textTheme.bodySmall),
                  TextSpan(text: currentVersion, style: theme.textTheme.labelMedium),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "${text.newVersion} ", style: theme.textTheme.bodySmall),
                  TextSpan(text: newVersion.presentVersion, style: theme.textTheme.labelMedium),
                ],
              ),
            ),
            ...switch (updater) {
              AppUpdaterDownloading(:final progress) => [
                const Gap(16),
                LinearProgressIndicator(value: progress),
                const Gap(6),
                Text(
                  progress == null ? text.downloading : '${text.downloading} ${(progress * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              AppUpdaterInstalling() => [const Gap(16), Text(text.installing, style: theme.textTheme.bodySmall)],
              AppUpdaterNeedsPermission() => [const Gap(16), Text(text.allowInstall, style: theme.textTheme.bodySmall)],
              AppUpdaterFailed(:final error) => [
                const Gap(16),
                Text(
                  '${text.failed}\n${t.presentShortError(error)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              AppUpdaterIdle() => const <Widget>[],
            },
          ],
        ),
        actions: switch (updater) {
          AppUpdaterDownloading() => [
            TextButton(onPressed: ref.read(appUpdaterProvider.notifier).cancel, child: Text(t.common.cancel)),
          ],
          AppUpdaterInstalling() => const <Widget>[],
          AppUpdaterFailed() => [
            TextButton(onPressed: openPage, child: Text(text.openPage)),
            TextButton(onPressed: update, child: Text(text.tryAgain)),
          ],
          AppUpdaterNeedsPermission() => [
            TextButton(onPressed: context.pop, child: Text(t.common.later)),
            TextButton(onPressed: update, child: Text(text.tryAgain)),
          ],
          AppUpdaterIdle() => [
            if (canIgnore)
              TextButton(
                onPressed: () async {
                  await ref.read(appUpdateNotifierProvider.notifier).ignoreRelease(newVersion);
                  if (context.mounted) context.pop();
                },
                child: Text(t.common.ignore),
              ),
            TextButton(onPressed: context.pop, child: Text(t.common.later)),
            FilledButton(onPressed: update, child: Text(text.updateNow)),
          ],
        },
      ),
    );
  }
}
