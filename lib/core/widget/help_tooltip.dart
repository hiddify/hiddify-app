import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// A help tooltip widget that shows a question mark icon with detailed explanation
class HelpTooltip extends StatelessWidget {
  const HelpTooltip({
    super.key,
    required this.message,
    this.iconSize = 20,
    this.iconColor,
    this.showDelay = const Duration(milliseconds: 500),
  });

  final String message;
  final double iconSize;
  final Color? iconColor;
  final Duration showDelay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Tooltip(
        message: message,
        showDuration: const Duration(seconds: 15),
        waitDuration: showDelay,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: TextStyle(
          color: Theme.of(context).colorScheme.onInverseSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        preferBelow: true,
        child: Icon(
          FluentIcons.question_circle_24_filled,
          size: iconSize,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// A widget that combines a title with a help tooltip
class TitleWithHelp extends StatelessWidget {
  const TitleWithHelp({
    super.key,
    required this.title,
    required this.helpMessage,
    this.titleStyle,
    this.spacing = 8,
  });

  final String title;
  final String helpMessage;
  final TextStyle? titleStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: titleStyle),
        SizedBox(width: spacing),
        HelpTooltip(message: helpMessage),
      ],
    );
  }
}
