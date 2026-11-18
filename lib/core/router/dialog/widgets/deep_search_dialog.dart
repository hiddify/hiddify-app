import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Asks whether [name], whose search for a way through (WARP endpoint, Psiphon route) found nothing
/// in a few minutes, should search on with no time limit. Pops true for "Deep search".
class DeepSearchDialog extends HookConsumerWidget {
  const DeepSearchDialog({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue.pages.proxies.deepSearch;
    return AlertDialog(
      icon: const Icon(Icons.travel_explore_rounded),
      title: Text(t.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(child: Text(t.message(name: name))),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(t.notNow)),
        FilledButton(onPressed: () => context.pop(true), child: Text(t.start)),
      ],
    );
  }
}
