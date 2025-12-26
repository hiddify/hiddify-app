import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SaveDialog extends HookConsumerWidget {
  const SaveDialog({super.key, required this.title, required this.description});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(constraints: AlertDialogConst.boxConstraints, child: Text(description)),
      actions: [
        TextButton(onPressed: () => context.pop(false), child: Text(t.common.discard)),
        TextButton(onPressed: () => context.pop(true), child: Text(t.common.save)),
      ],
    );
  }
}
