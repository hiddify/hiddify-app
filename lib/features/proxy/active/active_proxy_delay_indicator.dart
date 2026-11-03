import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/core/widget/unique_keys_layout.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
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
    final card = ref.watch(activeProxyCardProvider);
    final green = theme.extension<ConnectionButtonTheme>()!.connectedColor!;
    final error = theme.colorScheme.error;
    final bold = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);
    // The selected proxy can be dead while the hop shows no delay yet, so the card says so too.
    final dead = (delay > 0 && !isValid) || card?.serverStatus == StepStatus.failed;
    final offer = card?.offerLowest ?? false;

    final content = switch ((offer, dead)) {
      (true, _) => Row(
        key: const ValueKey('offer'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: error.withValues(alpha: .18), shape: BoxShape.circle),
            child: Center(child: Icon(FluentIcons.wifi_off_24_regular, size: 16, color: error)),
          ),
          const Gap(8),
          Icon(Icons.bolt_rounded, size: 18, color: green),
          const Gap(4),
          Text(t.connection.health.useFastest, style: bold?.copyWith(color: green)),
        ],
      ),
      (_, true) => Row(
        key: const ValueKey('dead'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.wifi_off_24_regular, size: 18, color: error),
          const Gap(6),
          Text(t.pages.proxies.delay.unavailable, style: bold?.copyWith(color: error)),
        ],
      ),
      _ => Row(
        key: ValueKey(delay),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.wifi_1_24_regular, size: 20),
          const Gap(6),
          if (isValid)
            Text.rich(
              semanticsLabel: t.pages.proxies.delay.result(delay: delay),
              TextSpan(
                children: [
                  TextSpan(text: delay.toString(), style: bold),
                  TextSpan(
                    text: " ms",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            Semantics(label: t.pages.proxies.delay.testing, child: const ShimmerSkeleton(width: 44, height: 16)),
        ],
      ),
    };

    final pingPill = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      height: 36,
      decoration: BoxDecoration(
        color: offer
            ? green.withValues(alpha: .16)
            : dead
            ? error.withValues(alpha: .14)
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () async {
            final notifier = ref.read(activeProxyNotifierProvider.notifier);
            try {
              if (offer) {
                await notifier.switchToLowest(card!.mainGroup);
              } else {
                await notifier.urlTest("");
              }
            } catch (e) {
              loggy.error("Error during ${offer ? "switch to lowest" : "URL test"}: $e");
            }
          },
          // the upload speed of the proxy in use, shown on the proxy card
          onLongPress: offer || dead ? null : () => ref.read(activeProxyNotifierProvider.notifier).uploadTest(),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(left: offer ? 4 : 14, right: 14),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                layoutBuilder: uniqueKeysLayout(),
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(animation), child: child),
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      height: _slotHeight,
      child: Center(child: pingPill),
    );
  }
}
