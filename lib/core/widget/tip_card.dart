import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A card widget for displaying tips and helpful information.
/// 
/// Shows a lightbulb icon with a message. Optionally dismissable.
/// 
/// Usage:
/// ```dart
/// TipCard(
///   message: 'Enable VPN for better privacy',
///   onDismiss: () => hideTip(),
/// )
/// ```
class TipCard extends StatelessWidget {
  /// Creates a tip card.
  /// 
  /// [message] is the tip text to display.
  /// [onDismiss] is called when the user dismisses the tip.
  const TipCard({
    required this.message, 
    this.onDismiss,
    super.key,
  });

  /// The tip message to display.
  final String message;
  
  /// Optional callback when the tip is dismissed.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tip: $message',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(
                FluentIcons.lightbulb_24_regular,
                semanticLabel: 'Tip',
              ),
              const Gap(8),
              Expanded(
                child: Text(message),
              ),
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
}
