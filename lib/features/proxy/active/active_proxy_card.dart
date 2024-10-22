import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/core/widget/animated_visibility.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
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
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final ipInfo = ref.watch(ipInfoNotifierProvider);
    final theme = Theme.of(context);
    final proxy = activeProxy.valueOrNull;
    return AnimatedVisibility(
      axis: Axis.vertical,
      visible: connectionStatus.value == Connected(),
      child: switch (connectionStatus) {
        AsyncData(value: Connected()) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: InkWell(
              onTap: () => ProxiesRoute().go(context),
              child: Column(children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  padding: const EdgeInsets.all(16),
                  // width: 350,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background.withOpacity(1),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.secondary.withOpacity(.21),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                          onTap: () => ref.read(ipInfoNotifierProvider.notifier).refresh(),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: switch (ipInfo) {
                                AsyncData(value: final info) => IPCountryFlag(
                                    countryCode: info.countryCode,
                                    size: 48,
                                    padding: const EdgeInsets.all(0),
                                  ),
                                AsyncError(error: final UnknownIp _) => const Icon(FluentIcons.arrow_sync_20_regular, size: 48),
                                AsyncError() => const Icon(FluentIcons.error_circle_20_regular, size: 48),
                                _ => const Icon(FluentIcons.question_circle_20_regular, size: 48),
                              })),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ProxiesRoute().go(context);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                  label: t.proxies.activeProxySemanticLabel,
                                  child: Text(
                                    proxy?.tagDisplay ?? "",
                                    style: theme?.textTheme?.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    // TextStyle(
                                    //   //   fontSize: 18,
                                    //   fontWeight: FontWeight.bold,
                                    // ),
                                  )),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  switch (ipInfo) {
                                    AsyncData(value: final info) => Row(
                                        children: [
                                          // const Gap(4),
                                          IPText(
                                            ip: info.ip,
                                            onLongPress: () async {
                                              ref.read(ipInfoNotifierProvider.notifier).refresh();
                                            },
                                            constrained: true,
                                          ),
                                          const Gap(4),
                                          OrganisationFlag(organization: info.org ?? ""),

                                          // const Gap(8),
                                        ],
                                      ),
                                    AsyncError(error: final UnknownIp _) => Row(
                                        children: [
                                          // const Icon(FluentIcons.arrow_sync_20_regular),
                                          // const Gap(8),
                                          UnknownIPText(
                                            text: t.proxies.checkIp,
                                            onTap: () async {
                                              ref.read(ipInfoNotifierProvider.notifier).refresh();
                                            },
                                          ),
                                        ],
                                      ),
                                    _ => Row(
                                        children: [
                                          // const Icon(FluentIcons.error_circle_20_regular),
                                          // const Gap(8),
                                          UnknownIPText(
                                            text: t.proxies.unknownIp,
                                            onTap: () async {
                                              ref.read(ipInfoNotifierProvider.notifier).refresh();
                                            },
                                          ),
                                        ],
                                      ),
                                    // _ => const Row(
                                    //     children: [
                                    //       // Icon(FluentIcons.question_circle_20_regular),
                                    //       // Gap(8),
                                    //       // Flexible(
                                    //       //   child: ShimmerSkeleton(
                                    //       //     height: 16,
                                    //       //     widthFactor: 1,
                                    //       //   ),
                                    //       // ),
                                    //     ],
                                    //   ),
                                  },
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Flexible(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           _InfoProp(
                //             icon: FluentIcons.arrow_routing_20_regular,
                //             text: proxy.selectedName.isNotNullOrBlank ? proxy.selectedName! : proxy.name,
                //             semanticLabel: t.proxies.activeProxySemanticLabel,
                //           ),
                //           const Gap(8),
                //         ],
                //       ),
                //     ),
                //     const _StatsColumn(),
                //   ],
                // ),
              ]),
            )),
        _ => const SizedBox(),
      },
    );
  }
}

class _StatsColumn extends HookConsumerWidget {
  const _StatsColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final stats = ref.watch(statsNotifierProvider).value;

    return Directionality(
      textDirection: TextDirection.values[(Directionality.of(context).index + 1) % TextDirection.values.length],
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
  const _InfoProp({
    required this.icon,
    required this.text,
    this.semanticLabel,
  });

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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFamily: FontFamily.emoji),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
