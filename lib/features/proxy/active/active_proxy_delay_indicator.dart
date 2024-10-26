import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/animated_visibility.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyDelayIndicator extends HookConsumerWidget {
  const ActiveProxyDelayIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final activeProxy = ref.watch(activeProxyNotifierProvider);

    return AnimatedVisibility(
      axis: Axis.vertical,
      visible: activeProxy is AsyncData,
      child: () {
        switch (activeProxy) {
          case AsyncData(value: final proxy):
            final delay = proxy.urlTestDelay;
            final timeout = delay > 65000;

            return Center(
              child: InkWell(
                onTap: () async {
                  await ref.read(activeProxyNotifierProvider.notifier).urlTest(proxy.tag);
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.wifi_1_24_regular),
                      const Gap(8),
                      if (delay > 0)
                        Text.rich(
                          semanticsLabel: timeout ? t.proxies.delaySemantics.timeout : t.proxies.delaySemantics.result(delay: delay),
                          TextSpan(
                            children: [
                              if (timeout)
                                TextSpan(
                                  text: t.general.timeout,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.error,
                                  ),
                                )
                              else ...[
                                TextSpan(
                                  text: delay.toString(),
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: " ms"),
                              ],
                            ],
                          ),
                        )
                      else
                        Semantics(
                          label: t.proxies.delaySemantics.testing,
                          child: const ShimmerSkeleton(width: 48, height: 18),
                        ),
                    ],
                  ),
                ),
              ),
            );
          default:
            return const SizedBox();
        }
      }(),
    );
  }
}
