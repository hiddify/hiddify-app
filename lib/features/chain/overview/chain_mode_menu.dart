import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/adaptive_menu.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/overview/chain_mode_icon.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChainModeMenu extends HookConsumerWidget {
  const ChainModeMenu(this.builder, {super.key, this.child, required this.type, required this.showConfiguration});

  final ChainType type;
  final bool showConfiguration;
  final AdaptiveMenuBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final menuItems = [
      AdaptiveMenuItem(
        leadingIcon: const Icon(Icons.block, size: 16),
        title: t.common.disable,
        onTap: () async {
          final status = ref.read(ConfigOptions.chainStatus);
          if (type.isEnable(status)) await ref.read(ConfigOptions.chainStatus.notifier).update(ChainStatus.off);
        },
      ),
      ...ChainMode.values.map((e) {
        return AdaptiveMenuItem(
          leadingIcon: ChainModeIcon(mode: e),
          title: e.present(t),
          divider: e == ChainMode.profile && showConfiguration,
          onTap: () async {
            switch (type) {
              case ChainType.extraSecurity:
                await ref.read(ConfigOptions.chainStatus.notifier).update(ChainStatus.extraSecurity);
                await ref.read(ConfigOptions.extraSecurityMode.notifier).update(e);
              case ChainType.unblocker:
                await ref.read(ConfigOptions.chainStatus.notifier).update(ChainStatus.unblocker);
                await ref.read(ConfigOptions.unblockerMode.notifier).update(e);
            }
          },
        );
      }),
      if (showConfiguration)
        AdaptiveMenuItem(
          title: t.common.configuration,
          trailingIcon: const Icon(Icons.arrow_right, size: 16),
          onTap: () {
            context.pop();
            context.goNamed('chainOptions');
          },
        ),
    ];

    return AdaptiveMenu(builder: builder, items: menuItems, child: child);
  }
}
