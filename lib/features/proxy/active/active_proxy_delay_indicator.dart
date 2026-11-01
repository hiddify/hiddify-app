import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/overview/chain_mode_icon.dart';
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

    return SizedBox(
      height: _slotHeight,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card?.hopStatus case final status?) _ChainPill(card!, status),
            InkWell(
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
                      Semantics(
                        label: t.pages.proxies.delay.testing,
                        child: const ShimmerSkeleton(width: 48, height: 18),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chain hop beside the ping: its icon and its state in a pill.
/// The icon breathes while the hop connects and turns grey while it waits or has failed.
class _ChainPill extends HookWidget {
  const _ChainPill(this.card, this.status);
  final ActiveProxyCardData card;
  final StepStatus status;

  static const _iconSize = 17.0;
  static const _stateSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final connecting = status == StepStatus.connecting || status == StepStatus.slow;
    final breath = useAnimationController(duration: const Duration(milliseconds: 1300));
    useEffect(() {
      connecting ? breath.repeat(reverse: true) : breath.value = 1;
      return null;
    }, [connecting]);

    final type = card.chain.isUnblocker() ? ChainType.unblocker : ChainType.extraSecurity;
    Widget icon = SizedBox.square(
      dimension: _iconSize,
      child: FittedBox(
        child: ChainTypeIcon(type: type, mode: card.hopMode),
      ),
    );
    if (status == StepStatus.waiting || status == StepStatus.failed) {
      icon = ColorFiltered(
        colorFilter: ColorFilter.mode(s.onSurface.withValues(alpha: .35), BlendMode.srcIn),
        child: icon,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: s.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: CurvedAnimation(parent: breath, curve: Curves.easeInOut).drive(Tween(begin: .35, end: 1)),
            child: icon,
          ),
          const Gap(5),
          SizedBox.square(
            dimension: _stateSize,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (status) {
                StepStatus.connecting || StepStatus.slow => CircularProgressIndicator(
                  key: const ValueKey('connecting'),
                  strokeWidth: 1.6,
                  backgroundColor: s.onSurface.withValues(alpha: .2),
                ),
                StepStatus.connected => Icon(
                  Icons.check_circle_rounded,
                  key: const ValueKey('connected'),
                  size: _stateSize,
                  color: Theme.of(context).extension<ConnectionButtonTheme>()!.connectedColor,
                ),
                StepStatus.failed => Icon(
                  Icons.error_rounded,
                  key: const ValueKey('failed'),
                  size: _stateSize,
                  color: s.error,
                ),
                StepStatus.waiting => Container(
                  key: const ValueKey('waiting'),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: s.onSurface.withValues(alpha: .28), width: 1.4),
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
