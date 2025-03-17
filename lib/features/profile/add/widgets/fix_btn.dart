import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FixBtn extends ConsumerWidget {
  const FixBtn({
    super.key,
    required this.height,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final double height;
  final String title;
  final IconData icon;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSmallBreakpoint = Breakpoints.small.isActive(context);
    final color = theme.colorScheme.primary;
    final borderRadius = BorderRadius.circular(18);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          alignment: Alignment.center,
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSmallBreakpoint ? 32 : 40,
                color: color,
              ),
              Gap(isSmallBreakpoint ? 4 : 8),
              Text(
                title,
                style: isSmallBreakpoint ? theme.textTheme.titleSmall!.copyWith(color: color) : theme.textTheme.titleMedium!.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
