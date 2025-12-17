import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.icon,
    super.key,
    this.color,
  });

  final String title;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;
    final effectiveColor = color ?? colors.primary;
    final iconBackgroundColor =
        color != null ? effectiveColor.withValues(alpha: 0.12) : colors.primaryContainer;
    final iconForegroundColor =
        color != null ? effectiveColor : colors.onPrimaryContainer;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(tokens.spacing.x2),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(tokens.radius.sm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconForegroundColor,
            ),
          ),
          SizedBox(width: tokens.spacing.x3),
        ],
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
