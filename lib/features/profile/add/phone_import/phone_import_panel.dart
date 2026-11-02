import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_notifier.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// On Android TV, in the add profile sheet: the code a phone scans to send a link to this TV.
class PhoneImportPanel extends ConsumerWidget {
  const PhoneImportPanel({super.key});

  static const _qrSize = 172.0;

  /// Its height: room for the code, or for the text at the system's text size, which TVs often
  /// raise (1.15 on a Mi TV).
  static double heightOf(BuildContext context) =>
      24 + max(_qrSize, 204 * MediaQuery.textScalerOf(context).scale(14) / 14);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final fromPhone = t.pages.profiles.fromPhone;
    final import = ref.watch(phoneImportProvider);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant);
    return Container(
      height: heightOf(context),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: s.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: _qrSize,
            height: _qrSize,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: switch (import) {
              AsyncData(value: PhoneImportState(locked: true)) => Icon(Icons.lock_rounded, size: 56, color: s.error),
              AsyncData(value: final state) => QrImageView(data: state.url.toString(), padding: EdgeInsets.zero),
              AsyncError() => Icon(Icons.wifi_off_rounded, size: 56, color: s.error),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          const Gap(20),
          Expanded(
            // if the text still does not fit, at a text size larger than measured, it shrinks
            child: LayoutBuilder(
              builder: (context, constraints) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_android_rounded, color: s.primary),
                          const Gap(8),
                          Flexible(child: Text(fromPhone.title, style: theme.textTheme.titleMedium)),
                        ],
                      ),
                      const Gap(8),
                      if (import case AsyncError(:final error))
                        Text(
                          error is PhoneImportNoNetwork ? fromPhone.noNetwork : t.presentShortError(error),
                          style: theme.textTheme.bodyMedium?.copyWith(color: s.error),
                        )
                      else if (import case AsyncData(value: PhoneImportState(locked: true)))
                        Text(fromPhone.locked, style: theme.textTheme.bodyMedium?.copyWith(color: s.error))
                      else ...[
                        Text(fromPhone.scan, style: muted),
                        const Gap(8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.wifi_rounded, size: 18, color: s.primary),
                            const Gap(6),
                            Expanded(child: Text(fromPhone.sameNetwork, style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                        if (import case AsyncData(value: final state)) ...[
                          const Gap(8),
                          // for a phone that can not scan: the address to type, all of it, secret
                          // included, without the "http://" every browser adds by itself. On one
                          // line, smaller if need be, so the code is never split.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: SelectableText(
                              '${state.url.authority}${state.url.path}',
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: s.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a phone sent, for the TV user to import or discard. Import has the focus, so one press
/// of the remote's center button imports it. Pops true to import.
class PhoneEntryDialog extends ConsumerWidget {
  const PhoneEntryDialog({super.key, required this.entry});

  final PhoneEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.phone_android_rounded),
      title: Text(t.pages.profiles.fromPhone.received),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.text,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            const Gap(8),
            Text(
              t.pages.profiles.fromPhone.from(address: entry.from.address),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.common.discard)),
        FilledButton(autofocus: true, onPressed: () => Navigator.of(context).pop(true), child: Text(t.common.import)),
      ],
    );
  }
}
