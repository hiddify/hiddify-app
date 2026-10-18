import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class IosActiveProxyDelayIndicator extends ConsumerWidget {
  const IosActiveProxyDelayIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(serviceRunningProvider).asData?.value != true) return const SizedBox.shrink();
    final t = ref.watch(translationsProvider).requireValue;
    final snapshot = ref.watch(iosActiveProxyMeasurementStateProvider).asData?.value;
    final phase = snapshot?.phase ?? IosProxyMeasurementPhase.idle;
    final checking = phase == IosProxyMeasurementPhase.checking;
    final delay = snapshot?.proxy?.urlTestDelay;
    final available = phase == IosProxyMeasurementPhase.available && delay != null && delay > 0 && delay <= 65000;
    final timedOut = phase == IosProxyMeasurementPhase.timedOut;
    final label = checking
        ? t.pages.proxies.delay.testing
        : available
        ? t.pages.proxies.delay.result(delay: delay)
        : timedOut
        ? t.pages.proxies.delay.timeout
        : t.common.unknown;

    Future<void> refresh() async {
      try {
        await ref.read(activeProxyNotifierProvider.notifier).urlTest('');
      } on Object {
        // The measurement state already exposes a closed failure or timeout.
      }
    }

    return Center(
      child: Semantics(
        button: true,
        enabled: !checking,
        label: label,
        onTap: checking ? null : refresh,
        child: ExcludeSemantics(
          child: Tooltip(
            message: t.common.update,
            child: InkWell(
              onTap: checking ? null : refresh,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FluentIcons.wifi_1_24_regular),
                    const Gap(8),
                    if (checking)
                      const ShimmerSkeleton(width: 48, height: 18)
                    else
                      Text(
                        available
                            ? '$delay ms'
                            : timedOut
                            ? t.common.timeout
                            : t.common.unknown,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (!checking) ...[const Gap(8), const Icon(Icons.refresh, size: 16)],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
