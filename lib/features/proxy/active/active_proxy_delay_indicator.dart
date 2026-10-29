import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyDelayIndicator extends HookConsumerWidget with InfraLogger {
  const ActiveProxyDelayIndicator({super.key});

  /// Matches the padded delay row so a stream rebind on resume cannot collapse
  /// this slot and recenter the connect button.
  static const _slotHeight = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // a ping the core found, or the timeout it found on the proxy the user selected
    final connected = ref.watch(
      connectionNotifierProvider.select((s) => s.valueOrNull is Connected || s.valueOrNull is NoAvailableProxies),
    );
    // Stale OutboundInfo can linger in valueOrNull after disconnect; never show then.
    if (!connected) return const SizedBox.shrink();

    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final theme = Theme.of(context);

    // Prefer valueOrNull so AsyncLoading-with-previous (coreRestart after resume)
    // keeps the last delay instead of returning an empty box via `is! AsyncData`.
    final proxy = activeProxy.valueOrNull;
    if (proxy == null) {
      // Only reserve space while rebinding; stay collapsed when truly disconnected.
      if (!activeProxy.isLoading) return const SizedBox.shrink();
      return const SizedBox(
        height: _slotHeight,
        child: Center(child: ShimmerSkeleton(width: 48, height: 18)),
      );
    }

    final delay = proxy.urlTestDelay;
    final isValid = ConnectionConst.isValidDelay(delay);

    return SizedBox(
      height: _slotHeight,
      child: Center(
        child: InkWell(
          onTap: () async {
            try {
              await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
            } catch (e) {
              loggy.error("Error during URL test: $e");
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FluentIcons.wifi_1_24_regular),
                const Gap(8),
                if (delay > 0)
                  Text.rich(
                    semanticsLabel: isValid
                        ? t.pages.proxies.delay.result(delay: delay)
                        : t.pages.proxies.delay.timeout,
                    TextSpan(
                      children: [
                        if (isValid) ...[
                          TextSpan(
                            text: delay.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: " ms"),
                        ] else
                          TextSpan(
                            text: t.common.timeout,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Semantics(label: t.pages.proxies.delay.testing, child: const ShimmerSkeleton(width: 48, height: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
