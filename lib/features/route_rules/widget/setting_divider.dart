import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingDivider extends ConsumerWidget {
  const SettingDivider({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (title == null) return const Divider(indent: 16, endIndent: 16, height: 1);
    return Row(
      children: [
        const Expanded(child: Divider(indent: 16, endIndent: 8, height: 1)),
        const Icon(size: 16, Icons.warning_rounded, color: Colors.amber),
        const Gap(2),
        Text(title!, style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onSurface)),
        const Expanded(child: Divider(indent: 8, endIndent: 16, height: 1)),
      ],
    );
  }
}
