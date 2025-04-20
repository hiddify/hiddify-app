// class GeoAssetsOverviewPage extends HookConsumerWidget {
//   const GeoAssetsOverviewPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = ref.watch(translationsProvider).requireValue;
//     final state = ref.watch(geoAssetsOverviewNotifierProvider);

//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             title: Text(t.settings.geoAssets.pageTitle),
//             pinned: true,
//             actions: [
//               PopupMenuButton(
//                 icon: Icon(AdaptiveIcon(context).more),
//                 itemBuilder: (context) {
//                   return [
//                     PopupMenuItem(
//                       child: Text(t.settings.geoAssets.addRecommended),
//                       onTap: () {
//                         ref
//                             .read(geoAssetsOverviewNotifierProvider.notifier)
//                             .addRecommended();
//                       },
//                     ),
//                   ];
//                 },
//               ),
//             ],
//           ),
//           if (state case AsyncData(value: (:final geoip, :final geosite)))
//             SliverPinnedHeader(
//               child: AnimatedVisibility(
//                 visible: (geoip + geosite)
//                     .where((e) => e.$1.active && e.$2 == null)
//                     .isNotEmpty,
//                 axis: Axis.vertical,
//                 child:
//                     TipCard(message: t.settings.geoAssets.missingGeoAssetsMsg),
//               ),
//             ),
//           switch (state) {
//             AsyncData(value: (:final geoip, :final geosite)) => MultiSliver(
//                 children: [
//                   ListTile(
//                     title: Text("${t.settings.geoAssets.geoip} ›"),
//                     titleTextStyle: Theme.of(context).textTheme.headlineSmall,
//                     dense: true,
//                   ),
//                   SliverList.builder(
//                     itemBuilder: (context, index) {
//                       final geoAsset = geoip[index];
//                       return GeoAssetTile(
//                         geoAsset,
//                         onMarkAsActive: () => ref
//                             .read(geoAssetsOverviewNotifierProvider.notifier)
//                             .markAsActive(geoAsset.$1),
//                       );
//                     },
//                     itemCount: geoip.length,
//                   ),
//                   const Divider(indent: 16, endIndent: 16),
//                   ListTile(
//                     title: Text("${t.settings.geoAssets.geosite} ›"),
//                     titleTextStyle: Theme.of(context).textTheme.headlineSmall,
//                     dense: true,
//                   ),
//                   SliverList.builder(
//                     itemBuilder: (context, index) {
//                       final geoAsset = geosite[index];
//                       return GeoAssetTile(
//                         geoAsset,
//                         onMarkAsActive: () => ref
//                             .read(geoAssetsOverviewNotifierProvider.notifier)
//                             .markAsActive(geoAsset.$1),
//                       );
//                     },
//                     itemCount: geosite.length,
//                   ),
//                   const Gap(16),
//                 ],
//               ),
//             _ => const SliverToBoxAdapter(),
//           },
//         ],
//       ),
//     );
//   }
// }
