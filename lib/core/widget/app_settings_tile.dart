import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_tokens.dart';

class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    required this.icon,
    required this.title,
    super.key,
    this.trailing,
    this.subtitle,
    this.iconColor,
    this.isDanger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget? trailing;
  final bool isDanger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    final iconBackground = isDanger
        ? colors.errorContainer
        : iconColor?.withValues(alpha: 0.2) ?? colors.secondaryContainer;
    final effectiveIconColor =
        isDanger ? colors.error : iconColor ?? colors.onSecondaryContainer;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.x4,
          vertical: tokens.spacing.x3,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(tokens.spacing.x2),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(tokens.radius.sm),
              ),
              child: Icon(icon, size: 20, color: effectiveIconColor),
            ),
            SizedBox(width: tokens.spacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDanger ? colors.error : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
