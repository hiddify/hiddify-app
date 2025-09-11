import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/animated_visibility.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/utils/perf_monitor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyDelayIndicator extends HookConsumerWidget {
  const ActiveProxyDelayIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);

    return RepaintBoundary(
        child: AnimatedVisibility(
      axis: Axis.vertical,
      visible: activeProxy is AsyncData,
      child: () {
        switch (activeProxy) {
          case AsyncData(value: final proxy):
            final delay = proxy.urlTestDelayInt; // Use Int version
            final timeout = delay > 65000;

            return Center(
              child: InkWell(
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await PerfMonitor.instance.measure('urlTest(${proxy.tag})', () async {
                      await ref.read(activeProxyNotifierProvider.notifier).urlTest(proxy.tag);
                    });
                    // Force repaint after url test completes
                    SchedulerBinding.instance.scheduleFrame();
                  });
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
                            text: timeout ? "∞" : "${delay}ms",
                            style: TextStyle(
                              color: timeout ? Theme.of(context).colorScheme.error : null,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            );
          default:
            return const SizedBox();
        }
      }(),
    ));
  }
}
