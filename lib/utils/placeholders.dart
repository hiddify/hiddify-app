import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// TODO: improve
class SliverBodyPlaceholder extends HookConsumerWidget {
  const SliverBodyPlaceholder(this.children, {super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
    );
  }
}

class SliverLoadingBodyPlaceholder extends HookConsumerWidget {
  const SliverLoadingBodyPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator()]),
    );
  }
}

class SliverErrorBodyPlaceholder extends HookConsumerWidget {
  const SliverErrorBodyPlaceholder(this.msg, {super.key, this.icon = FluentIcons.error_circle_24_regular});

  final String msg;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon), const Gap(16)],
          Text(msg),
        ],
      ),
    );
  }
}
