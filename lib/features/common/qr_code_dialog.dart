import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A dialog widget that displays a QR code for sharing data.
/// 
/// Shows a QR code image with an optional message below it.
/// Can be shown as a modal dialog.
/// 
/// Usage:
/// ```dart
/// await QrCodeDialog(
///   'https://example.com',
///   message: 'Scan to connect',
/// ).show(context);
/// ```
class QrCodeDialog extends StatelessWidget {
  /// Creates a QR code dialog.
  /// 
  /// [data] is the content to encode in the QR code.
  /// [message] is optional text displayed below the QR code.
  /// [width] controls the QR code size.
  /// [barrierDismissible] controls whether tapping outside closes the dialog.
  const QrCodeDialog(
    this.data, {
    super.key,
    this.message,
    this.width = 268,
    this.backgroundColor = Colors.white,
    this.barrierDismissible = true,
  });

  /// The data to encode in the QR code.
  final String data;
  
  /// Optional message displayed below the QR code.
  final String? message;
  
  /// Width of the QR code image.
  final double width;
  
  /// Background color of the QR code.
  final Color backgroundColor;
  
  /// Whether tapping outside the dialog dismisses it.
  final bool barrierDismissible;

  /// Shows this dialog as a modal.
  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context, 
      barrierDismissible: barrierDismissible,
      builder: (context) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Semantics(
        label: 'QR Code${message != null ? ': $message' : ''}',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QrImageView(
                    data: data, 
                    backgroundColor: backgroundColor,
                    semanticsLabel: 'QR code containing: $data',
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  MaterialLocalizations.of(context).closeButtonLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
