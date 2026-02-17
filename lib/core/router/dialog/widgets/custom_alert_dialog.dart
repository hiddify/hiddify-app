import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CustomAlertDialog extends HookConsumerWidget {
  const CustomAlertDialog({super.key, this.title, required this.message});

  final String? title;
  final String message;

  factory CustomAlertDialog.fromErr(({String type, String? message}) err) =>
      CustomAlertDialog(title: err.message == null ? null : err.type, message: err.message ?? err.type);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: title != null ? Text(title!) : null,
      content: SingleChildScrollView(
        child: SizedBox(width: 468, child: Text(message, textDirection: TextDirection.ltr)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: Text(t.common.ok),
        ),
      ],
    );
  }
}
