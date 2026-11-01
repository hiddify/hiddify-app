import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
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

    Future<void> onTap() async {
      // a ping that fails while connected has a reason the connection check explains
      final health = ref.read(connectionHealthProvider);
      if (health != null && (health.degraded || health.hopPending)) {
        return ref.read(bottomSheetsNotifierProvider.notifier).showConnectionHealth();
      }
      try {
        await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
      } catch (e) {
        loggy.error("Error during URL test: $e");
      }
    }

    return SizedBox(
      height: _slotHeight,
      child: Center(
        child: delay > 0 && !isValid
            ? _Unavailable(
                canSwitch: canSwitch,
                onTap: onTap,
                onSwitch: ref.read(activeProxyNotifierProvider.notifier).switchToFastest,
              )
            : InkWell(
                onTap: onTap,
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
                          semanticsLabel: t.pages.proxies.delay.result(delay: delay),
                          TextSpan(
                            children: [
                              TextSpan(
                                text: delay.toString(),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
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
                  ),
                ),
              ),
      ),
    );
  }
}

/// The selected proxy does not answer: one capsule says so, in the error color, and offers the
/// fastest server in its other half when one answers. The status half opens the connection check.
class _Unavailable extends ConsumerWidget {
  const _Unavailable({required this.canSwitch, required this.onTap, required this.onSwitch});

  final bool canSwitch;
  final VoidCallback onTap;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final green = theme.extension<ConnectionButtonTheme>()!.connectedColor!;
    final label = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    return Material(
          color: s.error.withValues(alpha: .10),
          shape: StadiumBorder(side: BorderSide(color: s.error.withValues(alpha: .22))),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: t.pages.proxies.delay.timeout,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 18, color: s.error),
                        const Gap(6),
                        Text(t.connection.health.unavailable, style: label?.copyWith(color: s.error)),
                      ],
                    ),
                  ),
                ),
              ),
              // the way out, in the connected green, grows in beside the status when one appears
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: canSwitch
                    ? Material(
                        color: green.withValues(alpha: .16),
                        child: InkWell(
                          onTap: onSwitch,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 18, color: green),
                                const Gap(4),
                                Text(t.connection.health.useFastest, style: label?.copyWith(color: green)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        )
        // it arrives once, softly, under the label that names the problem
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: .4, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
