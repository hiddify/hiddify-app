import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RelaunchAdminDialog extends HookConsumerWidget {
  const RelaunchAdminDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      icon: const Icon(Icons.shield_outlined),
      title: Text(t.errors.singbox.missingPrivilege),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: Text(t.errors.singbox.missingPrivilegeMsg),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => context.pop(true),
          child: Text(t.errors.singbox.relaunchAsAdmin),
        ),
      ],
    );
  }
}
