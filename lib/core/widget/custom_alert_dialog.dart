import 'package:flutter/material.dart';
import 'package:hiddify/core/model/failures.dart';

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    super.key,
    this.title,
    required this.message,
  });

  final String? title;
  final String message;

  factory CustomAlertDialog.fromError(PresentableError error) => CustomAlertDialog(
        title: error.message == null ? null : error.type,
        message: error.message ?? error.type,
      );

  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: title != null ? Text(title!) : null,
      content: SingleChildScrollView(
        child: SizedBox(
          width: 468,
          child: Text(message),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(localizations.okButtonLabel),
        ),
      ],
    );
  }
}
