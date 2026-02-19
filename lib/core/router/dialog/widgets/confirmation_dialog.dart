import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConfirmationDialog extends HookConsumerWidget {
  const ConfirmationDialog({super.key, required this.title, required this.message, this.icon, this.positiveBtnTxt});
  final String title;
  final String message;
  final IconData? icon;
  final String? positiveBtnTxt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      icon: icon != null ? Icon(icon) : null,
      title: Text(title),
      content: ConstrainedBox(constraints: AlertDialogConst.boxConstraints, child: Text(message)),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(t.common.cancel)),
        TextButton(onPressed: () => context.pop(true), child: Text(positiveBtnTxt ?? t.common.ok)),
      ],
    );
  }
}
