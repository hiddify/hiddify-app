import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NavBar extends ConsumerWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final freeSwitch = ref.watch(freeSwitchNotifierProvider);

    final textColor = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(
        AddProfileModalConst.navBarGap,
      ).copyWith(bottom: AddProfileModalConst.navBarBottomGap),
      child: Row(
        children: [
          Row(
            key: const ValueKey('free'),
            children: [
              Text(t.common.free, style: theme.textTheme.titleMedium!.copyWith(color: textColor)),
              const Gap(8),
              Switch(value: freeSwitch, onChanged: ref.read(freeSwitchNotifierProvider.notifier).onChange),
            ],
          ),
          const Spacer(),
          ActionChip(
            key: const ValueKey("help"),
            label: Text(t.common.help, style: theme.textTheme.labelLarge!.copyWith(color: textColor)),
            avatar: Icon(Icons.help_outline, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () async => await ref.read(dialogNotifierProvider.notifier).showNoActiveProfile(),
          ),
        ],
      ),
    );
  }
}
