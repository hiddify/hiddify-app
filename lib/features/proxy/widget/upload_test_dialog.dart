import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum UploadTestChoice {
  /// every proxy in the list
  all,

  /// only the fastest by their ping, up to the limit, which then are all that run
  fastest,
}

/// Asks before an upload test of [count] proxies, more than [limit]: it sends [megabytes] through
/// each of them.
class UploadTestWarningDialog extends ConsumerWidget {
  const UploadTestWarningDialog({super.key, required this.count, required this.limit, required this.megabytes});

  final int count;
  final int limit;
  final int megabytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.proxies.upload;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final warn = theme.brightness == Brightness.dark ? const Color(0xFFFFB74D) : Colors.orange.shade800;
    return AlertDialog(
      icon: Icon(Icons.data_usage_rounded, color: warn),
      title: Text(text.warnTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // the data it would send, at a glance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: Color.alphaBlend(warn.withValues(alpha: .12), s.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _amount(count * megabytes),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: warn,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Gap(2),
                  Text(
                    text.perProxy(count: count, n: megabytes),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant, letterSpacing: .3),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Text(text.warnBody(limit: limit), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(UploadTestChoice.all),
          child: Text(text.testAll(count: count)),
        ),
        FilledButton.icon(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(UploadTestChoice.fastest),
          icon: const Icon(Icons.bolt_rounded),
          label: Text(text.testFastest(limit: limit)),
        ),
      ],
    );
  }

  static String _amount(int megabytes) =>
      megabytes < 1024 ? '≈ $megabytes MB' : '≈ ${(megabytes / 1024).toStringAsFixed(1)} GB';
}
