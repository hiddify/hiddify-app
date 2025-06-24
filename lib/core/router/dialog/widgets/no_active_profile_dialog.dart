import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NoActiveProfileDialog extends HookConsumerWidget {
  const NoActiveProfileDialog({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: Text(t.home.noActiveProfileMsg),
      content: Text(t.home.emptyProfilesMsg.text),
      actions: [
        TextButton(
          onPressed: () async {
            await UriUtils.tryLaunch(
              Uri.parse(t.home.emptyProfilesMsg.buttonHelp.url),
            );
          },
          child: Text(t.home.emptyProfilesMsg.buttonHelp.label),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(t.general.ok),
        ),
      ],
    );
  }
}
