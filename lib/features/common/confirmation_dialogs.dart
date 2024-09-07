import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData? icon,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final localizations = MaterialLocalizations.of(context);
      return PlatformAlertDialog(
        material: (context, platform) => MaterialAlertDialogData(
          icon: icon != null ? Icon(icon) : null,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(localizations.okButtonLabel),
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
