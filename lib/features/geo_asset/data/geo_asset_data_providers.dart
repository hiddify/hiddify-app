// part 'geo_asset_data_providers.g.dart';

// @Riverpod(keepAlive: true)
// Future<GeoAssetRepository> geoAssetRepository(GeoAssetRepositoryRef ref) async {
//   final repo = GeoAssetRepositoryImpl(
//     geoAssetDataSource: ref.watch(geoAssetDataSourceProvider),
//     geoAssetPathResolver: ref.watch(geoAssetPathResolverProvider),
//     httpClient: ref.watch(httpClientProvider),
//   );
//   await repo.init().getOrElse((l) => throw l).run();
//   return repo;
// }

// @Riverpod(keepAlive: true)
// GeoAssetDataSource geoAssetDataSource(GeoAssetDataSourceRef ref) {
//   return GeoAssetsDao(ref.watch(appDatabaseProvider));
// }

// @Riverpod(keepAlive: true)
// GeoAssetPathResolver geoAssetPathResolver(GeoAssetPathResolverRef ref) {
//   return GeoAssetPathResolver(
//     ref.watch(appDirectoriesProvider).requireValue.workingDir,
//   );
// }
