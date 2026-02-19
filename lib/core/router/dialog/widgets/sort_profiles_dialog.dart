import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
                final double arrowTurn = sort.mode == SortMode.ascending ? 0 : 0.5;

                return ListTile(
                  title: Text(e.present(t)),
                  onTap: () {
                    if (selected) {
                      ref.read(profilesSortNotifierProvider.notifier).toggleMode();
                    } else {
                      ref.read(profilesSortNotifierProvider.notifier).changeSort(e);
                    }
                  },
                  selected: selected,
                  leading: Icon(e.icon),
                  trailing: selected
                      ? IconButton(
                          onPressed: () {
                            ref.read(profilesSortNotifierProvider.notifier).toggleMode();
                          },
                          icon: AnimatedRotation(
                            turns: arrowTurn,
                            duration: const Duration(milliseconds: 100),
                            child: Icon(FluentIcons.arrow_sort_up_24_regular, semanticLabel: sort.mode.name),
                          ),
                        )
                      : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
