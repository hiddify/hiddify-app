import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class TipCard extends StatelessWidget {
  const TipCard({required this.message, this.onDismiss, super.key});

  final String message;

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tip: $message',
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(FluentIcons.lightbulb_24_regular, semanticLabel: 'Tip'),
            const Gap(8),
            Expanded(child: Text(message)),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(FluentIcons.dismiss_24_regular),
                onPressed: onDismiss,
                tooltip: 'Dismiss tip',
                iconSize: 20,
              ),
          ],
        ),
      ),
    ),
  );
}
