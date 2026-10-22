import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyDelayIndicator extends HookConsumerWidget with InfraLogger {
  const ActiveProxyDelayIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final theme = Theme.of(context);
    final blizzard =
        BlizzardPresentation.isActive(context) || (theme.extension<BlizzardEligibility>()?.applied ?? false);

    if (theme.platform == TargetPlatform.iOS && ref.watch(iosActiveProxyMeasurementEnabledProvider)) {
      return const IosActiveProxyDelayIndicator();
    }

    if (activeProxy is! AsyncData) {
      return const SizedBox(); // Avoid building widget if data is not available
    }

    final proxy = activeProxy.value!;
    final delay = proxy.urlTestDelay;
    final timeout = delay > 65000;

    return Center(
      heightFactor: blizzard ? 1 : null,
      child: InkWell(
        onTap: () async {
          try {
            await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
          } catch (e) {
            // Handle error here
            loggy.error("Error during URL test: $e");
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: blizzard
              ? const EdgeInsets.fromLTRB(16, 2, 16, 22)
              : const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!blizzard) ...[const Icon(FluentIcons.wifi_1_24_regular), const Gap(8)],
              if (delay > 0)
                Text.rich(
                  semanticsLabel: timeout ? t.pages.proxies.delay.timeout : t.pages.proxies.delay.result(delay: delay),
                  TextSpan(
                    children: blizzard
                        ? [
                            TextSpan(
                              text: timeout
                                  ? t.common.timeout
                                  : t.pages.proxies.delay.result(delay: delay).replaceFirst(': ', ' '),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                                height: 20 / 15,
                                fontWeight: FontWeight.w400,
                                color: timeout ? theme.colorScheme.error : BlizzardPalette.muted,
                              ),
                            ),
                          ]
                        : [
                            if (timeout)
                              TextSpan(
                                text: t.common.timeout,
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
                Semantics(label: t.pages.proxies.delay.testing, child: const ShimmerSkeleton(width: 48, height: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
