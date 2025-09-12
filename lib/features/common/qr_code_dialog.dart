import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends StatelessWidget {
  const QrCodeDialog(
    this.data, {
    super.key,
    this.message,
    this.width = 268,
    this.backgroundColor = Colors.white,
  });

  final String data;
  final String? message;
  final double width;
  final Color backgroundColor;

  Future<void> show(BuildContext context) async {
    await showDialog(context: context, builder: (context) => this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            child: QrImageView(
              data: data,
              backgroundColor: backgroundColor,
            ),
          ),
          if (message != null)
            SizedBox(
              width: width,
              child: Material(
                color: theme.colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        message!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
