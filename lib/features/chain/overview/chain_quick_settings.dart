import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/chain/overview/chain_mode_button.dart';
import 'package:hiddify/features/common/custom_text_scroll.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChainQuickSettings extends HookConsumerWidget {
  const ChainQuickSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Gap(4),
                      Icon(ChainConst.iconByPlatform(), size: 20, color: onSurfaceVariant),
                      const Gap(4),
                      Text(
                        t.pages.settings.chain.levels.app.title,
                        style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant),
                      ),
                      const Gap(4),
                    ],
                  ),
                  const Gap(4),
                  Icon(Icons.arrow_downward_rounded, size: 20, color: theme.colorScheme.primary),
                  const Gap(4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      t.pages.settings.chain.levels.extraSecurity.title,
                      style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(2),
                  const ChainModeButton.extraSecurity(showConfiguration: true),
                  const Gap(2),
                  AnimatedOpacity(
                    duration: ChainConst.finalIpDuration,
                    opacity: ref.watch(ConfigOptions.chainStatus).isExtraSecurity() ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        t.pages.settings.chain.finalIp,
                        style: theme.textTheme.labelSmall?.copyWith(color: ChainConst.finalIpColor(theme)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.topCenter,
                      child: Material(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {
                            context.pop();
                            context.goNamed('chainOptions');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Gap(4),
                              Icon(Icons.webhook_rounded, size: 20, color: theme.colorScheme.primary),
                              const Gap(4),
                              Text(
                                t.pages.settings.chain.title,
                                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                              ),
                              const Gap(4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_rounded, size: 20, color: theme.colorScheme.primary),
                      ),
                      Flexible(
                        child: Column(
                          children: [
                            Text(
                              t.pages.settings.chain.levels.mainProfile.title,
                              style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(2),
                            Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              child: CustomTextScroll(
                                ref.watch(activeProfileProvider).value?.name ?? t.common.notSet,
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface),
                              ),
                            ),
                            AnimatedOpacity(
                              duration: ChainConst.finalIpDuration,
                              opacity: ref.watch(ConfigOptions.chainStatus).isExtraSecurity() ? 0 : 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  t.pages.settings.chain.finalIp,
                                  style: theme.textTheme.labelSmall?.copyWith(color: ChainConst.finalIpColor(theme)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_rounded, size: 20, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Gap(4),
                      Icon(Icons.wifi_rounded, size: 20, color: onSurfaceVariant),
                      const Gap(4),
                      Text(
                        t.pages.settings.chain.levels.filtering.title,
                        style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant),
                      ),
                      const Gap(4),
                    ],
                  ),
                  const Gap(4),
                  Icon(Icons.arrow_downward_rounded, size: 20, color: theme.colorScheme.primary),
                  const Gap(4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      t.pages.settings.chain.levels.unblocker.title,
                      style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(2),
                  const ChainModeButton.unblocker(showConfiguration: true),
                  const Gap(2),
                  // For equal height
                  Opacity(
                    opacity: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        t.pages.settings.chain.finalIp,
                        style: theme.textTheme.labelSmall?.copyWith(color: ChainConst.finalIpColor(theme)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
