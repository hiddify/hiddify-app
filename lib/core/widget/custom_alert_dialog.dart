import 'package:flutter/material.dart';
import 'package:hiddify/core/model/failures.dart';

/// A reusable alert dialog widget for displaying messages and errors.
/// 
/// Supports showing plain messages or error objects with proper formatting.
/// The message content is selectable for easy copying.
/// 
/// Usage:
/// ```dart
/// await CustomAlertDialog(
///   title: 'Error',
///   message: 'Connection failed',
/// ).show(context);
/// 
/// // Or from an error:
/// await CustomAlertDialog.fromError(error).show(context);
/// ```
class CustomAlertDialog extends StatelessWidget {
  /// Creates a custom alert dialog.
  /// 
  /// [title] is optional and displayed at the top.
  /// [message] is the main content text.
  /// [onDismiss] is called when the dialog is closed.
  const CustomAlertDialog({
    super.key, 
    this.title, 
    required this.message,
    this.onDismiss,
  });

  /// Optional title displayed at the top of the dialog.
  final String? title;
  
  /// The message content to display.
  final String message;
  
  /// Optional callback when the dialog is dismissed.
  final VoidCallback? onDismiss;

  /// Creates a dialog from a [PresentableError].
  factory CustomAlertDialog.fromError(PresentableError error) =>
      CustomAlertDialog(
        title: error.message == null ? null : error.type,
        message: error.message ?? error.type,
      );

  /// Shows this dialog and returns when it's dismissed.
  Future<void> show(BuildContext context) async {
    await showDialog(context: context, builder: (context) => this);
    onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Semantics(
      liveRegion: true,
      child: AlertDialog(
        title: title != null ? Text(title!) : null,
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 468),
            child: SelectableText(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
      ),
    );
  }
}
