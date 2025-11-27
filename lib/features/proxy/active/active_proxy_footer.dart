import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/animated_visibility.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyFooter extends HookConsumerWidget {
  const ActiveProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasActiveProxy = ref.watch(
      activeProxyProvider.select((value) => value is AsyncData),
    );
    final activeProxyName = ref.watch(
      activeProxyProvider.select((value) {
        final data = value.asData?.value;
        if (data == null) return null;
        return data.selectedName.isNotNullOrBlank
            ? data.selectedName!
            : data.name;
      }),
    );
    final ipInfo = ref.watch(ipInfoProvider);

    return AnimatedVisibility(
      axis: Axis.vertical,
      visible: hasActiveProxy,
      child: hasActiveProxy
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoProp(
                          icon: FluentIcons.arrow_routing_20_regular,
                          text: activeProxyName ?? "...",
                          semanticLabel: t.proxies.activeProxySemanticLabel,
                        ),
                        const Gap(8),
                        switch (ipInfo) {
                          AsyncData(value: final info) => Row(
                            children: [
                              IPCountryFlag(countryCode: info.countryCode),
                              const Gap(8),
                              IPText(
                                ip: info.ip,
                                onLongPress: () {
                                  ref.read(ipInfoProvider.notifier).refresh();
                                },
                              ),
                            ],
                          ),
                          AsyncError(error: final UnknownIp _) => Row(
                            children: [
                              const Icon(FluentIcons.arrow_sync_20_regular),
                              const Gap(8),
                              UnknownIPText(
                                text: t.proxies.checkIp,
                                onTap: () {
                                  ref.read(ipInfoProvider.notifier).refresh();
                                },
                              ),
                            ],
                          ),
                          AsyncError() => Row(
                            children: [
                              const Icon(FluentIcons.error_circle_20_regular),
                              const Gap(8),
                              UnknownIPText(
                                text: t.proxies.unknownIp,
                                onTap: () {
                                  ref.read(ipInfoProvider.notifier).refresh();
                                },
                              ),
                            ],
                          ),
                          _ => const Row(
                            children: [
                              Icon(FluentIcons.question_circle_20_regular),
                              Gap(8),
                              Flexible(
                                child: ShimmerSkeleton(
                                  height: 16,
                                  widthFactor: 1,
                                ),
                              ),
                            ],
                          ),
                        },
                      ],
                    ),
                  ),
                  const _StatsColumn(),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}

class _StatsColumn extends HookConsumerWidget {
  const _StatsColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final stats = ref.watch(statsProvider).value;

    return Directionality(
      textDirection:
          TextDirection.values[(Directionality.of(context).index + 1) %
              TextDirection.values.length],
      child: Flexible(
        child: Column(
          children: [
            _InfoProp(
              icon: FluentIcons.arrow_bidirectional_up_down_20_regular,
              text: (stats?.downlinkTotal ?? 0).size(),
              semanticLabel: t.stats.totalTransferred,
            ),
            const Gap(8),
            _InfoProp(
              icon: FluentIcons.arrow_download_20_regular,
              text: (stats?.downlink ?? 0).speed(),
              semanticLabel: t.stats.speed,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoProp extends StatelessWidget {
  const _InfoProp({required this.icon, required this.text, this.semanticLabel});

  final IconData icon;
  final String text;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Row(
        children: [
          Icon(icon),
          const Gap(8),
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontFamily: FontFamily.emoji),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
