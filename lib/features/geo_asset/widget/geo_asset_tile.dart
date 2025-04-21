// class GeoAssetTile extends HookConsumerWidget {
//   GeoAssetTile(
//     GeoAssetWithFileSize geoAssetWithFileSize, {
//     super.key,
//     required this.onMarkAsActive,
//   })  : geoAsset = geoAssetWithFileSize.$1,
//         size = geoAssetWithFileSize.$2;

//   final GeoAssetEntity geoAsset;
//   final int? size;
//   final VoidCallback onMarkAsActive;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = ref.watch(translationsProvider).requireValue;
//     final fetchState = ref.watch(fetchGeoAssetProvider(geoAsset.id));
//     final fileMissing = size == null;

//     ref.listen(
//       fetchGeoAssetProvider(geoAsset.id),
//       (_, next) {
//         switch (next) {
//           case AsyncError(:final error):
//             if (error case GeoAssetNoUpdateAvailable()) {
//               return CustomToast(t.failure.geoAssets.notUpdate).show(context);
//             }
//             CustomAlertDialog.fromErr(t.presentError(error)).show(context);
//           case AsyncData(value: final _?):
//             CustomToast.success(t.settings.geoAssets.successMsg).show(context);
//         }
//       },
//     );

//     return ListTile(
//       title: Text.rich(
//         TextSpan(
//           children: [
//             TextSpan(text: geoAsset.name),
//             if (geoAsset.providerName.isNotBlank)
//               TextSpan(text: " (${geoAsset.providerName})"),
//           ],
//         ),
//       ),
//       isThreeLine: true,
//       subtitle: fetchState.isLoading
//           ? const LinearProgressIndicator()
//           : Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 if (geoAsset.version.isNotNullOrBlank)
//                   Padding(
//                     padding: const EdgeInsetsDirectional.only(end: 8),
//                     child: Text(
//                       t.settings.geoAssets.version(version: geoAsset.version!),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   )
//                 else
//                   const SizedBox(),
//                 Flexible(
//                   child: Text.rich(
//                     TextSpan(
//                       children: [
//                         if (fileMissing)
//                           TextSpan(
//                             text: t.settings.geoAssets.fileMissing,
//                             style: TextStyle(
//                               color: Theme.of(context).colorScheme.error,
//                             ),
//                           )
//                         else
//                           TextSpan(text: size?.bytes().toString()),
//                         if (geoAsset.lastCheck != null) ...[
//                           const TextSpan(text: " • "),
//                           TextSpan(text: geoAsset.lastCheck!.format()),
//                         ],
//                       ],
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//       selected: geoAsset.active,
//       onTap: onMarkAsActive,
//       trailing: PopupMenuButton(
//         icon: Icon(AdaptiveIcon(context).more),
//         itemBuilder: (context) {
//           return [
//             PopupMenuItem(
//               enabled: !fetchState.isLoading,
//               onTap: () => ref
//                   .read(FetchGeoAssetProvider(geoAsset.id).notifier)
//                   .fetch(geoAsset),
//               child: fileMissing
//                   ? Text(t.settings.geoAssets.download)
//                   : Text(t.settings.geoAssets.update),
//             ),
//           ];
//         },
//       ),
//     );
//   }
// }
