import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/model/constants.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData? icon,
  String? okText,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final localizations = MaterialLocalizations.of(context);
      return AlertDialog(
        icon: icon != null ? Icon(icon) : null,
        title: Text(title),
        content: ConstrainedBox(
          constraints: AlertDialogConst.boxConstraints,
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(okText ?? localizations.okButtonLabel),
          ),
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(localizations.cancelButtonLabel),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
