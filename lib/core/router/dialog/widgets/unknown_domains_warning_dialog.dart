import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shown when a subscription-provided link is not in [TrustedLinks]. It doesn't
/// claim the link is malicious — only that we can't verify it — so the user is
/// aware before paying or sharing sensitive info. The "Open" button stays
/// disabled for [countdownSeconds] so the note actually gets read.
class UnknownDomainsWarningDialog extends HookConsumerWidget {
  const UnknownDomainsWarningDialog({super.key, required this.url, this.countdownSeconds = 10});

  final String url;
  final int countdownSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final secondsLeft = useState(countdownSeconds);

    useEffect(() {
      if (countdownSeconds <= 0) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsLeft.value <= 1) {
          secondsLeft.value = 0;
          timer.cancel();
        } else {
          secondsLeft.value = secondsLeft.value - 1;
        }
      });
      return timer.cancel;
    }, const []);

    final canOpen = secondsLeft.value <= 0;

    return AlertDialog(
      title: Text(t.dialogs.unknownDomainsWarning.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(url, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Gap(16),
          Text(t.dialogs.unknownDomainsWarning.cannotVerify),
          const Gap(8),
          Text(t.dialogs.unknownDomainsWarning.avoidIfUnsure),
          const Gap(8),
          Text(
            t.dialogs.unknownDomainsWarning.ownResponsibility,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(t.common.cancel)),
        TextButton(
          onPressed: canOpen ? () => context.pop(true) : null,
          child: Text(
            canOpen
                ? t.dialogs.unknownDomainsWarning.open
                : t.dialogs.unknownDomainsWarning.openIn(seconds: secondsLeft.value),
          ),
        ),
      ],
    );
  }
}
