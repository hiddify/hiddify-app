import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UnknownDomainsWarningDialog extends HookConsumerWidget {
  const UnknownDomainsWarningDialog({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.orange),
          const Gap(8),
          Text(t.dialogs.unknownDomainsWarning.title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dialogs.unknownDomainsWarning.youAreAboutToVisit),
          const Gap(8),
          Text(url, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Gap(16),
          Text(t.dialogs.unknownDomainsWarning.thisWebsiteIsNotInOurTrustedList),
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(t.common.cancel)),
        FilledButton(onPressed: () => context.pop(true), child: Text(t.common.kContinue)),
      ],
    );
  }
}
