import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SortProfilesDialog extends HookConsumerWidget {
  const SortProfilesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final sort = ref.watch(profilesSortNotifierProvider);

    return AlertDialog(
      title: Text(t.dialogs.sortProfiles.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ...ProfilesSort.values.map((e) {
                final selected = sort.by == e;

                return ListTile(
                  dense: true,
                  title: Text(e.present(t)),
                  subtitle: selected
                      ? Text(
                          e.directionLabel(t, sort.mode),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                        )
                      : null,
                  onTap: () {
                    if (selected) {
                      ref.read(profilesSortNotifierProvider.notifier).toggleMode();
                    } else {
                      ref.read(profilesSortNotifierProvider.notifier).changeSort(e);
                    }
                  },
                  selected: selected,
                  leading: Icon(e.icon),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
