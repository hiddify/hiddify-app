import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_tokens.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.x3,
        vertical: tokens.spacing.x2,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tokens.radius.sm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(tokens.radius.md),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
