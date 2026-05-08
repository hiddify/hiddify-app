import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/overview/chain_mode_button.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChainTimelineHeader extends HookConsumerWidget {
  const ChainTimelineHeader(this.level, {super.key});

  final ChainTimelineLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsetsDirectional.only(end: 16),
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadiusDirectional.only(topEnd: Radius.circular(100), bottomEnd: Radius.circular(100)),
      ),
      child: Row(
        children: [
          const Gap(4),
          SizedBox(child: Icon(level.icon(), size: 20, color: theme.colorScheme.onSurfaceVariant)),
          const Gap(12),
          Expanded(
            child: Text(
              level.present(t).title,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
              maxLines: 1,
            ),
          ),
          const Gap(12),
          AnimatedOpacity(
            duration: ChainConst.finalIpDuration,
            opacity:
                (level.isMainProfile() && !ref.watch(ConfigOptions.chainStatus).isExtraSecurity() ||
                    level.isExtraSecurity() && ref.watch(ConfigOptions.chainStatus).isExtraSecurity())
                ? 1
                : 0,
            child: Text(
              t.pages.settings.chain.finalIp,
              style: theme.textTheme.labelMedium?.copyWith(color: ChainConst.finalIpColor(theme)),
              maxLines: 1,
            ),
          ),
          const Gap(12),
          if (level.isExtraSecurity()) const ChainModeButton.extraSecurity(),
          if (level.isUnblocker()) const ChainModeButton.unblocker(),
        ],
      ),
    );
  }
}
