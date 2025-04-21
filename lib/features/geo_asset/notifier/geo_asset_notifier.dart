// part 'geo_asset_notifier.g.dart';

// @riverpod
// class FetchGeoAsset extends _$FetchGeoAsset with AppLogger {
//   @override
//   Future<Unit?> build(String id) async {
//     ref.disposeDelay(const Duration(seconds: 10));
//     return null;
//   }

//   Future<void> fetch(GeoAssetEntity geoAsset) async {
//     state = const AsyncLoading();
//     state = await AsyncValue.guard(
//       () => ref
//           .read(geoAssetRepositoryProvider)
//           .requireValue
//           .update(geoAsset)
//           .getOrElse(
//         (failure) {
//           loggy.warning("error updating geo asset $failure", failure);
//           throw failure;
//         },
//       ).run(),
//     );
//   }
// }
