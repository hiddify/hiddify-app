import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Lists [inactive] subscriptions, all checked, with why each one no longer works. Pops with the
/// ids still checked when the user removes them, or null.
class RemoveInactiveProfilesDialog extends HookConsumerWidget {
  const RemoveInactiveProfilesDialog(this.inactive, {super.key});

  final List<InactiveProfile> inactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final strings = t.pages.profiles.removeInactive;
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final checked = useState({for (final item in inactive) item.profile.id});

    String reason(InactiveProfile item) => switch (item) {
      (reason: InactiveReason.expired, since: final since?, profile: _) => strings.reason.expiredOn(
        date: localizations.formatMediumDate(since),
      ),
      (reason: InactiveReason.expired, since: null, profile: _) => strings.reason.expired,
      (reason: InactiveReason.noTraffic, since: _, profile: _) => strings.reason.noTraffic,
      (reason: InactiveReason.updateFailing, since: final since?, profile: _) => strings.reason.updateFailingSince(
        date: localizations.formatMediumDate(since),
      ),
      (reason: InactiveReason.updateFailing, since: null, profile: _) => strings.reason.updateFailing,
    };

    return AlertDialog(
      icon: const Icon(Icons.delete_sweep_rounded),
      title: Text(strings.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.hint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in inactive)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checked.value.contains(item.profile.id),
                      onChanged: (value) => checked.value = value ?? false
                          ? {...checked.value, item.profile.id}
                          : ({...checked.value}..remove(item.profile.id)),
                      title: Text(item.profile.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(reason(item), style: TextStyle(color: theme.colorScheme.error)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.cancel)),
        FilledButton(
          onPressed: checked.value.isEmpty ? null : () => Navigator.of(context).pop(checked.value.toList()),
          child: Text(strings.remove(count: checked.value.length)),
        ),
      ],
    );
  }
}
