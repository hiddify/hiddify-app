// class ActiveProxyFooter extends HookConsumerWidget {
//   const ActiveProxyFooter({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Column();
//     final t = ref.watch(translationsProvider).requireValue;
//     final activeProxy = ref.watch(activeProxyNotifierProvider);
//     // final ipInfo = ref.watch(ipInfoNotifierProvider);

//     return AnimatedVisibility(
//       axis: Axis.vertical,
//       visible: activeProxy is AsyncData,
//       child: switch (activeProxy) {
//         AsyncData(value: final proxy) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Flexible(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _InfoProp(
//                         icon: FluentIcons.arrow_routing_20_regular,
//                         text: proxy.tagDisplay,
//                         semanticLabel: t.proxies.activeProxySemanticLabel,
//                       ),
//                       const Gap(8),
//                       if (proxy.ipinfo.ip.isNotEmpty)
//                         Row(
//                           children: [
//                             IPCountryFlag(countryCode: proxy.ipinfo.countryCode),
//                             const Gap(4),
//                             OrganisationFlag(organization: proxy.ipinfo.org),
//                             const Gap(4),
//                             IPText(
//                               ip: proxy.ipinfo.ip,
//                               onLongPress: () async {
//                                 ref.read(ipInfoNotifierProvider.notifier).refresh();
//                               },
//                             ),
//                             // const Gap(8),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             const Icon(FluentIcons.arrow_sync_20_regular),
//                             const Gap(8),
//                             UnknownIPText(
//                               text: t.proxies.checkIp,
//                               onTap: () async {
//                                 ref.read(ipInfoNotifierProvider.notifier).refresh();
//                               },
//                             ),
//                           ],
//                         ),
//                       // switch (ipInfo) {
//                       //   AsyncData(value: final info) => Row(
//                       //       children: [
//                       //         IPCountryFlag(countryCode: info.countryCode),
//                       //         const Gap(4),
//                       //         OrganisationFlag(organization: info.org ?? ""),
//                       //         const Gap(4),
//                       //         IPText(
//                       //           ip: info.ip,
//                       //           onLongPress: () async {
//                       //             ref.read(ipInfoNotifierProvider.notifier).refresh();
//                       //           },
//                       //         ),
//                       //         // const Gap(8),
//                       //       ],
//                       //     ),
//                       //   AsyncError(error: final UnknownIp _) => Row(
//                       //       children: [
//                       //         const Icon(FluentIcons.arrow_sync_20_regular),
//                       //         const Gap(8),
//                       //         UnknownIPText(
//                       //           text: t.proxies.checkIp,
//                       //           onTap: () async {
//                       //             ref.read(ipInfoNotifierProvider.notifier).refresh();
//                       //           },
//                       //         ),
//                       //       ],
//                       //     ),
//                       //   AsyncError() => Row(
//                       //       children: [
//                       //         const Icon(FluentIcons.error_circle_20_regular),
//                       //         const Gap(8),
//                       //         UnknownIPText(
//                       //           text: t.proxies.unknownIp,
//                       //           onTap: () async {
//                       //             ref.read(ipInfoNotifierProvider.notifier).refresh();
//                       //           },
//                       //         ),
//                       //       ],
//                       //     ),
//                       //   _ => const Row(
//                       //       children: [
//                       //         Icon(FluentIcons.question_circle_20_regular),
//                       //         Gap(8),
//                       //         Flexible(
//                       //           child: ShimmerSkeleton(
//                       //             height: 16,
//                       //             widthFactor: 1,
//                       //           ),
//                       //         ),
//                       //       ],
//                       //     ),
//                       // },
//                     ],
//                   ),
//                 ),
//                 const _StatsColumn(),
//               ],
//             ),
//           ),
//         _ => const SizedBox(),
//       },
//     );
//   }
// }

// class _StatsColumn extends HookConsumerWidget {
//   const _StatsColumn();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = ref.watch(translationsProvider).requireValue;
//     final stats = ref.watch(statsNotifierProvider).value;

//     return Directionality(
//       textDirection: TextDirection.values[(Directionality.of(context).index + 1) % TextDirection.values.length],
//       child: Flexible(
//         child: Column(
//           children: [
//             _InfoProp(
//               icon: FluentIcons.arrow_bidirectional_up_down_20_regular,
//               text: (stats?.downlinkTotal.toInt() ?? 0).size(),
//               semanticLabel: t.stats.totalTransferred,
//             ),
//             const Gap(8),
//             _InfoProp(
//               icon: FluentIcons.arrow_download_20_regular,
//               text: (stats?.downlink.toInt() ?? 0).speed(),
//               semanticLabel: t.stats.speed,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _InfoProp extends StatelessWidget {
//   const _InfoProp({
//     required this.icon,
//     required this.text,
//     this.semanticLabel,
//   });

//   final IconData icon;
//   final String text;
//   final String? semanticLabel;

//   @override
//   Widget build(BuildContext context) {
//     return Semantics(
//       label: semanticLabel,
//       child: Row(
//         children: [
//           Icon(icon),
//           const Gap(8),
//           Flexible(
//             child: Text(
//               text,
//               style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFamily: FontFamily.emoji),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
