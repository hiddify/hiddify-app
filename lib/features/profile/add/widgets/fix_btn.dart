import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FixBtn extends ConsumerWidget {
  const FixBtn({
    super.key,
    required this.height,
    required this.title,
    required this.icon,
    required this.onTap,
    this.wrapLabel = false,
  });

  final double height;
  final String title;
  final IconData icon;
  final GestureTapCallback onTap;
  final bool wrapLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = Breakpoint(context).isMobile();
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
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: wrapLabel ? 24 : (isMobile ? 32 : 40), color: color),
              Gap(wrapLabel ? 8 : (isMobile ? 4 : 8)),
              Text(
                title,
                textAlign: wrapLabel ? TextAlign.center : null,
                softWrap: wrapLabel,
                style: isMobile
                    ? theme.textTheme.titleSmall!.copyWith(color: color)
                    : theme.textTheme.titleMedium!.copyWith(color: color),
                overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis,
                maxLines: wrapLabel ? null : 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
