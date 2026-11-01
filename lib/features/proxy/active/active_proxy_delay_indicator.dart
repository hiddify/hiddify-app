import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
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

    // the selected proxy is down while another one works: one tap moves to it, beside its ping
    final canSwitch = ref.watch(connectionHealthProvider.select((h) => h?.canSwitchToFastest ?? false));

    // a tap tests the selected proxy again, answering or not; the label above opens the check
    Future<void> urlTest() async {
      try {
        await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
      } catch (e) {
        loggy.error("Error during URL test: $e");
      }
    }

    final s = theme.colorScheme;
    final value = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return SizedBox(
      height: _slotHeight,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: urlTest,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (delay > 0 && !isValid) ...[
                      // the same row as a ping, in the error colour: unavailable in place of the ms
                      Icon(Icons.wifi_off_rounded, color: s.error),
                      const Gap(8),
                      Text(
                        t.connection.health.unavailable,
                        semanticsLabel: t.pages.proxies.delay.timeout,
                        style: value?.copyWith(color: s.error),
                      ),
                    ] else ...[
                      const Icon(FluentIcons.wifi_1_24_regular),
                      const Gap(8),
                      if (delay > 0)
                        Text.rich(
                          semanticsLabel: t.pages.proxies.delay.result(delay: delay),
                          TextSpan(
                            children: [
                              TextSpan(text: delay.toString(), style: value),
                              const TextSpan(text: " ms"),
                            ],
                          ),
                        )
                      else
                        Semantics(
                          label: t.pages.proxies.delay.testing,
                          child: const ShimmerSkeleton(width: 48, height: 18),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            // the way out, in the connected green, grows in beside the ping when one appears
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: canSwitch
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: _UseFastest(onTap: ref.read(activeProxyNotifierProvider.notifier).switchToFastest),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short green chip: the fastest server answers, one tap moves to it.
class _UseFastest extends ConsumerWidget {
  const _UseFastest({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final green = theme.extension<ConnectionButtonTheme>()!.connectedColor!;
    return Material(
      color: green.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: green),
              const Gap(4),
              Text(
                t.connection.health.useFastest,
                style: theme.textTheme.labelLarge?.copyWith(color: green, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: -.2, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
